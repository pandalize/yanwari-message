package handlers

import (
	"fmt"

	"github.com/gin-gonic/gin"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"yanwari-message-backend/models"
)

// getUserByJWT JWTトークンからMongoDBユーザーを取得するヘルパー関数
// UserServiceが必要なため、各ハンドラーで使用
func getUserByJWT(c *gin.Context, userService *models.UserService) (*models.User, error) {
	userID, exists := c.Get("userID")
	if !exists {
		return nil, fmt.Errorf("JWT認証が必要です")
	}

	user, err := userService.GetUserByID(c.Request.Context(), userID.(string))
	if err != nil {
		return nil, fmt.Errorf("ユーザーID %s に対応するユーザーが見つかりません: %v", userID, err)
	}

	return user, nil
}

// getUserID JWTトークンからユーザーIDを取得する関数
func getUserID(c *gin.Context) (primitive.ObjectID, error) {
	userID, exists := c.Get("userID")
	if !exists {
		return primitive.NilObjectID, fmt.Errorf("JWT認証が必要です")
	}

	objectID, err := primitive.ObjectIDFromHex(userID.(string))
	if err != nil {
		return primitive.NilObjectID, fmt.Errorf("無効なユーザーID: %v", err)
	}

	return objectID, nil
}

// getJWTUserID JWTトークンからユーザーID文字列を取得する共通ヘルパー関数
func getJWTUserID(c *gin.Context) (string, error) {
	userID, exists := c.Get("userID")
	if !exists {
		return "", fmt.Errorf("JWT認証が必要です")
	}
	return userID.(string), nil
}