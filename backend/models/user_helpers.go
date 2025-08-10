package models

import (
	"context"
	"fmt"
	"go.mongodb.org/mongo-driver/bson/primitive"
)

// UserInfo ユーザー情報構造体
type UserInfo struct {
	Name  string `json:"name"`
	Email string `json:"email"`
}

// GetUserInfoByService ユーザーサービスを使ってユーザー情報を取得するヘルパー関数
func GetUserInfoByService(ctx context.Context, userService *UserService, userID primitive.ObjectID) (*UserInfo, error) {
	user, err := userService.GetUserByID(ctx, userID.Hex())
	if err != nil {
		fmt.Printf("⚠️ [GetUserInfoByService] ユーザー取得エラー: UserID=%s, Error=%v\n", userID.Hex(), err)
		return &UserInfo{
			Name:  "Unknown User",
			Email: "unknown@example.com",
		}, nil
	}

	// 名前が空の場合はメールアドレスから表示名を生成
	displayName := user.Name
	if displayName == "" {
		// メールアドレスの@マークより前の部分を表示名として使用
		for i, char := range user.Email {
			if char == '@' {
				if i > 0 {
					displayName = user.Email[:i]
				} else {
					displayName = user.Email
				}
				break
			}
		}
		if displayName == "" {
			displayName = user.Email
		}
	}

	fmt.Printf("👤 [GetUserInfoByService] ユーザー情報取得成功: ID=%s, Email=%s, Name='%s', DisplayName='%s'\n", 
		user.ID.Hex(), user.Email, user.Name, displayName)

	return &UserInfo{
		Name:  displayName,
		Email: user.Email,
	}, nil
}

// GetUserInfo 従来の関数（後方互換性のため残す、新しい関数を使用することを推奨）
func GetUserInfo(ctx context.Context, userID primitive.ObjectID) (*UserInfo, error) {
	// 警告ログ出力
	fmt.Printf("⚠️ [GetUserInfo] 非推奨関数が呼ばれました。GetUserInfoByServiceを使用してください。UserID=%s\n", userID.Hex())
	return &UserInfo{
		Name:  "Unknown User",
		Email: "unknown@example.com",
	}, nil
}