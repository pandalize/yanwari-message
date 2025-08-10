package handlers

import (
	"log"
	"net/http"

	"yanwari-message-backend/models"

	"github.com/gin-gonic/gin"
)

// TestHandler 開発環境専用テストハンドラー
type TestHandler struct {
	userService    *models.UserService
	messageService *models.MessageService
}

// NewTestHandler テストハンドラーの初期化
func NewTestHandler(userService *models.UserService, messageService *models.MessageService) *TestHandler {
	return &TestHandler{
		userService:    userService,
		messageService: messageService,
	}
}

// CreateTestMessage 開発環境専用: テストメッセージ作成（Firebase認証なし）
func (h *TestHandler) CreateTestMessage(c *gin.Context) {
	log.Println("⚠️ 開発環境専用: テストメッセージ作成API")

	var req struct {
		SenderEmail    string `json:"senderEmail" binding:"required"`
		RecipientEmail string `json:"recipientEmail" binding:"required"`
		OriginalText   string `json:"originalText" binding:"required"`
		Reason         string `json:"reason"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "リクエストエラー",
			"message": err.Error(),
		})
		return
	}

	// 送信者を取得
	sender, err := h.userService.GetUserByEmail(c.Request.Context(), req.SenderEmail)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{
			"error":   "送信者が見つかりません",
			"message": req.SenderEmail,
		})
		return
	}

	// 受信者を取得（メッセージ作成には不要だが検証のため）
	_, err = h.userService.GetUserByEmail(c.Request.Context(), req.RecipientEmail)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{
			"error":   "受信者が見つかりません",
			"message": req.RecipientEmail,
		})
		return
	}

	// メッセージ作成リクエスト
	createReq := &models.CreateMessageRequest{
		RecipientEmail: req.RecipientEmail,
		OriginalText:   req.OriginalText,
		Reason:         req.Reason,
	}

	message, err := h.messageService.CreateDraft(c.Request.Context(), sender.ID, createReq)
	if err != nil {
		log.Printf("テストメッセージ作成エラー: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{
			"error":   "メッセージ作成失敗",
			"message": err.Error(),
		})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"status": "success",
		"data": gin.H{
			"id":             message.ID,
			"senderEmail":    req.SenderEmail,
			"recipientEmail": req.RecipientEmail,
			"originalText":   req.OriginalText,
			"reason":         req.Reason,
			"status":         message.Status,
		},
	})
}

// GetTestSentMessages 開発環境専用: 送信済みメッセージ取得（Firebase認証なし）
func (h *TestHandler) GetTestSentMessages(c *gin.Context) {
	log.Println("⚠️ 開発環境専用: 送信済みメッセージ取得API")

	senderEmail := c.Query("senderEmail")
	if senderEmail == "" {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "パラメータエラー",
			"message": "senderEmail パラメータが必要です",
		})
		return
	}

	// 送信者を取得
	sender, err := h.userService.GetUserByEmail(c.Request.Context(), senderEmail)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{
			"error":   "送信者が見つかりません",
			"message": senderEmail,
		})
		return
	}

	// 送信済みメッセージを取得（ページング: page=1, limit=100）
	messages, total, err := h.messageService.GetSentMessages(c.Request.Context(), sender.ID, 1, 100)
	if err != nil {
		log.Printf("送信済みメッセージ取得エラー: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{
			"error":   "メッセージ取得失敗",
			"message": err.Error(),
		})
		return
	}

	// 受信者情報を付与
	type MessageWithRecipient struct {
		*models.Message
		RecipientName  string `json:"recipientName"`
		RecipientEmail string `json:"recipientEmail"`
	}

	var messagesWithRecipient []MessageWithRecipient
	for _, msg := range messages {
		recipientName := "Unknown User"
		recipientEmail := ""

		if !msg.RecipientID.IsZero() {
			if recipient, err := h.userService.GetUserByID(c.Request.Context(), msg.RecipientID.Hex()); err == nil && recipient != nil {
				if recipient.Name != "" {
					recipientName = recipient.Name
				} else {
					recipientName = recipient.Email
				}
				recipientEmail = recipient.Email
			}
		}

		messagesWithRecipient = append(messagesWithRecipient, MessageWithRecipient{
			Message:        &msg,
			RecipientName:  recipientName,
			RecipientEmail: recipientEmail,
		})
	}

	c.JSON(http.StatusOK, gin.H{
		"status": "success",
		"data": gin.H{
			"messages":    messagesWithRecipient,
			"total":       total,
			"senderEmail": senderEmail,
		},
	})
}

// GetTestReceivedMessages 開発環境専用: 受信メッセージ取得（Firebase認証なし）
func (h *TestHandler) GetTestReceivedMessages(c *gin.Context) {
	log.Println("⚠️ 開発環境専用: 受信メッセージ取得API")

	recipientEmail := c.Query("recipientEmail")
	if recipientEmail == "" {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "パラメータエラー",
			"message": "recipientEmail パラメータが必要です",
		})
		return
	}

	// 受信者を取得
	recipient, err := h.userService.GetUserByEmail(c.Request.Context(), recipientEmail)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{
			"error":   "受信者が見つかりません",
			"message": recipientEmail,
		})
		return
	}

	// 受信メッセージを取得（ページング: page=1, limit=100）
	messages, total, err := h.messageService.GetReceivedMessages(c.Request.Context(), recipient.ID, 1, 100)
	if err != nil {
		log.Printf("受信メッセージ取得エラー: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{
			"error":   "メッセージ取得失敗",
			"message": err.Error(),
		})
		return
	}

	// 送信者情報を付与
	type MessageWithSender struct {
		*models.Message
		SenderName  string `json:"senderName"`
		SenderEmail string `json:"senderEmail"`
	}

	var messagesWithSender []MessageWithSender
	for _, msg := range messages {
		senderName := "Unknown User"
		senderEmail := ""

		if !msg.SenderID.IsZero() {
			if sender, err := h.userService.GetUserByID(c.Request.Context(), msg.SenderID.Hex()); err == nil && sender != nil {
				if sender.Name != "" {
					senderName = sender.Name
				} else {
					// メールアドレスのローカル部分を表示名として使用
					senderName = sender.Email
				}
				senderEmail = sender.Email
			}
		}

		messagesWithSender = append(messagesWithSender, MessageWithSender{
			Message:     &msg,
			SenderName:  senderName,
			SenderEmail: senderEmail,
		})
	}

	c.JSON(http.StatusOK, gin.H{
		"status": "success",
		"data": gin.H{
			"messages":       messagesWithSender,
			"total":          total,
			"recipientEmail": recipientEmail,
		},
	})
}

// RegisterTestRoutes 開発環境専用テストエンドポイントの登録
func (h *TestHandler) RegisterTestRoutes(router *gin.RouterGroup) {
	test := router.Group("/test")
	{
		test.POST("/message", h.CreateTestMessage)               // テストメッセージ作成
		test.GET("/sent", h.GetTestSentMessages)                // 送信済みメッセージ取得
		test.GET("/received", h.GetTestReceivedMessages)        // 受信メッセージ取得
	}
	
	log.Println("⚠️ 開発環境専用テストエンドポイントを登録しました:")
	log.Println("   POST /api/v1/test/message - テストメッセージ作成")
	log.Println("   GET /api/v1/test/sent?senderEmail=xxx - 送信済みメッセージ取得")
	log.Println("   GET /api/v1/test/received?recipientEmail=xxx - 受信メッセージ取得")
}