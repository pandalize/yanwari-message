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
		log.Printf("配信完了: %d件のメッセージを配信しました", len(messages))
		
		// 配信されたメッセージをログに記録
		for _, msg := range messages {
			log.Printf("配信済み: ID=%s, 受信者=%s, 送信日時=%v", 
				msg.ID.Hex(), 
				msg.RecipientID.Hex(),
				msg.SentAt.Format("2006-01-02 15:04:05"))
		}
	}
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