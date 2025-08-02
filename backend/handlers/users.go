package handlers

import (
	"net/http"
	"strconv"

	"yanwari-message-backend/models"

	"github.com/gin-gonic/gin"
)

// UserHandler ユーザーハンドラー
type UserHandler struct {
	userService *models.UserService
}

// NewUserHandler ユーザーハンドラーを作成
func NewUserHandler(userService *models.UserService) *UserHandler {
	return &UserHandler{
		userService: userService,
	}
}

// SearchUsers ユーザーを検索
// GET /api/v1/users/search?q=query&limit=10
func (h *UserHandler) SearchUsers(c *gin.Context) {
	// 認証チェック
	_, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "認証が必要です"})
		return
	}

	// クエリパラメータを取得
	query := c.Query("q")
	if query == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "検索クエリが必要です"})
		return
	}

	// リミット設定（デフォルト10、最大50）
	limit := 10
	if limitStr := c.Query("limit"); limitStr != "" {
		if l, err := strconv.Atoi(limitStr); err == nil && l > 0 && l <= 50 {
			limit = l
		}
	}

	// ユーザー検索実行
	users, err := h.userService.SearchUsers(c.Request.Context(), query, limit)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "ユーザー検索に失敗しました"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"data": gin.H{
			"users": users,
			"pagination": gin.H{
				"page":  1,
				"limit": limit,
				"total": len(users),
			},
		},
	})
}

// GetUserByEmail メールアドレスでユーザーを取得
// GET /api/v1/users/by-email?email=example@example.com
func (h *UserHandler) GetUserByEmail(c *gin.Context) {
	// 認証チェック
	_, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "認証が必要です"})
		return
	}

	email := c.Query("email")
	if email == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "メールアドレスが必要です"})
		return
	}

	user, err := h.userService.GetUserByEmail(c.Request.Context(), email)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "ユーザーが見つかりません"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"data": user,
	})
}

// GetUserByID ユーザーIDでユーザー情報を取得
// GET /api/v1/users/:id
func (h *UserHandler) GetUserByID(c *gin.Context) {
	// 認証チェック
	_, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "認証が必要です"})
		return
	}

	userID := c.Param("id")
	if userID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ユーザーIDが必要です"})
		return
	}

	user, err := h.userService.GetUserByID(c.Request.Context(), userID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "ユーザーが見つかりません"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"data": user,
	})
}

// GetCurrentUser 現在のログインユーザー情報を取得
// GET /api/v1/users/me
func (h *UserHandler) GetCurrentUser(c *gin.Context) {
	currentUserID, err := getUserID(c)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": err.Error()})
		return
	}

	user, err := h.userService.GetUserByID(c.Request.Context(), currentUserID.Hex())
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "ユーザーが見つかりません"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"data": user,
	})
}

// RegisterRoutes ユーザー関連のルートを登録
func (h *UserHandler) RegisterRoutes(router *gin.RouterGroup, authMiddleware gin.HandlerFunc) {
	users := router.Group("/users")
	users.Use(authMiddleware)
	{
		users.GET("/search", h.SearchUsers)
		users.GET("/by-email", h.GetUserByEmail)
		// 注意: /me は /:id より先に登録する必要がある
		users.GET("/me", h.GetCurrentUser)
		users.GET("/:id", h.GetUserByID)
	}
}