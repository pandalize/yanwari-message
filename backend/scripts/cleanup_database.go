package main

import (
	"context"
	"log"

	"github.com/joho/godotenv"
	"yanwari-message-backend/database"
)

// データベース完全クリーンアップ（Firebase移行用）
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
	database := db.Database

	log.Println("🗑️  既存データベースのクリーンアップを開始...")

	// 全コレクションを削除
	collections := []string{
		"users",
		"messages", 
		"schedules",
		"user_settings",
		"friend_requests",
		"friendships",
		"message_ratings",
	}

	for _, collectionName := range collections {
		collection := database.Collection(collectionName)
		
		// コレクション内の全ドキュメントを削除
		result, err := collection.DeleteMany(ctx, map[string]interface{}{})
		if err != nil {
			log.Printf("❌ %s コレクションの削除エラー: %v", collectionName, err)
		} else {
			log.Printf("✅ %s コレクション: %d ドキュメント削除", collectionName, result.DeletedCount)
		}
	}

	log.Println("🎉 データベースクリーンアップ完了！")
	log.Println("📝 次のステップ: Firebase対応デモアカウントを作成してください。")
}