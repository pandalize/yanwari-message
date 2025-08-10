package main

import (
	"context"
	"fmt"
	"log"
	"os"
	"strings"
	"time"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
	"go.mongodb.org/mongo-driver/bson/primitive"
)

// Message structure matching your model
type Message struct {
	ID           primitive.ObjectID `bson:"_id,omitempty" json:"id"`
	SenderID     primitive.ObjectID `bson:"senderId" json:"senderId"`
	RecipientID  primitive.ObjectID `bson:"recipientId,omitempty" json:"recipientId,omitempty"`
	OriginalText string             `bson:"originalText" json:"originalText"`
	SelectedTone string             `bson:"selectedTone,omitempty" json:"selectedTone,omitempty"`
	FinalText    string             `bson:"finalText,omitempty" json:"finalText,omitempty"`
	ScheduledAt  *time.Time         `bson:"scheduledAt,omitempty" json:"scheduledAt,omitempty"`
	Status       string             `bson:"status" json:"status"`
	CreatedAt    time.Time          `bson:"createdAt" json:"createdAt"`
	UpdatedAt    time.Time          `bson:"updatedAt" json:"updatedAt"`
	SentAt       *time.Time         `bson:"sentAt,omitempty" json:"sentAt,omitempty"`
}

func main() {
	// MongoDB接続情報を環境変数から取得
	mongoURI := os.Getenv("MONGODB_URI")
	if mongoURI == "" {
		log.Fatal("MONGODB_URI環境変数が設定されていません")
	}

	// MongoDB接続
	client, err := mongo.Connect(context.Background(), options.Client().ApplyURI(mongoURI))
	if err != nil {
		log.Fatalf("MongoDB接続エラー: %v", err)
	}
	defer client.Disconnect(context.Background())

	db := client.Database("yanwari-message")
	collection := db.Collection("messages")

	fmt.Println("🧪 配信サービステスト用メッセージ作成・監視")
	fmt.Println(strings.Repeat("=", 60))

	// 1. テスト用のscheduledメッセージを作成
	fmt.Println("📝 テスト用scheduled状態メッセージを作成中...")
	
	now := time.Now()
	futureTime := now.Add(2 * time.Minute) // 2分後に配信予定
	
	testMessage := Message{
		SenderID:     primitive.NewObjectID(), // テスト用ユーザーID
		RecipientID:  primitive.NewObjectID(), // テスト用受信者ID
		OriginalText: "配信サービステスト用メッセージです",
		SelectedTone: "gentle",
		FinalText:    "配信サービステスト用メッセージです（やんわり変換済み）",
		ScheduledAt:  &futureTime,
		Status:       "scheduled",
		CreatedAt:    now,
		UpdatedAt:    now,
	}
	
	result, err := collection.InsertOne(context.Background(), testMessage)
	if err != nil {
		log.Fatalf("テストメッセージ作成エラー: %v", err)
	}
	
	testMessageID := result.InsertedID.(primitive.ObjectID)
	fmt.Printf("✅ テストメッセージ作成完了: ID=%s\n", testMessageID.Hex())
	fmt.Printf("📅 配信予定時刻: %s\n", futureTime.Format("2006-01-02 15:04:05"))
	fmt.Println()

	// 2. 配信サービス関数と同じクエリを実行して監視
	fmt.Println("🔍 配信対象メッセージの監視開始（3分間）:")
	fmt.Println(strings.Repeat("-", 50))
	
	monitorStart := time.Now()
	checkInterval := 10 * time.Second
	maxDuration := 3 * time.Minute
	
	for time.Since(monitorStart) < maxDuration {
		currentTime := time.Now()
		
		// DeliverScheduledMessages関数と同じクエリ
		filter := bson.M{
			"status":      "scheduled",
			"scheduledAt": bson.M{"$lte": currentTime},
		}
		
		cursor, err := collection.Find(context.Background(), filter)
		if err != nil {
			log.Printf("❌ 配信対象検索エラー: %v", err)
			time.Sleep(checkInterval)
			continue
		}
		
		var messages []Message
		if err = cursor.All(context.Background(), &messages); err != nil {
			log.Printf("❌ メッセージ読み込みエラー: %v", err)
			cursor.Close(context.Background())
			time.Sleep(checkInterval)
			continue
		}
		cursor.Close(context.Background())
		
		fmt.Printf("[%s] 配信対象メッセージ: %d件\n", 
			currentTime.Format("15:04:05"), len(messages))
		
		for i, msg := range messages {
			fmt.Printf("  メッセージ #%d: ID=%s, status=%s, scheduledAt=%s\n", 
				i+1, msg.ID.Hex(), msg.Status, msg.ScheduledAt.Format("15:04:05"))
		}
		
		// テストメッセージの現在の状態をチェック
		var currentTestMessage Message
		err = collection.FindOne(context.Background(), bson.M{"_id": testMessageID}).Decode(&currentTestMessage)
		if err != nil {
			fmt.Printf("⚠️ テストメッセージ取得エラー: %v\n", err)
		} else {
			fmt.Printf("📋 テストメッセージ状態: status=%s", currentTestMessage.Status)
			if currentTestMessage.SentAt != nil {
				fmt.Printf(", sentAt=%s", currentTestMessage.SentAt.Format("15:04:05"))
			}
			fmt.Println()
		}
		
		fmt.Println()
		
		// scheduled状態でなくなったら監視終了
		if err == nil && currentTestMessage.Status != "scheduled" {
			fmt.Printf("🎉 テストメッセージが配信されました！ status=%s\n", currentTestMessage.Status)
			break
		}
		
		time.Sleep(checkInterval)
	}
	
	// 3. 最終状態確認
	fmt.Println("📋 最終状態確認:")
	fmt.Println(strings.Repeat("-", 50))
	
	var finalMessage Message
	err = collection.FindOne(context.Background(), bson.M{"_id": testMessageID}).Decode(&finalMessage)
	if err != nil {
		fmt.Printf("❌ 最終メッセージ取得エラー: %v\n", err)
	} else {
		fmt.Printf("最終ステータス: %s\n", finalMessage.Status)
		fmt.Printf("作成日時: %s\n", finalMessage.CreatedAt.Format("2006-01-02 15:04:05"))
		fmt.Printf("更新日時: %s\n", finalMessage.UpdatedAt.Format("2006-01-02 15:04:05"))
		if finalMessage.ScheduledAt != nil {
			fmt.Printf("配信予定時刻: %s\n", finalMessage.ScheduledAt.Format("2006-01-02 15:04:05"))
		}
		if finalMessage.SentAt != nil {
			fmt.Printf("送信日時: %s\n", finalMessage.SentAt.Format("2006-01-02 15:04:05"))
			
			// 配信遅延を計算
			if finalMessage.ScheduledAt != nil {
				expectedDelay := finalMessage.ScheduledAt.Sub(finalMessage.CreatedAt)
				actualDelay := finalMessage.SentAt.Sub(finalMessage.CreatedAt)
				fmt.Printf("配信遅延: 予定=%v, 実際=%v, 差分=%v\n", 
					expectedDelay.Round(time.Second), 
					actualDelay.Round(time.Second),
					(actualDelay - expectedDelay).Round(time.Second))
			}
		}
	}
	
	// 4. テストメッセージをクリーンアップ（オプション）
	fmt.Println("\n🧹 テストメッセージのクリーンアップ:")
	_, err = collection.DeleteOne(context.Background(), bson.M{"_id": testMessageID})
	if err != nil {
		fmt.Printf("⚠️ テストメッセージ削除エラー: %v\n", err)
	} else {
		fmt.Printf("✅ テストメッセージを削除しました: ID=%s\n", testMessageID.Hex())
	}
	
	fmt.Println("\n🔍 テスト完了")
	fmt.Println(strings.Repeat("=", 60))
	
	// 結論
	fmt.Println("\n📝 テスト結果の分析:")
	if finalMessage.Status == "scheduled" {
		fmt.Println("⚠️ 配信サービスが動作していない可能性があります")
		fmt.Println("- テストメッセージがscheduled状態のまま")
		fmt.Println("- バックグラウンド配信エンジンが停止している可能性")
	} else {
		fmt.Println("✅ 配信サービスは正常に動作しています")
		fmt.Printf("- テストメッセージが %s 状態に変更されました\n", finalMessage.Status)
		fmt.Println("- 今後scheduled状態のメッセージがない理由:")
		fmt.Println("  1. 配信サービスが高頻度で実行されている")
		fmt.Println("  2. メッセージが即座に処理されている")
	}
}