package main

import (
	"context"
	"fmt"
	"log"
	"time"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
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
	schedulesCollection := db.Collection("schedules")

	fmt.Println("=== テスト用送信予定メッセージとスケジュールを作成 ===")
	
	// Alice (送信者) と Bob (受信者) のユーザーID
	aliceID, _ := primitive.ObjectIDFromHex("688dacf0a1ea132f632faa77") // alice@yanwari.com
	bobID, _ := primitive.ObjectIDFromHex("688dacf0a1ea132f632faa78")   // bob@yanwari.com
	
	// 1時間後の時刻
	futureTime := time.Now().Add(1 * time.Hour)
	
	// テスト用メッセージを作成
	testMessage := bson.M{
		"_id":            primitive.NewObjectID(),
		"senderId":       aliceID,
		"recipientId":    bobID,
		"originalText":   "テスト用の送信予定メッセージです",
		"finalText":      "お疲れ様です。こちらはテスト用の送信予定メッセージでございます。",
		"selectedTone":   "gentle",
		"status":         "scheduled", // 重要：scheduledステータス
		"scheduledAt":    primitive.NewDateTimeFromTime(futureTime),
		"createdAt":      time.Now().UnixMilli(),
		"updatedAt":      time.Now().UnixMilli(),
		"variations": bson.M{
			"gentle": "お疲れ様です。こちらはテスト用の送信予定メッセージでございます。",
			"casual": "テスト用の送信予定メッセージだよ！",
			"constructive": "テスト用の送信予定メッセージを送信いたします。",
		},
	}
	
	// メッセージを挿入
	messageResult, err := messagesCollection.InsertOne(context.TODO(), testMessage)
	if err != nil {
		log.Fatal("メッセージ挿入エラー:", err)
	}
	messageID := messageResult.InsertedID.(primitive.ObjectID)
	fmt.Printf("✅ テスト用メッセージを作成しました (ID: %s)\n", messageID.Hex())
	
	// 対応するスケジュールを作成
	testSchedule := bson.M{
		"_id":         primitive.NewObjectID(),
		"userId":      aliceID,
		"messageId":   messageID,
		"scheduledAt": primitive.NewDateTimeFromTime(futureTime),
		"status":      "pending", // pendingステータス
		"timezone":    "Asia/Tokyo",
		"retryCount":  0,
		"createdAt":   time.Now().UnixMilli(),
		"updatedAt":   time.Now().UnixMilli(),
	}
	
	// スケジュールを挿入
	scheduleResult, err := schedulesCollection.InsertOne(context.TODO(), testSchedule)
	if err != nil {
		log.Fatal("スケジュール挿入エラー:", err)
	}
	scheduleID := scheduleResult.InsertedID.(primitive.ObjectID)
	fmt.Printf("✅ テスト用スケジュールを作成しました (ID: %s)\n", scheduleID.Hex())
	
	fmt.Printf("\n--- 作成されたテストデータ ---\n")
	fmt.Printf("メッセージID: %s\n", messageID.Hex())
	fmt.Printf("スケジュールID: %s\n", scheduleID.Hex())
	fmt.Printf("送信予定時刻: %s\n", futureTime.Format("2006-01-02 15:04:05"))
	fmt.Printf("メッセージステータス: scheduled\n")
	fmt.Printf("スケジュールステータス: pending\n")
	fmt.Printf("送信者: Alice (alice@yanwari.com)\n")
	fmt.Printf("受信者: Bob (bob@yanwari.com)\n")
	
	fmt.Println("\n=== テストデータ作成完了 ===")
	fmt.Println("これで送信予定画面にメッセージが表示されるはずです。")
}