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

// FriendRequest は友達申請を表すモデル
type FriendRequest struct {
	ID         primitive.ObjectID `bson:"_id,omitempty" json:"id"`
	FromUserID primitive.ObjectID `bson:"from_user_id" json:"from_user_id"`
	ToUserID   primitive.ObjectID `bson:"to_user_id" json:"to_user_id"`
	Status     string             `bson:"status" json:"status"` // pending, accepted, rejected, canceled
	Message    string             `bson:"message,omitempty" json:"message,omitempty"`
	CreatedAt  time.Time          `bson:"created_at" json:"created_at"`
	UpdatedAt  time.Time          `bson:"updated_at" json:"updated_at"`
}

// FriendRequestWithUsers は友達申請とユーザー情報を含む構造体
type FriendRequestWithUsers struct {
	FriendRequest
	FromUser *User `json:"from_user,omitempty"`
	ToUser   *User `json:"to_user,omitempty"`
}

// FriendRequestService は友達申請に関する操作を提供
type FriendRequestService struct {
	collection *mongo.Collection
	db         *mongo.Database
}

// NewFriendRequestService は新しいFriendRequestServiceを作成
func NewFriendRequestService(db *mongo.Database) *FriendRequestService {
	collection := db.Collection("friend_requests")
	
	// インデックスの作成
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	
	// 古いインデックスを削除（初回実行時のみ必要）
	collection.Indexes().DropOne(ctx, "from_user_id_1_to_user_id_1")
	
	// 複合インデックス（同じユーザー間のpending申請の重複を防ぐ）
	// PartialFilterを使用して、pendingステータスのみにユニーク制約を適用
	collection.Indexes().CreateOne(ctx, mongo.IndexModel{
		Keys: bson.D{
			{Key: "from_user_id", Value: 1},
			{Key: "to_user_id", Value: 1},
		},
		Options: options.Index().
			SetUnique(true).
			SetPartialFilterExpression(bson.M{"status": "pending"}).
			SetName("pending_friend_requests_unique"),
	})
	
	// ステータスインデックス
	collection.Indexes().CreateOne(ctx, mongo.IndexModel{
		Keys: bson.D{{Key: "status", Value: 1}},
	})
	
	// ユーザーIDインデックス
	collection.Indexes().CreateOne(ctx, mongo.IndexModel{
		Keys: bson.D{{Key: "to_user_id", Value: 1}},
	})
	
	return &FriendRequestService{
		collection: collection,
		db:         db,
	}
}

// Create は新しい友達申請を作成
func (s *FriendRequestService) Create(ctx context.Context, fromUserID, toUserID primitive.ObjectID, message string) (*FriendRequest, error) {
	// 自分自身への申請をチェック
	if fromUserID == toUserID {
		return nil, errors.New("自分自身に友達申請を送ることはできません")
	}
	
	// 既存の友達申請をチェック
	existingRequest, err := s.GetPendingRequest(ctx, fromUserID, toUserID)
	if err == nil && existingRequest != nil {
		return nil, errors.New("既に友達申請を送信済みです")
	}
	
	// 逆方向の申請をチェック
	reverseRequest, err := s.GetPendingRequest(ctx, toUserID, fromUserID)
	if err == nil && reverseRequest != nil {
		return nil, errors.New("相手から友達申請が来ています。申請を確認してください")
	}
	
	// 既に友達かどうかをチェック
	friendshipService := NewFriendshipService(s.db)
	isFriend, err := friendshipService.AreFriends(ctx, fromUserID, toUserID)
	if err != nil {
		return nil, err
	}
	if isFriend {
		return nil, errors.New("既に友達です")
	}
	
	request := &FriendRequest{
		FromUserID: fromUserID,
		ToUserID:   toUserID,
		Status:     "pending",
		Message:    message,
		CreatedAt:  time.Now(),
		UpdatedAt:  time.Now(),
	}
	
	result, err := s.collection.InsertOne(ctx, request)
	if err != nil {
		if mongo.IsDuplicateKeyError(err) {
			// より具体的なエラーメッセージを提供
			return nil, errors.New("既にpending状態の友達申請が存在します")
		}
		return nil, err
	}
	
	request.ID = result.InsertedID.(primitive.ObjectID)
	return request, nil
}

