<template>
  <div class="message-with-rating">
    <div class="message-card" :class="{ 'message-unread': message.status !== 'read' }">
      <!-- メッセージヘッダー -->
      <div class="message-header">
        <div class="sender-info">
          <div class="sender-avatar">
            {{ getSenderInitial(message.senderName) }}
          </div>
          <div class="sender-details">
            <h4 class="sender-name">{{ message.senderName }}</h4>
            <p class="sender-email">{{ message.senderEmail }}</p>
          </div>
        </div>
        <div class="message-meta">
          <span class="message-date">{{ formatDate(message.createdAt) }}</span>
          <span class="message-status" :class="`status-${message.status}`">
            {{ getStatusText(message.status) }}
          </span>
        </div>
      </div>

      <!-- メッセージ内容 -->
      <div class="message-content">
        <div class="message-text">
          {{ message.finalText }}
        </div>
        <div v-if="message.originalText !== message.finalText" class="original-text">
          <details>
            <summary>元のメッセージを見る</summary>
            <p>{{ message.originalText }}</p>
          </details>
        </div>
      </div>

      <!-- 評価セクション -->
      <div class="rating-section">
        <div class="rating-header">
          <h5>このメッセージを評価</h5>
          <button
            v-if="message.rating"
            class="delete-rating-btn"
            @click="handleDeleteRating"
            :disabled="deletingRating"
            title="評価を削除"
          >
            <svg class="delete-icon" viewBox="0 0 20 20" fill="currentColor">
              <path fill-rule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" clip-rule="evenodd" />
            </svg>
          </button>
        </div>
        
        <StarRating
          v-model="currentRating"
          :loading="savingRating"
          @rate="handleRatingChange"
          size="medium"
          :show-label="true"
        />
        
        <div v-if="ratingError" class="rating-error">
          {{ ratingError }}
        </div>
        
        <div v-if="ratingSuccess" class="rating-success">
          評価を保存しました
        </div>
      </div>

      <!-- アクションボタン -->
      <div class="message-actions">
        <button
          v-if="message.status !== 'read'"
          class="mark-read-btn"
          @click="handleMarkAsRead"
          :disabled="markingAsRead"
        >
          <svg class="action-icon" viewBox="0 0 20 20" fill="currentColor">
            <path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd" />
          </svg>
          既読にする
        </button>
        
        <button class="reply-btn" @click="handleReply">
          <svg class="action-icon" viewBox="0 0 20 20" fill="currentColor">
            <path fill-rule="evenodd" d="M7.707 3.293a1 1 0 010 1.414L5.414 7H11a7 7 0 017 7v2a1 1 0 11-2 0v-2a5 5 0 00-5-5H5.414l2.293 2.293a1 1 0 11-1.414 1.414l-4-4a1 1 0 010-1.414l4-4a1 1 0 011.414 0z" clip-rule="evenodd" />
          </svg>
          返信
        </button>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, watch, nextTick } from 'vue'
import StarRating from './StarRating.vue'
import { ratingService, type InboxMessageWithRating } from '../../services/ratingService'

// Props
interface Props {
  message: InboxMessageWithRating
}

const props = defineProps<Props>()

// Events
const emit = defineEmits<{
  'rating-changed': [messageId: string, rating: number]
  'rating-deleted': [messageId: string]
  'mark-as-read': [messageId: string]
  'reply': [message: InboxMessageWithRating]
}>()

// State
const currentRating = ref<number>(props.message.rating || 0)
const savingRating = ref<boolean>(false)
const deletingRating = ref<boolean>(false)
const markingAsRead = ref<boolean>(false)
const ratingError = ref<string>('')
const ratingSuccess = ref<string>('')

// Watch for changes in message rating
watch(() => props.message.rating, (newRating) => {
  currentRating.value = newRating || 0
})

