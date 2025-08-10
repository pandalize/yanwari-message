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

	fmt.Println("=== 配信テスト: スケジュール時刻を過去に変更 ===")
	
	// テスト用メッセージID（先ほど作成したもの）
	testMessageID, _ := primitive.ObjectIDFromHex("68920197ce97cbbd08ceac6e")
	testScheduleID, _ := primitive.ObjectIDFromHex("68920197ce97cbbd08ceac6f")
	
	// 現在時刻の5分前に設定
	pastTime := time.Now().Add(-5 * time.Minute)
	
	fmt.Printf("テストメッセージID: %s\n", testMessageID.Hex())
	fmt.Printf("テストスケジュールID: %s\n", testScheduleID.Hex())
	fmt.Printf("設定時刻: %s（5分前）\n", pastTime.Format("2006-01-02 15:04:05"))
	
	// 1. メッセージのscheduledAtを過去に変更
	messageUpdateResult, err := messagesCollection.UpdateOne(
		context.TODO(),
		bson.M{"_id": testMessageID},
		bson.M{"$set": bson.M{"scheduledAt": primitive.NewDateTimeFromTime(pastTime)}},
	)
	if err != nil {
		log.Fatal("メッセージ更新エラー:", err)
	}
	
	if messageUpdateResult.ModifiedCount > 0 {
		fmt.Printf("✅ メッセージのscheduledAtを過去時刻に更新しました\n")
	} else {
		fmt.Printf("❌ メッセージの更新に失敗しました\n")
	}
	
	// 2. スケジュールのscheduledAtを過去に変更
	scheduleUpdateResult, err := schedulesCollection.UpdateOne(
		context.TODO(),
		bson.M{"_id": testScheduleID},
		bson.M{"$set": bson.M{"scheduledAt": primitive.NewDateTimeFromTime(pastTime)}},
	)
	if err != nil {
		log.Fatal("スケジュール更新エラー:", err)
	}
	
	if scheduleUpdateResult.ModifiedCount > 0 {
		fmt.Printf("✅ スケジュールのscheduledAtを過去時刻に更新しました\n")
	} else {
		fmt.Printf("❌ スケジュールの更新に失敗しました\n")
	}
	
	fmt.Println("\n=== 更新完了 ===")
	fmt.Println("これで配信エンジンが次回実行時（1分以内）にこのメッセージを配信するはずです。")
	fmt.Println("または手動配信APIを呼び出してテストすることもできます。")
	
	// 現在の状態を確認
	fmt.Println("\n=== 現在の状態確認 ===")
	
	var message bson.M
	err = messagesCollection.FindOne(context.TODO(), bson.M{"_id": testMessageID}).Decode(&message)
	if err != nil {
		log.Printf("メッセージの確認に失敗: %v", err)
	} else {
		fmt.Printf("メッセージステータス: %v\n", message["status"])
		fmt.Printf("メッセージscheduledAt: %v\n", message["scheduledAt"])
	}
	
	var schedule bson.M
	err = schedulesCollection.FindOne(context.TODO(), bson.M{"_id": testScheduleID}).Decode(&schedule)
	if err != nil {
		log.Printf("スケジュールの確認に失敗: %v", err)
	} else {
		fmt.Printf("スケジュールステータス: %v\n", schedule["status"])
		fmt.Printf("スケジュールscheduledAt: %v\n", schedule["scheduledAt"])
	}
}