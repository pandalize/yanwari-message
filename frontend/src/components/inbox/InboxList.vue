<template>
  <div class="inbox-list">
    <div class="inbox-header">
      <h2>📫 受信トレイ</h2>
      <div class="header-actions">
        <div class="unread-count" v-if="inboxStore.unreadCount > 0">
          <span class="count-badge">{{ inboxStore.unreadCount }}</span>
          <span>件の未読</span>
        </div>
        <button @click="inboxStore.refresh()" :disabled="inboxStore.isLoading" class="refresh-btn">
          <span class="refresh-icon" :class="{ spinning: inboxStore.isLoading }">🔄</span>
          更新
        </button>
      </div>
    </div>

    <!-- ローディング状態 -->
    <div v-if="inboxStore.isLoading" class="loading-state">
      <div class="spinner"></div>
      <p>メッセージを読み込み中...</p>
    </div>

    <!-- エラー状態 -->
    <div v-else-if="inboxStore.error" class="error-state">
      <p>❌ {{ inboxStore.error }}</p>
      <button @click="inboxStore.refresh()" class="retry-btn">再試行</button>
    </div>

    <!-- メッセージ一覧 -->
    <div v-else-if="inboxStore.messages.length > 0" class="messages-container">
      <div 
        v-for="message in inboxStore.messages" 
        :key="message.id"
        @click="openMessage(message)"
        class="message-item"
        :class="{ 
          'unread': message.status !== 'read',
          'read': message.status === 'read'
        }"
      >
        <div class="message-header">
          <div class="sender-info">
            <span class="sender-icon">{{ getSenderInitial(message) }}</span>
            <div class="sender-details">
              <span class="sender-name">{{ message.senderName || '名前未設定' }}</span>
              <span class="sender-email">{{ message.senderEmail || 'unknown@example.com' }}</span>
            </div>
          </div>
          <div class="message-meta">
            <span class="status-badge" :class="`status-${getStatusBadge(message.status).color}`">
              {{ getStatusBadge(message.status).text }}
            </span>
            <span class="sent-time">{{ formatSentTime(message.sentAt) }}</span>
          </div>
        </div>

        <div class="message-content">
          <div class="message-text">
            {{ message.finalText || message.originalText }}
          </div>
          <div class="message-details" v-if="message.selectedTone">
            <span class="tone-badge" :class="`tone-${message.selectedTone}`">
              🎭 {{ getToneLabel(message.selectedTone) }}
            </span>
          </div>
        </div>

        <div class="message-actions" v-if="message.status !== 'read'">
          <button 
            @click.stop="markAsRead(message.id)"
            class="mark-read-btn"
            :disabled="isMarkingRead === message.id"
          >
            {{ isMarkingRead === message.id ? '既読中...' : '既読にする' }}
          </button>
        </div>
      </div>

      <!-- ページネーション -->
      <div class="pagination" v-if="inboxStore.totalPages > 1">
        <button 
          @click="inboxStore.prevPage()" 
          :disabled="!inboxStore.hasPrevPage || inboxStore.isLoading"
          class="page-btn"
        >
          ← 前へ
        </button>
        
        <span class="page-info">
          {{ inboxStore.currentPage }} / {{ inboxStore.totalPages }} ページ
          ({{ inboxStore.totalMessages }} 件)
        </span>
        
        <button 
          @click="inboxStore.nextPage()" 
          :disabled="!inboxStore.hasNextPage || inboxStore.isLoading"
          class="page-btn"
        >
          次へ →
        </button>
      </div>
    </div>

    <!-- 空の状態 -->
    <div v-else class="empty-state">
      <div class="empty-icon">📭</div>
      <h3>受信メッセージはありません</h3>
      <p>まだメッセージを受信していません。<br>誰かからやんわり伝言が届くのを待ちましょう！</p>
    </div>

    <!-- メッセージ詳細モーダル -->
    <MessageDetailModal 
      v-if="selectedMessage"
      :message="selectedMessage"
      @close="selectedMessage = null"
      @marked-as-read="handleMarkedAsRead"
    />
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useInboxStore } from '../../stores/inbox'
import { inboxService, type ReceivedMessage } from '../../services/inboxService'
import MessageDetailModal from './MessageDetailModal.vue'

