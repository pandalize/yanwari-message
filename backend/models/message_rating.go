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

// MessageRating メッセージ評価データ構造
type MessageRating struct {
	ID          primitive.ObjectID `bson:"_id,omitempty" json:"id,omitempty"`
	MessageID   primitive.ObjectID `bson:"messageId" json:"messageId"`
	RecipientID primitive.ObjectID `bson:"recipientId" json:"recipientId"`
	Rating      int                `bson:"rating" json:"rating"` // 1-5の評価値 (1=bad, 5=good)
	CreatedAt   time.Time          `bson:"createdAt" json:"createdAt"`
	UpdatedAt   time.Time          `bson:"updatedAt" json:"updatedAt"`
}

// MessageRatingService メッセージ評価関連のサービス
type MessageRatingService struct {
	collection *mongo.Collection
}

// NewMessageRatingService 新しいMessageRatingServiceを作成
func NewMessageRatingService(db *mongo.Database) *MessageRatingService {
	service := &MessageRatingService{
		collection: db.Collection("message_ratings"),
	}
	
	// インデックス作成
	service.createIndexes()
	
	return service
}

// createIndexes インデックス作成
func (mrs *MessageRatingService) createIndexes() {
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	// 複合インデックス（messageId + recipientId で一意制約）
	uniqueIndex := mongo.IndexModel{
		Keys: bson.D{
			{Key: "messageId", Value: 1},
			{Key: "recipientId", Value: 1},
		},
		Options: options.Index().SetUnique(true),
	}

	// 評価順ソート用インデックス
	ratingIndex := mongo.IndexModel{
		Keys: bson.D{
			{Key: "recipientId", Value: 1},
			{Key: "rating", Value: -1},
		},
	}

	// メッセージ検索用インデックス
	messageIndex := mongo.IndexModel{
		Keys: bson.D{
			{Key: "messageId", Value: 1},
		},
	}

	_, err := mrs.collection.Indexes().CreateMany(ctx, []mongo.IndexModel{
		uniqueIndex,
		ratingIndex,
		messageIndex,
	})
	if err != nil {
		// インデックス作成エラーはログに記録するが、サービス開始は継続
		// TODO: ログライブラリを使用してエラーを記録
		println("Warning: Failed to create indexes for message_ratings:", err.Error())
	}
}

// CreateOrUpdateRating メッセージ評価を作成または更新
func (mrs *MessageRatingService) CreateOrUpdateRating(ctx context.Context, messageID, recipientID primitive.ObjectID, rating int) (*MessageRating, error) {
	// 評価値のバリデーション
	if rating < 1 || rating > 5 {
		return nil, errors.New("評価は1-5の範囲で指定してください")
	}

	now := time.Now()
	
	// 既存の評価を検索
	filter := bson.M{
		"messageId":   messageID,
		"recipientId": recipientID,
	}

	existingRating := &MessageRating{}
	err := mrs.collection.FindOne(ctx, filter).Decode(existingRating)
	
	if err == mongo.ErrNoDocuments {
		// 新規作成
		newRating := &MessageRating{
			ID:          primitive.NewObjectID(),
			MessageID:   messageID,
			RecipientID: recipientID,
			Rating:      rating,
			CreatedAt:   now,
			UpdatedAt:   now,
		}

		_, err = mrs.collection.InsertOne(ctx, newRating)
		if err != nil {
			return nil, err
		}

		return newRating, nil
	} else if err != nil {
		return nil, err
	}

	// 既存レコードの更新
	update := bson.M{
		"$set": bson.M{
			"rating":    rating,
			"updatedAt": now,
		},
	}

	_, err = mrs.collection.UpdateOne(ctx, filter, update)
	if err != nil {
		return nil, err
	}

	// 更新されたレコードを取得
	existingRating.Rating = rating
	existingRating.UpdatedAt = now

	return existingRating, nil
}

// GetRatingByMessageAndRecipient 特定のメッセージ・受信者の評価を取得
func (mrs *MessageRatingService) GetRatingByMessageAndRecipient(ctx context.Context, messageID, recipientID primitive.ObjectID) (*MessageRating, error) {
	filter := bson.M{
		"messageId":   messageID,
		"recipientId": recipientID,
	}

	rating := &MessageRating{}
	err := mrs.collection.FindOne(ctx, filter).Decode(rating)
	if err == mongo.ErrNoDocuments {
		return nil, nil // 評価が存在しない場合はnilを返す
	}
	if err != nil {
		return nil, err
	}

	return rating, nil
}

