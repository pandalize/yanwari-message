package handlers

import (
	"net/http"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"

	"yanwari-message-backend/models"
)

// MessageRatingHandler メッセージ評価関連のハンドラー
type MessageRatingHandler struct {
	ratingService  *models.MessageRatingService
	messageService *models.MessageService
}

// NewMessageRatingHandler 新しいMessageRatingHandlerを作成
func NewMessageRatingHandler(ratingService *models.MessageRatingService, messageService *models.MessageService) *MessageRatingHandler {
	return &MessageRatingHandler{
		ratingService:  ratingService,
		messageService: messageService,
	}
}

// RateMessageRequest メッセージ評価リクエスト
type RateMessageRequest struct {
	Rating int `json:"rating" binding:"required,min=1,max=5"`
}

// RateMessage メッセージを評価
// POST /api/v1/messages/:id/rate
func (mrh *MessageRatingHandler) RateMessage(c *gin.Context) {
	// 認証チェック
	userID, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "認証が必要です"})
		return
	}
	recipientID, ok := userID.(primitive.ObjectID)
	if !ok {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "ユーザーIDの取得に失敗しました"})
		return
	}

	// メッセージIDの取得・バリデーション
	messageIDStr := c.Param("id")
	messageID, err := primitive.ObjectIDFromHex(messageIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "無効なメッセージIDです"})
		return
	}

	// リクエストボディの解析
	var req RateMessageRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "リクエストが無効です", "details": err.Error()})
		return
	}

	// メッセージの存在確認と受信者権限チェック
	message, err := mrh.messageService.GetMessageByID(c.Request.Context(), messageID)
	if err == mongo.ErrNoDocuments {
		c.JSON(http.StatusNotFound, gin.H{"error": "メッセージが見つかりません"})
		return
	}
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "メッセージの取得に失敗しました"})
		return
	}

	// 受信者のみが評価可能
	if message.RecipientID != recipientID {
		c.JSON(http.StatusForbidden, gin.H{"error": "このメッセージを評価する権限がありません"})
		return
	}

	// 配信済みメッセージのみ評価可能
	if message.Status != "delivered" && message.Status != "read" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "配信済みのメッセージのみ評価できます"})
		return
	}

	// 評価の作成または更新
	rating, err := mrh.ratingService.CreateOrUpdateRating(c.Request.Context(), messageID, recipientID, req.Rating)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "評価の保存に失敗しました", "details": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "評価を保存しました",
		"data": gin.H{
			"id":        rating.ID,
			"messageId": rating.MessageID,
			"rating":    rating.Rating,
			"createdAt": rating.CreatedAt,
			"updatedAt": rating.UpdatedAt,
		},
	})
}

// GetMessageRating メッセージの評価を取得
// GET /api/v1/messages/:id/rating
func (mrh *MessageRatingHandler) GetMessageRating(c *gin.Context) {
	// 認証チェック
	userID, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "認証が必要です"})
		return
	}
	recipientID, ok := userID.(primitive.ObjectID)
	if !ok {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "ユーザーIDの取得に失敗しました"})
		return
	}

	// メッセージIDの取得・バリデーション
	messageIDStr := c.Param("id")
	messageID, err := primitive.ObjectIDFromHex(messageIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "無効なメッセージIDです"})
		return
	}

	// 受信者権限チェック
	message, err := mrh.messageService.GetMessageByID(c.Request.Context(), messageID)
	if err == mongo.ErrNoDocuments {
		c.JSON(http.StatusNotFound, gin.H{"error": "メッセージが見つかりません"})
		return
	}
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "メッセージの取得に失敗しました"})
		return
	}

	if message.RecipientID != recipientID {
		c.JSON(http.StatusForbidden, gin.H{"error": "このメッセージにアクセスする権限がありません"})
		return
	}

	// 評価を取得
	rating, err := mrh.ratingService.GetRatingByMessageAndRecipient(c.Request.Context(), messageID, recipientID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "評価の取得に失敗しました"})
		return
	}

	if rating == nil {
		c.JSON(http.StatusOK, gin.H{
			"message": "評価が見つかりません",
			"data":    nil,
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "評価を取得しました",
		"data": gin.H{
			"id":        rating.ID,
			"messageId": rating.MessageID,
			"rating":    rating.Rating,
			"createdAt": rating.CreatedAt,
			"updatedAt": rating.UpdatedAt,
		},
	})
}

// InboxMessageWithRating 評価付き受信メッセージ構造体
type InboxMessageWithRating struct {
	ID            primitive.ObjectID `json:"id"`
	SenderID      primitive.ObjectID `json:"senderId"`
	SenderName    string             `json:"senderName"`
	SenderEmail   string             `json:"senderEmail"`
	OriginalText  string             `json:"originalText"`
	FinalText     string             `json:"finalText"`
	Status        string             `json:"status"`
	Rating        *int               `json:"rating,omitempty"`        // 受信者による評価（1-5、未評価はnull）
	RatingID      *primitive.ObjectID `json:"ratingId,omitempty"`    // 評価ID
	CreatedAt     primitive.DateTime `json:"createdAt"`
	SentAt        *primitive.DateTime `json:"sentAt,omitempty"`
	DeliveredAt   *primitive.DateTime `json:"deliveredAt,omitempty"`
	ReadAt        *primitive.DateTime `json:"readAt,omitempty"`
}

