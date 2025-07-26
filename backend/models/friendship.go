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

// Friendship は友達関係を表すモデル
type Friendship struct {
	ID        primitive.ObjectID `bson:"_id,omitempty" json:"id"`
	User1ID   primitive.ObjectID `bson:"user1_id" json:"user1_id"` // 小さいID
	User2ID   primitive.ObjectID `bson:"user2_id" json:"user2_id"` // 大きいID
	CreatedAt time.Time          `bson:"created_at" json:"created_at"`
}

// FriendshipWithUser は友達関係とユーザー情報を含む構造体
type FriendshipWithUser struct {
	FriendshipID primitive.ObjectID `json:"friendship_id"`
	Friend       *User              `json:"friend"`
	CreatedAt    time.Time          `json:"created_at"`
}

// FriendshipService は友達関係に関する操作を提供
type FriendshipService struct {
	collection *mongo.Collection
	db         *mongo.Database
}

// NewFriendshipService は新しいFriendshipServiceを作成
func NewFriendshipService(db *mongo.Database) *FriendshipService {
	collection := db.Collection("friendships")
	
	// インデックスの作成
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	
	// 複合ユニークインデックス（重複防止）
	collection.Indexes().CreateOne(ctx, mongo.IndexModel{
		Keys: bson.D{
			{Key: "user1_id", Value: 1},
			{Key: "user2_id", Value: 1},
		},
		Options: options.Index().SetUnique(true),
	})
	
	// 個別インデックス（検索高速化）
	collection.Indexes().CreateOne(ctx, mongo.IndexModel{
		Keys: bson.D{{Key: "user1_id", Value: 1}},
	})
	
	collection.Indexes().CreateOne(ctx, mongo.IndexModel{
		Keys: bson.D{{Key: "user2_id", Value: 1}},
	})
	
	return &FriendshipService{
		collection: collection,
		db:         db,
	}
}

// normalizeUserIDs はユーザーIDを正規化（小さい方をuser1_id、大きい方をuser2_idにする）
func (s *FriendshipService) normalizeUserIDs(userID1, userID2 primitive.ObjectID) (primitive.ObjectID, primitive.ObjectID) {
	if userID1.Hex() < userID2.Hex() {
		return userID1, userID2
	}
	return userID2, userID1
}

// Create は新しい友達関係を作成
func (s *FriendshipService) Create(ctx context.Context, userID1, userID2 primitive.ObjectID) (*Friendship, error) {
	// 自分自身との友達関係をチェック
	if userID1 == userID2 {
		return nil, errors.New("自分自身と友達になることはできません")
	}
	
	// IDを正規化
	user1ID, user2ID := s.normalizeUserIDs(userID1, userID2)
	
	// 既存の友達関係をチェック
	exists, err := s.AreFriends(ctx, userID1, userID2)
	if err != nil {
		return nil, err
	}
	if exists {
		return nil, errors.New("既に友達です")
	}
	
	friendship := &Friendship{
		User1ID:   user1ID,
		User2ID:   user2ID,
		CreatedAt: time.Now(),
	}
	
	result, err := s.collection.InsertOne(ctx, friendship)
	if err != nil {
		if mongo.IsDuplicateKeyError(err) {
			return nil, errors.New("既に友達です")
		}
		return nil, err
	}
	
	friendship.ID = result.InsertedID.(primitive.ObjectID)
	return friendship, nil
}

// AreFriends は2人のユーザーが友達かどうかを確認
func (s *FriendshipService) AreFriends(ctx context.Context, userID1, userID2 primitive.ObjectID) (bool, error) {
	// IDを正規化
	user1ID, user2ID := s.normalizeUserIDs(userID1, userID2)
	
	count, err := s.collection.CountDocuments(ctx, bson.M{
		"user1_id": user1ID,
		"user2_id": user2ID,
	})
	
	if err != nil {
		return false, err
	}
	
	return count > 0, nil
}

