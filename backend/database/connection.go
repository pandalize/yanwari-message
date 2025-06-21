package database

import (
	"context"
	"fmt"
	"log"
	"os"
	"time"

	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

// DB データベース接続を管理する構造体
type DB struct {
	Client   *mongo.Client
	Database *mongo.Database
}

// Connect MongoDB Atlas に接続してDBインスタンスを返す
func Connect() (*DB, error) {
	// 環境変数からMongoDB URIを取得
	mongoURI := os.Getenv("MONGODB_URI")
	if mongoURI == "" {
		return nil, fmt.Errorf("MONGODB_URI 環境変数が設定されていません")
	}

	// データベース名を環境変数から取得（デフォルト値設定）
	dbName := os.Getenv("MONGODB_DATABASE")
	if dbName == "" {
		dbName = "yanwari-message" // デフォルトのデータベース名
	}

	// MongoDB接続設定
	clientOptions := options.Client().
		ApplyURI(mongoURI).
		SetMaxPoolSize(20).                     // 最大接続プール数
		SetMinPoolSize(5).                      // 最小接続プール数
		SetMaxConnIdleTime(30 * time.Second).   // アイドル接続の最大時間
		SetServerSelectionTimeout(10 * time.Second) // サーバー選択タイムアウト

	// 接続コンテキスト（タイムアウト設定）
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	// MongoDBクライアント作成
	client, err := mongo.Connect(ctx, clientOptions)
	if err != nil {
		return nil, fmt.Errorf("MongoDB接続エラー: %w", err)
	}

	// 接続テスト（Ping）
	if err := client.Ping(ctx, nil); err != nil {
		return nil, fmt.Errorf("MongoDB Pingエラー: %w", err)
	}

	log.Printf("MongoDB Atlas への接続が成功しました。データベース: %s", dbName)

	return &DB{
		Client:   client,
		Database: client.Database(dbName),
	}, nil
}

// Close データベース接続を閉じる
func (db *DB) Close() error {
	if db.Client == nil {
		return nil
	}

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	if err := db.Client.Disconnect(ctx); err != nil {
		return fmt.Errorf("MongoDB切断エラー: %w", err)
	}

	log.Println("MongoDB Atlas への接続を閉じました")
	return nil
}

// HealthCheck データベース接続の健全性チェック
func (db *DB) HealthCheck() error {
	if db.Client == nil {
		return fmt.Errorf("データベースクライアントが初期化されていません")
	}

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	if err := db.Client.Ping(ctx, nil); err != nil {
		return fmt.Errorf("データベースヘルスチェック失敗: %w", err)
	}

	return nil
}

// GetCollection 指定されたコレクションを取得
func (db *DB) GetCollection(name string) *mongo.Collection {
	return db.Database.Collection(name)
}