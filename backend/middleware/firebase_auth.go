package middleware

import (
	"log"
	"strings"

	"github.com/gin-gonic/gin"
	"yanwari-message-backend/services"
)

// FirebaseAuthMiddleware Firebase ID Tokenを検証するミドルウェア
func FirebaseAuthMiddleware(firebaseService *services.FirebaseService) gin.HandlerFunc {
	return func(c *gin.Context) {
		// Authorizationヘッダーを取得
		authHeader := c.GetHeader("Authorization")
		if authHeader == "" {
			log.Printf("Firebase認証ミドルウェア: Authorizationヘッダーがありません")
			c.JSON(401, gin.H{
				"error":   "認証が必要です",
				"message": "Authorizationヘッダーが見つかりません",
			})
			c.Abort()
			return
		}

		// Bearer トークンの形式をチェック
		if !strings.HasPrefix(authHeader, "Bearer ") {
			log.Printf("Firebase認証ミドルウェア: 無効なAuthorizationヘッダー形式: %s", authHeader[:min(len(authHeader), 20)])
			c.JSON(401, gin.H{
				"error":   "認証が必要です",
				"message": "無効なAuthorizationヘッダー形式です",
			})
			c.Abort()
			return
		}

		// トークンを抽出
		idToken := strings.TrimPrefix(authHeader, "Bearer ")
		if idToken == "" {
			log.Printf("Firebase認証ミドルウェア: 空のIDトークン")
			c.JSON(401, gin.H{
				"error":   "認証が必要です",
				"message": "IDトークンが空です",
			})
			c.Abort()
			return
		}

		// Firebase ID Tokenを検証
		token, err := firebaseService.VerifyIDToken(idToken)
		if err != nil {
			log.Printf("Firebase認証ミドルウェア: IDトークン検証エラー: %v", err)
			c.JSON(401, gin.H{
				"error":   "認証に失敗しました",
				"message": "無効なIDトークンです",
			})
			c.Abort()
			return
		}

		// トークンからユーザー情報を抽出
		firebaseUID := token.UID
		userEmail := ""
		
		// emailクレームを安全に取得
		if email, ok := token.Claims["email"].(string); ok {
			userEmail = email
		}

		// ユーザー情報が不足している場合はFirebaseから追加取得
		if userEmail == "" {
			firebaseUser, err := firebaseService.GetUserByUID(firebaseUID)
			if err != nil {
				log.Printf("Firebase認証ミドルウェア: ユーザー情報取得エラー: %v", err)
				c.JSON(401, gin.H{
					"error":   "認証に失敗しました",
					"message": "ユーザー情報の取得に失敗しました",
				})
				c.Abort()
				return
			}
			userEmail = firebaseUser.Email
		}

		// 必須情報の検証
		if firebaseUID == "" {
			log.Printf("Firebase認証ミドルウェア: Firebase UIDが空です")
			c.JSON(401, gin.H{
				"error":   "認証に失敗しました",
				"message": "ユーザーIDが取得できませんでした",
			})
			c.Abort()
			return
		}

		// デバッグログ（本番環境では削除推奨）
		log.Printf("Firebase認証成功: UID=%s, Email=%s", firebaseUID, userEmail)

		// 認証情報をコンテキストに設定
		c.Set("firebase_uid", firebaseUID)
		c.Set("user_email", userEmail)
		
		// Firebase関連の追加情報もコンテキストに設定
		c.Set("firebase_token", token)
		if emailVerified, ok := token.Claims["email_verified"].(bool); ok {
			c.Set("email_verified", emailVerified)
		}
		
		// カスタムクレームがあれば設定
		if customClaims := token.Claims; len(customClaims) > 0 {
			c.Set("custom_claims", customClaims)
		}

		// 次のハンドラーに処理を渡す
		c.Next()
	}
}

// GetFirebaseUID コンテキストからFirebase UIDを取得するヘルパー関数
func GetFirebaseUID(c *gin.Context) (string, bool) {
	if uid, exists := c.Get("firebase_uid"); exists {
		if uidStr, ok := uid.(string); ok {
			return uidStr, true
		}
	}
	return "", false
}

// GetUserEmail コンテキストからユーザーメールアドレスを取得するヘルパー関数
func GetUserEmail(c *gin.Context) (string, bool) {
	if email, exists := c.Get("user_email"); exists {
		if emailStr, ok := email.(string); ok {
			return emailStr, true
		}
	}
	return "", false
}

// IsEmailVerified コンテキストからメール確認状態を取得するヘルパー関数
func IsEmailVerified(c *gin.Context) bool {
	if verified, exists := c.Get("email_verified"); exists {
		if verifiedBool, ok := verified.(bool); ok {
			return verifiedBool
		}
	}
	return false
}

// GetCustomClaims コンテキストからカスタムクレームを取得するヘルパー関数
func GetCustomClaims(c *gin.Context) (map[string]interface{}, bool) {
	if claims, exists := c.Get("custom_claims"); exists {
		if claimsMap, ok := claims.(map[string]interface{}); ok {
			return claimsMap, true
		}
	}
	return nil, false
}

// min ヘルパー関数（Go 1.21未満用）
func min(a, b int) int {
	if a < b {
		return a
	}
	return b
}