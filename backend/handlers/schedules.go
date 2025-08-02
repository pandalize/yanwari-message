package handlers

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"os"
	"strconv"
	"time"

	"yanwari-message-backend/config"
	"yanwari-message-backend/models"

	"github.com/gin-gonic/gin"
	"go.mongodb.org/mongo-driver/bson/primitive"
)

// Anthropic API用の構造体（schedules.go専用）
type ScheduleAnthropicRequest struct {
	Model     string               `json:"model"`
	MaxTokens int                  `json:"max_tokens"`
	Messages  []ScheduleMessage    `json:"messages"`
}

type ScheduleMessage struct {
	Role    string `json:"role"`
	Content string `json:"content"`
}

type ScheduleAnthropicResponse struct {
	Content []ScheduleContent `json:"content"`
}

type ScheduleContent struct {
	Text string `json:"text"`
	Type string `json:"type"`
}

// ScheduleHandler スケジュール関連のハンドラー
type ScheduleHandler struct {
	scheduleService  *models.ScheduleService
	messageService   *models.MessageService
	anthropicAPIKey  string
	scheduleConfig   *config.ScheduleConfig
}

// NewScheduleHandler スケジュールハンドラーのコンストラクタ
func NewScheduleHandler(scheduleService *models.ScheduleService, messageService *models.MessageService) *ScheduleHandler {
	// スケジュール設定を読み込み
	scheduleConfig, err := config.LoadScheduleConfig()
	if err != nil {
		// ログ出力（実運用では適切なロガーを使用）
		fmt.Printf("警告: スケジュール設定の読み込みに失敗しました: %v\n", err)
	}

	return &ScheduleHandler{
		scheduleService: scheduleService,
		messageService:  messageService,
		anthropicAPIKey: os.Getenv("ANTHROPIC_API_KEY"),
		scheduleConfig:  scheduleConfig,
	}
}

// CreateSchedule スケジュール作成
// POST /api/v1/schedules
func (h *ScheduleHandler) CreateSchedule(c *gin.Context) {
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

	var req models.CreateScheduleRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "リクエストが無効です", "details": err.Error()})
		return
	}

	// メッセージIDの検証とアクセス権確認
	messageID, err := primitive.ObjectIDFromHex(req.MessageID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "無効なメッセージIDです"})
		return
	}

	// メッセージへのアクセス権を確認
	_, err = h.messageService.GetMessage(c.Request.Context(), messageID, currentUserID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "メッセージが見つかりません"})
		return
	}

	// 送信時刻が現在より未来であることを確認
	// UTC時刻で統一して比較
	now := time.Now().UTC()
	scheduledTime := req.ScheduledAt.UTC()
	
	// デバッグログ追加
	fmt.Printf("=== スケジュール時刻検証 ===\n")
	fmt.Printf("受信した時刻（元）: %s\n", req.ScheduledAt.Format(time.RFC3339))
	fmt.Printf("受信した時刻（UTC）: %s\n", scheduledTime.Format(time.RFC3339))
	fmt.Printf("現在時刻（UTC）: %s\n", now.Format(time.RFC3339))
	
	// 日本時間でも表示
	jst, _ := time.LoadLocation("Asia/Tokyo")
	fmt.Printf("受信した時刻（JST）: %s\n", scheduledTime.In(jst).Format(time.RFC3339))
	fmt.Printf("現在時刻（JST）: %s\n", now.In(jst).Format(time.RFC3339))
	
	timeDiff := scheduledTime.Sub(now)
	fmt.Printf("時刻差分: %v\n", timeDiff)
	fmt.Printf("========================\n")
	
	if scheduledTime.Before(now) || scheduledTime.Equal(now) {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "送信時刻は現在より未来である必要があります",
			"details": map[string]interface{}{
				"provided_time": scheduledTime.Format(time.RFC3339),
				"current_time":  now.Format(time.RFC3339),
				"provided_time_jst": scheduledTime.In(jst).Format(time.RFC3339),
				"current_time_jst":  now.In(jst).Format(time.RFC3339),
				"time_diff_minutes": timeDiff.Minutes(),
			},
		})
		return
	}

	// スケジュール作成
	schedule, err := h.scheduleService.CreateSchedule(c.Request.Context(), currentUserID, &req)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "スケジュールの作成に失敗しました"})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"data":    schedule,
		"message": "スケジュールを作成しました",
	})
}

// GetSchedules スケジュール一覧取得
// GET /api/v1/schedules
func (h *ScheduleHandler) GetSchedules(c *gin.Context) {
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

	// クエリパラメータを取得
	status := c.Query("status")
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

	// スケジュール一覧取得
	schedules, total, err := h.scheduleService.GetSchedules(c.Request.Context(), currentUserID, status, page, limit)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "スケジュール一覧の取得に失敗しました"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"data": gin.H{
			"schedules": schedules,
			"pagination": gin.H{
				"page":  page,
				"limit": limit,
				"total": total,
			},
		},
		"message": "スケジュール一覧を取得しました",
	})
}

