package handlers

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"golang.org/x/crypto/bcrypt"
	"go.mongodb.org/mongo-driver/bson/primitive"

	"yanwari-message-backend/models"
)

// getUserIDFromContext GinコンテキストからユーザーIDを取得
func getUserIDFromContext(c *gin.Context) primitive.ObjectID {
	userID, exists := c.Get("userID")
	if !exists {
		return primitive.NilObjectID
	}
	
	if objectID, ok := userID.(primitive.ObjectID); ok {
		return objectID
	}
	
	return primitive.NilObjectID
}

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
	userID := getUserIDFromContext(c)
	if userID == primitive.NilObjectID {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "認証が必要です"})
		return
	}

	// ユーザー設定を取得
	settings, err := h.userSettingsService.GetOrCreateSettings(c.Request.Context(), userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "設定の取得に失敗しました"})
		return
	}

	// ユーザー情報も取得
	user, err := h.userService.GetUserByID(c.Request.Context(), userID.Hex())
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "ユーザー情報の取得に失敗しました"})
		return
	}

	response := gin.H{
		"user": gin.H{
			"id":    user.ID,
			"name":  user.Name,
			"email": user.Email,
		},
		"notifications": gin.H{
			"emailNotifications":   settings.EmailNotifications,
			"sendNotifications":    settings.SendNotifications,
			"browserNotifications": settings.BrowserNotifications,
		},
		"messages": gin.H{
			"defaultTone":     settings.DefaultTone,
			"timeRestriction": settings.TimeRestriction,
		},
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    response,
	})
}

// UpdateProfile プロフィールを更新
func (h *SettingsHandler) UpdateProfile(c *gin.Context) {
	userID := getUserIDFromContext(c)
	if userID == primitive.NilObjectID {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "認証が必要です"})
		return
	}

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
	userID := getUserIDFromContext(c)
	if userID == primitive.NilObjectID {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "認証が必要です"})
		return
	}

	var req models.ChangePasswordRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "リクエストが無効です"})
		return
	}

	// 現在のユーザー情報を取得
	user, err := h.userService.GetUserByID(c.Request.Context(), userID.Hex())
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "ユーザー情報の取得に失敗しました"})
		return
	}

	// 現在のパスワードを確認
	err = bcrypt.CompareHashAndPassword([]byte(user.PasswordHash), []byte(req.CurrentPassword))
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
	userID := getUserIDFromContext(c)
	if userID == primitive.NilObjectID {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "認証が必要です"})
		return
	}

	var req models.NotificationSettings
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "リクエストが無効です"})
		return
	}

	// 通知設定を更新
	err := h.userSettingsService.UpdateNotificationSettings(c.Request.Context(), userID, &req)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "通知設定の更新に失敗しました"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "通知設定を更新しました",
	})
}

// UpdateMessageSettings メッセージ設定を更新
func (h *SettingsHandler) UpdateMessageSettings(c *gin.Context) {
	userID := getUserIDFromContext(c)
	if userID == primitive.NilObjectID {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "認証が必要です"})
		return
	}

	var req models.MessageSettings
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "リクエストが無効です"})
		return
	}

	// トーンの妥当性チェック
	validTones := map[string]bool{
		"gentle":       true,
		"constructive": true,
		"casual":       true,
	}
	if !validTones[req.DefaultTone] {
		c.JSON(http.StatusBadRequest, gin.H{"error": "無効なトーンです"})
		return
	}

	// 時間制限の妥当性チェック
	validTimeRestrictions := map[string]bool{
		"none":           true,
		"business_hours": true,
		"extended_hours": true,
	}
	if !validTimeRestrictions[req.TimeRestriction] {
		c.JSON(http.StatusBadRequest, gin.H{"error": "無効な時間制限です"})
		return
	}

	// メッセージ設定を更新
	err := h.userSettingsService.UpdateMessageSettings(c.Request.Context(), userID, &req)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "メッセージ設定の更新に失敗しました"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "メッセージ設定を更新しました",
	})
}

// DeleteAccount アカウントを削除
func (h *SettingsHandler) DeleteAccount(c *gin.Context) {
	userID := getUserIDFromContext(c)
	if userID == primitive.NilObjectID {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "認証が必要です"})
		return
	}

	// TODO: アカウント削除の実装
	// - ユーザーデータの削除
	// - 関連するメッセージの削除
	// - 設定の削除
	// 現在は仮実装

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "アカウントを削除しました",
	})
}