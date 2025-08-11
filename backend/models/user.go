package models

import (
	"context"
	"fmt"
	"time"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

// User データベースに保存するユーザー情報を表現
type User struct {
	ID           primitive.ObjectID `bson:"_id,omitempty" json:"id"`
	Name         string             `bson:"name" json:"name"`
	Email        string             `bson:"email" json:"email"`
	FirebaseUID  string             `bson:"firebaseUid,omitempty" json:"firebaseUid,omitempty"` // Firebase UID追加
	PasswordHash string             `bson:"password_hash" json:"-"` // JSONには含めない（セキュリティ上重要）
	Salt         string             `bson:"salt" json:"-"`
	Timezone     string             `bson:"timezone" json:"timezone"`
	CreatedAt    time.Time          `bson:"createdAt" json:"createdAt"`
	UpdatedAt    time.Time          `bson:"updatedAt" json:"updatedAt"`
}

// UserService ユーザー関連のデータベース操作を担当
type UserService struct {
	collection *mongo.Collection
}

// NewUserService UserServiceのコンストラクタ
func NewUserService(db *mongo.Database) *UserService {
	return &UserService{
		collection: db.Collection("users"),
	}
}

// CreateUser 新しいユーザーを作成
func (s *UserService) CreateUser(ctx context.Context, user *User) error {
	// 作成・更新時刻を設定
	now := time.Now()
	user.CreatedAt = now
	user.UpdatedAt = now

	// タイムゾーンのデフォルト設定
	if user.Timezone == "" {
		user.Timezone = "Asia/Tokyo"
	}

	// ユーザーをデータベースに挿入
	result, err := s.collection.InsertOne(ctx, user)
	if err != nil {
		// 重複エラーの場合（email にユニークインデックスが設定されている場合）
		if mongo.IsDuplicateKeyError(err) {
			return fmt.Errorf("このメールアドレスは既に登録されています")
		}
		return fmt.Errorf("ユーザー作成エラー: %w", err)
	}

	// 作成されたユーザーのIDを設定
	user.ID = result.InsertedID.(primitive.ObjectID)
	return nil
}

// GetUserByEmail メールアドレスでユーザーを取得
func (s *UserService) GetUserByEmail(ctx context.Context, email string) (*User, error) {
	var user User
	
	filter := bson.M{"email": email}
	err := s.collection.FindOne(ctx, filter).Decode(&user)
	
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return nil, fmt.Errorf("ユーザーが見つかりません")
		}
		return nil, fmt.Errorf("ユーザー取得エラー: %w", err)
	}

	return &user, nil
}

// GetUserByID ユーザーIDでユーザーを取得
func (s *UserService) GetUserByID(ctx context.Context, id string) (*User, error) {
	objectID, err := primitive.ObjectIDFromHex(id)
	if err != nil {
		return nil, fmt.Errorf("無効なユーザーID: %w", err)
	}

	var user User
	filter := bson.M{"_id": objectID}
	err = s.collection.FindOne(ctx, filter).Decode(&user)
	
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return nil, fmt.Errorf("ユーザーが見つかりません")
		}
		return nil, fmt.Errorf("ユーザー取得エラー: %w", err)
	}

	return &user, nil
}

// EmailExists メールアドレスが既に登録されているかチェック
func (s *UserService) EmailExists(ctx context.Context, email string) (bool, error) {
	filter := bson.M{"email": email}
	count, err := s.collection.CountDocuments(ctx, filter)
	
	if err != nil {
		return false, fmt.Errorf("メールアドレス重複チェックエラー: %w", err)
	}

	return count > 0, nil
}

// UpdateUser ユーザー情報を更新
func (s *UserService) UpdateUser(ctx context.Context, user *User) error {
	// 更新時刻を設定
	user.UpdatedAt = time.Now()

	filter := bson.M{"_id": user.ID}
	update := bson.M{
		"$set": bson.M{
			"name":          user.Name,
			"email":         user.Email,
			"password_hash": user.PasswordHash,
			"salt":          user.Salt,
			"timezone":      user.Timezone,
			"updated_at":    user.UpdatedAt,
		},
	}

	result, err := s.collection.UpdateOne(ctx, filter, update)
	if err != nil {
		return fmt.Errorf("ユーザー更新エラー: %w", err)
	}

	if result.MatchedCount == 0 {
		return fmt.Errorf("更新対象のユーザーが見つかりません")
	}

	return nil
}

// DeleteUser ユーザーを削除
func (s *UserService) DeleteUser(ctx context.Context, id string) error {
	objectID, err := primitive.ObjectIDFromHex(id)
	if err != nil {
		return fmt.Errorf("無効なユーザーID: %w", err)
	}

	filter := bson.M{"_id": objectID}
	result, err := s.collection.DeleteOne(ctx, filter)
	
	if err != nil {
		return fmt.Errorf("ユーザー削除エラー: %w", err)
	}

	if result.DeletedCount == 0 {
		return fmt.Errorf("削除対象のユーザーが見つかりません")
	}

	return nil
}

