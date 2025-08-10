package main

import (
	"context"
	"fmt"
	"log"

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
	schedulesCollection := db.Collection("schedules")
	messagesCollection := db.Collection("messages")

	fmt.Println("=== スケジュールとメッセージのステータス同期修正 ===")
	
	// pendingスケジュールを取得
	cursor, err := schedulesCollection.Find(context.TODO(), bson.M{"status": "pending"})
	if err != nil {
		log.Fatal("スケジュール検索エラー:", err)
	}
	defer cursor.Close(context.TODO())

	var schedules []bson.M
	if err = cursor.All(context.TODO(), &schedules); err != nil {
		log.Fatal("スケジュールデータ取得エラー:", err)
	}

	fmt.Printf("修正対象のpendingスケジュール数: %d\n\n", len(schedules))
	
	fixedCount := 0
	for _, schedule := range schedules {
		scheduleId := schedule["_id"].(primitive.ObjectID)
		messageId := schedule["messageId"].(primitive.ObjectID)
		
		fmt.Printf("--- スケジュール %s を確認中 ---\n", scheduleId.Hex())
		fmt.Printf("関連メッセージID: %s\n", messageId.Hex())
		
		// メッセージのステータスを確認
		var message bson.M
		err := messagesCollection.FindOne(context.TODO(), bson.M{"_id": messageId}).Decode(&message)
		if err != nil {
			fmt.Printf("メッセージが見つかりません: %v\n", err)
			continue
		}
		
		messageStatus := message["status"].(string)
		fmt.Printf("メッセージステータス: %s\n", messageStatus)
		
		// メッセージが送信済み/配信済み/既読の場合、スケジュールステータスを更新
		if messageStatus == "sent" || messageStatus == "delivered" || messageStatus == "read" {
			fmt.Printf("スケジュールステータスをsentに更新中...\n")
			
			updateResult, err := schedulesCollection.UpdateOne(
				context.TODO(),
				bson.M{"_id": scheduleId},
				bson.M{"$set": bson.M{"status": "sent"}},
			)
			if err != nil {
				fmt.Printf("更新エラー: %v\n", err)
				continue
			}
			
			if updateResult.ModifiedCount > 0 {
				fmt.Printf("✅ スケジュール %s のステータスをsentに更新しました\n", scheduleId.Hex())
				fixedCount++
			} else {
				fmt.Printf("❌ スケジュール %s の更新に失敗しました\n", scheduleId.Hex())
			}
		} else {
			fmt.Printf("メッセージはまだ送信されていません (status: %s)\n", messageStatus)
		}
		
		fmt.Println()
	}
	
	fmt.Printf("=== 修正完了 ===\n")
	fmt.Printf("修正されたスケジュール数: %d件\n", fixedCount)
}