package handlers

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"os"
	"sync"

	"yanwari-message-backend/config"
	"yanwari-message-backend/models"

	"github.com/gin-gonic/gin"
	"go.mongodb.org/mongo-driver/bson/primitive"
)

// TransformHandler AIトーン変換ハンドラー
type TransformHandler struct {
	messageService  *models.MessageService
	anthropicAPIKey string
	toneConfig      *config.ToneConfig
}

// NewTransformHandler トーン変換ハンドラーを作成
func NewTransformHandler(messageService *models.MessageService) *TransformHandler {
	// トーン設定を読み込み
	toneConfig, err := config.LoadToneConfig()
	if err != nil {
		// ログ出力（実運用では適切なロガーを使用）
		fmt.Printf("警告: トーン設定の読み込みに失敗しました: %v\n", err)
	}

	return &TransformHandler{
		messageService:  messageService,
		anthropicAPIKey: os.Getenv("ANTHROPIC_API_KEY"),
		toneConfig:      toneConfig,
	}
}

// ToneTransformRequest トーン変換リクエスト
type ToneTransformRequest struct {
	MessageID    string `json:"messageId" binding:"required"`
	OriginalText string `json:"originalText" binding:"required"`
}

// ToneVariation トーン変換結果
type ToneVariation struct {
	Tone string `json:"tone"`
	Text string `json:"text"`
}

// ToneTransformResponse トーン変換レスポンス
type ToneTransformResponse struct {
	MessageID  string          `json:"messageId"`
	Variations []ToneVariation `json:"variations"`
}

// AnthropicRequest Anthropic API リクエスト構造
type AnthropicRequest struct {
	Model     string    `json:"model"`
	MaxTokens int       `json:"max_tokens"`
	Messages  []Message `json:"messages"`
}

// Message Anthropic APIメッセージ構造
type Message struct {
	Role    string `json:"role"`
	Content string `json:"content"`
}

// AnthropicResponse Anthropic API レスポンス構造
type AnthropicResponse struct {
	Content []Content `json:"content"`
}

// Content Anthropic APIコンテンツ構造
type Content struct {
	Text string `json:"text"`
	Type string `json:"type"`
}

// TransformToTones メッセージを3つのトーンに変換
// POST /api/v1/transform/tones
func (h *TransformHandler) TransformToTones(c *gin.Context) {
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

	var req ToneTransformRequest
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

	// 設定ファイルから利用可能なトーンを取得
	var availableTones []string
	if h.toneConfig != nil {
		for toneName := range h.toneConfig.Tones {
			availableTones = append(availableTones, toneName)
		}
	} else {
		// フォールバック: デフォルトトーン
		availableTones = []string{"gentle", "constructive", "casual"}
	}

	// 並行変換処理
	variations := make([]ToneVariation, len(availableTones))
	var wg sync.WaitGroup
	var mu sync.Mutex
	errorChan := make(chan error, len(availableTones))

	for i, tone := range availableTones {
		wg.Add(1)
		go func(index int, toneType string) {
			defer wg.Done()

			transformedText, err := h.callAnthropicAPI(c.Request.Context(), req.OriginalText, toneType)
			if err != nil {
				errorChan <- fmt.Errorf("%sトーンの変換に失敗: %w", toneType, err)
				return
			}

			mu.Lock()
			variations[index] = ToneVariation{
				Tone: toneType,
				Text: transformedText,
			}
			mu.Unlock()
		}(i, tone)
	}

	wg.Wait()
	close(errorChan)

	// エラーチェック
	if len(errorChan) > 0 {
		err := <-errorChan
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	// データベースにトーン変換結果を保存
	updateReq := &models.UpdateMessageRequest{
		ToneVariations: map[string]string{
			"gentle":       variations[0].Text,
			"constructive": variations[1].Text,
			"casual":       variations[2].Text,
		},
	}

	_, err = h.messageService.UpdateMessage(c.Request.Context(), messageID, currentUserID, updateReq)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "トーン変換結果の保存に失敗しました"})
		return
	}

	response := ToneTransformResponse{
		MessageID:  req.MessageID,
		Variations: variations,
	}

	c.JSON(http.StatusOK, gin.H{
		"data":    response,
		"message": "トーン変換が完了しました",
	})
}