// GetPendingRequest は保留中の友達申請を取得
func (s *FriendRequestService) GetPendingRequest(ctx context.Context, fromUserID, toUserID primitive.ObjectID) (*FriendRequest, error) {
	var request FriendRequest
	err := s.collection.FindOne(ctx, bson.M{
		"from_user_id": fromUserID,
		"to_user_id":   toUserID,
		"status":       "pending",
	}).Decode(&request)
	
	if err != nil {
		return nil, err
	}
	
	return &request, nil
}

// GetReceivedRequests は受信した友達申請一覧を取得
func (s *FriendRequestService) GetReceivedRequests(ctx context.Context, userID primitive.ObjectID) ([]*FriendRequestWithUsers, error) {
	// パイプラインで友達申請とユーザー情報を結合
	pipeline := mongo.Pipeline{
		{{Key: "$match", Value: bson.M{
			"to_user_id": userID,
			"status":     "pending",
		}}},
		{{Key: "$lookup", Value: bson.M{
			"from":         "users",
			"localField":   "from_user_id",
			"foreignField": "_id",
			"as":           "from_user",
		}}},
		{{Key: "$unwind", Value: bson.M{
			"path":                       "$from_user",
			"preserveNullAndEmptyArrays": false,
		}}},
		{{Key: "$sort", Value: bson.M{"created_at": -1}}},
	}
	
	cursor, err := s.collection.Aggregate(ctx, pipeline)
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)
	
	var requests []*FriendRequestWithUsers
	for cursor.Next(ctx) {
		var result struct {
			FriendRequest `bson:",inline"`
			FromUser      User `bson:"from_user"`
		}
		
		if err := cursor.Decode(&result); err != nil {
			continue
		}
		
		requests = append(requests, &FriendRequestWithUsers{
			FriendRequest: result.FriendRequest,
			FromUser:      &result.FromUser,
		})
	}
	
	return requests, nil
}

// GetSentRequests は送信した友達申請一覧を取得
func (s *FriendRequestService) GetSentRequests(ctx context.Context, userID primitive.ObjectID) ([]*FriendRequestWithUsers, error) {
	// パイプラインで友達申請とユーザー情報を結合
	pipeline := mongo.Pipeline{
		{{Key: "$match", Value: bson.M{
			"from_user_id": userID,
			"status":       "pending",
		}}},
		{{Key: "$lookup", Value: bson.M{
			"from":         "users",
			"localField":   "to_user_id",
			"foreignField": "_id",
			"as":           "to_user",
		}}},
		{{Key: "$unwind", Value: bson.M{
			"path":                       "$to_user",
			"preserveNullAndEmptyArrays": false,
		}}},
		{{Key: "$sort", Value: bson.M{"created_at": -1}}},
	}
	
	cursor, err := s.collection.Aggregate(ctx, pipeline)
	if err != nil {
		return nil, err
	}
	defer cursor.Close(ctx)
	
	var requests []*FriendRequestWithUsers
	for cursor.Next(ctx) {
		var result struct {
			FriendRequest `bson:",inline"`
			ToUser        User `bson:"to_user"`
		}
		
		if err := cursor.Decode(&result); err != nil {
			continue
		}
		
		requests = append(requests, &FriendRequestWithUsers{
			FriendRequest: result.FriendRequest,
			ToUser:        &result.ToUser,
		})
	}
	
	return requests, nil
}