const inboxStore = useInboxStore()
const selectedMessage = ref<ReceivedMessage | null>(null)
const isMarkingRead = ref<string | null>(null)

// メッセージを開く
const openMessage = (message: ReceivedMessage) => {
  selectedMessage.value = message
  
  // 未読の場合は自動的に既読にする
  if (message.status !== 'read') {
    markAsRead(message.id, false) // モーダル内で既読処理するのでここでは無音で実行
  }
}

// 既読にする
const markAsRead = async (messageId: string, showFeedback = true) => {
  if (isMarkingRead.value === messageId) return
  
  isMarkingRead.value = messageId
  
  try {
    await inboxStore.markAsRead(messageId)
    if (showFeedback) {
      // 既読成功の視覚フィードバック（必要に応じて）
    }
  } catch (error) {
    console.error('既読処理エラー:', error)
  } finally {
    isMarkingRead.value = null
  }
}

// 既読処理完了時のハンドラ
const handleMarkedAsRead = (messageId: string) => {
  // 必要に応じて追加の処理
}

// ヘルパー関数
const getStatusBadge = inboxService.getStatusBadge
const getToneLabel = inboxService.getToneLabel
const formatSentTime = (sentAt?: string) => {
  return sentAt ? inboxService.formatSentTime(sentAt) : ''
}

// 送信者のイニシャルを取得
const getSenderInitial = (message: ReceivedMessage) => {
  if (message.senderName) {
    return message.senderName.charAt(0).toUpperCase()
  } else if (message.senderEmail) {
    return message.senderEmail.charAt(0).toUpperCase()
  }
  return '?'
}

// 初期化
onMounted(() => {
  inboxStore.fetchMessages()
})
</script>

<style scoped>
.inbox-list {
  background: #f8f9fa;
  min-height: 100vh;
  padding: var(--spacing-3xl) 5%;
}

@media (min-width: 768px) {
  .inbox-list {
    padding: var(--spacing-3xl) 10%;
  }
}

@media (min-width: 1200px) {
  .inbox-list {
    padding: var(--spacing-3xl) 15%;
  }
}

@media (min-width: 1600px) {
  .inbox-list {
    padding: var(--spacing-3xl) 20%;
  }
}

.inbox-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 2rem;
  padding: 1.5rem;
  background: white;
  border-radius: 16px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.06);
}

.inbox-header h2 {
  margin: 0;
  color: #1a1a1a;
  font-size: 1.75rem;
  font-weight: 700;
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.header-actions {
  display: flex;
  align-items: center;
  gap: 1rem;
}

.unread-count {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  background: #fff3e0;
  padding: 0.5rem 1rem;
  border-radius: 12px;
  color: #f57c00;
  font-weight: 500;
}

.count-badge {
  background: #ff6b6b;
  color: white;
  padding: 0.25rem 0.75rem;
  border-radius: 20px;
  font-size: 0.875rem;
  font-weight: 700;
  min-width: 1.5rem;
  text-align: center;
  box-shadow: 0 2px 4px rgba(255, 107, 107, 0.2);
}

.refresh-btn {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.75rem 1.25rem;
  background: #4285f4;
  color: white;
  border: none;
  border-radius: 12px;
  cursor: pointer;
  font-weight: 500;
  transition: all 0.3s ease;
  box-shadow: 0 2px 4px rgba(66, 133, 244, 0.2);
}

.refresh-btn:hover:not(:disabled) {
  background: #3367d6;
  transform: translateY(-1px);
  box-shadow: 0 4px 8px rgba(66, 133, 244, 0.3);
}

.refresh-btn:disabled {
  background: #e0e0e0;
  color: #9e9e9e;
  cursor: not-allowed;
  box-shadow: none;
}

.refresh-icon.spinning {
  animation: spin 1s linear infinite;
}

@keyframes spin {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}

.loading-state {
  text-align: center;
  padding: 5rem 2rem;
  background: white;
  border-radius: 16px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.06);
}

