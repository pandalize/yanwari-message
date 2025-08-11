package main

import (
	"context"
	"log"

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
	messageService := models.NewMessageService(db.Database, userService)
	friendshipService := models.NewFriendshipService(db.Database)

	log.Println("🏗️ Bob用のテストデータを作成中...")

	// 現在のAliceとBobユーザーを取得
	alice, err := userService.GetUserByFirebaseUID(ctx, "42KXtAePGIhXdeClVDJcEf1Qpz63")
	if err != nil {
		log.Fatalf("❌ Aliceユーザー取得エラー: %v", err)
	}
	log.Printf("✅ Alice見つかりました: %s (%s)", alice.Email, alice.ID.Hex())

	bob, err := userService.GetUserByFirebaseUID(ctx, "183P9sHTdJR1pbkZvGyY4ODVKCh2")
	if err != nil {
		log.Fatalf("❌ Bobユーザー取得エラー: %v", err)
	}
	log.Printf("✅ Bob見つかりました: %s (%s)", bob.Email, bob.ID.Hex())

	// 友達関係を作成
	log.Println("👫 友達関係を作成中...")
	
	// 既存の友達関係があるかチェック
	areFriends, err := friendshipService.AreFriends(ctx, alice.ID, bob.ID)
	if err != nil {
		log.Printf("❌ 友達関係チェックエラー: %v", err)
	}
	
	if !areFriends {
		friendship, err := friendshipService.Create(ctx, alice.ID, bob.ID)
		if err != nil {
			log.Fatalf("❌ 友達関係作成エラー: %v", err)
		}
		log.Printf("✅ 友達関係作成成功: %s", friendship.ID.Hex())
	} else {
		log.Println("✅ 友達関係は既に存在します")
	}

	// Bob用テストメッセージを作成
	log.Println("💬 Bob用テストメッセージを作成中...")

	// 1. Alice → Bob のメッセージ（送信済み）
	message1Req := &models.CreateMessageRequest{
		RecipientEmail: "bob@yanwari.com",
		OriginalText:   "Bob、お疲れさまです！プロジェクトの件でお聞きしたいことがあります。",
	}

	message1, err := messageService.CreateDraft(ctx, alice.ID, message1Req)
	if err != nil {
		log.Printf("❌ Alice → Bob メッセージ作成エラー: %v", err)
	} else {
		// メッセージを送信済み状態に変更
		err = messageService.UpdateMessageStatus(ctx, message1.ID, models.MessageStatusSent)
		if err != nil {
			log.Printf("❌ メッセージステータス更新エラー: %v", err)
		} else {
			log.Printf("✅ Alice → Bob メッセージ作成成功: %s", message1.ID.Hex())
		}
	}

	// 2. Bob → Alice のメッセージ（下書き）
	message2Req := &models.CreateMessageRequest{
		RecipientEmail: "alice@yanwari.com",
		OriginalText:   "Alice、お疲れさまです！何時でもお話しできますよ。",
	}

	message2, err := messageService.CreateDraft(ctx, bob.ID, message2Req)
	if err != nil {
		log.Printf("❌ Bob → Alice 下書き作成エラー: %v", err)
	} else {
		log.Printf("✅ Bob → Alice 下書き作成成功: %s", message2.ID.Hex())
	}

	// 3. Bob宛ての受信メッセージ（Alice から）
	message3Req := &models.CreateMessageRequest{
		RecipientEmail: "bob@yanwari.com",
		OriginalText:   "来週のミーティングの準備について相談したいことがあります。",
	}

	message3, err := messageService.CreateDraft(ctx, alice.ID, message3Req)
	if err != nil {
		log.Printf("❌ Alice → Bob 受信メッセージ作成エラー: %v", err)
	} else {
		// メッセージを配信済み状態に変更
		err = messageService.UpdateMessageStatus(ctx, message3.ID, models.MessageStatusDelivered)
		if err != nil {
			log.Printf("❌ メッセージステータス更新エラー: %v", err)
		} else {
			log.Printf("✅ Alice → Bob 受信メッセージ作成成功: %s", message3.ID.Hex())
		}
	}

	log.Println("🎉 Bob用テストデータ作成完了！")
	log.Println("📊 作成されたデータ:")
	log.Printf("   👫 友達関係: Alice ↔ Bob")
	log.Printf("   💬 メッセージ: 3件 (送信済み1件、下書き1件、受信1件)")
	log.Println("")
	log.Println("🧪 Bob でログインして確認してください:")
	log.Println("   📧 Email: bob@yanwari.com")
	log.Printf("   🔑 Firebase UID: %s", bob.FirebaseUID)
}