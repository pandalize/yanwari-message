package handlers

import (
	"net/http"

	"github.com/gin-gonic/gin"
)

// ScheduleHandler スケジュール関連のハンドラー
type ScheduleHandler struct {
	// TODO: 依存関係を追加 (ScheduleService, QueueService など)
}

// NewScheduleHandler スケジュールハンドラーのコンストラクタ
func NewScheduleHandler() *ScheduleHandler {
	return &ScheduleHandler{}
}

// CreateSchedule スケジュール作成
// POST /api/v1/schedules
func (h *ScheduleHandler) CreateSchedule(c *gin.Context) {
	// TODO: F-03 スケジュール作成機能実装
	// - 下書きIDと送信時刻の受信
	// - ISO8601形式の時刻パース
	// - タイムゾーン変換 (UTC+TZ)
	// - 送信キューに登録
	c.JSON(http.StatusNotImplemented, gin.H{
		"message": "F-03: スケジュール作成機能 - 実装予定",
		"feature": "schedule-system",
	})
}

// GetSchedules スケジュール一覧取得
// GET /api/v1/schedules
func (h *ScheduleHandler) GetSchedules(c *gin.Context) {
	// TODO: F-03 スケジュール一覧機能実装
	// - ユーザーのスケジュール一覧取得
	// - ページネーション対応
	// - 状態フィルタリング (pending/sent/failed)
	c.JSON(http.StatusNotImplemented, gin.H{
		"message": "F-03: スケジュール一覧機能 - 実装予定",
		"feature": "schedule-system",
	})
}

// UpdateSchedule スケジュール更新
// PUT /api/v1/schedules/:id
func (h *ScheduleHandler) UpdateSchedule(c *gin.Context) {
	// TODO: F-03 スケジュール更新機能実装
	// - 送信時刻の変更
	// - 送信キューの更新
	// - 送信済みスケジュールは更新不可
	c.JSON(http.StatusNotImplemented, gin.H{
		"message": "F-03: スケジュール更新機能 - 実装予定",
		"feature": "schedule-system",
	})
}

// DeleteSchedule スケジュール削除
// DELETE /api/v1/schedules/:id
func (h *ScheduleHandler) DeleteSchedule(c *gin.Context) {
	// TODO: F-03 スケジュール削除機能実装
	// - スケジュール削除
	// - 送信キューからも削除
	// - 送信済みスケジュールは削除不可
	c.JSON(http.StatusNotImplemented, gin.H{
		"message": "F-03: スケジュール削除機能 - 実装予定",
		"feature": "schedule-system",
	})
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