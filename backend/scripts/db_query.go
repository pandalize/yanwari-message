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

type User struct {
	ID       primitive.ObjectID `bson:"_id,omitempty"`
	Email    string            `bson:"email"`
	Name     string            `bson:"name,omitempty"`
	FirebaseUID string         `bson:"firebase_uid,omitempty"`
}

type Message struct {
	ID              primitive.ObjectID `bson:"_id,omitempty"`
	SenderID        primitive.ObjectID `bson:"sender_id,omitempty"`
	RecipientID     primitive.ObjectID `bson:"recipient_id,omitempty"`
	RecipientEmail  string            `bson:"recipient_email,omitempty"`
	OriginalText    string            `bson:"original_text"`
	FinalText       string            `bson:"final_text,omitempty"`
	Status          string            `bson:"status"`
	CreatedAt       time.Time         `bson:"created_at"`
}

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
	usersCollection := db.Collection("users")
	messagesCollection := db.Collection("messages")

	fmt.Println("=== bob/demoに関連するユーザー検索 ===")
	
	// ユーザー検索（emailまたはnameにbob/demoを含む）
	userFilter := bson.M{
		"$or": []bson.M{
			{"email": bson.M{"$regex": "bob", "$options": "i"}},
			{"email": bson.M{"$regex": "demo", "$options": "i"}},
			{"name": bson.M{"$regex": "bob", "$options": "i"}},
			{"name": bson.M{"$regex": "demo", "$options": "i"}},
		},
	}

	cursor, err := usersCollection.Find(context.TODO(), userFilter)
	if err != nil {
		log.Fatal("ユーザー検索エラー:", err)
	}
	defer cursor.Close(context.TODO())

	var users []User
	if err = cursor.All(context.TODO(), &users); err != nil {
		log.Fatal("ユーザーデータ取得エラー:", err)
	}

	fmt.Printf("見つかったユーザー数: %d\n", len(users))
	for _, user := range users {
		fmt.Printf("- ID: %s, Email: %s, Name: %s, FirebaseUID: %s\n", 
			user.ID.Hex(), user.Email, user.Name, user.FirebaseUID)
	}

	if len(users) == 0 {
		fmt.Println("bob/demoに関連するユーザーが見つかりませんでした")
		return
	}

	fmt.Println("\n=== 該当ユーザー宛てのメッセージ検索 ===")
	
	// ユーザーIDとemailを収集
	var userIDs []primitive.ObjectID
	var userEmails []string
	for _, user := range users {
		userIDs = append(userIDs, user.ID)
		userEmails = append(userEmails, user.Email)
	}

	// メッセージ検索（recipientIDまたはrecipientEmailが該当ユーザー）
	messageFilter := bson.M{
		"$or": []bson.M{
			{"recipient_id": bson.M{"$in": userIDs}},
			{"recipient_email": bson.M{"$in": userEmails}},
		},
	}

	messageCursor, err := messagesCollection.Find(context.TODO(), messageFilter)
	if err != nil {
		log.Fatal("メッセージ検索エラー:", err)
	}
	defer messageCursor.Close(context.TODO())

	var messages []Message
	if err = messageCursor.All(context.TODO(), &messages); err != nil {
		log.Fatal("メッセージデータ取得エラー:", err)
	}

	fmt.Printf("見つかったメッセージ数: %d\n", len(messages))
	for i, message := range messages {
		fmt.Printf("\n--- メッセージ %d ---\n", i+1)
		fmt.Printf("ID: %s\n", message.ID.Hex())
		fmt.Printf("送信者ID: %s\n", message.SenderID.Hex())
		fmt.Printf("受信者ID: %s\n", message.RecipientID.Hex())
		fmt.Printf("受信者Email: %s\n", message.RecipientEmail)
		fmt.Printf("原文: %s\n", message.OriginalText)
		fmt.Printf("最終テキスト: %s\n", message.FinalText)
		fmt.Printf("ステータス: %s\n", message.Status)
		fmt.Printf("作成日時: %s\n", message.CreatedAt.Format("2006-01-02 15:04:05"))
	}

	if len(messages) == 0 {
		fmt.Println("該当ユーザー宛てのメッセージが見つかりませんでした")
	}

	fmt.Println("\n=== 全ユーザー一覧（参考情報） ===")
	allUsersCursor, err := usersCollection.Find(context.TODO(), bson.M{})
	if err == nil {
		var allUsers []User
		if err = allUsersCursor.All(context.TODO(), &allUsers); err == nil {
			fmt.Printf("データベース内の全ユーザー数: %d\n", len(allUsers))
			for _, user := range allUsers {
				fmt.Printf("- %s (%s)\n", user.Email, user.Name)
			}
		}
		allUsersCursor.Close(context.TODO())
	}

	fmt.Println("\n=== 全メッセージ一覧（参考情報） ===")
	allMessagesCursor, err := messagesCollection.Find(context.TODO(), bson.M{})
	if err == nil {
		var allMessages []Message
		if err = allMessagesCursor.All(context.TODO(), &allMessages); err == nil {
			fmt.Printf("データベース内の全メッセージ数: %d\n", len(allMessages))
			for _, message := range allMessages {
				fmt.Printf("- %s → %s: %s\n", 
					message.SenderID.Hex()[:8], 
					message.RecipientEmail, 
					message.OriginalText[:min(50, len(message.OriginalText))])
			}
		}
		allMessagesCursor.Close(context.TODO())
	}
}

func min(a, b int) int {
	if a < b {
		return a
	}
	return b
}