package models

import (
	"context"
	"go.mongodb.org/mongo-driver/bson/primitive"
)

// UserInfo ユーザー情報構造体
type UserInfo struct {
	Name  string `json:"name"`
	Email string `json:"email"`
}

// GetUserInfo ユーザー情報を取得するヘルパー関数
func GetUserInfo(ctx context.Context, userID primitive.ObjectID) (*UserInfo, error) {
	// TODO: 実際のユーザーサービスと連携
	// 現在はダミーデータを返す
	return &UserInfo{
		Name:  "Unknown User",
		Email: "unknown@example.com",
	}, nil
}