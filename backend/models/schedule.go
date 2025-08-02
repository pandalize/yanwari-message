package models

import (
	"context"
	"time"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

// Schedule メッセージ送信スケジュール
type Schedule struct {
	ID             primitive.ObjectID `bson:"_id,omitempty" json:"id"`
	MessageID      primitive.ObjectID `bson:"messageId" json:"messageId"`
	UserID         primitive.ObjectID `bson:"userId" json:"userId"`
	ScheduledAt    time.Time          `bson:"scheduledAt" json:"scheduledAt"`
	Status         string             `bson:"status" json:"status"` // pending, sent, failed, cancelled
	CreatedAt      time.Time          `bson:"createdAt" json:"createdAt"`
	UpdatedAt      time.Time          `bson:"updatedAt" json:"updatedAt"`
	SentAt         *time.Time         `bson:"sentAt,omitempty" json:"sentAt,omitempty"`
	FailureReason  string             `bson:"failureReason,omitempty" json:"failureReason,omitempty"`
	RetryCount     int                `bson:"retryCount" json:"retryCount"`
	Timezone       string             `bson:"timezone" json:"timezone"`
}

// ScheduleSuggestionRequest AI時間提案リクエスト
type ScheduleSuggestionRequest struct {
	MessageID       string `json:"messageId" binding:"required"`
	MessageText     string `json:"messageText" binding:"required"`
	SelectedTone    string `json:"selectedTone" binding:"required"`
	UserContext     string `json:"userContext,omitempty"`
	UserPreferences string `json:"userPreferences,omitempty"`
}

// SuggestionOption AI提案オプション
type SuggestionOption struct {
	Option       string `json:"option"`
	Priority     string `json:"priority"`     // 最推奨|推奨|選択肢
	Reason       string `json:"reason"`
	DelayMinutes interface{} `json:"delay_minutes"` // number or "next_business_day_9am"
}

// ScheduleSuggestionResponse AI時間提案レスポンス
type ScheduleSuggestionResponse struct {
	MessageType       string             `json:"message_type"`
	
	RecommendedTiming string             `json:"recommended_timing"`
	Reasoning         string             `json:"reasoning"`
	SuggestedOptions  []SuggestionOption `json:"suggested_options"`
}

// CreateScheduleRequest スケジュール作成リクエスト
type CreateScheduleRequest struct {
	MessageID    string    `json:"messageId" binding:"required"`
	ScheduledAt  time.Time `json:"scheduledAt" binding:"required"`
	Timezone     string    `json:"timezone"`
	FinalText    string    `json:"finalText"`
	SelectedTone string    `json:"selectedTone"`
}

// UpdateScheduleRequest スケジュール更新リクエスト
type UpdateScheduleRequest struct {
	ScheduledAt *time.Time `json:"scheduledAt,omitempty"`
	Status      string     `json:"status,omitempty"`
}

// ScheduleService スケジュール関連サービス
type ScheduleService struct {
	collection     *mongo.Collection
	messageService *MessageService
}

// NewScheduleService スケジュールサービスのコンストラクタ
func NewScheduleService(db *mongo.Database, messageService *MessageService) *ScheduleService {
	collection := db.Collection("schedules")

	// インデックス作成
	indexModel := []mongo.IndexModel{
		{
			Keys: bson.D{
				{Key: "userId", Value: 1},
				{Key: "status", Value: 1},
			},
		},
		{
			Keys: bson.D{
				{Key: "scheduledAt", Value: 1},
				{Key: "status", Value: 1},
			},
		},
		{
			Keys: bson.D{{Key: "messageId", Value: 1}},
		},
	}

	collection.Indexes().CreateMany(context.Background(), indexModel)

	return &ScheduleService{
		collection:     collection,
		messageService: messageService,
	}
}

// CreateSchedule スケジュール作成
func (s *ScheduleService) CreateSchedule(ctx context.Context, userID primitive.ObjectID, request *CreateScheduleRequest) (*Schedule, error) {
	messageID, err := primitive.ObjectIDFromHex(request.MessageID)
	if err != nil {
		return nil, err
	}

	now := time.Now()
	schedule := &Schedule{
		MessageID:   messageID,
		UserID:      userID,
		ScheduledAt: request.ScheduledAt,
		Status:      "pending",
		CreatedAt:   now,
		UpdatedAt:   now,
		RetryCount:  0,
		Timezone:    request.Timezone,
	}

	if schedule.Timezone == "" {
		schedule.Timezone = "Asia/Tokyo"
	}

	// スケジュール作成と同時にメッセージのステータスを scheduled に更新
	messageUpdateData := bson.M{
		"status":      MessageStatusScheduled,
		"scheduledAt": request.ScheduledAt,
		"updatedAt":   now,
	}

	// finalText と selectedTone が提供されている場合は更新
	if request.FinalText != "" {
		messageUpdateData["finalText"] = request.FinalText
	}
	if request.SelectedTone != "" {
		messageUpdateData["selectedTone"] = request.SelectedTone
	}

	// メッセージを更新
	messageFilter := bson.M{
		"_id":      messageID,
		"senderId": userID,
		"status":   MessageStatusDraft, // draft状態のメッセージのみ更新可能
	}

	_, err = s.messageService.collection.UpdateOne(ctx, messageFilter, bson.M{"$set": messageUpdateData})
	if err != nil {
		return nil, err
	}

	result, err := s.collection.InsertOne(ctx, schedule)
	if err != nil {
		return nil, err
	}

	schedule.ID = result.InsertedID.(primitive.ObjectID)
	return schedule, nil
}

// GetSchedule スケジュール取得
func (s *ScheduleService) GetSchedule(ctx context.Context, scheduleID primitive.ObjectID, userID primitive.ObjectID) (*Schedule, error) {
	var schedule Schedule
	filter := bson.M{
		"_id":    scheduleID,
		"userId": userID,
	}

	err := s.collection.FindOne(ctx, filter).Decode(&schedule)
	if err != nil {
		return nil, err
	}

	return &schedule, nil
}

// GetSchedules ユーザーのスケジュール一覧取得
func (s *ScheduleService) GetSchedules(ctx context.Context, userID primitive.ObjectID, status string, page, limit int) ([]*Schedule, int64, error) {
	filter := bson.M{"userId": userID}
	if status != "" {
		filter["status"] = status
	}

	// 総数取得
	total, err := s.collection.CountDocuments(ctx, filter)
	if err != nil {
		return nil, 0, err
	}

	// ページネーション
	skip := (page - 1) * limit
	opts := options.Find().
		SetSort(bson.D{{Key: "scheduledAt", Value: 1}}).
		SetSkip(int64(skip)).
		SetLimit(int64(limit))

	cursor, err := s.collection.Find(ctx, filter, opts)
	if err != nil {
		return nil, 0, err
	}
	defer cursor.Close(ctx)

	var schedules []*Schedule
	for cursor.Next(ctx) {
		var schedule Schedule
		if err := cursor.Decode(&schedule); err != nil {
			return nil, 0, err
		}
		schedules = append(schedules, &schedule)
	}

	return schedules, total, nil
}

// UpdateSchedule スケジュール更新
func (s *ScheduleService) UpdateSchedule(ctx context.Context, scheduleID primitive.ObjectID, userID primitive.ObjectID, request *UpdateScheduleRequest) (*Schedule, error) {
	filter := bson.M{
		"_id":    scheduleID,
		"userId": userID,
		"status": bson.M{"$in": []string{"pending"}}, // pending状態のみ更新可能
	}

	update := bson.M{
		"$set": bson.M{
			"updatedAt": time.Now(),
		},
	}

	if request.ScheduledAt != nil {
		update["$set"].(bson.M)["scheduledAt"] = *request.ScheduledAt
	}

	if request.Status != "" {
		update["$set"].(bson.M)["status"] = request.Status
	}

	opts := options.FindOneAndUpdate().SetReturnDocument(options.After)
	var schedule Schedule
	err := s.collection.FindOneAndUpdate(ctx, filter, update, opts).Decode(&schedule)
	if err != nil {
		return nil, err
	}

	return &schedule, nil
}

// DeleteSchedule スケジュール削除
func (s *ScheduleService) DeleteSchedule(ctx context.Context, scheduleID primitive.ObjectID, userID primitive.ObjectID) error {
	filter := bson.M{
		"_id":    scheduleID,
		"userId": userID,
		"status": "pending", // pending状態のみ削除可能
	}

	result, err := s.collection.DeleteOne(ctx, filter)
	if err != nil {
		return err
	}

	if result.DeletedCount == 0 {
		return mongo.ErrNoDocuments
	}

	return nil
}

// GetPendingSchedules 実行待ちスケジュール取得（バックグラウンド処理用）
func (s *ScheduleService) GetPendingSchedules(ctx context.Context, beforeTime time.Time) ([]*Schedule, error) {
	filter := bson.M{
		"status":      "pending",
		"scheduledAt": bson.M{"$lte": beforeTime},
	}

	cursor, err := s.collection.Find(ctx, filter)
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)

	var schedules []*Schedule
	for cursor.Next(ctx) {
		var schedule Schedule
		if err := cursor.Decode(&schedule); err != nil {
			return nil, err
		}
		schedules = append(schedules, &schedule)
	}

	return schedules, nil
}

// MarkAsSent 送信完了マーク
func (s *ScheduleService) MarkAsSent(ctx context.Context, scheduleID primitive.ObjectID) error {
	now := time.Now()
	filter := bson.M{"_id": scheduleID}
	update := bson.M{
		"$set": bson.M{
			"status":    "sent",
			"sentAt":    now,
			"updatedAt": now,
		},
	}

	_, err := s.collection.UpdateOne(ctx, filter, update)
	return err
}

// MarkAsFailed 送信失敗マーク
func (s *ScheduleService) MarkAsFailed(ctx context.Context, scheduleID primitive.ObjectID, reason string, retryCount int) error {
	filter := bson.M{"_id": scheduleID}
	update := bson.M{
		"$set": bson.M{
			"status":        "failed",
			"failureReason": reason,
			"retryCount":    retryCount,
			"updatedAt":     time.Now(),
		},
	}

	_, err := s.collection.UpdateOne(ctx, filter, update)
	return err
}