.spinner {
  width: 48px;
  height: 48px;
  border: 4px solid #f3f3f3;
  border-top: 4px solid #4285f4;
  border-radius: 50%;
  animation: spin 1s linear infinite;
  margin: 0 auto 1.5rem;
}

.loading-state p {
  color: #757575;
  font-size: 1rem;
  font-weight: 500;
}

.error-state {
  text-align: center;
  padding: 5rem 2rem;
  background: white;
  border-radius: 16px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.06);
}

.error-state p {
  color: #d32f2f;
  font-size: 1.125rem;
  margin-bottom: 1.5rem;
  font-weight: 500;
}

.retry-btn {
  padding: 0.75rem 1.5rem;
  background: #d32f2f;
  color: white;
  border: none;
  border-radius: 10px;
  cursor: pointer;
  font-weight: 500;
  transition: all 0.3s ease;
  box-shadow: 0 2px 4px rgba(211, 47, 47, 0.2);
}

.retry-btn:hover {
  background: #b71c1c;
  transform: translateY(-1px);
  box-shadow: 0 4px 8px rgba(211, 47, 47, 0.3);
}

.messages-container {
  space-y: 1rem;
}

.message-item {
  background: white;
  border: none;
  border-radius: 16px;
  padding: 1.75rem;
  cursor: pointer;
  transition: all 0.3s ease;
  margin-bottom: 1rem;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.04);
  position: relative;
  overflow: hidden;
}

.message-item:hover {
  transform: translateY(-2px);
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.08);
}

.message-item.unread {
  background: linear-gradient(135deg, #ffffff 0%, #f0f7ff 100%);
  box-shadow: 0 2px 12px rgba(66, 133, 244, 0.15);
}

.message-item.unread::before {
  content: '';
  position: absolute;
  left: 0;
  top: 0;
  bottom: 0;
  width: 4px;
  background: #4285f4;
}

.message-item.read {
  background: white;
  opacity: 0.85;
}

.message-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 1rem;
}

.sender-info {
  display: flex;
  align-items: center;
  gap: 0.75rem;
}

.sender-icon {
  width: 40px;
  height: 40px;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 1.25rem;
  color: white;
  flex-shrink: 0;
}

.sender-details {
  display: flex;
  flex-direction: column;
  gap: 0.125rem;
}

.sender-name {
  font-weight: 600;
  color: #1a1a1a;
  font-size: 1rem;
}

.sender-email {
  font-size: 0.875rem;
  color: #757575;
}

.message-meta {
  display: flex;
  flex-direction: column;
  align-items: flex-end;
  gap: 0.5rem;
}

.status-badge {
  padding: 0.375rem 0.875rem;
  border-radius: 20px;
  font-size: 0.75rem;
  font-weight: 600;
  letter-spacing: 0.025em;
}

.status-blue { 
  background: #e3f2fd; 
  color: #1565c0; 
}
.status-green { 
  background: #e8f5e8; 
  color: #2e7d32; 
}
.status-gray { 
  background: #f5f5f5; 
  color: #616161; 
}

.sent-time {
  color: #9e9e9e;
  font-size: 0.875rem;
  font-weight: 400;
}

.message-content {
  margin-bottom: 1rem;
  padding-left: 3.25rem;
}