// GetRatingsByRecipient 受信者のすべての評価を取得
func (mrs *MessageRatingService) GetRatingsByRecipient(ctx context.Context, recipientID primitive.ObjectID) ([]MessageRating, error) {
	filter := bson.M{"recipientId": recipientID}
	
	// 評価順（高評価から低評価）でソート
	opts := options.Find().SetSort(bson.D{
		{Key: "rating", Value: -1},
		{Key: "updatedAt", Value: -1},
	})

	cursor, err := mrs.collection.Find(ctx, filter, opts)
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)

	var ratings []MessageRating
	err = cursor.All(ctx, &ratings)
	if err != nil {
		return nil, err
	}

	return ratings, nil
}

// GetRatingsByMessages 複数のメッセージIDに対する評価を取得
func (mrs *MessageRatingService) GetRatingsByMessages(ctx context.Context, messageIDs []primitive.ObjectID, recipientID primitive.ObjectID) (map[string]*MessageRating, error) {
	filter := bson.M{
		"messageId": bson.M{"$in": messageIDs},
		"recipientId": recipientID,
	}

	cursor, err := mrs.collection.Find(ctx, filter)
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)

	ratings := make(map[string]*MessageRating)
	for cursor.Next(ctx) {
		var rating MessageRating
		err := cursor.Decode(&rating)
		if err != nil {
			return nil, err
		}
		ratings[rating.MessageID.Hex()] = &rating
	}

	return ratings, nil
}

// DeleteRating 評価を削除
func (mrs *MessageRatingService) DeleteRating(ctx context.Context, messageID, recipientID primitive.ObjectID) error {
	filter := bson.M{
		"messageId":   messageID,
		"recipientId": recipientID,
	}

	result, err := mrs.collection.DeleteOne(ctx, filter)
	if err != nil {
		return err
	}

	if result.DeletedCount == 0 {
		return errors.New("削除対象の評価が見つかりません")
	}

	return nil
}

// GetRatingStatsByMessage メッセージの評価統計を取得（プライバシー配慮版）
// 注意: 送信者には詳細な評価を見せず、統計のみ提供する場合に使用
func (mrs *MessageRatingService) GetRatingStatsByMessage(ctx context.Context, messageID primitive.ObjectID) (*RatingStats, error) {
	pipeline := []bson.M{
		{
			"$match": bson.M{
				"messageId": messageID,
			},
		},
		{
			"$group": bson.M{
				"_id": "$messageId",
				"avgRating": bson.M{"$avg": "$rating"},
				"totalRatings": bson.M{"$sum": 1},
				"ratings": bson.M{"$push": "$rating"},
			},
		},
	}

	cursor, err := mrs.collection.Aggregate(ctx, pipeline)
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)

	var results []bson.M
	err = cursor.All(ctx, &results)
	if err != nil {
		return nil, err
	}

	if len(results) == 0 {
		return &RatingStats{
			MessageID:    messageID,
			AverageRating: 0,
			TotalRatings: 0,
			RatingCounts: make(map[int]int),
		}, nil
	}

	result := results[0]
	ratings := result["ratings"].(primitive.A)
	
	// 評価の分布を計算
	ratingCounts := make(map[int]int)
	for _, rating := range ratings {
		r := int(rating.(int32))
		ratingCounts[r]++
	}

	return &RatingStats{
		MessageID:     messageID,
		AverageRating: result["avgRating"].(float64),
		TotalRatings:  int(result["totalRatings"].(int32)),
		RatingCounts:  ratingCounts,
	}, nil
}

// RatingStats 評価統計データ構造
type RatingStats struct {
	MessageID     primitive.ObjectID `json:"messageId"`
	AverageRating float64            `json:"averageRating"`
	TotalRatings  int                `json:"totalRatings"`
	RatingCounts  map[int]int        `json:"ratingCounts"` // 評価値 -> 件数
}