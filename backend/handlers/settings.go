package handlers

import (
	"fmt"
	"net/http"

	"github.com/gin-gonic/gin"
	"golang.org/x/crypto/bcrypt"

	"yanwari-message-backend/models"
)


// SettingsHandler 設定関連のHTTPハンドラー
type SettingsHandler struct {
	userService         *models.UserService
	userSettingsService *models.UserSettingsService
}

// NewSettingsHandler 設定ハンドラーを作成
func NewSettingsHandler(userService *models.UserService, userSettingsService *models.UserSettingsService) *SettingsHandler {
	return &SettingsHandler{
		userService:         userService,
		userSettingsService: userSettingsService,
	}
}

// GetSettings ユーザー設定を取得
func (h *SettingsHandler) GetSettings(c *gin.Context) {
	fmt.Printf("🔧 [GetSettings] 開始\n")
	defer func() {
		if r := recover(); r != nil {
			fmt.Printf("🚨 [GetSettings] パニック発生: %v\n", r)
			c.JSON(http.StatusInternalServerError, gin.H{"error": "設定の取得に失敗しました（内部エラー）"})
		}
	}()
	
	user, err := getUserByJWT(c, h.userService)
	if err != nil {
		fmt.Printf("❌ [GetSettings] 認証エラー: %v\n", err)
		c.JSON(http.StatusUnauthorized, gin.H{"error": err.Error()})
		return
	}
	userID := user.ID
	fmt.Printf("✅ [GetSettings] 認証成功: UserID=%s\n", userID.Hex())

	// ユーザー設定を取得
	fmt.Printf("🔄 [GetSettings] ユーザー設定取得中...\n")
	settings, err := h.userSettingsService.GetOrCreateSettings(c.Request.Context(), userID)
	if err != nil {
		fmt.Printf("❌ [GetSettings] 設定取得エラー: %v\n", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "設定の取得に失敗しました"})
		return
	}
	fmt.Printf("✅ [GetSettings] 設定取得成功: ID=%s\n", settings.ID.Hex())

	// ユーザー情報も取得
	fmt.Printf("🔄 [GetSettings] ユーザー情報取得中...\n")
	userInfo, err := h.userService.GetUserByID(c.Request.Context(), userID.Hex())
	if err != nil {
		fmt.Printf("❌ [GetSettings] ユーザー情報取得エラー: %v\n", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "ユーザー情報の取得に失敗しました"})
		return
	}
	fmt.Printf("✅ [GetSettings] ユーザー情報取得成功: Name=%s\n", userInfo.Name)

	response := gin.H{
		"user": gin.H{
			"id":    userInfo.ID,
			"name":  userInfo.Name,
			"email": userInfo.Email,
		},
		"notifications": gin.H{
			"emailNotifications":   settings.EmailNotifications,
			"sendNotifications":    settings.SendNotifications,
			"browserNotifications": settings.BrowserNotifications,
		},
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    response,
	})
}

// UpdateProfile プロフィールを更新
func (h *SettingsHandler) UpdateProfile(c *gin.Context) {
	user, err := getUserByJWT(c, h.userService)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": err.Error()})
		return
	}
	userID := user.ID

	var req models.UpdateProfileRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "リクエストが無効です"})
		return
	}

	// 名前が提供されている場合は更新
	if req.Name != "" {
		err := h.userService.UpdateProfile(c.Request.Context(), userID, req.Name)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "名前の更新に失敗しました"})
			return
		}
	}

	// メールアドレスが提供されている場合は更新
	if req.Email != "" {
		err := h.userService.UpdateEmail(c.Request.Context(), userID, req.Email)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
			return
		}
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "プロフィールを更新しました",
	})
}

// ChangePassword パスワードを変更
func (h *SettingsHandler) ChangePassword(c *gin.Context) {
	user, err := getUserByJWT(c, h.userService)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": err.Error()})
		return
	}
	userID := user.ID

	var req models.ChangePasswordRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "リクエストが無効です"})
		return
	}

	// 現在のユーザー情報を取得
	currentUserInfo, err := h.userService.GetUserByID(c.Request.Context(), userID.Hex())
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "ユーザー情報の取得に失敗しました"})
		return
	}

	// 現在のパスワードを確認
	err = bcrypt.CompareHashAndPassword([]byte(currentUserInfo.PasswordHash), []byte(req.CurrentPassword))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "現在のパスワードが正しくありません"})
		return
	}

	// 新しいパスワードをハッシュ化
	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(req.NewPassword), bcrypt.DefaultCost)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "パスワードの暗号化に失敗しました"})
		return
	}

	// パスワードを更新
	err = h.userService.UpdatePassword(c.Request.Context(), userID, string(hashedPassword))
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "パスワードの更新に失敗しました"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "パスワードを変更しました",
	})
}

// UpdateNotificationSettings 通知設定を更新
func (h *SettingsHandler) UpdateNotificationSettings(c *gin.Context) {
	user, err := getUserByJWT(c, h.userService)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": err.Error()})
		return
	}
	userID := user.ID

	var req models.NotificationSettings
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "リクエストが無効です"})
		return
	}

	// 通知設定を更新
	err = h.userSettingsService.UpdateNotificationSettings(c.Request.Context(), userID, &req)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "通知設定の更新に失敗しました"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "通知設定を更新しました",
	})
}


// DeleteAccount アカウントを削除
func (h *SettingsHandler) DeleteAccount(c *gin.Context) {
	user, err := getUserByJWT(c, h.userService)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": err.Error()})
		return
	}
	userID := user.ID

	// TODO: アカウント削除の実装
	// - ユーザーデータの削除
	_ = userID // 一時的に使用済みとしてマーク
	// - 関連するメッセージの削除
	// - 設定の削除
	// 現在は仮実装

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "アカウントを削除しました",
	})
}

// RegisterRoutes 設定関連のルートを登録
func (h *SettingsHandler) RegisterRoutes(v1 *gin.RouterGroup, jwtMiddleware gin.HandlerFunc) {
	settings := v1.Group("/settings")
	settings.Use(jwtMiddleware)
	{
		settings.GET("", h.GetSettings)                           // 設定取得
		settings.PUT("/profile", h.UpdateProfile)                 // プロフィール更新
		settings.PUT("/password", h.ChangePassword)               // パスワード変更
		settings.PUT("/notifications", h.UpdateNotificationSettings) // 通知設定更新
		settings.DELETE("/account", h.DeleteAccount)             // アカウント削除
	}
}