// GetInboxWithRatings 評価付き受信トレイを取得
// GET /api/v1/messages/inbox-with-ratings
func (mrh *MessageRatingHandler) GetInboxWithRatings(c *gin.Context) {
	// 認証チェック
	userID, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "認証が必要です"})
		return
	}
	recipientID, ok := userID.(primitive.ObjectID)
	if !ok {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "ユーザーIDの取得に失敗しました"})
		return
	}

	// ページネーション
	pageStr := c.DefaultQuery("page", "1")
	limitStr := c.DefaultQuery("limit", "20")
	
	page, err := strconv.Atoi(pageStr)
	if err != nil || page < 1 {
		page = 1
	}
	
	limit, err := strconv.Atoi(limitStr)
	if err != nil || limit < 1 || limit > 100 {
		limit = 20
	}

	// 受信メッセージを取得
	messages, total, err := mrh.messageService.GetReceivedMessagesWithPagination(c.Request.Context(), recipientID, page, limit)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "メッセージの取得に失敗しました"})
		return
	}

	// メッセージIDリストを作成
	messageIDs := make([]primitive.ObjectID, len(messages))
	for i, msg := range messages {
		messageIDs[i] = msg.ID
	}

	// 評価を一括取得
	ratings := make(map[string]*models.MessageRating)
	if len(messageIDs) > 0 {
		ratings, err = mrh.ratingService.GetRatingsByMessages(c.Request.Context(), messageIDs, recipientID)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "評価の取得に失敗しました"})
			return
		}
	}

	// レスポンス用データを構築
	inboxMessages := make([]InboxMessageWithRating, len(messages))
	for i, msg := range messages {
		// 送信者情報の取得（getUserInfoヘルパーを使用）
		senderInfo, err := models.GetUserInfo(c.Request.Context(), msg.SenderID)
		if err != nil {
			// エラーログを出力するが処理は継続
			senderInfo = &models.UserInfo{
				Name:  "Unknown User",
				Email: "unknown@example.com",
			}
		}

		inboxMsg := InboxMessageWithRating{
			ID:           msg.ID,
			SenderID:     msg.SenderID,
			SenderName:   senderInfo.Name,
			SenderEmail:  senderInfo.Email,
			OriginalText: msg.OriginalText,
			FinalText:    msg.FinalText,
			Status:       string(msg.Status),
			CreatedAt:    primitive.NewDateTimeFromTime(msg.CreatedAt),
			SentAt:       convertTimeToDateTime(msg.SentAt),
			DeliveredAt:  convertTimeToDateTime(msg.DeliveredAt),
			ReadAt:       convertTimeToDateTime(msg.ReadAt),
		}

		// 評価情報を追加
		if rating, exists := ratings[msg.ID.Hex()]; exists {
			inboxMsg.Rating = &rating.Rating
			inboxMsg.RatingID = &rating.ID
		}

		inboxMessages[i] = inboxMsg
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "評価付き受信トレイを取得しました",
		"data": gin.H{
			"messages": inboxMessages,
			"pagination": gin.H{
				"page":       page,
				"limit":      limit,
				"total":      total,
				"totalPages": (total + int64(limit) - 1) / int64(limit),
			},
		},
	})
}

// DeleteMessageRating メッセージ評価を削除
// DELETE /api/v1/messages/:id/rating
func (mrh *MessageRatingHandler) DeleteMessageRating(c *gin.Context) {
	// 認証チェック
	userID, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "認証が必要です"})
		return
	}
	recipientID, ok := userID.(primitive.ObjectID)
	if !ok {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "ユーザーIDの取得に失敗しました"})
		return
	}

	// メッセージIDの取得・バリデーション
	messageIDStr := c.Param("id")
	messageID, err := primitive.ObjectIDFromHex(messageIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "無効なメッセージIDです"})
		return
	}

	// 評価を削除
	err = mrh.ratingService.DeleteRating(c.Request.Context(), messageID, recipientID)
	if err != nil {
		if err.Error() == "削除対象の評価が見つかりません" {
			c.JSON(http.StatusNotFound, gin.H{"error": err.Error()})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"error": "評価の削除に失敗しました"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "評価を削除しました"})
}

// convertTimeToDateTime *time.Time を *primitive.DateTime に変換するヘルパー関数
func convertTimeToDateTime(t *time.Time) *primitive.DateTime {
	if t == nil {
		return nil
	}
	dt := primitive.NewDateTimeFromTime(*t)
	return &dt
}

// RegisterMessageRatingRoutes メッセージ評価関連のルートを登録
func (mrh *MessageRatingHandler) RegisterRoutes(rg *gin.RouterGroup, jwtMiddleware gin.HandlerFunc) {
	messages := rg.Group("/messages").Use(jwtMiddleware)
	{
		// 個別メッセージの評価
		messages.POST("/:id/rate", mrh.RateMessage)
		messages.GET("/:id/rating", mrh.GetMessageRating)
		messages.DELETE("/:id/rating", mrh.DeleteMessageRating)
		
		// 評価付き受信トレイ
		messages.GET("/inbox-with-ratings", mrh.GetInboxWithRatings)
	}
}