// Methods
const handleRatingChange = async (rating: number) => {
  if (savingRating.value) return
  
  savingRating.value = true
  ratingError.value = ''
  ratingSuccess.value = ''
  
  try {
    await ratingService.rateMessage(props.message.id, rating)
    emit('rating-changed', props.message.id, rating)
    
    ratingSuccess.value = '評価を保存しました'
    setTimeout(() => {
      ratingSuccess.value = ''
    }, 2000)
  } catch (error: any) {
    console.error('評価の保存に失敗:', error)
    ratingError.value = error.response?.data?.error || '評価の保存に失敗しました'
    // エラー時は元の評価に戻す
    currentRating.value = props.message.rating || 0
  } finally {
    savingRating.value = false
  }
}

const handleDeleteRating = async () => {
  if (deletingRating.value || !props.message.rating) return
  
  deletingRating.value = true
  ratingError.value = ''
  
  try {
    await ratingService.deleteMessageRating(props.message.id)
    currentRating.value = 0
    emit('rating-deleted', props.message.id)
    
    ratingSuccess.value = '評価を削除しました'
    setTimeout(() => {
      ratingSuccess.value = ''
    }, 2000)
  } catch (error: any) {
    console.error('評価の削除に失敗:', error)
    ratingError.value = error.response?.data?.error || '評価の削除に失敗しました'
  } finally {
    deletingRating.value = false
  }
}

const handleMarkAsRead = async () => {
  markingAsRead.value = true
  emit('mark-as-read', props.message.id)
  // Note: 実際のAPI呼び出しは親コンポーネントで行う
  setTimeout(() => {
    markingAsRead.value = false
  }, 1000)
}

const handleReply = () => {
  emit('reply', props.message)
}

// Utility functions
const getSenderInitial = (name: string): string => {
  return name ? name.charAt(0).toUpperCase() : '?'
}

const formatDate = (dateString: string): string => {
  const date = new Date(dateString)
  const now = new Date()
  const diffInHours = (now.getTime() - date.getTime()) / (1000 * 60 * 60)
  
  if (diffInHours < 24) {
    return date.toLocaleTimeString('ja-JP', { hour: '2-digit', minute: '2-digit' })
  } else if (diffInHours < 7 * 24) {
    return date.toLocaleDateString('ja-JP', { month: 'short', day: 'numeric' })
  } else {
    return date.toLocaleDateString('ja-JP', { year: 'numeric', month: 'short', day: 'numeric' })
  }
}

const getStatusText = (status: string): string => {
  const statusMap: Record<string, string> = {
    'delivered': '配信済み',
    'read': '既読',
    'sent': '送信済み'
  }
  return statusMap[status] || status
}
</script>

<style scoped>
.message-with-rating {
  margin-bottom: 16px;
}

.message-card {
  background: white;
  border: 1px solid #e5e7eb;
  border-radius: 12px;
  padding: 20px;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
  transition: all 0.2s ease;
}

.message-card.message-unread {
  border-left: 4px solid #3b82f6;
  background: #fafbff;
}

.message-card:hover {
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
}

.message-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 16px;
}

.sender-info {
  display: flex;
  align-items: center;
  gap: 12px;
}

.sender-avatar {
  width: 40px;
  height: 40px;
  border-radius: 50%;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  display: flex;
  align-items: center;
  justify-content: center;
  color: white;
  font-weight: 600;
  font-size: 16px;
}

.sender-details {
  display: flex;
  flex-direction: column;
}

.sender-name {
  margin: 0;
  font-size: 16px;
  font-weight: 600;
  color: #111827;
}

.sender-email {
  margin: 0;
  font-size: 14px;
  color: #6b7280;
}

.message-meta {
  display: flex;
  flex-direction: column;
  align-items: flex-end;
  gap: 4px;
}

.message-date {
  font-size: 12px;
  color: #9ca3af;
}

.message-status {
  font-size: 12px;
  padding: 2px 8px;
  border-radius: 12px;
  font-weight: 500;
}

.status-delivered {
  background: #dbeafe;
  color: #1e40af;
}

.status-read {
  background: #d1fae5;
  color: #065f46;
}

.status-sent {
  background: #fef3c7;
  color: #92400e;
}

.message-content {
  margin-bottom: 20px;
}

.message-text {
  font-size: 16px;
  line-height: 1.6;
  color: #374151;
  margin-bottom: 12px;
}

