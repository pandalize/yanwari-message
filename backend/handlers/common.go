package handlers

import (
	"fmt"

	"github.com/gin-gonic/gin"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"yanwari-message-backend/middleware"
	"yanwari-message-backend/models"
)

// getUserByFirebaseUID Firebase UIDからMongoDBユーザーを取得するヘルパー関数
// UserServiceが必要なため、各ハンドラーで使用
func getUserByFirebaseUID(c *gin.Context, userService *models.UserService) (*models.User, error) {
	firebaseUID, exists := middleware.GetFirebaseUID(c)
	if !exists {
		return nil, fmt.Errorf("Firebase認証が必要です")
	}

	user, err := userService.GetUserByFirebaseUID(c.Request.Context(), firebaseUID)
	if err != nil {
		return nil, fmt.Errorf("Firebase UID %s に対応するユーザーが見つかりません: %v", firebaseUID, err)
	}

	return user, nil
}

// DEPRECATED: この関数は使用しないでください
func getUserID(c *gin.Context) (primitive.ObjectID, error) {
	return primitive.NilObjectID, fmt.Errorf("この関数は廃止されました。getUserByFirebaseUID() を使用してください")
}

// getFirebaseUID Firebase UIDを取得する共通ヘルパー関数
func getFirebaseUID(c *gin.Context) (string, error) {
	firebaseUID, exists := middleware.GetFirebaseUID(c)
	if !exists {
		return "", fmt.Errorf("Firebase認証が必要です")
	}
	return firebaseUID, nil
}