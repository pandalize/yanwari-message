package main

import (
	"context"
	"fmt"
	"log"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

func main() {
	// MongoDB接続URI
	uri := "mongodb+srv://wiskty21:NeKwMdJ427DX33f2@cluster0.12fnzwn.mongodb.net/yanwari-message?retryWrites=true&w=majority&appName=Cluster0"
	
	// MongoDB接続
	client, err := mongo.Connect(context.TODO(), options.Client().ApplyURI(uri))
	if err != nil {
		log.Fatal("MongoDB接続エラー:", err)
	}
	defer client.Disconnect(context.TODO())

	// データベース・コレクション取得
	db := client.Database("yanwari-message")
	messagesCollection := db.Collection("messages")

	fmt.Println("=== 全メッセージの詳細調査 ===")
	
	// 全メッセージを詳細に取得
	cursor, err := messagesCollection.Find(context.TODO(), bson.M{})
	if err != nil {
		log.Fatal("メッセージ検索エラー:", err)
	}
	defer cursor.Close(context.TODO())

	var messages []bson.M
	if err = cursor.All(context.TODO(), &messages); err != nil {
		log.Fatal("メッセージデータ取得エラー:", err)
	}

	fmt.Printf("見つかったメッセージ数: %d\n\n", len(messages))
	
	for i, message := range messages {
		fmt.Printf("--- メッセージ %d ---\n", i+1)
		
		// 各フィールドを個別にチェック
		if id, ok := message["_id"]; ok {
			fmt.Printf("ID: %v\n", id)
		}
		if senderId, ok := message["sender_id"]; ok {
			fmt.Printf("送信者ID: %v\n", senderId)
		}
		if recipientId, ok := message["recipient_id"]; ok {
			fmt.Printf("受信者ID: %v\n", recipientId)
		}
		if recipientEmail, ok := message["recipient_email"]; ok {
			fmt.Printf("受信者Email: %v\n", recipientEmail)
		}
		if originalText, ok := message["original_text"]; ok {
			fmt.Printf("原文: %v\n", originalText)
		}
		if finalText, ok := message["final_text"]; ok {
			fmt.Printf("最終テキスト: %v\n", finalText)
		}
		if variations, ok := message["variations"]; ok {
			fmt.Printf("変換バリエーション: %v\n", variations)
		}
		if selectedTone, ok := message["selected_tone"]; ok {
			fmt.Printf("選択されたトーン: %v\n", selectedTone)
		}
		if status, ok := message["status"]; ok {
			fmt.Printf("ステータス: %v\n", status)
		}
		if createdAt, ok := message["created_at"]; ok {
			fmt.Printf("作成日時: %v\n", createdAt)
		}
		if sentAt, ok := message["sent_at"]; ok {
			fmt.Printf("送信日時: %v\n", sentAt)
		}
		if readAt, ok := message["read_at"]; ok {
			fmt.Printf("既読日時: %v\n", readAt)
		}
		
		// 全フィールド表示（デバッグ用）
		fmt.Printf("全データ: %+v\n", message)
		fmt.Println()
	}

	// bob/demoユーザーの詳細確認
	fmt.Println("=== bob/demoユーザーの詳細 ===")
	usersCollection := db.Collection("users")
	
	userFilter := bson.M{
		"$or": []bson.M{
			{"email": bson.M{"$regex": "bob", "$options": "i"}},
			{"email": bson.M{"$regex": "demo", "$options": "i"}},
			{"name": bson.M{"$regex": "bob", "$options": "i"}},
			{"name": bson.M{"$regex": "demo", "$options": "i"}},
		},
	}

	userCursor, err := usersCollection.Find(context.TODO(), userFilter)
	if err != nil {
		log.Fatal("ユーザー検索エラー:", err)
	}
	defer userCursor.Close(context.TODO())

	var users []bson.M
	if err = userCursor.All(context.TODO(), &users); err != nil {
		log.Fatal("ユーザーデータ取得エラー:", err)
	}

	for i, user := range users {
		fmt.Printf("--- ユーザー %d ---\n", i+1)
		fmt.Printf("全データ: %+v\n", user)
		fmt.Println()
	}

	// 特定の検索パターンでメッセージを探す
	fmt.Println("=== bob@yanwari.com 宛てメッセージ検索 ===")
	bobEmailFilter := bson.M{"recipient_email": "bob@yanwari.com"}
	bobCursor, err := messagesCollection.Find(context.TODO(), bobEmailFilter)
	if err != nil {
		log.Fatal("Bob宛メッセージ検索エラー:", err)
	}
	defer bobCursor.Close(context.TODO())

	var bobMessages []bson.M
	if err = bobCursor.All(context.TODO(), &bobMessages); err != nil {
		log.Fatal("Bobメッセージデータ取得エラー:", err)
	}

	fmt.Printf("bob@yanwari.com 宛てメッセージ数: %d\n", len(bobMessages))
	for _, msg := range bobMessages {
		fmt.Printf("メッセージ: %+v\n", msg)
	}
}