package handlers

import (
	"net/http"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
	"go.mongodb.org/mongo-driver/bson/primitive"

	"yanwari-message-backend/models"
)

// DashboardHandler ダッシュボード関連のハンドラー
type DashboardHandler struct {
	messageService *models.MessageService
	userService    *models.UserService
}

// NewDashboardHandler 新しいDashboardHandlerを作成
func NewDashboardHandler(messageService *models.MessageService, userService *models.UserService) *DashboardHandler {
	return &DashboardHandler{
		messageService: messageService,
		userService:    userService,
	}
}

// ActivityStats 活動統計
type ActivityStats struct {
	Today struct {
		MessagesSent     int `json:"messagesSent"`
		MessagesReceived int `json:"messagesReceived"`
		MessagesRead     int `json:"messagesRead"`
	} `json:"today"`
	ThisMonth struct {
		MessagesSent     int `json:"messagesSent"`
		MessagesReceived int `json:"messagesReceived"`
		MessagesRead     int `json:"messagesRead"`
	} `json:"thisMonth"`
	Total struct {
		MessagesSent     int `json:"messagesSent"`
		MessagesReceived int `json:"messagesReceived"`
		Friends          int `json:"friends"`
	} `json:"total"`
}

// RecentMessage 最近のメッセージ
type RecentMessage struct {
	ID           string    `json:"id"`
	Type         string    `json:"type"` // "sent" or "received"
	SenderName   string    `json:"senderName"`
	SenderEmail  string    `json:"senderEmail"`
	RecipientName string   `json:"recipientName"`
	RecipientEmail string  `json:"recipientEmail"`
	Text         string    `json:"text"`
	SentAt       time.Time `json:"sentAt"`
	ReadAt       *time.Time `json:"readAt,omitempty"`
	IsRead       bool      `json:"isRead"`
}

// DashboardResponse ダッシュボード情報のレスポンス
type DashboardResponse struct {
	ActivityStats    ActivityStats   `json:"activityStats"`
	RecentMessages   []RecentMessage `json:"recentMessages"`
	PendingMessages  int            `json:"pendingMessages"`  // 未読メッセージ数
	ScheduledMessages int           `json:"scheduledMessages"` // スケジュール済みメッセージ数
}

// GetDashboard ダッシュボード情報を取得
// GET /api/v1/dashboard
func (dh *DashboardHandler) GetDashboard(c *gin.Context) {
	// 認証チェック
	currentUser, err := getUserByFirebaseUID(c, dh.userService)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": err.Error()})
		return
	}
	currentUserID := currentUser.ID

	// 時間範囲を設定
	now := time.Now()
	today := time.Date(now.Year(), now.Month(), now.Day(), 0, 0, 0, 0, time.Local)
	thisMonth := time.Date(now.Year(), now.Month(), 1, 0, 0, 0, 0, time.Local)

	// 活動統計を取得
	activityStats, err := dh.getActivityStats(c, currentUserID, today, thisMonth)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "活動統計の取得に失敗しました"})
		return
	}

	// 最近のメッセージを取得（送信・受信合わせて10件）
	recentMessages, err := dh.getRecentMessages(c, currentUserID, 10)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "最近のメッセージ取得に失敗しました"})
		return
	}

	// 未読メッセージ数を取得
	pendingCount, err := dh.messageService.GetUnreadCount(c.Request.Context(), currentUserID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "未読メッセージ数取得に失敗しました"})
		return
	}

	// スケジュール済みメッセージ数を取得
	scheduledCount, err := dh.messageService.GetScheduledCount(c.Request.Context(), currentUserID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "スケジュール済みメッセージ数取得に失敗しました"})
		return
	}

	response := DashboardResponse{
		ActivityStats:     *activityStats,
		RecentMessages:    recentMessages,
		PendingMessages:   pendingCount,
		ScheduledMessages: scheduledCount,
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    response,
	})
}

// getActivityStats 活動統計を取得
func (dh *DashboardHandler) getActivityStats(c *gin.Context, userID primitive.ObjectID, today, thisMonth time.Time) (*ActivityStats, error) {
	ctx := c.Request.Context()

	stats := &ActivityStats{}

	// 今日の統計
	todayStats, err := dh.messageService.GetStatsForPeriod(ctx, userID, today, time.Now())
	if err != nil {
		return nil, err
	}
	stats.Today = todayStats

	// 今月の統計
	monthStats, err := dh.messageService.GetStatsForPeriod(ctx, userID, thisMonth, time.Now())
	if err != nil {
		return nil, err
	}
	stats.ThisMonth = monthStats

	// 全期間の統計
	totalStats, err := dh.messageService.GetStatsForPeriod(ctx, userID, time.Time{}, time.Now())
	if err != nil {
		return nil, err
	}
	stats.Total.MessagesSent = totalStats.MessagesSent
	stats.Total.MessagesReceived = totalStats.MessagesReceived

	// 友達数を取得
	friendsCount, err := dh.userService.GetFriendsCount(ctx, userID)
	if err != nil {
		return nil, err
	}
	stats.Total.Friends = friendsCount

	return stats, nil
}

