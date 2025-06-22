package handlers

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"os"
	"sync"

	"yanwari-message-backend/models"

	"github.com/gin-gonic/gin"
	"go.mongodb.org/mongo-driver/bson/primitive"
)

// TransformHandler AIトーン変換ハンドラー
type TransformHandler struct {
	messageService  *models.MessageService
	anthropicAPIKey string
}

// NewTransformHandler トーン変換ハンドラーを作成
func NewTransformHandler(messageService *models.MessageService) *TransformHandler {
	return &TransformHandler{
		messageService:  messageService,
		anthropicAPIKey: os.Getenv("ANTHROPIC_API_KEY"),
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

	// 3つのトーンで並行変換
	tones := []string{"gentle", "constructive", "casual"}
	variations := make([]ToneVariation, len(tones))
	var wg sync.WaitGroup
	var mu sync.Mutex
	errorChan := make(chan error, len(tones))

	for i, tone := range tones {
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
	// トーン別プロンプトテンプレート
	prompts := map[string]string{
		"gentle": `あなたはコミュニケーションコーチです。以下のメッセージを、相手の気持ちを最大限に配慮した優しく思いやりのあるトーンに変換してください。

特徴:
- 丁寧語・敬語を使用
- 相手の立場や感情を理解していることを示す
- クッション言葉を活用
- 絵文字を適度に使用（😊など）
- 感謝や謝罪の気持ちを表現

元のメッセージ: %s

優しめトーンに変換:`,

		"constructive": `あなたはコミュニケーションコーチです。以下のメッセージを、建設的で前向きなトーンに変換してください。

特徴:
- 問題解決志向
- 具体的で明確な表現
- 相手との協力を重視
- 代替案や提案を含む
- プロフェッショナルな敬語

元のメッセージ: %s

建設的トーンに変換:`,

		"casual": `あなたはコミュニケーションコーチです。以下のメッセージを、親しみやすくカジュアルなトーンに変換してください。

特徴:
- フレンドリーで親近感のある表現
- 適度な関西弁や話し言葉
- 相手との距離を縮める表現
- シンプルで分かりやすい
- 絵文字の適度な使用

元のメッセージ: %s

カジュアルトーンに変換:`,
	}

	prompt, exists := prompts[tone]
	if !exists {
		return "", fmt.Errorf("サポートされていないトーンです: %s", tone)
	}

	// リクエストボディを作成
	requestBody := AnthropicRequest{
		Model:     "claude-3-5-sonnet-20241022",
		MaxTokens: 1000,
		Messages: []Message{
			{
				Role:    "user",
				Content: fmt.Sprintf(prompt, originalText),
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

// RegisterRoutes トーン変換関連のルートを登録
func (h *TransformHandler) RegisterRoutes(router *gin.RouterGroup, authMiddleware gin.HandlerFunc) {
	transform := router.Group("/transform")
	transform.Use(authMiddleware)
	{
		transform.POST("/tones", h.TransformToTones)
	}
}