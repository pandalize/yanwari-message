package handlers

import (
	"log"
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
// @Summary 下書きメッセージを作成
// @Description ユーザーがメッセージの下書きを作成します。AIによるトーン変換も含まれます。
// @Tags messages
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param request body models.CreateMessageRequest true "メッセージ作成リクエスト"
// @Success 201 {object} models.MessageResponse "作成成功"
// @Failure 400 {object} map[string]string "リクエストエラー"
// @Failure 401 {object} map[string]string "認証エラー" 
// @Failure 500 {object} map[string]string "サーバーエラー"
// @Router /api/v1/messages/draft [post]
func (h *MessageHandler) CreateDraft(c *gin.Context) {
	sender, err := getUserByFirebaseUID(c, h.messageService.GetUserService())
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": err.Error()})
		return
	}
	senderID := sender.ID

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
		log.Printf("CreateDraft error: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "メッセージの作成に失敗しました", "details": err.Error()})
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
	sender, err := getUserByFirebaseUID(c, h.messageService.GetUserService())
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": err.Error()})
		return
	}
	senderID := sender.ID

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
	currentUser, err := getUserByFirebaseUID(c, h.messageService.GetUserService())
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": err.Error()})
		return
	}
	currentUserID := currentUser.ID

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
	currentUser, err := getUserByFirebaseUID(c, h.messageService.GetUserService())
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": err.Error()})
		return
	}
	currentUserID := currentUser.ID

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

	// ✅ 修正: DBレベルでページネーション実装
	messages, total, err := h.messageService.GetUserDrafts(c.Request.Context(), currentUserID, page, limit)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "下書きの取得に失敗しました"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"data": gin.H{
			"messages": messages,
			"pagination": gin.H{
				"page":  page,
				"limit": limit,
				"total": total, // ✅ DBから正確な総数を取得
			},
		},
	})
}

// DeleteMessage メッセージを削除
// DELETE /api/v1/messages/:id
func (h *MessageHandler) DeleteMessage(c *gin.Context) {
	sender, err := getUserByFirebaseUID(c, h.messageService.GetUserService())
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": err.Error()})
		return
	}
	senderID := sender.ID

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

// GetReceivedMessages 受信メッセージ一覧を取得
// GET /api/v1/messages/received
func (h *MessageHandler) GetReceivedMessages(c *gin.Context) {
	recipient, err := getUserByFirebaseUID(c, h.messageService.GetUserService())
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": err.Error()})
		return
	}
	recipientID := recipient.ID

	// ページネーション
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

	messages, total, err := h.messageService.GetReceivedMessagesWithSender(c.Request.Context(), recipientID, page, limit)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "受信メッセージの取得に失敗しました"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"data": gin.H{
			"messages": messages,
			"pagination": gin.H{
				"page":  page,
				"limit": limit,
				"total": total,
			},
		},
		"message": "受信メッセージを取得しました",
	})
}

// MarkMessageAsRead メッセージを既読にする
// POST /api/v1/messages/:id/read
func (h *MessageHandler) MarkMessageAsRead(c *gin.Context) {
	recipient, err := getUserByFirebaseUID(c, h.messageService.GetUserService())
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": err.Error()})
		return
	}
	recipientID := recipient.ID

	messageIDStr := c.Param("id")
	messageID, err := primitive.ObjectIDFromHex(messageIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "無効なメッセージIDです"})
		return
	}

	err = h.messageService.MarkMessageAsRead(c.Request.Context(), messageID, recipientID)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			c.JSON(http.StatusNotFound, gin.H{"error": "メッセージが見つかりません"})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"error": "既読更新に失敗しました"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "メッセージを既読にしました",
	})
}

// DeliverScheduledMessages スケジュール配信を実行（管理者API）
// POST /api/v1/messages/deliver-scheduled
func (h *MessageHandler) DeliverScheduledMessages(c *gin.Context) {
	messages, err := h.messageService.DeliverScheduledMessages(c.Request.Context())
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "スケジュール配信に失敗しました", "details": err.Error()})
		return
	}

	response := gin.H{
		"data": gin.H{
			"delivered_count": len(messages),
			"messages":        nil, // セキュリティ上、メッセージ詳細は返さない
		},
		"message": "スケジュール配信を実行しました",
	}

	// 詳細情報をリクエストされた場合のみ追加
	if c.Query("include_details") == "true" {
		response["data"].(gin.H)["messages"] = messages
	}

	c.JSON(http.StatusOK, response)
}

// GetSentMessages 送信済みメッセージ一覧を取得（送信者向け）
// @Summary 送信済みメッセージ一覧を取得
// @Description 認証されたユーザーが送信した送信済みメッセージの一覧を取得します。受信者の名前も含まれます。
// @Tags messages
// @Accept json
// @Produce json
// @Param page query int false "ページ番号" default(1) minimum(1)
// @Param limit query int false "1ページあたりの件数" default(20) minimum(1) maximum(100)
// @Success 200 {object} models.GetSentMessagesResponse "送信済みメッセージ一覧（recipientName、recipientEmailフィールド付き）"
// @Failure 401 {object} map[string]interface{} "認証エラー"
// @Failure 500 {object} map[string]interface{} "サーバーエラー"
// @Router /messages/sent [get]
// @Security BearerAuth
func (h *MessageHandler) GetSentMessages(c *gin.Context) {
	sender, err := getUserByFirebaseUID(c, h.messageService.GetUserService())
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": err.Error()})
		return
	}
	senderID := sender.ID

	// ページネーション
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))
	if page < 1 {
		page = 1
	}
	if limit < 1 || limit > 100 {
		limit = 20
	}

	// 送信済みメッセージを取得
	messages, total, err := h.messageService.GetSentMessages(c.Request.Context(), senderID, page, limit)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "送信済みメッセージの取得に失敗しました"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"data": gin.H{
			"messages": messages,
			"pagination": gin.H{
				"page":  page,
				"limit": limit,
				"total": total,
			},
		},
		"message": "送信済みメッセージ一覧を取得しました",
	})
}

// RegisterRoutes メッセージ関連のルートを登録
func (h *MessageHandler) RegisterRoutes(router *gin.RouterGroup, firebaseMiddleware gin.HandlerFunc) {
	messages := router.Group("/messages")
	messages.Use(firebaseMiddleware)
	{
		// 送信者向け
		messages.POST("/draft", h.CreateDraft)
		messages.GET("/drafts", h.GetDrafts)
		messages.GET("/sent", h.GetSentMessages)     // 特定パスを先に配置
		messages.PUT("/:id", h.UpdateMessage)
		messages.GET("/:id", h.GetMessage)
		messages.DELETE("/:id", h.DeleteMessage)
		
		// 受信者向け
		messages.GET("/received", h.GetReceivedMessages)
		messages.POST("/:id/read", h.MarkMessageAsRead)
		
		// システム内部用（配信エンジン）
		messages.POST("/deliver-scheduled", h.DeliverScheduledMessages)
	}
}