// SearchUsers ユーザーを検索（名前またはメールアドレス）
func (s *UserService) SearchUsers(ctx context.Context, query string, limit int) ([]*User, error) {
	if query == "" {
		return []*User{}, nil
	}

	// 大文字小文字を無視した部分一致検索
	filter := bson.M{
		"$or": []bson.M{
			{"name": bson.M{"$regex": query, "$options": "i"}},
			{"email": bson.M{"$regex": query, "$options": "i"}},
		},
	}

	// 検索オプション設定
	findOptions := options.Find()
	findOptions.SetLimit(int64(limit))
	findOptions.SetSort(bson.D{{Key: "name", Value: 1}}) // 名前順でソート

	cursor, err := s.collection.Find(ctx, filter, findOptions)
	if err != nil {
		return nil, fmt.Errorf("ユーザー検索エラー: %w", err)
	}
	defer cursor.Close(ctx)

	var users []*User
	for cursor.Next(ctx) {
		var user User
		if err := cursor.Decode(&user); err != nil {
			continue // エラーが発生したドキュメントはスキップ
		}
		users = append(users, &user)
	}

	if err := cursor.Err(); err != nil {
		return nil, fmt.Errorf("ユーザー検索カーソルエラー: %w", err)
	}

	return users, nil
}

// GetUsersByIDs 複数のユーザーIDからユーザー情報を一括取得
func (s *UserService) GetUsersByIDs(ctx context.Context, userIDs []primitive.ObjectID) ([]User, error) {
	if len(userIDs) == 0 {
		return []User{}, nil
	}

	filter := bson.M{
		"_id": bson.M{"$in": userIDs},
	}

	cursor, err := s.collection.Find(ctx, filter)
	if err != nil {
		return nil, fmt.Errorf("ユーザー一括取得エラー: %w", err)
	}
	defer cursor.Close(ctx)

	var users []User
	if err = cursor.All(ctx, &users); err != nil {
		return nil, fmt.Errorf("ユーザー情報デコードエラー: %w", err)
	}

	return users, nil
}

// CreateEmailIndex メールアドレスにユニークインデックスを作成
func (s *UserService) CreateEmailIndex(ctx context.Context) error {
	indexModel := mongo.IndexModel{
		Keys:    bson.D{{Key: "email", Value: 1}}, // 昇順インデックス
		Options: options.Index().SetUnique(true),   // ユニーク制約
	}

	_, err := s.collection.Indexes().CreateOne(ctx, indexModel)
	if err != nil {
		return fmt.Errorf("メールアドレスインデックス作成エラー: %w", err)
	}

	return nil
}

// CreateNameIndex 名前にインデックスを作成（検索パフォーマンス向上）
func (s *UserService) CreateNameIndex(ctx context.Context) error {
	indexModel := mongo.IndexModel{
		Keys: bson.D{{Key: "name", Value: 1}}, // 昇順インデックス
	}

	_, err := s.collection.Indexes().CreateOne(ctx, indexModel)
	if err != nil {
		return fmt.Errorf("名前インデックス作成エラー: %w", err)
	}

	return nil
}

// UpdateProfile ユーザーのプロフィール（名前）を更新
func (s *UserService) UpdateProfile(ctx context.Context, userID primitive.ObjectID, name string) error {
	now := time.Now()
	
	filter := bson.M{"_id": userID}
	update := bson.M{
		"$set": bson.M{
			"name":       name,
			"updated_at": now,
		},
	}

	result, err := s.collection.UpdateOne(ctx, filter, update)
	if err != nil {
		return fmt.Errorf("プロフィール更新エラー: %w", err)
	}

	if result.MatchedCount == 0 {
		return fmt.Errorf("更新対象のユーザーが見つかりません")
	}

	return nil
}

// UpdatePassword ユーザーのパスワードを更新
func (s *UserService) UpdatePassword(ctx context.Context, userID primitive.ObjectID, passwordHash string) error {
	now := time.Now()
	
	filter := bson.M{"_id": userID}
	update := bson.M{
		"$set": bson.M{
			"password_hash": passwordHash,
			"updated_at":    now,
		},
	}

	result, err := s.collection.UpdateOne(ctx, filter, update)
	if err != nil {
		return fmt.Errorf("パスワード更新エラー: %w", err)
	}

	if result.MatchedCount == 0 {
		return fmt.Errorf("更新対象のユーザーが見つかりません")
	}

	return nil
}

