package handlers

import (
	"net/http"

	"github.com/gin-gonic/gin"
)

// DraftHandler 下書き関連のハンドラー
type DraftHandler struct {
	// TODO: 依存関係を追加 (DraftService, AnthropicService など)
}

// NewDraftHandler 下書きハンドラーのコンストラクタ
func NewDraftHandler() *DraftHandler {
	return &DraftHandler{}
}

// CreateDraft 下書き作成
// POST /api/v1/drafts
func (h *DraftHandler) CreateDraft(c *gin.Context) {
	// TODO: F-02 下書き作成機能実装
	// - 元文章の受信
	// - トーンプリセット選択 (gentle/constructive/casual)
	// - Anthropic API連携でトーン変換
	// - 下書き保存
	c.JSON(http.StatusNotImplemented, gin.H{
		"message": "F-02: 下書き作成機能 - 実装予定",
		"feature": "message-drafts",
	})
}

// GetDraft 下書き取得
// GET /api/v1/drafts/:id
func (h *DraftHandler) GetDraft(c *gin.Context) {
	// TODO: F-02 下書き取得機能実装
	// - 下書きID検証
	// - ユーザー権限確認
	// - 下書きデータ返却
	c.JSON(http.StatusNotImplemented, gin.H{
		"message": "F-02: 下書き取得機能 - 実装予定",
		"feature": "message-drafts",
	})
}

// UpdateDraft 下書き更新
// PUT /api/v1/drafts/:id
func (h *DraftHandler) UpdateDraft(c *gin.Context) {
	// TODO: F-02 下書き更新機能実装
	// - 下書き内容更新
	// - 再トーン変換オプション
	c.JSON(http.StatusNotImplemented, gin.H{
		"message": "F-02: 下書き更新機能 - 実装予定",
		"feature": "message-drafts",
	})
}

// DeleteDraft 下書き削除
// DELETE /api/v1/drafts/:id
func (h *DraftHandler) DeleteDraft(c *gin.Context) {
	// TODO: F-02 下書き削除機能実装
	// - 下書き削除
	// - 関連スケジュールも削除
	c.JSON(http.StatusNotImplemented, gin.H{
		"message": "F-02: 下書き削除機能 - 実装予定",
		"feature": "message-drafts",
	})
}

// TransformTone トーン変換
// POST /api/v1/drafts/:id/transform
func (h *DraftHandler) TransformTone(c *gin.Context) {
	// TODO: F-02 トーン変換機能実装
	// - Anthropic API呼び出し
	// - プロンプトテンプレート適用
	// - 変換結果返却
	c.JSON(http.StatusNotImplemented, gin.H{
		"message": "F-02: トーン変換機能 - 実装予定",
		"feature": "message-drafts",
		"tones":   []string{"gentle", "constructive", "casual"},
	})
}