// UpdateSchedule スケジュール更新
// PUT /api/v1/schedules/:id
func (h *ScheduleHandler) UpdateSchedule(c *gin.Context) {
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

	scheduleIDStr := c.Param("id")
	scheduleID, err := primitive.ObjectIDFromHex(scheduleIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "無効なスケジュールIDです"})
		return
	}

	var req models.UpdateScheduleRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "リクエストが無効です", "details": err.Error()})
		return
	}

	// 送信時刻が現在より未来であることを確認
	if req.ScheduledAt != nil {
		now := time.Now().UTC()
		scheduledTime := req.ScheduledAt.UTC()
		
		if scheduledTime.Before(now) || scheduledTime.Equal(now) {
			jst, _ := time.LoadLocation("Asia/Tokyo")
			timeDiff := scheduledTime.Sub(now)
			
			c.JSON(http.StatusBadRequest, gin.H{
				"error": "送信時刻は現在より未来である必要があります",
				"details": map[string]interface{}{
					"provided_time": scheduledTime.Format(time.RFC3339),
					"current_time":  now.Format(time.RFC3339),
					"provided_time_jst": scheduledTime.In(jst).Format(time.RFC3339),
					"current_time_jst":  now.In(jst).Format(time.RFC3339),
					"time_diff_minutes": timeDiff.Minutes(),
				},
			})
			return
		}
	}

	// スケジュール更新
	schedule, err := h.scheduleService.UpdateSchedule(c.Request.Context(), scheduleID, currentUserID, &req)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "スケジュールの更新に失敗しました"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"data":    schedule,
		"message": "スケジュールを更新しました",
	})
}

// DeleteSchedule スケジュール削除
// DELETE /api/v1/schedules/:id
func (h *ScheduleHandler) DeleteSchedule(c *gin.Context) {
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

	scheduleIDStr := c.Param("id")
	scheduleID, err := primitive.ObjectIDFromHex(scheduleIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "無効なスケジュールIDです"})
		return
	}

	// スケジュール削除
	err = h.scheduleService.DeleteSchedule(c.Request.Context(), scheduleID, currentUserID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "スケジュールの削除に失敗しました"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "スケジュールを削除しました",
	})
}

// SuggestSchedule AI時間提案
// POST /api/v1/schedule/suggest
func (h *ScheduleHandler) SuggestSchedule(c *gin.Context) {
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

	var req models.ScheduleSuggestionRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "リクエストが無効です", "details": err.Error()})
		return
	}

	// APIキーの確認
	if h.anthropicAPIKey == "" {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Anthropic APIキーが設定されていません"})
		return
	}

	// メッセージIDの検証とアクセス権確認
	messageID, err := primitive.ObjectIDFromHex(req.MessageID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "無効なメッセージIDです"})
		return
	}

	// メッセージへのアクセス権を確認
	_, err = h.messageService.GetMessage(c.Request.Context(), messageID, currentUserID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "メッセージが見つかりません"})
		return
	}

	// AI分析を実行
	suggestion, err := h.callAnthropicScheduleAPI(c.Request.Context(), req.MessageText, req.SelectedTone, req.UserContext, req.UserPreferences)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "AI分析に失敗しました", "details": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"data":    suggestion,
		"message": "AI時間提案を取得しました",
	})
}

