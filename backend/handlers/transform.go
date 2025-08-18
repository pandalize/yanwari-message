package handlers

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"strings"
	"sync"
	"time"

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
	fmt.Println("[TransformHandler] 初期化開始...")
	
	// トーン設定を読み込み
	toneConfig, err := config.LoadToneConfig()
	if err != nil {
		// 詳細なエラーログ出力
		fmt.Printf("❌ [TransformHandler] トーン設定の読み込みに失敗: %v\n", err)
		fmt.Printf("❌ [TransformHandler] フォールバックモード（デフォルトプロンプト）で動作します\n")
		toneConfig = nil
	} else {
		fmt.Printf("✅ [TransformHandler] トーン設定の読み込み成功\n")
	}

	// Anthropic API キーの確認
	apiKey := os.Getenv("ANTHROPIC_API_KEY")
	if apiKey == "" {
		fmt.Printf("⚠️ [TransformHandler] ANTHROPIC_API_KEY環境変数が設定されていません\n")
	} else {
		fmt.Printf("✅ [TransformHandler] ANTHROPIC_API_KEY設定確認済み\n")
	}

	handler := &TransformHandler{
		messageService:  messageService,
		anthropicAPIKey: apiKey,
		toneConfig:      toneConfig,
	}
	
	fmt.Printf("✅ [TransformHandler] 初期化完了（YAMLファイル使用: %t）\n", toneConfig != nil)
	return handler
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
	currentUser, err := getUserByJWT(c, h.messageService.GetUserService())
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": err.Error()})
		return
	}
	currentUserID := currentUser.ID

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
		fmt.Printf("[Transform] YAML設定ファイルからトーン一覧を取得中...\n")
		for toneName := range h.toneConfig.Tones {
			availableTones = append(availableTones, toneName)
			fmt.Printf("[Transform] - YAML設定トーン: %s\n", toneName)
		}
		fmt.Printf("✅ [Transform] YAML設定ファイル使用: %d個のトーン\n", len(availableTones))
	} else {
		// フォールバック: デフォルトトーン
		availableTones = []string{"gentle", "constructive", "casual"}
		fmt.Printf("⚠️ [Transform] フォールバックモード: デフォルトプロンプトを使用\n")
	}

	// 並行変換処理（詳細ログ付き）
	variations := make([]ToneVariation, len(availableTones))
	var wg sync.WaitGroup
	var mu sync.Mutex
	errors := make([]error, 0)
	
	fmt.Printf("=== トーン変換開始: %d個のトーンを並行処理 ===\n", len(availableTones))

	for i, tone := range availableTones {
		wg.Add(1)
		go func(index int, toneType string) {
			defer wg.Done()
			
			fmt.Printf("[%s] API呼び出し開始\n", toneType)
			startTime := time.Now()

			transformedText, err := h.callAnthropicAPI(c.Request.Context(), req.OriginalText, toneType)
			
			duration := time.Since(startTime)
			fmt.Printf("[%s] API呼び出し完了 (所要時間: %v)\n", toneType, duration)
			
			mu.Lock()
			if err != nil {
				fmt.Printf("[%s] エラー: %v\n", toneType, err)
				errors = append(errors, fmt.Errorf("%sトーンの変換に失敗: %w", toneType, err))
			} else {
				fmt.Printf("[%s] 成功: %d文字の変換結果\n", toneType, len(transformedText))
				variations[index] = ToneVariation{
					Tone: toneType,
					Text: transformedText,
				}
			}
			mu.Unlock()
		}(i, tone)
	}

	wg.Wait()
	fmt.Printf("=== 並行処理完了: %d個のエラー ===\n", len(errors))

	// エラーチェック
	if len(errors) > 0 {
		// 最初のエラーを返す
		c.JSON(http.StatusInternalServerError, gin.H{"error": errors[0].Error()})
		return
	}

	// データベースにトーン変換結果を保存
	toneMap := make(map[string]string)
	for _, variation := range variations {
		toneMap[variation.Tone] = variation.Text
	}
	
	updateReq := &models.UpdateMessageRequest{
		ToneVariations: toneMap,
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
		fmt.Printf("[%s] YAML設定からプロンプト生成中...\n", tone)
		var err error
		prompt, err = h.toneConfig.GetPrompt(tone, originalText)
		if err != nil {
			fmt.Printf("[%s] プロンプト生成エラー: %v\n", tone, err)
			return "", fmt.Errorf("プロンプト生成エラー: %w", err)
		}
		modelConfig = h.toneConfig.GetAIModelConfig()
		fmt.Printf("[%s] ✅ YAML設定プロンプト生成成功 (Model: %s, MaxTokens: %d)\n", tone, modelConfig.Name, modelConfig.MaxTokens)
	} else {
		// フォールバック: デフォルトプロンプト
		fmt.Printf("[%s] デフォルトプロンプト使用\n", tone)
		prompt, modelConfig = h.getDefaultPrompt(originalText, tone)
		fmt.Printf("[%s] ✅ デフォルトプロンプト生成成功 (Model: %s, MaxTokens: %d)\n", tone, modelConfig.Name, modelConfig.MaxTokens)
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

	// HTTPクライアントでリクエストを送信（詳細ログ付きリトライ機能）
	client := &http.Client{
		Timeout: 30 * time.Second,
	}
	
	fmt.Printf("[%s] リクエスト詳細 - URL: %s, Model: %s, MaxTokens: %d\n", tone, "https://api.anthropic.com/v1/messages", requestBody.Model, requestBody.MaxTokens)
	fmt.Printf("[%s] リクエストサイズ: %d bytes\n", tone, len(jsonData))
	
	var resp *http.Response
	var lastErr error
	maxRetries := 3
	
	for attempt := 1; attempt <= maxRetries; attempt++ {
		fmt.Printf("[%s] 試行 %d/%d - リクエスト送信中...\n", tone, attempt, maxRetries)
		
		resp, err = client.Do(req)
		if err != nil {
			lastErr = err
			fmt.Printf("[%s] 試行 %d/%d - 接続エラー: %v\n", tone, attempt, maxRetries, err)
			if attempt < maxRetries {
				// 指数バックオフでリトライ
				waitTime := time.Duration(attempt*attempt) * time.Second
				fmt.Printf("[%s] %d秒後にリトライします\n", tone, int(waitTime.Seconds()))
				time.Sleep(waitTime)
				continue
			}
			return "", fmt.Errorf("API呼び出しに失敗（%d回試行後）: %w", maxRetries, err)
		}
		
		fmt.Printf("[%s] 試行 %d/%d - レスポンス受信: ステータス %d\n", tone, attempt, maxRetries, resp.StatusCode)
		
		// 529, 502, 503エラーの場合はリトライ
		if resp.StatusCode == 529 || resp.StatusCode == 502 || resp.StatusCode == 503 {
			bodyBytes, _ := io.ReadAll(resp.Body)
			resp.Body.Close()
			fmt.Printf("[%s] 試行 %d/%d - 一時的エラー（%d）: %s\n", tone, attempt, maxRetries, resp.StatusCode, string(bodyBytes))
			lastErr = fmt.Errorf("Anthropic API 一時的エラー: status %d", resp.StatusCode)
			if attempt < maxRetries {
				waitTime := time.Duration(attempt*2) * time.Second
				fmt.Printf("[%s] %d秒後にリトライします\n", tone, int(waitTime.Seconds()))
				time.Sleep(waitTime)
				continue
			}
		}
		
		break
	}
	
	if resp == nil {
		return "", fmt.Errorf("API呼び出しが失敗しました: %v", lastErr)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		// エラーレスポンスの詳細を取得
		bodyBytes, _ := io.ReadAll(resp.Body)
		return "", fmt.Errorf("Anthropic API エラー: status %d, response: %s", resp.StatusCode, string(bodyBytes))
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
		Name:      "claude-3-haiku-20240307",
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
func (h *TransformHandler) RegisterRoutes(router *gin.RouterGroup, jwtMiddleware gin.HandlerFunc) {
	transform := router.Group("/transform")
	transform.Use(jwtMiddleware)
	{
		transform.POST("/tones", h.TransformToTones)
		transform.POST("/reload-config", h.ReloadConfig) // チューニング用
	}
}