.original-text {
  margin-top: 8px;
}

.original-text details {
  cursor: pointer;
}

.original-text summary {
  font-size: 14px;
  color: #6b7280;
  margin-bottom: 8px;
}

.original-text p {
  background: #f9fafb;
  padding: 12px;
  border-radius: 8px;
  font-size: 14px;
  color: #6b7280;
  border-left: 3px solid #d1d5db;
  margin: 0;
}

.rating-section {
  border-top: 1px solid #e5e7eb;
  padding-top: 16px;
  margin-bottom: 16px;
}

.rating-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 12px;
}

.rating-header h5 {
  margin: 0;
  font-size: 14px;
  font-weight: 600;
  color: #374151;
}

.delete-rating-btn {
  background: none;
  border: none;
  color: #ef4444;
  cursor: pointer;
  padding: 4px;
  border-radius: 4px;
  transition: background-color 0.2s ease;
}

.delete-rating-btn:hover {
  background: #fef2f2;
}

.delete-rating-btn:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.delete-icon {
  width: 16px;
  height: 16px;
}

.rating-error {
  margin-top: 8px;
  padding: 8px;
  background: #fef2f2;
  color: #dc2626;
  font-size: 14px;
  border-radius: 6px;
  border: 1px solid #fecaca;
}

.rating-success {
  margin-top: 8px;
  padding: 8px;
  background: #f0fdf4;
  color: #16a34a;
  font-size: 14px;
  border-radius: 6px;
  border: 1px solid #bbf7d0;
}

.message-actions {
  border-top: 1px solid #e5e7eb;
  padding-top: 16px;
  display: flex;
  gap: 12px;
}

.mark-read-btn,
.reply-btn {
  display: flex;
  align-items: center;
  gap: 6px;
  padding: 8px 12px;
  border: 1px solid #d1d5db;
  background: white;
  color: #374151;
  border-radius: 6px;
  cursor: pointer;
  font-size: 14px;
  transition: all 0.2s ease;
}

.mark-read-btn:hover {
  background: #f3f4f6;
  border-color: #9ca3af;
}

.reply-btn:hover {
  background: #eff6ff;
  border-color: #3b82f6;
  color: #1d4ed8;
}

.action-icon {
  width: 16px;
  height: 16px;
}

/* レスポンシブ対応 */
@media (max-width: 768px) {
  .message-card {
    padding: 16px;
  }
  
  .message-header {
    flex-direction: column;
    gap: 12px;
  }
  
  .message-meta {
    align-items: flex-start;
  }
  
  .sender-info {
    width: 100%;
  }
  
  .message-actions {
    flex-direction: column;
  }
}

/* 440px以下の超小型モバイル対応 */
@media (max-width: 440px) {
  .message-with-rating {
    width: auto;
    max-width: calc(100vw - 24px);
    margin: 0 auto;
  }
  
  .message-card {
    padding: 12px;
    border-width: 1px;
  }
  
  .sender-avatar {
    width: 32px;
    height: 32px;
    font-size: 14px;
  }
  
  .sender-name {
    font-size: 14px;
  }
  
  .sender-email {
    font-size: 12px;
  }
  
  .message-date {
    font-size: 12px;
  }
  
  .message-status {
    font-size: 12px;
    padding: 2px 6px;
  }
  
  .message-text {
    font-size: 14px;
    line-height: 1.4;
  }
  
  .original-text {
    font-size: 13px;
  }
  
  .original-text summary {
    font-size: 12px;
  }
  
  .rating-header h5 {
    font-size: 14px;
  }
  
  .delete-rating-btn {
    padding: 4px;
  }
  
  .delete-icon {
    width: 14px;
    height: 14px;
  }
  
  .rating-error,
  .rating-success {
    font-size: 12px;
    padding: 6px;
  }
  
  .mark-read-btn,
  .reply-btn {
    padding: 6px 10px;
    font-size: 12px;
    gap: 4px;
  }
  
  .action-icon {
    width: 14px;
    height: 14px;
  }
}
</style>