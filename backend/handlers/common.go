package handlers

import (
	"fmt"

	"github.com/gin-gonic/gin"
	"go.mongodb.org/mongo-driver/bson/primitive"
)

// getUserID JWTトークンからユーザーIDを取得する共通ヘルパー関数
// JWTミドルウェアで設定されたuserID（string）をprimitive.ObjectIDに変換
func getUserID(c *gin.Context) (primitive.ObjectID, error) {
	userID, exists := c.Get("userID")
	if !exists {
		return primitive.NilObjectID, fmt.Errorf("認証が必要です")
	}

	userIDStr, ok := userID.(string)
	if !ok {
		return primitive.NilObjectID, fmt.Errorf("ユーザーIDの取得に失敗しました")
	}

	objID, err := primitive.ObjectIDFromHex(userIDStr)
	if err != nil {
		return primitive.NilObjectID, fmt.Errorf("ユーザーIDの変換に失敗しました")
	}

	return objID, nil
}