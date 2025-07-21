package models

import (
	"context"
	"time"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
)

// UserSettings ユーザー設定モデル
type UserSettings struct {
	ID                    primitive.ObjectID `bson:"_id,omitempty" json:"id"`
	UserID                primitive.ObjectID `bson:"userId" json:"userId"`
	EmailNotifications    bool               `bson:"emailNotifications" json:"emailNotifications"`
	SendNotifications     bool               `bson:"sendNotifications" json:"sendNotifications"`
	BrowserNotifications  bool               `bson:"browserNotifications" json:"browserNotifications"`
	DefaultTone           string             `bson:"defaultTone" json:"defaultTone"`
	TimeRestriction       string             `bson:"timeRestriction" json:"timeRestriction"`
	CreatedAt             time.Time          `bson:"createdAt" json:"createdAt"`
	UpdatedAt             time.Time          `bson:"updatedAt" json:"updatedAt"`
}

// NotificationSettings 通知設定
type NotificationSettings struct {
	EmailNotifications   bool `json:"emailNotifications"`
	SendNotifications    bool `json:"sendNotifications"`
	BrowserNotifications bool `json:"browserNotifications"`
}

// MessageSettings メッセージ設定
type MessageSettings struct {
	DefaultTone     string `json:"defaultTone"`
	TimeRestriction string `json:"timeRestriction"`
}

// UpdateProfileRequest プロフィール更新リクエスト
type UpdateProfileRequest struct {
	Name string `json:"name" binding:"max=100"`
}

// ChangePasswordRequest パスワード変更リクエスト
type ChangePasswordRequest struct {
	CurrentPassword string `json:"currentPassword" binding:"required,min=8"`
	NewPassword     string `json:"newPassword" binding:"required,min=8"`
}

// UserSettingsService ユーザー設定サービス
type UserSettingsService struct {
	collection  *mongo.Collection
	userService *UserService
}

// NewUserSettingsService ユーザー設定サービスを作成
func NewUserSettingsService(db *mongo.Database, userService *UserService) *UserSettingsService {
	return &UserSettingsService{
		collection:  db.Collection("user_settings"),
		userService: userService,
	}
}

// GetOrCreateSettings ユーザー設定を取得または作成
func (s *UserSettingsService) GetOrCreateSettings(ctx context.Context, userID primitive.ObjectID) (*UserSettings, error) {
	var settings UserSettings

	// 既存の設定を検索
	err := s.collection.FindOne(ctx, bson.M{"userId": userID}).Decode(&settings)
	if err == nil {
		return &settings, nil
	}

	// 設定が存在しない場合、デフォルト設定を作成
	if err == mongo.ErrNoDocuments {
		now := time.Now()
		settings = UserSettings{
			UserID:               userID,
			EmailNotifications:   true,
			SendNotifications:    true,
			BrowserNotifications: false,
			DefaultTone:          "gentle",
			TimeRestriction:      "none",
			CreatedAt:            now,
			UpdatedAt:            now,
		}

		result, err := s.collection.InsertOne(ctx, settings)
		if err != nil {
			return nil, err
		}

		settings.ID = result.InsertedID.(primitive.ObjectID)
		return &settings, nil
	}

	return nil, err
}

// UpdateNotificationSettings 通知設定を更新
func (s *UserSettingsService) UpdateNotificationSettings(ctx context.Context, userID primitive.ObjectID, settings *NotificationSettings) error {
	now := time.Now()

	update := bson.M{
		"$set": bson.M{
			"emailNotifications":   settings.EmailNotifications,
			"sendNotifications":    settings.SendNotifications,
			"browserNotifications": settings.BrowserNotifications,
			"updatedAt":            now,
		},
	}

	_, err := s.collection.UpdateOne(
		ctx,
		bson.M{"userId": userID},
		update,
	)

	return err
}

// UpdateMessageSettings メッセージ設定を更新
func (s *UserSettingsService) UpdateMessageSettings(ctx context.Context, userID primitive.ObjectID, settings *MessageSettings) error {
	now := time.Now()

	update := bson.M{
		"$set": bson.M{
			"defaultTone":     settings.DefaultTone,
			"timeRestriction": settings.TimeRestriction,
			"updatedAt":       now,
		},
	}

	_, err := s.collection.UpdateOne(
		ctx,
		bson.M{"userId": userID},
		update,
	)

	return err
}

// CreateIndexes ユーザー設定コレクションのインデックスを作成
func (s *UserSettingsService) CreateIndexes(ctx context.Context) error {
	indexes := []mongo.IndexModel{
		{
			Keys: bson.D{
				{Key: "userId", Value: 1},
			},
		},
	}

	_, err := s.collection.Indexes().CreateMany(ctx, indexes)
	return err
}