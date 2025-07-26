package services

import (
	"context"
	"log"
	"time"

	"yanwari-message-backend/models"
)

// DeliveryService メッセージ配信サービス
type DeliveryService struct {
	messageService *models.MessageService
	ticker         *time.Ticker
	done           chan bool
}

// NewDeliveryService 配信サービスを作成
func NewDeliveryService(messageService *models.MessageService) *DeliveryService {
	return &DeliveryService{
		messageService: messageService,
		done:           make(chan bool),
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
	// TODO: 実際の配信処理を実装
	// - メール送信
	// - プッシュ通知
	// - SMS送信
	// - その他外部API連携
	
	log.Printf("受信者配信処理: メッセージID=%s, 受信者ID=%s, 内容=%s", 
		msg.ID.Hex(), 
		msg.RecipientID.Hex(),
		truncateText(msg.FinalText, 50))
	
	// 現在はログ出力のみ（実際の外部配信は将来実装）
	// ここで受信者への実際の通知を行う
	
	// ステータスをdeliveredに更新
	err := s.messageService.UpdateMessageStatus(ctx, msg.ID, models.MessageStatusDelivered)
	if err != nil {
		return err
	}
	
	return nil
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