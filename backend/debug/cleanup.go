package main

import (
	"context"
	"fmt"
	"log"
	"os"
	
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

func main() {
	mongoURI := os.Getenv("MONGODB_URI")
	if mongoURI == "" {
		log.Fatal("MONGODB_URI環境変数が設定されていません")
	}

	client, err := mongo.Connect(context.Background(), options.Client().ApplyURI(mongoURI))
	if err != nil {
		log.Fatalf("MongoDB接続エラー: %v", err)
	}
	defer client.Disconnect(context.Background())

	db := client.Database("yanwari-message")
	collection := db.Collection("messages")

	// テストメッセージID
	testID, _ := primitive.ObjectIDFromHex("68959679c5b63ee726e0641e")
	
	result, err := collection.DeleteOne(context.Background(), bson.M{"_id": testID})
	if err != nil {
		log.Printf("削除エラー: %v", err)
	} else {
		fmt.Printf("削除されたメッセージ数: %d件\n", result.DeletedCount)
	}
}