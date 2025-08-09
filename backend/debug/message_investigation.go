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

	fmt.Println("🔍 メッセージコレクション調査開始")
	fmt.Println(strings.Repeat("=", 60))

	// 1. 全メッセージ数を取得
	totalCount, err := collection.CountDocuments(context.Background(), bson.M{})
	if err != nil {
		log.Fatalf("総メッセージ数取得エラー: %v", err)
	}
	fmt.Printf("📊 総メッセージ数: %d件\n\n", totalCount)

	// 2. ステータス別メッセージ数
	statusCounts := []string{"draft", "processing", "scheduled", "sent", "delivered", "read"}
	fmt.Println("📋 ステータス別メッセージ数:")
	for _, status := range statusCounts {
		count, err := collection.CountDocuments(context.Background(), bson.M{"status": status})
		if err != nil {
			log.Printf("ステータス%s取得エラー: %v", status, err)
			continue
		}
		fmt.Printf("  %s: %d件\n", status, count)
	}
	fmt.Println()

	// 3. scheduled状態のメッセージを詳細表示
	fmt.Println("🕒 scheduled状態のメッセージ詳細:")
	fmt.Println(strings.Repeat("-", 80))
	
	scheduledCursor, err := collection.Find(context.Background(), bson.M{"status": "scheduled"})
	if err != nil {
		log.Fatalf("scheduled メッセージ取得エラー: %v", err)
	}
	defer scheduledCursor.Close(context.Background())

	scheduledCount := 0
	now := time.Now()
	
	for scheduledCursor.Next(context.Background()) {
		var msg Message
		if err := scheduledCursor.Decode(&msg); err != nil {
			log.Printf("メッセージデコードエラー: %v", err)
			continue
		}
		
		scheduledCount++
		fmt.Printf("メッセージ #%d:\n", scheduledCount)
		fmt.Printf("  ID: %s\n", msg.ID.Hex())
		fmt.Printf("  送信者ID: %s\n", msg.SenderID.Hex())
		fmt.Printf("  受信者ID: %s\n", msg.RecipientID.Hex())
		fmt.Printf("  ステータス: %s\n", msg.Status)
		
		if msg.ScheduledAt != nil {
			fmt.Printf("  配信予定時刻: %s (JST: %s)\n", 
				msg.ScheduledAt.Format("2006-01-02 15:04:05 UTC"), 
				msg.ScheduledAt.In(time.FixedZone("JST", 9*3600)).Format("2006-01-02 15:04:05"))
			
			// 現在時刻との比較
			if msg.ScheduledAt.Before(now) {
				timeDiff := now.Sub(*msg.ScheduledAt)
				fmt.Printf("  ⚠️  配信予定時刻が過去 (%v前)\n", timeDiff.Round(time.Second))
			} else {
				timeDiff := msg.ScheduledAt.Sub(now)
				fmt.Printf("  ⏰ 配信まで残り %v\n", timeDiff.Round(time.Second))
			}
		} else {
			fmt.Printf("  ⚠️  ScheduledAtがnull\n")
		}
		
		fmt.Printf("  作成日時: %s\n", msg.CreatedAt.Format("2006-01-02 15:04:05"))
		fmt.Printf("  更新日時: %s\n", msg.UpdatedAt.Format("2006-01-02 15:04:05"))
		fmt.Printf("  選択トーン: %s\n", msg.SelectedTone)
		
		// テキストの一部を表示（長い場合は切り詰める）
		originalText := msg.OriginalText
		if len(originalText) > 50 {
			originalText = originalText[:50] + "..."
		}
		fmt.Printf("  元テキスト: %s\n", originalText)
		
		finalText := msg.FinalText
		if len(finalText) > 50 {
			finalText = finalText[:50] + "..."
		}
		fmt.Printf("  最終テキスト: %s\n", finalText)
		
		fmt.Println()
	}

	if scheduledCount == 0 {
		fmt.Println("  ✅ scheduled状態のメッセージは見つかりませんでした\n")
	}

	// 4. 過去の配信予定時刻を持つメッセージをチェック
	fmt.Println("⏰ 過去の配信予定時刻を持つメッセージ:")
	fmt.Println(strings.Repeat("-", 80))
	
	pastScheduledFilter := bson.M{
		"scheduledAt": bson.M{"$lte": now},
		"status": bson.M{"$nin": []string{"sent", "delivered", "read"}},
	}
	
	pastCursor, err := collection.Find(context.Background(), pastScheduledFilter)
	if err != nil {
		log.Fatalf("過去配信予定メッセージ取得エラー: %v", err)
	}
	defer pastCursor.Close(context.Background())

	pastCount := 0
	for pastCursor.Next(context.Background()) {
		var msg Message
		if err := pastCursor.Decode(&msg); err != nil {
			log.Printf("メッセージデコードエラー: %v", err)
			continue
		}
		
		pastCount++
		fmt.Printf("過去配信予定メッセージ #%d:\n", pastCount)
		fmt.Printf("  ID: %s\n", msg.ID.Hex())
		fmt.Printf("  ステータス: %s\n", msg.Status)
		
		if msg.ScheduledAt != nil {
			timeDiff := now.Sub(*msg.ScheduledAt)
			fmt.Printf("  配信予定時刻: %s (%v前)\n", 
				msg.ScheduledAt.Format("2006-01-02 15:04:05"), timeDiff.Round(time.Second))
		}
		fmt.Println()
	}
	
	if pastCount == 0 {
		fmt.Println("  ✅ 過去の配信予定時刻を持つ未配信メッセージはありません\n")
	}

	// 5. DeliverScheduledMessages関数と同じクエリを実行
	fmt.Println("🔍 DeliverScheduledMessages関数の実行シミュレーション:")
	fmt.Println(strings.Repeat("-", 80))
	
	deliveryFilter := bson.M{
		"status":      "scheduled",
		"scheduledAt": bson.M{"$lte": now},
	}
	
	fmt.Printf("🔍 検索条件: status='scheduled', scheduledAt<='%s'\n", now.Format("2006-01-02 15:04:05"))
	
	deliveryCursor, err := collection.Find(context.Background(), deliveryFilter)
	if err != nil {
		log.Fatalf("配信対象メッセージ取得エラー: %v", err)
	}
	defer deliveryCursor.Close(context.Background())

	deliveryCount := 0
	for deliveryCursor.Next(context.Background()) {
		var msg Message
		if err := deliveryCursor.Decode(&msg); err != nil {
			log.Printf("メッセージデコードエラー: %v", err)
			continue
		}
		
		deliveryCount++
		fmt.Printf("配信対象メッセージ #%d:\n", deliveryCount)
		fmt.Printf("  ID: %s\n", msg.ID.Hex())
		fmt.Printf("  ステータス: %s\n", msg.Status)
		
		if msg.ScheduledAt != nil {
			fmt.Printf("  配信予定時刻: %s\n", msg.ScheduledAt.Format("2006-01-02 15:04:05"))
		}
		fmt.Println()
	}
	
	fmt.Printf("📋 DeliverScheduledMessages関数の結果: %d件のメッセージが配信対象\n\n", deliveryCount)

	// 6. 最近作成されたメッセージ上位5件
	fmt.Println("📅 最近作成されたメッセージ（上位5件）:")
	fmt.Println(strings.Repeat("-", 80))
	
	recentOptions := options.Find().SetSort(bson.D{{"createdAt", -1}}).SetLimit(5)
	recentCursor, err := collection.Find(context.Background(), bson.M{}, recentOptions)
	if err != nil {
		log.Fatalf("最近のメッセージ取得エラー: %v", err)
	}
	defer recentCursor.Close(context.Background())

	recentCount := 0
	for recentCursor.Next(context.Background()) {
		var msg Message
		if err := recentCursor.Decode(&msg); err != nil {
			log.Printf("メッセージデコードエラー: %v", err)
			continue
		}
		
		recentCount++
		fmt.Printf("メッセージ #%d:\n", recentCount)
		fmt.Printf("  ID: %s\n", msg.ID.Hex())
		fmt.Printf("  ステータス: %s\n", msg.Status)
		fmt.Printf("  作成日時: %s\n", msg.CreatedAt.Format("2006-01-02 15:04:05"))
		
		if msg.ScheduledAt != nil {
			fmt.Printf("  配信予定時刻: %s\n", msg.ScheduledAt.Format("2006-01-02 15:04:05"))
		}
		
		originalText := msg.OriginalText
		if len(originalText) > 30 {
			originalText = originalText[:30] + "..."
		}
		fmt.Printf("  テキスト: %s\n", originalText)
		fmt.Println()
	}

	fmt.Println("🔍 調査完了")
	fmt.Println(strings.Repeat("=", 60))
}