// UpdateEmail ユーザーのメールアドレスを更新
func (s *UserService) UpdateEmail(ctx context.Context, userID primitive.ObjectID, email string) error {
	// まず新しいメールアドレスが既に使用されていないかチェック
	exists, err := s.EmailExists(ctx, email)
	if err != nil {
		return fmt.Errorf("メールアドレス重複チェックエラー: %w", err)
	}
	if exists {
		return fmt.Errorf("このメールアドレスは既に使用されています")
	}

	now := time.Now()
	
	filter := bson.M{"_id": userID}
	update := bson.M{
		"$set": bson.M{
			"email":      email,
			"updated_at": now,
		},
	}

	result, err := s.collection.UpdateOne(ctx, filter, update)
	if err != nil {
		// 重複エラーの場合（インデックス制約違反）
		if mongo.IsDuplicateKeyError(err) {
			return fmt.Errorf("このメールアドレスは既に使用されています")
		}
		return fmt.Errorf("メールアドレス更新エラー: %w", err)
	}

	if result.MatchedCount == 0 {
		return fmt.Errorf("更新対象のユーザーが見つかりません")
	}

	return nil
}

// Firebase対応メソッド

// UpdateFirebaseUID ユーザーのFirebase UIDを更新
func (s *UserService) UpdateFirebaseUID(ctx context.Context, userID primitive.ObjectID, firebaseUID string) error {
	if firebaseUID == "" {
		return fmt.Errorf("Firebase UIDが空です")
	}
	
	now := time.Now()
	filter := bson.M{"_id": userID}
	update := bson.M{
		"$set": bson.M{
			"firebaseUid": firebaseUID,
			"updatedAt":   now,
		},
	}
	
	result, err := s.collection.UpdateOne(ctx, filter, update)
	if err != nil {
		return fmt.Errorf("Firebase UID更新エラー: %w", err)
	}
	
	if result.MatchedCount == 0 {
		return fmt.Errorf("更新対象のユーザーが見つかりません")
	}
	
	return nil
}

// GetUserByFirebaseUID Firebase UIDでユーザーを取得
func (s *UserService) GetUserByFirebaseUID(ctx context.Context, firebaseUID string) (*User, error) {
	if firebaseUID == "" {
		return nil, fmt.Errorf("Firebase UIDが空です")
	}
	
	var user User
	filter := bson.M{"firebaseUid": firebaseUID}
	
	err := s.collection.FindOne(ctx, filter).Decode(&user)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return nil, fmt.Errorf("Firebase UID %s のユーザーが見つかりません", firebaseUID)
		}
		return nil, fmt.Errorf("Firebase UIDでのユーザー取得エラー: %w", err)
	}
	
	return &user, nil
}

// CreateUserWithFirebaseUID Firebase UIDを持つユーザーを作成
func (s *UserService) CreateUserWithFirebaseUID(ctx context.Context, user *User) error {
	if user.FirebaseUID == "" {
		return fmt.Errorf("Firebase UIDが必要です")
	}
	
	// 既存のCreateUserロジックを使用
	now := time.Now()
	user.CreatedAt = now
	user.UpdatedAt = now
	
	// タイムゾーンのデフォルト設定
	if user.Timezone == "" {
		user.Timezone = "Asia/Tokyo"
	}
	
	result, err := s.collection.InsertOne(ctx, user)
	if err != nil {
		// 重複エラーをチェック
		if mongo.IsDuplicateKeyError(err) {
			return fmt.Errorf("このメールアドレスまたはFirebase UIDは既に使用されています")
		}
		return fmt.Errorf("Firebase対応ユーザー作成エラー: %w", err)
	}
	
	user.ID = result.InsertedID.(primitive.ObjectID)
	return nil
}

// GetAllUsers 全ユーザーを取得（移行用）
func (s *UserService) GetAllUsers(ctx context.Context) ([]User, error) {
	cursor, err := s.collection.Find(ctx, bson.M{})
	if err != nil {
		return nil, fmt.Errorf("全ユーザー取得エラー: %w", err)
	}
	defer cursor.Close(ctx)
	
	var users []User
	if err = cursor.All(ctx, &users); err != nil {
		return nil, fmt.Errorf("ユーザーデータデコードエラー: %w", err)
	}
	
	return users, nil
}

// CreateFirebaseUIDIndex Firebase UIDにインデックスを作成
func (s *UserService) CreateFirebaseUIDIndex(ctx context.Context) error {
	indexModel := mongo.IndexModel{
		Keys:    bson.D{{Key: "firebaseUid", Value: 1}}, // 昇順インデックス
		Options: options.Index().SetUnique(true).SetSparse(true), // ユニーク制約、スパースインデックス
	}
	
	_, err := s.collection.Indexes().CreateOne(ctx, indexModel)
	if err != nil {
		return fmt.Errorf("Firebase UIDインデックス作成エラー: %w", err)
	}
	
	return nil
}