.message-text {
  color: #424242;
  font-size: 1rem;
  line-height: 1.6;
  margin-bottom: 0.75rem;
  display: -webkit-box;
  -webkit-line-clamp: 3;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

.message-details {
  display: flex;
  align-items: center;
  gap: 0.75rem;
}

.tone-badge {
  padding: 0.375rem 0.75rem;
  border-radius: 16px;
  font-size: 0.75rem;
  font-weight: 600;
  display: inline-flex;
  align-items: center;
  gap: 0.25rem;
}

.tone-gentle { 
  background: #f3e5f5; 
  color: #7b1fa2; 
}
.tone-constructive { 
  background: #e8f5e8; 
  color: #2e7d32; 
}
.tone-casual { 
  background: #fff3e0; 
  color: #e65100; 
}

.message-actions {
  text-align: right;
  padding-left: 3.25rem;
}

.mark-read-btn {
  padding: 0.625rem 1.25rem;
  background: #34a853;
  color: white;
  border: none;
  border-radius: 10px;
  cursor: pointer;
  font-size: 0.875rem;
  font-weight: 500;
  transition: all 0.3s ease;
  box-shadow: 0 2px 4px rgba(52, 168, 83, 0.2);
}

.mark-read-btn:hover:not(:disabled) {
  background: #2d8e47;
  transform: translateY(-1px);
  box-shadow: 0 4px 8px rgba(52, 168, 83, 0.3);
}

.mark-read-btn:disabled {
  background: #e0e0e0;
  color: #9e9e9e;
  cursor: not-allowed;
  box-shadow: none;
}

.pagination {
  display: flex;
  justify-content: center;
  align-items: center;
  gap: 1rem;
  margin-top: 3rem;
  padding: 1.5rem;
  background: white;
  border-radius: 16px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.06);
}

.page-btn {
  padding: 0.75rem 1.5rem;
  background: white;
  color: #4285f4;
  border: 2px solid #4285f4;
  border-radius: 10px;
  cursor: pointer;
  font-weight: 500;
  transition: all 0.3s ease;
}

.page-btn:hover:not(:disabled) {
  background: #4285f4;
  color: white;
  transform: translateY(-1px);
  box-shadow: 0 4px 8px rgba(66, 133, 244, 0.2);
}

.page-btn:disabled {
  background: #f5f5f5;
  color: #bdbdbd;
  border-color: #e0e0e0;
  cursor: not-allowed;
}

.page-info {
  color: #757575;
  font-size: 0.875rem;
  font-weight: 500;
  padding: 0 1rem;
}

.empty-state {
  text-align: center;
  padding: 5rem 2rem;
  background: white;
  border-radius: 16px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.06);
}

.empty-icon {
  font-size: 5rem;
  margin-bottom: 1.5rem;
  filter: grayscale(20%);
}

.empty-state h3 {
  margin: 1rem 0;
  color: #1a1a1a;
  font-size: 1.5rem;
  font-weight: 600;
}

.empty-state p {
  line-height: 1.8;
  color: #757575;
  font-size: 1rem;
  max-width: 400px;
  margin: 0 auto;
}

/* モバイル表示 */
@media (max-width: 767px) {
  
  .inbox-header {
    flex-direction: column;
    gap: var(--spacing-lg);
    align-items: stretch;
    padding: var(--spacing-lg);
  }
  
  .header-actions {
    justify-content: space-between;
  }
  
  .message-item {
    padding: var(--spacing-lg);
  }
  
  .message-header {
    flex-direction: column;
    gap: var(--spacing-sm);
    align-items: stretch;
  }
  
  .message-meta {
    justify-content: space-between;
  }
  
  .sender-icon {
    width: 32px;
    height: 32px;
  }
  
  .message-content {
    padding-left: 0;
    margin-top: var(--spacing-sm);
  }
  
  .message-actions {
    padding-left: 0;
  }
  
  .pagination {
    flex-direction: column;
    gap: var(--spacing-sm);
  }
}

/* 小さいモバイル表示 */
@media (max-width: 479px) {
  
  .inbox-header {
    padding: var(--spacing-md);
  }
  
  .inbox-header h2 {
    font-size: 1.5rem;
  }
  
  .message-item {
    padding: var(--spacing-md);
  }
  
  .sender-details {
    gap: 0.125rem;
  }
  
  .sender-name {
    font-size: 0.875rem;
  }
  
  .sender-email {
    font-size: 0.75rem;
  }
  
  .message-text {
    font-size: 0.875rem;
    -webkit-line-clamp: 2;
  }
}
</style>