package models

import (
	"context"
	"errors"
	"time"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

// Message やんわり伝言のメッセージモデル
type Message struct {
	ID           primitive.ObjectID `bson:"_id,omitempty" json:"id"`
	SenderID     primitive.ObjectID `bson:"senderId" json:"senderId"`
	RecipientID  primitive.ObjectID `bson:"recipientId,omitempty" json:"recipientId,omitempty"`
	OriginalText string             `bson:"originalText" json:"originalText"`
	Variations   MessageVariations  `bson:"variations" json:"variations"`
	SelectedTone string             `bson:"selectedTone,omitempty" json:"selectedTone,omitempty"`
	FinalText    string             `bson:"finalText,omitempty" json:"finalText,omitempty"`
	ScheduledAt  *time.Time         `bson:"scheduledAt,omitempty" json:"scheduledAt,omitempty"`
	Status       MessageStatus      `bson:"status" json:"status"`
	CreatedAt    time.Time          `bson:"createdAt" json:"createdAt"`
	UpdatedAt    time.Time          `bson:"updatedAt" json:"updatedAt"`
	SentAt       *time.Time         `bson:"sentAt,omitempty" json:"sentAt,omitempty"`
	ReadAt       *time.Time         `bson:"readAt,omitempty" json:"readAt,omitempty"`
}

// MessageWithSender 送信者情報を含むメッセージ
type MessageWithSender struct {
	Message
	SenderEmail string `json:"senderEmail"`
	SenderName  string `json:"senderName,omitempty"`
}

// MessageVariations AIトーン変換結果
type MessageVariations struct {
	Gentle       string `bson:"gentle,omitempty" json:"gentle,omitempty"`
	Constructive string `bson:"constructive,omitempty" json:"constructive,omitempty"`
	Casual       string `bson:"casual,omitempty" json:"casual,omitempty"`
}

// MessageStatus メッセージの状態
type MessageStatus string

const (
	MessageStatusDraft      MessageStatus = "draft"      // 下書き
	MessageStatusProcessing MessageStatus = "processing" // AI変換中
	MessageStatusScheduled  MessageStatus = "scheduled"  // 送信予約済み
	MessageStatusSent       MessageStatus = "sent"       // 送信完了
	MessageStatusDelivered  MessageStatus = "delivered"  // 配信完了
	MessageStatusRead       MessageStatus = "read"       // 既読
)

// CreateMessageRequest メッセージ作成リクエスト
type CreateMessageRequest struct {
	RecipientEmail string `json:"recipientEmail,omitempty"`
	OriginalText   string `json:"originalText" binding:"required,min=1,max=1000"`
}

// UpdateMessageRequest メッセージ更新リクエスト
type UpdateMessageRequest struct {
	RecipientEmail   string            `json:"recipientEmail,omitempty"`
	OriginalText     string            `json:"originalText,omitempty"`
	Variations       MessageVariations `json:"variations,omitempty"`
	ToneVariations   map[string]string `json:"toneVariations,omitempty"` // トーン変換結果用
	SelectedTone     string            `json:"selectedTone,omitempty"`
	ScheduledAt      *time.Time        `json:"scheduledAt,omitempty"`
}

// MessageService メッセージサービス
type MessageService struct {
	collection *mongo.Collection
	userService *UserService
	db         *mongo.Database
}

// NewMessageService メッセージサービスを作成
func NewMessageService(db *mongo.Database, userService *UserService) *MessageService {
	return &MessageService{
		collection:  db.Collection("messages"),
		userService: userService,
		db:          db,
	}
}

// CreateDraft 下書きメッセージを作成
func (s *MessageService) CreateDraft(ctx context.Context, senderID primitive.ObjectID, req *CreateMessageRequest) (*Message, error) {
	now := time.Now()
	
	message := &Message{
		SenderID:     senderID,
		OriginalText: req.OriginalText,
		Status:       MessageStatusDraft,
		CreatedAt:    now,
		UpdatedAt:    now,
	}

	// 受信者が指定されている場合は検索
	if req.RecipientEmail != "" {
		recipient, err := s.userService.GetUserByEmail(ctx, req.RecipientEmail)
		if err != nil {
			return nil, err
		}
		message.RecipientID = recipient.ID
		
		// 友達関係をチェック
		friendshipService := NewFriendshipService(s.db)
		areFriends, err := friendshipService.AreFriends(ctx, senderID, recipient.ID)
		if err != nil {
			return nil, err
		}
		if !areFriends {
			return nil, errors.New("メッセージを送るには友達になる必要があります")
		}
	}

	result, err := s.collection.InsertOne(ctx, message)
	if err != nil {
		return nil, err
	}

	message.ID = result.InsertedID.(primitive.ObjectID)
	return message, nil
}

// UpdateMessage メッセージを更新
func (s *MessageService) UpdateMessage(ctx context.Context, messageID, senderID primitive.ObjectID, req *UpdateMessageRequest) (*Message, error) {
	now := time.Now()
	
	// 更新データを構築
	updateData := bson.M{
		"updatedAt": now,
	}
	
	if req.OriginalText != "" {
		updateData["originalText"] = req.OriginalText
	}
	
	if req.Variations.Gentle != "" || req.Variations.Constructive != "" || req.Variations.Casual != "" {
		updateData["variations"] = req.Variations
	}
	
	// トーン変換結果を直接設定する場合（APIから呼び出される場合）
	if req.ToneVariations != nil {
		variations := MessageVariations{}
		if gentle, ok := req.ToneVariations["gentle"]; ok {
			variations.Gentle = gentle
		}
		if constructive, ok := req.ToneVariations["constructive"]; ok {
			variations.Constructive = constructive
		}
		if casual, ok := req.ToneVariations["casual"]; ok {
			variations.Casual = casual
		}
		updateData["variations"] = variations
	}
	
	if req.SelectedTone != "" {
		updateData["selectedTone"] = req.SelectedTone
		// 選択されたトーンに基づいて最終テキストを設定
		switch req.SelectedTone {
		case "gentle":
			if req.Variations.Gentle != "" {
				updateData["finalText"] = req.Variations.Gentle
			}
		case "constructive":
			if req.Variations.Constructive != "" {
				updateData["finalText"] = req.Variations.Constructive
			}
		case "casual":
			if req.Variations.Casual != "" {
				updateData["finalText"] = req.Variations.Casual
			}
		}
	}
	
	if req.ScheduledAt != nil {
		updateData["scheduledAt"] = req.ScheduledAt
		updateData["status"] = MessageStatusScheduled
	}

	// 受信者が指定されている場合は検索
	if req.RecipientEmail != "" {
		recipient, err := s.userService.GetUserByEmail(ctx, req.RecipientEmail)
		if err != nil {
			return nil, err
		}
		updateData["recipientId"] = recipient.ID
		
		// 友達関係をチェック
		friendshipService := NewFriendshipService(s.db)
		areFriends, err := friendshipService.AreFriends(ctx, senderID, recipient.ID)
		if err != nil {
			return nil, err
		}
		if !areFriends {
			return nil, errors.New("メッセージを送るには友達になる必要があります")
		}
	}

	// 送信者のメッセージのみ更新可能
	filter := bson.M{
		"_id":      messageID,
		"senderId": senderID,
	}

	_, err := s.collection.UpdateOne(ctx, filter, bson.M{"$set": updateData})
	if err != nil {
		return nil, err
	}

	return s.GetMessage(ctx, messageID, senderID)
}

// GetMessage メッセージを取得
func (s *MessageService) GetMessage(ctx context.Context, messageID, userID primitive.ObjectID) (*Message, error) {
	var message Message
	
	// 送信者または受信者のメッセージのみ取得可能
	filter := bson.M{
		"_id": messageID,
		"$or": []bson.M{
			{"senderId": userID},
			{"recipientId": userID},
		},
	}

	err := s.collection.FindOne(ctx, filter).Decode(&message)
	if err != nil {
		return nil, err
	}

	return &message, nil
}

// GetUserDrafts ユーザーの下書き一覧を取得
func (s *MessageService) GetUserDrafts(ctx context.Context, userID primitive.ObjectID) ([]Message, error) {
	var messages []Message
	
	filter := bson.M{
		"senderId": userID,
		"status":   MessageStatusDraft,
	}

	cursor, err := s.collection.Find(ctx, filter, nil)
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)

	if err = cursor.All(ctx, &messages); err != nil {
		return nil, err
	}

	if messages == nil {
		messages = []Message{}
	}

	return messages, nil
}