// getRecentMessages 最近のメッセージを取得
func (dh *DashboardHandler) getRecentMessages(c *gin.Context, userID primitive.ObjectID, limit int) ([]RecentMessage, error) {
	ctx := c.Request.Context()

	// 送信メッセージを取得
	sentMessages, _, err := dh.messageService.GetSentMessages(ctx, userID, 1, limit/2)
	if err != nil {
		return nil, err
	}

	// 受信メッセージを取得
	receivedMessages, _, err := dh.messageService.GetReceivedMessages(ctx, userID, 1, limit/2)
	if err != nil {
		return nil, err
	}

	var recentMessages []RecentMessage

	// 送信メッセージを追加
	for _, msg := range sentMessages {
		recipientInfo, _ := dh.userService.GetUserByID(ctx, msg.RecipientID.Hex())
		recipientName := "Unknown User"
		recipientEmail := ""
		if recipientInfo != nil {
			if recipientInfo.Name != "" {
				recipientName = recipientInfo.Name
			} else {
				recipientName = recipientInfo.Email
			}
			recipientEmail = recipientInfo.Email
		}

		recentMessages = append(recentMessages, RecentMessage{
			ID:             msg.ID.Hex(),
			Type:           "sent",
			RecipientName:  recipientName,
			RecipientEmail: recipientEmail,
			Text:           msg.FinalText,
			SentAt:         func() time.Time {
				if msg.SentAt != nil {
					return *msg.SentAt
				}
				return time.Time{}
			}(),
			ReadAt:         msg.ReadAt,
			IsRead:         msg.ReadAt != nil,
		})
	}

	// 受信メッセージを追加
	for _, msg := range receivedMessages {
		senderInfo, _ := dh.userService.GetUserByID(ctx, msg.SenderID.Hex())
		senderName := "Unknown User"
		senderEmail := ""
		if senderInfo != nil {
			if senderInfo.Name != "" {
				senderName = senderInfo.Name
			} else {
				senderName = senderInfo.Email
			}
			senderEmail = senderInfo.Email
		}

		recentMessages = append(recentMessages, RecentMessage{
			ID:          msg.ID.Hex(),
			Type:        "received",
			SenderName:  senderName,
			SenderEmail: senderEmail,
			Text:        msg.FinalText,
			SentAt:      func() time.Time {
				if msg.SentAt != nil {
					return *msg.SentAt
				}
				return time.Time{}
			}(),
			ReadAt:      msg.ReadAt,
			IsRead:      msg.ReadAt != nil,
		})
	}

	// 送信時刻でソート（新しい順）
	for i := 0; i < len(recentMessages)-1; i++ {
		for j := i + 1; j < len(recentMessages); j++ {
			if recentMessages[i].SentAt.Before(recentMessages[j].SentAt) {
				recentMessages[i], recentMessages[j] = recentMessages[j], recentMessages[i]
			}
		}
	}

	// 指定された件数に制限
	if len(recentMessages) > limit {
		recentMessages = recentMessages[:limit]
	}

	return recentMessages, nil
}

// DeliveryStatus 送信状況情報
type DeliveryStatus struct {
	MessageID    string     `json:"messageId"`
	Status       string     `json:"status"`
	SentAt       *time.Time `json:"sentAt,omitempty"`
	DeliveredAt  *time.Time `json:"deliveredAt,omitempty"`
	ReadAt       *time.Time `json:"readAt,omitempty"`
	RecipientName string    `json:"recipientName"`
	Text         string     `json:"text"`
	ErrorMessage string     `json:"errorMessage,omitempty"`
}

// GetDeliveryStatuses 送信状況一覧を取得
// GET /api/v1/delivery-status
func (dh *DashboardHandler) GetDeliveryStatuses(c *gin.Context) {
	// 認証チェック
	currentUser, err := getUserByFirebaseUID(c, dh.userService)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": err.Error()})
		return
	}
	currentUserID := currentUser.ID

	// ページネーションパラメータ
	page := 1
	limit := 20
	if p := c.Query("page"); p != "" {
		if parsed, err := strconv.Atoi(p); err == nil && parsed > 0 {
			page = parsed
		}
	}
	if l := c.Query("limit"); l != "" {
		if parsed, err := strconv.Atoi(l); err == nil && parsed > 0 && parsed <= 100 {
			limit = parsed
		}
	}

	// 送信メッセージを取得
	messages, total, err := dh.messageService.GetSentMessages(c.Request.Context(), currentUserID, page, limit)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "送信メッセージ取得に失敗しました"})
		return
	}

	// DeliveryStatus形式に変換
	var statuses []DeliveryStatus
	for _, msg := range messages {
		// 受信者情報を取得
		recipientInfo, _ := dh.userService.GetUserByID(c.Request.Context(), msg.RecipientID.Hex())
		recipientName := "Unknown User"
		if recipientInfo != nil {
			if recipientInfo.Name != "" {
				recipientName = recipientInfo.Name
			} else {
				recipientName = recipientInfo.Email
			}
		}

		status := DeliveryStatus{
			MessageID:     msg.ID.Hex(),
			Status:        string(msg.Status),
			SentAt:        msg.SentAt,
			DeliveredAt:   msg.DeliveredAt,
			ReadAt:        msg.ReadAt,
			RecipientName: recipientName,
			Text:          msg.FinalText,
		}

		// エラーメッセージの生成（必要に応じて）
		if msg.Status == "failed" {
			status.ErrorMessage = "送信に失敗しました"
		}

		statuses = append(statuses, status)
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data": gin.H{
			"statuses":    statuses,
			"total":       total,
			"page":        page,
			"limit":       limit,
			"totalPages":  (total + int64(limit) - 1) / int64(limit),
		},
	})
}