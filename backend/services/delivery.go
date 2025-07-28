package services

import (
	"context"
	"log"
	"strings"
	"time"

	"yanwari-message-backend/models"
)

// DeliveryService メッセージ配信サービス
type DeliveryService struct {
	messageService  *models.MessageService
	scheduleService *models.ScheduleService
	ticker          *time.Ticker
	done            chan bool
}

// NewDeliveryService 配信サービスを作成
func NewDeliveryService(messageService *models.MessageService, scheduleService *models.ScheduleService) *DeliveryService {
	return &DeliveryService{
		messageService:  messageService,
		scheduleService: scheduleService,
		done:            make(chan bool),
	}
}

// Start バックグラウンド配信エンジンを開始
func (s *DeliveryService) Start(interval time.Duration) {
	log.Printf("配信エンジンを開始しました（間隔: %v）", interval)
	
	s.ticker = time.NewTicker(interval)
	
	go func() {
		for {
			select {
			case <-s.ticker.C:
				s.processScheduledMessages()
			case <-s.done:
				s.ticker.Stop()
				log.Println("配信エンジンを停止しました")
				return
			}
		}
	}()
}

// Stop バックグラウンド配信エンジンを停止
func (s *DeliveryService) Stop() {
	if s.ticker != nil {
		s.done <- true
	}
}

// processScheduledMessages スケジュールされたメッセージを処理
func (s *DeliveryService) processScheduledMessages() {
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	messages, err := s.messageService.DeliverScheduledMessages(ctx)
	if err != nil {
		log.Printf("スケジュール配信エラー: %v", err)
		return
	}

	if len(messages) > 0 {
		log.Printf("配信開始: %d件のメッセージを配信中...", len(messages))
		
		// 各メッセージについて実際の配信処理を実行
		for _, msg := range messages {
			err := s.deliverMessageToRecipient(ctx, msg)
			if err != nil {
				log.Printf("配信エラー: ID=%s, エラー=%v", msg.ID.Hex(), err)
				// エラーが発生した場合、メッセージのステータスを戻すことも検討
				continue
			}
			
			log.Printf("配信成功: ID=%s, 受信者=%s, 送信日時=%v", 
				msg.ID.Hex(), 
				msg.RecipientID.Hex(),
				msg.SentAt.Format("2006-01-02 15:04:05"))
		}
		
		log.Printf("配信完了: %d件のメッセージ処理完了", len(messages))
	}
}

// deliverMessageToRecipient メッセージを受信者に実際に配信
func (s *DeliveryService) deliverMessageToRecipient(ctx context.Context, msg models.Message) error {
	// 配信処理の詳細ログ
	log.Printf("📤 配信開始: ID=%s, 受信者=%s, 内容=%s", 
		msg.ID.Hex(), 
		msg.RecipientID.Hex(),
		truncateText(msg.FinalText, 50))
	
	// 配信試行回数の制限チェック（将来の再試行機能用）
	// TODO: メッセージモデルにretryCountフィールドを追加することを検討
	// maxRetries := 3
	
	// 実際の配信処理を実行
	deliveryError := s.performDelivery(ctx, &msg)
	
	if deliveryError != nil {
		// 配信エラー時の処理
		log.Printf("❌ 配信エラー: ID=%s, エラー=%v", msg.ID.Hex(), deliveryError)
		
		// エラーの種類に応じて処理を分岐
		if isRetryableError(deliveryError) {
			// 再試行可能なエラーの場合
			log.Printf("🔄 再試行可能エラー: ID=%s, %s", msg.ID.Hex(), deliveryError.Error())
			// メッセージのステータスはsentのまま維持（次回のバックグラウンド処理で再試行）
			return deliveryError
		} else {
			// 再試行不可能なエラーの場合
			log.Printf("💀 致命的エラー: ID=%s, %s", msg.ID.Hex(), deliveryError.Error())
			// ステータスを失敗に更新
			if err := s.messageService.UpdateMessageStatus(ctx, msg.ID, models.MessageStatusSent); err != nil {
				log.Printf("ステータス更新エラー: %v", err)
			}
			return deliveryError
		}
	}
	
	// 配信成功時の処理
	log.Printf("✅ 配信成功: ID=%s, 受信者=%s", msg.ID.Hex(), msg.RecipientID.Hex())
	
	// ステータスをdeliveredに更新
	err := s.messageService.UpdateMessageStatus(ctx, msg.ID, models.MessageStatusDelivered)
	if err != nil {
		log.Printf("ステータス更新エラー: ID=%s, エラー=%v", msg.ID.Hex(), err)
		return err
	}
	
	// スケジュールのステータスを送信済みに更新
	if s.scheduleService != nil {
		if err := s.scheduleService.UpdateScheduleStatusByMessageID(ctx, msg.ID, "sent"); err != nil {
			log.Printf("スケジュールステータス更新エラー: MessageID=%s, エラー=%v", msg.ID.Hex(), err)
		} else {
			log.Printf("📅 スケジュールステータス更新成功: MessageID=%s → sent", msg.ID.Hex())
		}
	}
	
	// 送信者への送信完了通知を実行
	s.notifySenderOfDelivery(ctx, &msg)
	
	return nil
}

// performDelivery 実際の配信処理を実行
func (s *DeliveryService) performDelivery(ctx context.Context, msg *models.Message) error {
	// TODO: 実際の配信処理を実装
	// - メール送信
	// - プッシュ通知
	// - SMS送信
	// - Webhook呼び出し
	// - 外部API連携
	
	// 現在は成功として扱う（将来の外部サービス連携のため）
	log.Printf("📧 実際の配信処理実行中... (現在はログ出力のみ)")
	
	// シミュレーション: 10%の確率でエラーを発生させる（テスト用）
	// if rand.Float32() < 0.1 {
	//     return fmt.Errorf("シミュレーション配信エラー")
	// }
	
	return nil
}

// isRetryableError エラーが再試行可能かどうか判定
func isRetryableError(err error) bool {
	// 再試行可能エラーの条件
	errorMsg := err.Error()
	
	// ネットワーク関連エラー
	if strings.Contains(errorMsg, "connection") ||
	   strings.Contains(errorMsg, "timeout") ||
	   strings.Contains(errorMsg, "temporary") {
		return true
	}
	
	// レート制限エラー
	if strings.Contains(errorMsg, "rate limit") ||
	   strings.Contains(errorMsg, "too many requests") {
		return true
	}
	
	// サーバーエラー（5xx）
	if strings.Contains(errorMsg, "server error") ||
	   strings.Contains(errorMsg, "service unavailable") {
		return true
	}
	
	// デフォルトは再試行不可
	return false
}

// notifySenderOfDelivery 送信者に配信完了を通知
func (s *DeliveryService) notifySenderOfDelivery(ctx context.Context, msg *models.Message) {
	// TODO: 送信者への通知実装
	// - プッシュ通知
	// - メール通知
	// - アプリ内通知
	// - WebSocket/SSE通知
	
	log.Printf("📬 送信者通知: 送信者=%s, メッセージ配信完了", msg.SenderID.Hex())
}

// truncateText テキストを指定文字数で切り詰め
func truncateText(text string, maxLen int) string {
	if len(text) <= maxLen {
		return text
	}
	return text[:maxLen] + "..."
}

// DeliverNow 即座にスケジュール配信を実行（手動実行用）
func (s *DeliveryService) DeliverNow() (int, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	messages, err := s.messageService.DeliverScheduledMessages(ctx)
	if err != nil {
		return 0, err
	}

	log.Printf("手動配信完了: %d件のメッセージを配信しました", len(messages))
	return len(messages), nil
}