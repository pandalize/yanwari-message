package middleware

import (
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
	"yanwari-message-backend/utils"
)

// JWT認証ミドルウェア
func JWTAuthMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		// Authorizationヘッダーからトークンを取得
		authHeader := c.GetHeader("Authorization")
		if authHeader == "" {
			c.JSON(http.StatusUnauthorized, gin.H{
				"error": "認証トークンが必要です",
			})
			c.Abort()
			return
		}

		// Bearer トークンの形式チェック
		parts := strings.Split(authHeader, " ")
		if len(parts) != 2 || parts[0] != "Bearer" {
			c.JSON(http.StatusUnauthorized, gin.H{
				"error": "無効な認証ヘッダー形式です",
			})
			c.Abort()
			return
		}

		tokenString := parts[1]

		// トークンの検証
		claims, err := utils.ValidateJWT(tokenString)
		if err != nil {
			c.JSON(http.StatusUnauthorized, gin.H{
				"error": "無効なトークンです: " + err.Error(),
			})
			c.Abort()
			return
		}

		// ユーザー情報をコンテキストに保存
		c.Set("userID", claims.UserID)
		c.Set("email", claims.Email)
		c.Set("name", claims.Name)
		c.Set("claims", claims)

		c.Next()
	}
}

// オプショナルJWT認証ミドルウェア（トークンがあれば検証、なくても続行）
func OptionalJWTAuthMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		authHeader := c.GetHeader("Authorization")
		if authHeader == "" {
			c.Next()
			return
		}

		parts := strings.Split(authHeader, " ")
		if len(parts) != 2 || parts[0] != "Bearer" {
			c.Next()
			return
		}

		tokenString := parts[1]
		claims, err := utils.ValidateJWT(tokenString)
		if err == nil {
			// 検証成功時のみユーザー情報を設定
			c.Set("userID", claims.UserID)
			c.Set("email", claims.Email)
			c.Set("name", claims.Name)
			c.Set("claims", claims)
		}

		c.Next()
	}
}