package main

import (
	"context"
	"log"
	"time"

	"github.com/joho/godotenv"
	"yanwari-message-backend/database"
	"yanwari-message-backend/models"
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
	userService := models.NewUserService(db.Database)

	log.Println("🏗️  Firebase対応デモデータを作成中...")

	// デモアカウント情報
	aliceFirebaseUID := "42KXtAePGIhXdeClVDJcEf1Qpz63"
	bobFirebaseUID := "183P9sHTdJR1pbkZvGyY4ODVKCh2"

	// Alice のユーザー作成
	alice := &models.User{
		Name:        "Alice Demo",
		Email:       "alice@yanwari.com",
		FirebaseUID: aliceFirebaseUID,
		Timezone:    "Asia/Tokyo",
		CreatedAt:   time.Now(),
		UpdatedAt:   time.Now(),
	}

	err = userService.CreateUserWithFirebaseUID(ctx, alice)
	if err != nil {
		log.Fatalf("❌ Alice ユーザー作成エラー: %v", err)
	}
	log.Printf("✅ Alice 作成成功 - ID: %s, Firebase UID: %s", alice.ID.Hex(), alice.FirebaseUID)

	// Bob のユーザー作成
	bob := &models.User{
		Name:        "Bob Demo",
		Email:       "bob@yanwari.com",
		FirebaseUID: bobFirebaseUID,
		Timezone:    "Asia/Tokyo",
		CreatedAt:   time.Now(),
		UpdatedAt:   time.Now(),
	}

	err = userService.CreateUserWithFirebaseUID(ctx, bob)
	if err != nil {
		log.Fatalf("❌ Bob ユーザー作成エラー: %v", err)
	}
	log.Printf("✅ Bob 作成成功 - ID: %s, Firebase UID: %s", bob.ID.Hex(), bob.FirebaseUID)

	// サービス初期化
	messageService := models.NewMessageService(db.Database, userService)
	friendRequestService := models.NewFriendRequestService(db.Database)

	// 友達関係を作成（Alice → Bob → 承認済み）
	log.Println("👫 友達関係を作成中...")
	
	// Alice → Bob 友達申請
	friendRequest, err := friendRequestService.Create(ctx, alice.ID, bob.ID, "テスト用の友達申請です！")
	if err != nil {
		log.Fatalf("❌ 友達申請作成エラー: %v", err)
	}
	log.Printf("✅ 友達申請作成成功 - ID: %s", friendRequest.ID.Hex())

	// 友達申請を承認（Bob が承認）
	err = friendRequestService.Accept(ctx, friendRequest.ID, bob.ID)
	if err != nil {
		log.Fatalf("❌ 友達申請承認エラー: %v", err)
	}
	log.Printf("✅ 友達申請承認成功（Alice ↔ Bob 友達関係成立）")

	// テストメッセージを作成
	log.Println("💬 テストメッセージを作成中...")

	// Alice → Bob メッセージ（下書き作成）
	message1Req := &models.CreateMessageRequest{
		RecipientEmail: "bob@yanwari.com",
		OriginalText:   "明日の会議なんですが、準備が間に合わなくて延期してもらえませんか？",
	}

	message1, err := messageService.CreateDraft(ctx, alice.ID, message1Req)
	if err != nil {
		log.Fatalf("❌ Alice → Bob メッセージ作成エラー: %v", err)
	}
	log.Printf("✅ Alice → Bob メッセージ作成成功 - ID: %s", message1.ID.Hex())

	// メッセージ作成成功（下書き状態のまま）
	log.Printf("✅ Alice → Bob メッセージ（下書き状態）")

	// Bob → Alice 返信メッセージ（下書き状態）
	message2Req := &models.CreateMessageRequest{
		RecipientEmail: "alice@yanwari.com",
		OriginalText:   "了解です！来週の同じ時間はいかがですか？",
	}

	message2, err := messageService.CreateDraft(ctx, bob.ID, message2Req)
	if err != nil {
		log.Fatalf("❌ Bob → Alice メッセージ作成エラー: %v", err)
	}
	log.Printf("✅ Bob → Alice 下書きメッセージ作成成功 - ID: %s", message2.ID.Hex())

	log.Println("🎉 Firebase対応デモデータ作成完了！")
	log.Println("📊 作成されたデータ:")
	log.Printf("   👤 ユーザー: 2人 (Alice, Bob)")
	log.Printf("   👫 友達関係: 1組 (Alice ↔ Bob)")
	log.Printf("   💬 メッセージ: 2件 (送信済み1件、下書き1件)")
	log.Println("")
	log.Println("🧪 テスト用Firebase認証情報:")
	log.Println("   Alice: alice@yanwari.com / AliceDemo123!")
	log.Printf("   Alice Firebase UID: %s", aliceFirebaseUID)
	log.Println("   Bob: bob@yanwari.com / BobDemo123!")
	log.Printf("   Bob Firebase UID: %s", bobFirebaseUID)
}