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
	schedulesCollection := db.Collection("schedules")
	messagesCollection := db.Collection("messages")

	fmt.Println("=== スケジュールコレクション調査 ===")
	
	// 全スケジュールを詳細に取得
	cursor, err := schedulesCollection.Find(context.TODO(), bson.M{})
	if err != nil {
		log.Fatal("スケジュール検索エラー:", err)
	}
	defer cursor.Close(context.TODO())

	var schedules []bson.M
	if err = cursor.All(context.TODO(), &schedules); err != nil {
		log.Fatal("スケジュールデータ取得エラー:", err)
	}

	fmt.Printf("見つかったスケジュール数: %d\n\n", len(schedules))
	
	for i, schedule := range schedules {
		fmt.Printf("--- スケジュール %d ---\n", i+1)
		fmt.Printf("全データ: %+v\n", schedule)
		fmt.Println()
	}

	fmt.Println("=== メッセージのステータス別集計 ===")
	
	// メッセージステータス別集計
	statuses := []string{"draft", "scheduled", "sent", "delivered", "read"}
	for _, status := range statuses {
		count, err := messagesCollection.CountDocuments(context.TODO(), bson.M{"status": status})
		if err != nil {
			log.Printf("ステータス %s の集計エラー: %v", status, err)
			continue
		}
		fmt.Printf("ステータス '%s': %d件\n", status, count)
	}

	fmt.Println("\n=== scheduledAt フィールドがあるメッセージ ===")
	
	// scheduledAtフィールドを持つメッセージを検索
	scheduledMsgCursor, err := messagesCollection.Find(context.TODO(), bson.M{"scheduledAt": bson.M{"$exists": true}})
	if err != nil {
		log.Fatal("scheduledAtメッセージ検索エラー:", err)
	}
	defer scheduledMsgCursor.Close(context.TODO())

	var scheduledMessages []bson.M
	if err = scheduledMsgCursor.All(context.TODO(), &scheduledMessages); err != nil {
		log.Fatal("scheduledAtメッセージデータ取得エラー:", err)
	}

	fmt.Printf("scheduledAtフィールド付きメッセージ数: %d\n\n", len(scheduledMessages))
	
	for i, msg := range scheduledMessages {
		fmt.Printf("--- 予定メッセージ %d ---\n", i+1)
		fmt.Printf("ID: %v\n", msg["_id"])
		fmt.Printf("ステータス: %v\n", msg["status"])
		fmt.Printf("原文: %v\n", msg["originalText"])
		fmt.Printf("スケジュール時刻: %v\n", msg["scheduledAt"])
		if sentAt, ok := msg["sentAt"]; ok {
			fmt.Printf("送信時刻: %v\n", sentAt)
		}
		fmt.Println()
	}
}