// DeleteMessage メッセージを削除
func (s *MessageService) DeleteMessage(ctx context.Context, messageID, senderID primitive.ObjectID) error {
	filter := bson.M{
		"_id":      messageID,
		"senderId": senderID,
		"status":   MessageStatusDraft, // 下書きのみ削除可能
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

// DeliverScheduledMessages スケジュール配信: scheduled → sent
func (s *MessageService) DeliverScheduledMessages(ctx context.Context) ([]Message, error) {
	now := time.Now()
	
	// 配信時刻が過ぎたスケジュールメッセージを取得
	filter := bson.M{
		"status":      MessageStatusScheduled,
		"scheduledAt": bson.M{"$lte": now},
	}

	var messages []Message
	cursor, err := s.collection.Find(ctx, filter)
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)

	if err = cursor.All(ctx, &messages); err != nil {
		return nil, err
	}

	// バッチで配信済みに更新
	if len(messages) > 0 {
		messageIDs := make([]primitive.ObjectID, len(messages))
		for i, msg := range messages {
			messageIDs[i] = msg.ID
		}

		updateFilter := bson.M{
			"_id": bson.M{"$in": messageIDs},
		}

		updateData := bson.M{
			"$set": bson.M{
				"status":    MessageStatusSent,
				"sentAt":    now,
				"updatedAt": now,
			},
		}

		_, err = s.collection.UpdateMany(ctx, updateFilter, updateData)
		if err != nil {
			return nil, err
		}

		// 更新後のメッセージを取得
		for i := range messages {
			messages[i].Status = MessageStatusSent
			messages[i].SentAt = &now
			messages[i].UpdatedAt = now
		}
	}

	return messages, nil
}

// GetReceivedMessages 受信メッセージ一覧を取得（受信者向け）
func (s *MessageService) GetReceivedMessages(ctx context.Context, recipientID primitive.ObjectID, page, limit int) ([]Message, int64, error) {
	var messages []Message
	
	// 受信者宛てで、送信済み以上の状態のメッセージを取得
	filter := bson.M{
		"recipientId": recipientID,
		"status": bson.M{"$in": []MessageStatus{
			MessageStatusSent,
			MessageStatusDelivered,
			MessageStatusRead,
		}},
	}

	// 総数を取得
	total, err := s.collection.CountDocuments(ctx, filter)
	if err != nil {
		return nil, 0, err
	}

	// ページネーション設定
	skip := int64((page - 1) * limit)
	limitInt64 := int64(limit)
	
	cursor, err := s.collection.Find(ctx, filter, &options.FindOptions{
		Sort:  bson.D{{Key: "sentAt", Value: -1}}, // 送信日時の降順
		Skip:  &skip,
		Limit: &limitInt64,
	})
	if err != nil {
		return nil, 0, err
	}
	defer cursor.Close(ctx)

	if err = cursor.All(ctx, &messages); err != nil {
		return nil, 0, err
	}

	if messages == nil {
		messages = []Message{}
	}

	return messages, total, nil
}

// MarkMessageAsRead メッセージを既読にする
func (s *MessageService) MarkMessageAsRead(ctx context.Context, messageID, recipientID primitive.ObjectID) error {
	now := time.Now()
	
	filter := bson.M{
		"_id":         messageID,
		"recipientId": recipientID,
		"status": bson.M{"$in": []MessageStatus{
			MessageStatusSent,
			MessageStatusDelivered,
		}},
	}

	updateData := bson.M{
		"$set": bson.M{
			"status":    MessageStatusRead,
			"readAt":    now,
			"updatedAt": now,
		},
	}

	result, err := s.collection.UpdateOne(ctx, filter, updateData)
	if err != nil {
		return err
	}

	if result.MatchedCount == 0 {
		return mongo.ErrNoDocuments
	}

	return nil
}

// CreateIndexes メッセージコレクションのインデックスを作成
func (s *MessageService) CreateIndexes(ctx context.Context) error {
	indexes := []mongo.IndexModel{
		{
			Keys: bson.D{
				{Key: "senderId", Value: 1},
				{Key: "status", Value: 1},
			},
		},
		{
			Keys: bson.D{
				{Key: "recipientId", Value: 1},
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
			Keys: bson.D{
				{Key: "sentAt", Value: -1}, // 受信メッセージのソート用
			},
		},
		{
			Keys: bson.D{
				{Key: "createdAt", Value: -1},
			},
		},
	}

	_, err := s.collection.Indexes().CreateMany(ctx, indexes)
	return err
}

// GetReceivedMessagesWithSender 送信者情報を含む受信メッセージ一覧を取得
func (s *MessageService) GetReceivedMessagesWithSender(ctx context.Context, recipientID primitive.ObjectID, page, limit int) ([]MessageWithSender, int64, error) {
	// まず通常のメッセージ一覧を取得
	messages, total, err := s.GetReceivedMessages(ctx, recipientID, page, limit)
	if err != nil {
		return nil, 0, err
	}

	// 送信者IDのリストを作成
	senderIDs := make([]primitive.ObjectID, 0)
	senderIDMap := make(map[primitive.ObjectID]bool)
	for _, msg := range messages {
		if !senderIDMap[msg.SenderID] {
			senderIDs = append(senderIDs, msg.SenderID)
			senderIDMap[msg.SenderID] = true
		}
	}

	// 送信者情報を一括取得
	users, err := s.userService.GetUsersByIDs(ctx, senderIDs)
	if err != nil {
		return nil, 0, err
	}

	// ユーザー情報をマップに変換
	userMap := make(map[primitive.ObjectID]*User)
	for _, user := range users {
		userMap[user.ID] = &user
	}

	// メッセージに送信者情報を追加
	messagesWithSender := make([]MessageWithSender, len(messages))
	for i, msg := range messages {
		msgWithSender := MessageWithSender{
			Message:     msg,
			SenderEmail: "",
			SenderName:  "",
		}
		
		if sender, ok := userMap[msg.SenderID]; ok {
			msgWithSender.SenderEmail = sender.Email
			msgWithSender.SenderName = sender.Name
		}
		
		messagesWithSender[i] = msgWithSender
	}

	return messagesWithSender, total, nil
}