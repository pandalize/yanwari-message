<template>
  <div class="modal-overlay" @click="$emit('close')">
    <div class="modal-content" @click.stop>
      <div class="modal-header">
        <h3>📧 メッセージ詳細</h3>
        <button @click="$emit('close')" class="close-btn">✕</button>
      </div>

      <div class="modal-body">
        <!-- 送信者情報 -->
        <div class="sender-section">
          <div class="section-header">
            <span class="icon">👤</span>
            <span class="label">送信者</span>
          </div>
          <div class="sender-info">
            <div class="sender-main-info">
              <span class="sender-name">{{ message.senderName || '名前未設定' }}</span>
              <span class="sender-email">{{ message.senderEmail || 'unknown@example.com' }}</span>
            </div>
            <span class="sent-time">{{ formatSentTime(message.sentAt) }}</span>
          </div>
        </div>

        <!-- メッセージ本文 -->
        <div class="message-section">
          <div class="section-header">
            <span class="icon">💬</span>
            <span class="label">メッセージ</span>
          </div>
          
          <div class="message-content">
            <div class="final-message">
              {{ message.finalText || message.originalText }}
            </div>
          </div>
        </div>
      </div>

      <div class="modal-footer">
        <div class="footer-actions">
          <button 
            v-if="message.status !== 'read'"
            @click="markAsRead"
            :disabled="isMarkingRead"
            class="mark-read-btn"
          >
            {{ isMarkingRead ? '既読中...' : '既読にする' }}
          </button>
          
          <button @click="$emit('close')" class="close-modal-btn">
            閉じる
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import { useInboxStore } from '../../stores/inbox'
import { inboxService, type ReceivedMessage } from '../../services/inboxService'

interface Props {
  message: ReceivedMessage
}

interface Emits {
  (e: 'close'): void
  (e: 'marked-as-read', messageId: string): void
}

const props = defineProps<Props>()
const emit = defineEmits<Emits>()

const inboxStore = useInboxStore()
const isMarkingRead = ref(false)

// メソッド
const markAsRead = async () => {
  if (isMarkingRead.value) return
  
  isMarkingRead.value = true
  
  try {
    await inboxStore.markAsRead(props.message.id)
    emit('marked-as-read', props.message.id)
  } catch (error) {
    console.error('既読処理エラー:', error)
  } finally {
    isMarkingRead.value = false
  }
}

// ヘルパー関数
const formatSentTime = (sentAt?: string) => {
  return sentAt ? inboxService.formatSentTime(sentAt) : ''
}
</script>

<style scoped>
.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.5);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
  padding: 2rem;
}

.modal-content {
  background: white;
  border-radius: 16px;
  width: 100%;
  max-width: 600px;
  max-height: 90vh;
  overflow-y: auto;
  box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
}

.modal-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 1.5rem 2rem;
  border-bottom: 1px solid #e0e0e0;
}

.modal-header h3 {
  margin: 0;
  color: #333;
}

.close-btn {
  background: none;
  border: none;
  font-size: 1.5rem;
  cursor: pointer;
  padding: 0.5rem;
  border-radius: 50%;
  width: 2.5rem;
  height: 2.5rem;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: background-color 0.3s ease;
}

.close-btn:hover {
  background: #f8f9fa;
}

.modal-body {
  padding: 2rem;
}

.sender-section,
.message-section {
  margin-bottom: 2rem;
}

.section-header {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  margin-bottom: 1rem;
  font-weight: 600;
  color: #333;
}

.icon {
  font-size: 1.25rem;
}

.label {
  font-size: 1.1rem;
}


.sender-info {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 1rem;
  background: #f8f9fa;
  border-radius: 8px;
}

.sender-main-info {
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
}

.sender-name {
  font-weight: 600;
  color: #1a1a1a;
  font-size: 1.125rem;
}

.sender-email {
  color: #757575;
  font-size: 0.875rem;
}

.sender-id {
  font-weight: 600;
  color: #333;
}

.sent-time {
  color: #6c757d;
  font-size: 0.875rem;
}

.message-content {
  background: #f8f9fa;
  border-radius: 8px;
  padding: 1.5rem;
}

.final-message {
  font-size: 1.1rem;
  line-height: 1.6;
  color: #333;
  margin-bottom: 1rem;
}


.modal-footer {
  padding: 1.5rem 2rem;
  border-top: 1px solid #e0e0e0;
  background: #f8f9fa;
  border-radius: 0 0 16px 16px;
}

.footer-actions {
  display: flex;
  justify-content: flex-end;
  gap: 1rem;
}

.mark-read-btn {
  padding: 0.75rem 1.5rem;
  background: #28a745;
  color: white;
  border: none;
  border-radius: 8px;
  cursor: pointer;
  font-weight: 500;
  transition: background-color 0.3s ease;
}

.mark-read-btn:hover:not(:disabled) {
  background: #218838;
}

.mark-read-btn:disabled {
  background: #6c757d;
  cursor: not-allowed;
}

.close-modal-btn {
  padding: 0.75rem 1.5rem;
  background: #6c757d;
  color: white;
  border: none;
  border-radius: 8px;
  cursor: pointer;
  font-weight: 500;
  transition: background-color 0.3s ease;
}

.close-modal-btn:hover {
  background: #545b62;
}

@media (max-width: 768px) {
  .modal-overlay {
    padding: 1rem;
  }
  
  .modal-header,
  .modal-body,
  .modal-footer {
    padding: 1rem;
  }
  
  .sender-info {
    flex-direction: column;
    align-items: stretch;
    gap: 0.5rem;
  }
  
  .timestamp-item {
    flex-direction: column;
    align-items: stretch;
    gap: 0.25rem;
  }
  
  .footer-actions {
    flex-direction: column;
  }
}
</style>