// callAnthropicScheduleAPI Anthropic Claude APIを呼び出してスケジュール提案を取得
func (h *ScheduleHandler) callAnthropicScheduleAPI(ctx context.Context, messageText, selectedTone, userContext, userPreferences string) (*models.ScheduleSuggestionResponse, error) {
	var prompt string
	var modelConfig config.AIModelConfig

	// 設定ファイルからプロンプトを生成
	if h.scheduleConfig != nil {
		var err error
		prompt, err = h.scheduleConfig.GetSchedulePrompt(messageText, selectedTone, userContext, userPreferences)
		if err != nil {
			return nil, fmt.Errorf("プロンプト生成エラー: %w", err)
		}
		modelConfig = h.scheduleConfig.GetScheduleAIModelConfig()
	} else {
		// フォールバック: デフォルトプロンプト
		prompt, modelConfig = h.getDefaultSchedulePrompt(messageText, selectedTone, userContext, userPreferences)
	}

	// リクエストボディを作成
	requestBody := ScheduleAnthropicRequest{
		Model:     modelConfig.Name,
		MaxTokens: modelConfig.MaxTokens,
		Messages: []ScheduleMessage{
			{
				Role:    "user",
				Content: prompt,
			},
		},
	}

	jsonData, err := json.Marshal(requestBody)
	if err != nil {
		return nil, fmt.Errorf("リクエストの作成に失敗: %w", err)
	}

	// HTTP リクエストを作成
	req, err := http.NewRequestWithContext(ctx, "POST", "https://api.anthropic.com/v1/messages", bytes.NewBuffer(jsonData))
	if err != nil {
		return nil, fmt.Errorf("HTTPリクエストの作成に失敗: %w", err)
	}

	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("x-api-key", h.anthropicAPIKey)
	req.Header.Set("anthropic-version", "2023-06-01")

	// HTTPクライアントでリクエストを送信（30秒タイムアウト）
	client := &http.Client{
		Timeout: 30 * time.Second,
	}
	resp, err := client.Do(req)
	if err != nil {
		return nil, fmt.Errorf("API呼び出しに失敗: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("Anthropic API エラー: status %d", resp.StatusCode)
	}

	// レスポンスをパース
	var apiResponse ScheduleAnthropicResponse
	if err := json.NewDecoder(resp.Body).Decode(&apiResponse); err != nil {
		return nil, fmt.Errorf("レスポンスの解析に失敗: %w", err)
	}

	if len(apiResponse.Content) == 0 {
		return nil, fmt.Errorf("空のレスポンスが返されました")
	}

	// JSON文字列をパース
	var suggestion models.ScheduleSuggestionResponse
	if err := json.Unmarshal([]byte(apiResponse.Content[0].Text), &suggestion); err != nil {
		return nil, fmt.Errorf("AI応答の解析に失敗: %w", err)
	}

	return &suggestion, nil
}

// getDefaultSchedulePrompt フォールバック用デフォルトプロンプト
func (h *ScheduleHandler) getDefaultSchedulePrompt(messageText, selectedTone, userContext, userPreferences string) (string, config.AIModelConfig) {
	now := time.Now()
	currentTime := now.Format("2006-01-02 15:04:05")
	dayOfWeek := getDayOfWeekInJapanese(now.Weekday())

	prompt := fmt.Sprintf(`あなたは日本のビジネスコミュニケーション専門家です。
以下のメッセージを分析し、最適な送信タイミングを提案してください。

メッセージ内容: "%s"
補足状況説明: "%s"
選択されたトーン: %s
現在時刻: %s
曜日: %s
ユーザー設定: "%s"

必ず以下のJSON形式で回答してください：
{
  "message_type": "謝罪|お礼|依頼|報告|相談|確認|連絡|その他",
  "recommended_timing": "今すぐ|1時間以内|当日中|翌朝|翌日中|来週",
  "reasoning": "推奨理由を日本語で100文字以内で説明",
  "suggested_options": [
    {
      "option": "今すぐ送信",
      "priority": "最推奨|推奨|選択肢",
      "reason": "選択理由を簡潔に",
      "delay_minutes": 0
    }
  ]
}`, messageText, userContext, selectedTone, currentTime, dayOfWeek, userPreferences)

	defaultConfig := config.AIModelConfig{
		Name:      "claude-3-5-sonnet-20241022",
		MaxTokens: 500,
	}

	return prompt, defaultConfig
}

// getDayOfWeekInJapanese 英語の曜日を日本語に変換（handlers内用）
func getDayOfWeekInJapanese(weekday time.Weekday) string {
	days := map[time.Weekday]string{
		time.Sunday:    "日曜日",
		time.Monday:    "月曜日",
		time.Tuesday:   "火曜日",
		time.Wednesday: "水曜日",
		time.Thursday:  "木曜日",
		time.Friday:    "金曜日",
		time.Saturday:  "土曜日",
	}
	return days[weekday]
}

// ExecuteSchedule スケジュール実行 (内部用)
// この関数は定期実行される送信処理で使用
func (h *ScheduleHandler) ExecuteSchedule(scheduleID string) error {
	// TODO: F-03 スケジュール実行機能実装
	// - 送信時刻チェック
	// - メッセージ送信処理
	// - 送信状態更新
	// - エラーハンドリング
	return nil
}

// RegisterRoutes スケジュール関連のルートを登録
func (h *ScheduleHandler) RegisterRoutes(router *gin.RouterGroup, authMiddleware gin.HandlerFunc) {
	schedule := router.Group("/schedule")
	schedule.Use(authMiddleware)
	{
		schedule.POST("/suggest", h.SuggestSchedule) // AI時間提案
	}

	schedules := router.Group("/schedules")
	schedules.Use(authMiddleware)
	{
		schedules.POST("/", h.CreateSchedule)
		schedules.GET("/", h.GetSchedules)
		schedules.PUT("/:id", h.UpdateSchedule)
		schedules.DELETE("/:id", h.DeleteSchedule)
	}
}