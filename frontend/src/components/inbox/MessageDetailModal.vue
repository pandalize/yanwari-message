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
            <span 
              v-if="message.selectedTone" 
              class="tone-badge" 
              :class="`tone-${message.selectedTone}`"
            >
              🎭 {{ getToneLabel(message.selectedTone) }}
            </span>
          </div>
          
          <div class="message-content">
            <div class="final-message">
              {{ message.finalText || message.originalText }}
            </div>
            
            <!-- 元のメッセージが異なる場合は表示 -->
            <div 
              v-if="message.finalText && message.finalText !== message.originalText" 
              class="original-message"
            >
              <h4>📝 元のメッセージ</h4>
              <p>{{ message.originalText }}</p>
            </div>

            <!-- トーン変換のバリエーション -->
            <div v-if="hasVariations" class="variations-section">
              <h4>🎭 その他のトーン</h4>
              <div class="variations-list">
                <div 
                  v-for="(text, tone) in availableVariations" 
                  :key="tone"
                  class="variation-item"
                  :class="{ 'selected': tone === message.selectedTone }"
                >
                  <div class="variation-header">
                    <span class="tone-name">{{ getToneLabel(tone) }}</span>
                    <span v-if="tone === message.selectedTone" class="selected-badge">選択済み</span>
                  </div>
                  <div class="variation-text">{{ text }}</div>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- ステータス情報 -->
        <div class="status-section">
          <div class="section-header">
            <span class="icon">📊</span>
            <span class="label">ステータス</span>
          </div>
          <div class="status-info">
            <div class="status-item">
              <span class="status-badge" :class="`status-${getStatusBadge(message.status).color}`">
                {{ getStatusBadge(message.status).text }}
              </span>
            </div>
            <div class="timestamp-info">
              <div v-if="message.sentAt" class="timestamp-item">
                <span class="timestamp-label">配信日時:</span>
                <span class="timestamp-value">{{ formatFullTime(message.sentAt) }}</span>
              </div>
              <div v-if="message.readAt" class="timestamp-item">
                <span class="timestamp-label">既読日時:</span>
                <span class="timestamp-value">{{ formatFullTime(message.readAt) }}</span>
              </div>
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

// 計算プロパティ
const hasVariations = computed(() => {
  const variations = props.message.variations
  return variations && (variations.gentle || variations.constructive || variations.casual)
})

const availableVariations = computed(() => {
  const variations = props.message.variations
  const result: Record<string, string> = {}
  
  if (variations?.gentle) result.gentle = variations.gentle
  if (variations?.constructive) result.constructive = variations.constructive
  if (variations?.casual) result.casual = variations.casual
  
  return result
})

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
const getStatusBadge = inboxService.getStatusBadge
const getToneLabel = inboxService.getToneLabel

const formatSentTime = (sentAt?: string) => {
  return sentAt ? inboxService.formatSentTime(sentAt) : ''
}

const formatFullTime = (dateTime: string) => {
  const date = new Date(dateTime)
  return date.toLocaleString('ja-JP', {
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit'
  })
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
.message-section,
.status-section {
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

.tone-badge {
  padding: 0.25rem 0.75rem;
  border-radius: 16px;
  font-size: 0.75rem;
  font-weight: 500;
  margin-left: auto;
}

.tone-gentle { background: #f3e5f5; color: #7b1fa2; }
.tone-constructive { background: #e8f5e8; color: #2e7d32; }
.tone-casual { background: #fff3e0; color: #e65100; }

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

.original-message {
  margin-top: 1.5rem;
  padding-top: 1.5rem;
  border-top: 1px solid #dee2e6;
}

.original-message h4 {
  margin: 0 0 0.5rem 0;
  font-size: 0.9rem;
  color: #6c757d;
}

.original-message p {
  margin: 0;
  font-style: italic;
  color: #6c757d;
}

.variations-section {
  margin-top: 1.5rem;
  padding-top: 1.5rem;
  border-top: 1px solid #dee2e6;
}

.variations-section h4 {
  margin: 0 0 1rem 0;
  font-size: 0.9rem;
  color: #6c757d;
}

.variations-list {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.variation-item {
  padding: 1rem;
  border: 1px solid #dee2e6;
  border-radius: 8px;
  background: white;
}

.variation-item.selected {
  border-color: #007bff;
  background: #f8f9ff;
}

.variation-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 0.5rem;
}

.tone-name {
  font-weight: 600;
  color: #333;
}

.selected-badge {
  background: #007bff;
  color: white;
  padding: 0.25rem 0.5rem;
  border-radius: 12px;
  font-size: 0.75rem;
}

.variation-text {
  color: #555;
  line-height: 1.5;
}

.status-info {
  background: #f8f9fa;
  border-radius: 8px;
  padding: 1rem;
}

.status-item {
  margin-bottom: 1rem;
}

.status-badge {
  padding: 0.5rem 1rem;
  border-radius: 20px;
  font-weight: 500;
}

.status-blue { background: #cce7ff; color: #004085; }
.status-green { background: #d4edda; color: #155724; }
.status-gray { background: #f8f9fa; color: #6c757d; }

.timestamp-info {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.timestamp-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.timestamp-label {
  color: #6c757d;
  font-size: 0.875rem;
}

.timestamp-value {
  color: #333;
  font-size: 0.875rem;
  font-weight: 500;
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