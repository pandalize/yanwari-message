package handlers

import (
	"net/http"

	"github.com/gin-gonic/gin"
)

// AuthHandler 認証関連のハンドラー
type AuthHandler struct {
	// TODO: 依存関係を追加 (UserService, JWTService など)
}

// NewAuthHandler 認証ハンドラーのコンストラクタ
func NewAuthHandler() *AuthHandler {
	return &AuthHandler{}
}

// Register ユーザー登録
// POST /api/v1/auth/register
func (h *AuthHandler) Register(c *gin.Context) {
	// TODO: F-01 認証システム実装
	// - メール・パスワードバリデーション
	// - Argon2パスワードハッシュ化
	// - ユーザー作成
	c.JSON(http.StatusNotImplemented, gin.H{
		"message": "F-01: ユーザー登録機能 - 実装予定",
		"feature": "auth-system",
	})
}

// Login ユーザーログイン
// POST /api/v1/auth/login
func (h *AuthHandler) Login(c *gin.Context) {
	// TODO: F-01 認証システム実装
	// - メール・パスワード認証
	// - JWT発行 (access 15min / refresh 14d)
	// - レスポンス返却
	c.JSON(http.StatusNotImplemented, gin.H{
		"message": "F-01: ユーザーログイン機能 - 実装予定",
		"feature": "auth-system",
	})
}

// RefreshToken リフレッシュトークン
// POST /api/v1/auth/refresh
func (h *AuthHandler) RefreshToken(c *gin.Context) {
	// TODO: F-01 認証システム実装
	// - リフレッシュトークン検証
	// - 新しいアクセストークン発行
	c.JSON(http.StatusNotImplemented, gin.H{
		"message": "F-01: トークンリフレッシュ機能 - 実装予定",
		"feature": "auth-system",
	})
}

// Logout ユーザーログアウト
// POST /api/v1/auth/logout
func (h *AuthHandler) Logout(c *gin.Context) {
	// TODO: F-01 認証システム実装
	// - JWT失効処理
	// - セッション削除
	c.JSON(http.StatusNotImplemented, gin.H{
		"message": "F-01: ユーザーログアウト機能 - 実装予定",
		"feature": "auth-system",
	})
}