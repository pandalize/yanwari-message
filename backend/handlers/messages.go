package handlers

import (
	"net/http"
	"strconv"

	"yanwari-message-backend/models"

	"github.com/gin-gonic/gin"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
)

// MessageHandler メッセージハンドラー
type MessageHandler struct {
	messageService *models.MessageService
}

// NewMessageHandler メッセージハンドラーを作成
func NewMessageHandler(messageService *models.MessageService) *MessageHandler {
	return &MessageHandler{
		messageService: messageService,
	}
}

// CreateDraft 下書きメッセージを作成
// POST /api/v1/messages/draft
func (h *MessageHandler) CreateDraft(c *gin.Context) {
	userID, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "認証が必要です"})
		return
	}

	senderID, ok := userID.(primitive.ObjectID)
	if !ok {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "ユーザーIDの取得に失敗しました"})
		return
	}

	var req models.CreateMessageRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "リクエストが無効です", "details": err.Error()})
		return
	}

	message, err := h.messageService.CreateDraft(c.Request.Context(), senderID, &req)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			c.JSON(http.StatusBadRequest, gin.H{"error": "指定された受信者が見つかりません"})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"error": "メッセージの作成に失敗しました"})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"data":    message,
		"message": "下書きを作成しました",
	})
}

// UpdateMessage メッセージを更新
// PUT /api/v1/messages/:id
func (h *MessageHandler) UpdateMessage(c *gin.Context) {
	userID, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "認証が必要です"})
		return
	}

	senderID, ok := userID.(primitive.ObjectID)
	if !ok {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "ユーザーIDの取得に失敗しました"})
		return
	}

	messageIDStr := c.Param("id")
	messageID, err := primitive.ObjectIDFromHex(messageIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "無効なメッセージIDです"})
		return
	}

	var req models.UpdateMessageRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "リクエストが無効です", "details": err.Error()})
		return
	}

	message, err := h.messageService.UpdateMessage(c.Request.Context(), messageID, senderID, &req)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			c.JSON(http.StatusNotFound, gin.H{"error": "メッセージが見つかりません"})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"error": "メッセージの更新に失敗しました"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"data":    message,
		"message": "メッセージを更新しました",
	})
}

// GetMessage メッセージを取得
// GET /api/v1/messages/:id
func (h *MessageHandler) GetMessage(c *gin.Context) {
	userID, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "認証が必要です"})
		return
	}

	currentUserID, ok := userID.(primitive.ObjectID)
	if !ok {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "ユーザーIDの取得に失敗しました"})
		return
	}

	messageIDStr := c.Param("id")
	messageID, err := primitive.ObjectIDFromHex(messageIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "無効なメッセージIDです"})
		return
	}

	message, err := h.messageService.GetMessage(c.Request.Context(), messageID, currentUserID)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			c.JSON(http.StatusNotFound, gin.H{"error": "メッセージが見つかりません"})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"error": "メッセージの取得に失敗しました"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"data": message,
	})
}

// GetDrafts 下書き一覧を取得
// GET /api/v1/messages/drafts
func (h *MessageHandler) GetDrafts(c *gin.Context) {
	userID, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "認証が必要です"})
		return
	}

	currentUserID, ok := userID.(primitive.ObjectID)
	if !ok {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "ユーザーIDの取得に失敗しました"})
		return
	}

	// ページネーション対応
	page := 1
	if pageStr := c.Query("page"); pageStr != "" {
		if p, err := strconv.Atoi(pageStr); err == nil && p > 0 {
			page = p
		}
	}

	limit := 20
	if limitStr := c.Query("limit"); limitStr != "" {
		if l, err := strconv.Atoi(limitStr); err == nil && l > 0 && l <= 100 {
			limit = l
		}
	}

	messages, err := h.messageService.GetUserDrafts(c.Request.Context(), currentUserID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "下書きの取得に失敗しました"})
		return
	}

	// 簡易ページネーション（将来的にはDBレベルで実装）
	start := (page - 1) * limit
	end := start + limit
	if start >= len(messages) {
		messages = []models.Message{}
	} else {
		if end > len(messages) {
			end = len(messages)
		}
		messages = messages[start:end]
	}

	c.JSON(http.StatusOK, gin.H{
		"data": gin.H{
			"messages": messages,
			"pagination": gin.H{
				"page":  page,
				"limit": limit,
				"total": len(messages),
			},
		},
	})
}

// DeleteMessage メッセージを削除
// DELETE /api/v1/messages/:id
func (h *MessageHandler) DeleteMessage(c *gin.Context) {
	userID, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "認証が必要です"})
		return
	}

	senderID, ok := userID.(primitive.ObjectID)
	if !ok {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "ユーザーIDの取得に失敗しました"})
		return
	}

	messageIDStr := c.Param("id")
	messageID, err := primitive.ObjectIDFromHex(messageIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "無効なメッセージIDです"})
		return
	}

	err = h.messageService.DeleteMessage(c.Request.Context(), messageID, senderID)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			c.JSON(http.StatusNotFound, gin.H{"error": "削除可能なメッセージが見つかりません"})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"error": "メッセージの削除に失敗しました"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "メッセージを削除しました",
	})
}

// RegisterRoutes メッセージ関連のルートを登録
func (h *MessageHandler) RegisterRoutes(router *gin.RouterGroup, authMiddleware gin.HandlerFunc) {
	messages := router.Group("/messages")
	messages.Use(authMiddleware)
	{
		messages.POST("/draft", h.CreateDraft)
		messages.PUT("/:id", h.UpdateMessage)
		messages.GET("/drafts", h.GetDrafts)
		messages.GET("/:id", h.GetMessage)
		messages.DELETE("/:id", h.DeleteMessage)
	}
}