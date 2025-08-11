package main

import (
	"context"
	"log"

	"github.com/joho/godotenv"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"yanwari-message-backend/database"
)

func main() {
	// 環境変数の読み込み
	if err := godotenv.Load(".env"); err != nil {
		log.Println("Warning: .env file not found - using system environment variables")
	}

	// データベース接続
	db, err := database.Connect()
	if err != nil {
		log.Fatal("MongoDB接続に失敗: ", err)
	}
	defer func() {
		if err := db.Close(); err != nil {
			log.Printf("MongoDB切断エラー: %v", err)
		}
	}()

	ctx := context.Background()
	usersCollection := db.Database.Collection("users")
	messagesCollection := db.Database.Collection("messages")
	friendshipsCollection := db.Database.Collection("friendships")
	friendRequestsCollection := db.Database.Collection("friend_requests")

	log.Println("🔧 Bob ユーザーデータを修正中...")

	// 現在のFirebase認証で使用されるBobユーザー（正しいUID）
	correctFirebaseUID := "183P9sHTdJR1pbkZvGyY4ODVKCh2"
	
	// 正しいFirebase UIDを持つBobユーザーを検索
	var correctBobUser bson.M
	err = usersCollection.FindOne(ctx, bson.M{
		"firebase_uid": correctFirebaseUID,
		"email": "bob@yanwari.com",
	}).Decode(&correctBobUser)
	
	if err != nil {
		log.Fatalf("❌ 正しいBobユーザーが見つかりません: %v", err)
	}
	
	correctBobID := correctBobUser["_id"].(primitive.ObjectID)
	log.Printf("✅ 正しいBobユーザー見つかりました: %s", correctBobID.Hex())

	// 古いテストUID用のBobユーザーを検索
	oldTestUID := "test_firebase_uid_002"
	var oldBobUser bson.M
	err = usersCollection.FindOne(ctx, bson.M{
		"firebase_uid": oldTestUID,
		"email": "bob@yanwari.com",
	}).Decode(&oldBobUser)
	
	if err != nil {
		log.Printf("古いBobユーザーが見つかりません（おそらく正常）: %v", err)
		log.Println("✅ データ修正完了（修正の必要なし）")
		return
	}
	
	oldBobID := oldBobUser["_id"].(primitive.ObjectID)
	log.Printf("🔍 古いBobユーザー見つかりました: %s", oldBobID.Hex())

	// 1. メッセージのsenderIdとrecipientIdを更新
	log.Println("📝 メッセージのユーザーIDを更新中...")
	
	// 送信者IDを更新
	senderResult, err := messagesCollection.UpdateMany(ctx,
		bson.M{"senderId": oldBobID},
		bson.M{"$set": bson.M{"senderId": correctBobID}},
	)
	if err != nil {
		log.Printf("❌ メッセージ送信者ID更新エラー: %v", err)
	} else {
		log.Printf("✅ 送信者ID更新: %d件", senderResult.ModifiedCount)
	}

	// 受信者IDを更新
	recipientResult, err := messagesCollection.UpdateMany(ctx,
		bson.M{"recipientId": oldBobID},
		bson.M{"$set": bson.M{"recipientId": correctBobID}},
	)
	if err != nil {
		log.Printf("❌ メッセージ受信者ID更新エラー: %v", err)
	} else {
		log.Printf("✅ 受信者ID更新: %d件", recipientResult.ModifiedCount)
	}

	// 2. 友達関係を更新
	log.Println("👫 友達関係のユーザーIDを更新中...")
	
	// user1を更新
	friendship1Result, err := friendshipsCollection.UpdateMany(ctx,
		bson.M{"user1": oldBobID},
		bson.M{"$set": bson.M{"user1": correctBobID}},
	)
	if err != nil {
		log.Printf("❌ 友達関係user1更新エラー: %v", err)
	} else {
		log.Printf("✅ 友達関係user1更新: %d件", friendship1Result.ModifiedCount)
	}

	// user2を更新
	friendship2Result, err := friendshipsCollection.UpdateMany(ctx,
		bson.M{"user2": oldBobID},
		bson.M{"$set": bson.M{"user2": correctBobID}},
	)
	if err != nil {
		log.Printf("❌ 友達関係user2更新エラー: %v", err)
	} else {
		log.Printf("✅ 友達関係user2更新: %d件", friendship2Result.ModifiedCount)
	}

	// 3. 友達申請を更新
	log.Println("🤝 友達申請のユーザーIDを更新中...")
	
	// from_user_idを更新
	fromUserResult, err := friendRequestsCollection.UpdateMany(ctx,
		bson.M{"from_user_id": oldBobID},
		bson.M{"$set": bson.M{"from_user_id": correctBobID}},
	)
	if err != nil {
		log.Printf("❌ 友達申請from_user_id更新エラー: %v", err)
	} else {
		log.Printf("✅ 友達申請from_user_id更新: %d件", fromUserResult.ModifiedCount)
	}

	// to_user_idを更新
	toUserResult, err := friendRequestsCollection.UpdateMany(ctx,
		bson.M{"to_user_id": oldBobID},
		bson.M{"$set": bson.M{"to_user_id": correctBobID}},
	)
	if err != nil {
		log.Printf("❌ 友達申請to_user_id更新エラー: %v", err)
	} else {
		log.Printf("✅ 友達申請to_user_id更新: %d件", toUserResult.ModifiedCount)
	}

	// 4. 古いBobユーザーを削除
	log.Println("🗑️ 古いBobユーザーを削除中...")
	
	deleteResult, err := usersCollection.DeleteOne(ctx, bson.M{"_id": oldBobID})
	if err != nil {
		log.Printf("❌ 古いBobユーザー削除エラー: %v", err)
	} else {
		log.Printf("✅ 古いBobユーザー削除: %d件", deleteResult.DeletedCount)
	}

	log.Println("🎉 Bobユーザーデータ修正完了！")
	log.Printf("   📊 修正サマリー:")
	log.Printf("   📝 メッセージ更新: 送信者%d件、受信者%d件", senderResult.ModifiedCount, recipientResult.ModifiedCount)
	log.Printf("   👫 友達関係更新: user1=%d件、user2=%d件", friendship1Result.ModifiedCount, friendship2Result.ModifiedCount)
	log.Printf("   🤝 友達申請更新: from=%d件、to=%d件", fromUserResult.ModifiedCount, toUserResult.ModifiedCount)
	log.Printf("   🗑️ 削除ユーザー: %d件", deleteResult.DeletedCount)
}