// callAnthropicAPI Anthropic Claude APIを呼び出してトーン変換を実行
func (h *TransformHandler) callAnthropicAPI(ctx context.Context, originalText, tone string) (string, error) {
	var prompt string
	var modelConfig config.AIModelConfig

	// 設定ファイルからプロンプトを生成
	if h.toneConfig != nil {
		var err error
		prompt, err = h.toneConfig.GetPrompt(tone, originalText)
		if err != nil {
			return "", fmt.Errorf("プロンプト生成エラー: %w", err)
		}
		modelConfig = h.toneConfig.GetAIModelConfig()
	} else {
		// フォールバック: デフォルトプロンプト
		prompt, modelConfig = h.getDefaultPrompt(originalText, tone)
	}

	// リクエストボディを作成
	requestBody := AnthropicRequest{
		Model:     modelConfig.Name,
		MaxTokens: modelConfig.MaxTokens,
		Messages: []Message{
			{
				Role:    "user",
				Content: prompt,
			},
		},
	}

	jsonData, err := json.Marshal(requestBody)
	if err != nil {
		return "", fmt.Errorf("リクエストの作成に失敗: %w", err)
	}

	// HTTP リクエストを作成
	req, err := http.NewRequestWithContext(ctx, "POST", "https://api.anthropic.com/v1/messages", bytes.NewBuffer(jsonData))
	if err != nil {
		return "", fmt.Errorf("HTTPリクエストの作成に失敗: %w", err)
	}

	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("x-api-key", h.anthropicAPIKey)
	req.Header.Set("anthropic-version", "2023-06-01")

	// HTTPクライアントでリクエストを送信
	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		return "", fmt.Errorf("API呼び出しに失敗: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return "", fmt.Errorf("Anthropic API エラー: status %d", resp.StatusCode)
	}

	// レスポンスをパース
	var apiResponse AnthropicResponse
	if err := json.NewDecoder(resp.Body).Decode(&apiResponse); err != nil {
		return "", fmt.Errorf("レスポンスの解析に失敗: %w", err)
	}

	if len(apiResponse.Content) == 0 {
		return "", fmt.Errorf("空のレスポンスが返されました")
	}

	return apiResponse.Content[0].Text, nil
}

// getDefaultPrompt フォールバック用デフォルトプロンプト
func (h *TransformHandler) getDefaultPrompt(originalText, tone string) (string, config.AIModelConfig) {
	prompts := map[string]string{
		"gentle": "あなたはコミュニケーションコーチです。以下のメッセージを、相手の気持ちを最大限に配慮した優しく思いやりのあるトーンに変換してください。\n\n元のメッセージ: " + originalText + "\n\n優しめトーンに変換:",
		"constructive": "あなたはコミュニケーションコーチです。以下のメッセージを、建設的で前向きなトーンに変換してください。\n\n元のメッセージ: " + originalText + "\n\n建設的トーンに変換:",
		"casual": "あなたはコミュニケーションコーチです。以下のメッセージを、親しみやすくカジュアルなトーンに変換してください。\n\n元のメッセージ: " + originalText + "\n\nカジュアルトーンに変換:",
	}

	prompt := prompts[tone]
	if prompt == "" {
		prompt = "以下のメッセージを変換してください: " + originalText
	}

	defaultConfig := config.AIModelConfig{
		Name:      "claude-3-5-sonnet-20241022",
		MaxTokens: 1000,
	}

	return prompt, defaultConfig
}

// ReloadConfig 設定ファイルを再読み込み（開発・チューニング用）
// POST /api/v1/transform/reload-config
func (h *TransformHandler) ReloadConfig(c *gin.Context) {
	if err := config.ReloadConfig(); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "設定の再読み込みに失敗しました"})
		return
	}

	// ハンドラーの設定も更新
	newConfig, err := config.LoadToneConfig()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "新しい設定の読み込みに失敗しました"})
		return
	}

	h.toneConfig = newConfig

	availableTones := h.toneConfig.GetAvailableTones()
	c.JSON(http.StatusOK, gin.H{
		"message": "設定を再読み込みしました",
		"available_tones": availableTones,
	})
}

// RegisterRoutes トーン変換関連のルートを登録
func (h *TransformHandler) RegisterRoutes(router *gin.RouterGroup, authMiddleware gin.HandlerFunc) {
	transform := router.Group("/transform")
	transform.Use(authMiddleware)
	{
		transform.POST("/tones", h.TransformToTones)
		transform.POST("/reload-config", h.ReloadConfig) // チューニング用
	}
}