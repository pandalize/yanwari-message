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

// Schedule structure
type Schedule struct {
	ID        primitive.ObjectID `bson:"_id,omitempty" json:"id"`
	UserID    primitive.ObjectID `bson:"userId" json:"userId"`
	MessageID primitive.ObjectID `bson:"messageId" json:"messageId"`
	Status    string             `bson:"status" json:"status"`
	CreatedAt time.Time          `bson:"createdAt" json:"createdAt"`
	UpdatedAt time.Time          `bson:"updatedAt" json:"updatedAt"`
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
	messagesCollection := db.Collection("messages")
	schedulesCollection := db.Collection("schedules")

	fmt.Println("🔍 スケジュール機能フロー調査開始")
	fmt.Println(strings.Repeat("=", 60))

	// 1. scheduledAt フィールドを持つメッセージを検索
	fmt.Println("📅 scheduledAt フィールドを持つメッセージ:")
	fmt.Println(strings.Repeat("-", 50))
	
	scheduledAtFilter := bson.M{"scheduledAt": bson.M{"$exists": true, "$ne": nil}}
	scheduledAtCursor, err := messagesCollection.Find(context.Background(), scheduledAtFilter, 
		options.Find().SetSort(bson.D{{"createdAt", -1}}).SetLimit(10))
	if err != nil {
		log.Fatalf("scheduledAtメッセージ取得エラー: %v", err)
	}
	defer scheduledAtCursor.Close(context.Background())

	scheduledAtCount := 0
	now := time.Now()
	
	for scheduledAtCursor.Next(context.Background()) {
		var msg Message
		if err := scheduledAtCursor.Decode(&msg); err != nil {
			log.Printf("メッセージデコードエラー: %v", err)
			continue
		}
		
		scheduledAtCount++
		fmt.Printf("メッセージ #%d:\n", scheduledAtCount)
		fmt.Printf("  ID: %s\n", msg.ID.Hex())
		fmt.Printf("  ステータス: %s\n", msg.Status)
		fmt.Printf("  作成日時: %s\n", msg.CreatedAt.Format("2006-01-02 15:04:05"))
		fmt.Printf("  更新日時: %s\n", msg.UpdatedAt.Format("2006-01-02 15:04:05"))
		
		if msg.ScheduledAt != nil {
			fmt.Printf("  配信予定時刻: %s\n", msg.ScheduledAt.Format("2006-01-02 15:04:05"))
			if msg.ScheduledAt.Before(now) {
				timeDiff := now.Sub(*msg.ScheduledAt)
				fmt.Printf("    ⚠️  配信予定時刻が過去 (%v前)\n", timeDiff.Round(time.Minute))
			}
		}
		
		if msg.SentAt != nil {
			fmt.Printf("  送信日時: %s\n", msg.SentAt.Format("2006-01-02 15:04:05"))
		}
		
		fmt.Printf("  選択トーン: %s\n", msg.SelectedTone)
		fmt.Println()
	}

	if scheduledAtCount == 0 {
		fmt.Println("  ✅ scheduledAtフィールドを持つメッセージは見つかりませんでした")
	}

	// 2. Schedules コレクションの調査
	fmt.Println("📋 Schedules コレクションの調査:")
	fmt.Println(strings.Repeat("-", 50))
	
	scheduleCount, err := schedulesCollection.CountDocuments(context.Background(), bson.M{})
	if err != nil {
		log.Printf("スケジュール数取得エラー: %v", err)
	} else {
		fmt.Printf("総スケジュール数: %d件\n", scheduleCount)
	}

	// スケジュールのステータス別件数
	statusPipeline := []bson.M{
		{"$group": bson.M{"_id": "$status", "count": bson.M{"$sum": 1}}},
		{"$sort": bson.M{"_id": 1}},
	}
	
	statusCursor, err := schedulesCollection.Aggregate(context.Background(), statusPipeline)
	if err != nil {
		log.Printf("スケジュールステータス集計エラー: %v", err)
	} else {
		defer statusCursor.Close(context.Background())
		fmt.Println("ステータス別スケジュール数:")
		for statusCursor.Next(context.Background()) {
			var result struct {
				ID    string `bson:"_id"`
				Count int    `bson:"count"`
			}
			if err := statusCursor.Decode(&result); err != nil {
				log.Printf("ステータス集計デコードエラー: %v", err)
				continue
			}
			fmt.Printf("  %s: %d件\n", result.ID, result.Count)
		}
	}

	// 最近のスケジュール5件を表示
	fmt.Println("\n最近のスケジュール5件:")
	recentSchedulesCursor, err := schedulesCollection.Find(context.Background(), bson.M{}, 
		options.Find().SetSort(bson.D{{"createdAt", -1}}).SetLimit(5))
	if err != nil {
		log.Printf("最近のスケジュール取得エラー: %v", err)
	} else {
		defer recentSchedulesCursor.Close(context.Background())
		recentScheduleCount := 0
		for recentSchedulesCursor.Next(context.Background()) {
			var schedule Schedule
			if err := recentSchedulesCursor.Decode(&schedule); err != nil {
				log.Printf("スケジュールデコードエラー: %v", err)
				continue
			}
			recentScheduleCount++
			fmt.Printf("スケジュール #%d:\n", recentScheduleCount)
			fmt.Printf("  ID: %s\n", schedule.ID.Hex())
			fmt.Printf("  ユーザーID: %s\n", schedule.UserID.Hex())
			fmt.Printf("  メッセージID: %s\n", schedule.MessageID.Hex())
			fmt.Printf("  ステータス: %s\n", schedule.Status)
			fmt.Printf("  作成日時: %s\n", schedule.CreatedAt.Format("2006-01-02 15:04:05"))
			fmt.Println()
		}
		if recentScheduleCount == 0 {
			fmt.Println("  ✅ スケジュールが見つかりませんでした")
		}
	}

	// 3. ステータス変更履歴の分析
	fmt.Println("📊 メッセージステータス変更パターンの分析:")
	fmt.Println(strings.Repeat("-", 50))
	
	// 配信済みメッセージで、scheduledAtが設定されているものを調査
	deliveredWithScheduledFilter := bson.M{
		"status": bson.M{"$in": []string{"sent", "delivered", "read"}},
		"scheduledAt": bson.M{"$exists": true, "$ne": nil},
	}
	
	deliveredCursor, err := messagesCollection.Find(context.Background(), deliveredWithScheduledFilter, 
		options.Find().SetSort(bson.D{{"createdAt", -1}}).SetLimit(5))
	if err != nil {
		log.Printf("配信済みメッセージ取得エラー: %v", err)
	} else {
		defer deliveredCursor.Close(context.Background())
		deliveredCount := 0
		fmt.Println("配信済み（scheduledAt設定済み）メッセージ:")
		for deliveredCursor.Next(context.Background()) {
			var msg Message
			if err := deliveredCursor.Decode(&msg); err != nil {
				log.Printf("メッセージデコードエラー: %v", err)
				continue
			}
			deliveredCount++
			fmt.Printf("  メッセージ #%d: ID=%s, status=%s\n", deliveredCount, msg.ID.Hex(), msg.Status)
			fmt.Printf("    作成: %s\n", msg.CreatedAt.Format("2006-01-02 15:04:05"))
			fmt.Printf("    更新: %s\n", msg.UpdatedAt.Format("2006-01-02 15:04:05"))
			if msg.ScheduledAt != nil {
				fmt.Printf("    予定: %s\n", msg.ScheduledAt.Format("2006-01-02 15:04:05"))
			}
			if msg.SentAt != nil {
				fmt.Printf("    送信: %s\n", msg.SentAt.Format("2006-01-02 15:04:05"))
			}
			
			// 作成から配信までの時間を計算
			if msg.SentAt != nil && msg.ScheduledAt != nil {
				scheduledDelay := msg.ScheduledAt.Sub(msg.CreatedAt)
				actualDelay := msg.SentAt.Sub(msg.CreatedAt)
				fmt.Printf("    遅延: 予定=%v, 実際=%v\n", scheduledDelay.Round(time.Second), actualDelay.Round(time.Second))
			}
			fmt.Println()
		}
		if deliveredCount == 0 {
			fmt.Println("  ✅ 配信済みでscheduledAtが設定されたメッセージはありません")
		}
	}

	fmt.Println("🔍 調査完了")
	fmt.Println(strings.Repeat("=", 60))
	
	// まとめ
	fmt.Println("\n📝 調査結果まとめ:")
	fmt.Printf("- scheduledAtを持つメッセージ: %d件\n", scheduledAtCount)
	fmt.Printf("- 総スケジュール数: %d件\n", scheduleCount)
	fmt.Println("- 現在scheduled状態のメッセージ: 0件（前回調査結果）")
	
	if scheduledAtCount > 0 {
		fmt.Println("\n🔍 推論:")
		fmt.Println("- メッセージはスケジュール機能を使用して作成されている")
		fmt.Println("- しかし現在scheduled状態のメッセージが0件")
		fmt.Println("- 配信サービスが正常動作し、scheduled→sent/delivered に変更済みの可能性")
		fmt.Println("- または、メッセージ作成時にscheduled状態を経由せず直接sent状態になっている可能性")
	} else {
		fmt.Println("\n🔍 推論:")
		fmt.Println("- スケジュール機能が使用されていない")
		fmt.Println("- または、scheduledAtフィールドが正常に保存されていない")
	}
}