// Accept は友達申請を承諾
func (s *FriendRequestService) Accept(ctx context.Context, requestID, userID primitive.ObjectID) error {
	// 申請を取得
	var request FriendRequest
	err := s.collection.FindOne(ctx, bson.M{
		"_id":        requestID,
		"to_user_id": userID,
		"status":     "pending",
	}).Decode(&request)
	
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return errors.New("友達申請が見つかりません")
		}
		return err
	}
	
	// ステータスを更新
	_, err = s.collection.UpdateOne(ctx, bson.M{
		"_id": requestID,
	}, bson.M{
		"$set": bson.M{
			"status":     "accepted",
			"updated_at": time.Now(),
		},
	})
	
	if err != nil {
		return err
	}
	
	// 友達関係を作成
	friendshipService := NewFriendshipService(s.db)
	_, err = friendshipService.Create(ctx, request.FromUserID, request.ToUserID)
	
	return err
}

// Reject は友達申請を拒否（完全削除）
func (s *FriendRequestService) Reject(ctx context.Context, requestID, userID primitive.ObjectID) error {
	// pending状態の申請を完全に削除
	result, err := s.collection.DeleteOne(ctx, bson.M{
		"_id":        requestID,
		"to_user_id": userID,
		"status":     "pending",
	})
	
	if err != nil {
		return err
	}
	
	if result.DeletedCount == 0 {
		return errors.New("友達申請が見つかりません")
	}
	
	return nil
}

// RejectSoft は友達申請をソフト拒否（ステータス変更）
func (s *FriendRequestService) RejectSoft(ctx context.Context, requestID, userID primitive.ObjectID) error {
	result, err := s.collection.UpdateOne(ctx, bson.M{
		"_id":        requestID,
		"to_user_id": userID,
		"status":     "pending",
	}, bson.M{
		"$set": bson.M{
			"status":     "rejected",
			"updated_at": time.Now(),
		},
	})
	
	if err != nil {
		return err
	}
	
	if result.MatchedCount == 0 {
		return errors.New("友達申請が見つかりません")
	}
	
	return nil
}

// Cancel は送信した友達申請をキャンセル（完全削除）
func (s *FriendRequestService) Cancel(ctx context.Context, requestID, userID primitive.ObjectID) error {
	// pending状態の申請を完全に削除
	result, err := s.collection.DeleteOne(ctx, bson.M{
		"_id":          requestID,
		"from_user_id": userID,
		"status":       "pending",
	})
	
	if err != nil {
		return err
	}
	
	if result.DeletedCount == 0 {
		return errors.New("友達申請が見つかりません")
	}
	
	return nil
}

// CancelSoft は送信した友達申請をソフトキャンセル（ステータス変更）
func (s *FriendRequestService) CancelSoft(ctx context.Context, requestID, userID primitive.ObjectID) error {
	result, err := s.collection.UpdateOne(ctx, bson.M{
		"_id":          requestID,
		"from_user_id": userID,
		"status":       "pending",
	}, bson.M{
		"$set": bson.M{
			"status":     "canceled",
			"updated_at": time.Now(),
		},
	})
	
	if err != nil {
		return err
	}
	
	if result.MatchedCount == 0 {
		return errors.New("友達申請が見つかりません")
	}
	
	return nil
}

// GetByID は友達申請をIDで取得
func (s *FriendRequestService) GetByID(ctx context.Context, requestID primitive.ObjectID) (*FriendRequest, error) {
	var request FriendRequest
	err := s.collection.FindOne(ctx, bson.M{"_id": requestID}).Decode(&request)
	if err != nil {
		return nil, err
	}
	return &request, nil
}

// CleanupCanceledAndRejected はキャンセル・拒否済みの古い友達申請を削除
func (s *FriendRequestService) CleanupCanceledAndRejected(ctx context.Context) (int64, error) {
	// 30日以上古いキャンセル・拒否済み申請を削除
	thirtyDaysAgo := time.Now().AddDate(0, 0, -30)
	
	result, err := s.collection.DeleteMany(ctx, bson.M{
		"status": bson.M{"$in": []string{"canceled", "rejected"}},
		"updated_at": bson.M{"$lt": thirtyDaysAgo},
	})
	
	if err != nil {
		return 0, err
	}
	
	return result.DeletedCount, nil
}