// GetFriends はユーザーの友達一覧を取得
func (s *FriendshipService) GetFriends(ctx context.Context, userID primitive.ObjectID) ([]*FriendshipWithUser, error) {
	// user1_idまたはuser2_idがuserIDの友達関係を取得
	pipeline := mongo.Pipeline{
		// 友達関係を検索
		{{Key: "$match", Value: bson.M{
			"$or": []bson.M{
				{"user1_id": userID},
				{"user2_id": userID},
			},
		}}},
		// 友達のIDを抽出
		{{Key: "$project", Value: bson.M{
			"_id":        1,
			"created_at": 1,
			"friend_id": bson.M{
				"$cond": bson.M{
					"if":   bson.M{"$eq": []interface{}{"$user1_id", userID}},
					"then": "$user2_id",
					"else": "$user1_id",
				},
			},
		}}},
		// ユーザー情報を結合
		{{Key: "$lookup", Value: bson.M{
			"from":         "users",
			"localField":   "friend_id",
			"foreignField": "_id",
			"as":           "friend",
		}}},
		{{Key: "$unwind", Value: bson.M{
			"path":                       "$friend",
			"preserveNullAndEmptyArrays": false,
		}}},
		// ソート（新しい友達順）
		{{Key: "$sort", Value: bson.M{"created_at": -1}}},
	}
	
	cursor, err := s.collection.Aggregate(ctx, pipeline)
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)
	
	var friends []*FriendshipWithUser
	for cursor.Next(ctx) {
		var result struct {
			ID        primitive.ObjectID `bson:"_id"`
			CreatedAt time.Time          `bson:"created_at"`
			Friend    User               `bson:"friend"`
		}
		
		if err := cursor.Decode(&result); err != nil {
			continue
		}
		
		friends = append(friends, &FriendshipWithUser{
			FriendshipID: result.ID,
			Friend:       &result.Friend,
			CreatedAt:    result.CreatedAt,
		})
	}
	
	return friends, nil
}

// GetFriendCount はユーザーの友達数を取得
func (s *FriendshipService) GetFriendCount(ctx context.Context, userID primitive.ObjectID) (int64, error) {
	count, err := s.collection.CountDocuments(ctx, bson.M{
		"$or": []bson.M{
			{"user1_id": userID},
			{"user2_id": userID},
		},
	})
	
	return count, err
}

// Delete は友達関係を削除
func (s *FriendshipService) Delete(ctx context.Context, userID1, userID2 primitive.ObjectID) error {
	// IDを正規化
	user1ID, user2ID := s.normalizeUserIDs(userID1, userID2)
	
	result, err := s.collection.DeleteOne(ctx, bson.M{
		"user1_id": user1ID,
		"user2_id": user2ID,
	})
	
	if err != nil {
		return err
	}
	
	if result.DeletedCount == 0 {
		return errors.New("友達関係が見つかりません")
	}
	
	return nil
}

// GetFriendIDs はユーザーの友達のIDリストを取得
func (s *FriendshipService) GetFriendIDs(ctx context.Context, userID primitive.ObjectID) ([]primitive.ObjectID, error) {
	// user1_idまたはuser2_idがuserIDの友達関係を取得
	cursor, err := s.collection.Find(ctx, bson.M{
		"$or": []bson.M{
			{"user1_id": userID},
			{"user2_id": userID},
		},
	})
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)
	
	var friendIDs []primitive.ObjectID
	for cursor.Next(ctx) {
		var friendship Friendship
		if err := cursor.Decode(&friendship); err != nil {
			continue
		}
		
		// 友達のIDを抽出
		if friendship.User1ID == userID {
			friendIDs = append(friendIDs, friendship.User2ID)
		} else {
			friendIDs = append(friendIDs, friendship.User1ID)
		}
	}
	
	return friendIDs, nil
}

// GetMutualFriends は共通の友達を取得
func (s *FriendshipService) GetMutualFriends(ctx context.Context, userID1, userID2 primitive.ObjectID) ([]*User, error) {
	// 両ユーザーの友達IDを取得
	friends1, err := s.GetFriendIDs(ctx, userID1)
	if err != nil {
		return nil, err
	}
	
	friends2, err := s.GetFriendIDs(ctx, userID2)
	if err != nil {
		return nil, err
	}
	
	// 共通の友達IDを抽出
	mutualMap := make(map[primitive.ObjectID]bool)
	for _, f1 := range friends1 {
		mutualMap[f1] = false
	}
	
	var mutualIDs []primitive.ObjectID
	for _, f2 := range friends2 {
		if _, exists := mutualMap[f2]; exists {
			mutualIDs = append(mutualIDs, f2)
		}
	}
	
	if len(mutualIDs) == 0 {
		return []*User{}, nil
	}
	
	// ユーザー情報を取得
	userService := NewUserService(s.db)
	var mutualFriends []*User
	
	for _, id := range mutualIDs {
		user, err := userService.GetUserByID(ctx, id.Hex())
		if err != nil {
			continue
		}
		mutualFriends = append(mutualFriends, user)
	}
	
	return mutualFriends, nil
}