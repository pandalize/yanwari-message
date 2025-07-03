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
            <span class="sender-icon">👤</span>
            <span class="sender-id">{{ message.senderId }}</span>
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

// 初期化
onMounted(() => {
  inboxStore.fetchMessages()
})
</script>

<style scoped>
.inbox-list {
  max-width: 800px;
  margin: 0 auto;
  padding: 2rem;
}

.inbox-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 2rem;
  padding-bottom: 1rem;
  border-bottom: 2px solid #e0e0e0;
}

.inbox-header h2 {
  margin: 0;
  color: #333;
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
  color: #666;
}

.count-badge {
  background: #dc3545;
  color: white;
  padding: 0.25rem 0.5rem;
  border-radius: 12px;
  font-size: 0.875rem;
  font-weight: 600;
  min-width: 1.5rem;
  text-align: center;
}

.refresh-btn {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.5rem 1rem;
  background: #007bff;
  color: white;
  border: none;
  border-radius: 6px;
  cursor: pointer;
  transition: background-color 0.3s ease;
}

.refresh-btn:hover:not(:disabled) {
  background: #0056b3;
}

.refresh-btn:disabled {
  background: #6c757d;
  cursor: not-allowed;
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
  padding: 3rem;
}

.spinner {
  width: 40px;
  height: 40px;
  border: 3px solid #f3f3f3;
  border-top: 3px solid #007bff;
  border-radius: 50%;
  animation: spin 1s linear infinite;
  margin: 0 auto 1rem;
}

.error-state {
  text-align: center;
  padding: 3rem;
  color: #dc3545;
}

.retry-btn {
  margin-top: 1rem;
  padding: 0.5rem 1rem;
  background: #dc3545;
  color: white;
  border: none;
  border-radius: 6px;
  cursor: pointer;
}

.messages-container {
  space-y: 1rem;
}

.message-item {
  background: white;
  border: 1px solid #e0e0e0;
  border-radius: 12px;
  padding: 1.5rem;
  cursor: pointer;
  transition: all 0.3s ease;
  margin-bottom: 1rem;
}

.message-item:hover {
  border-color: #007bff;
  box-shadow: 0 2px 8px rgba(0, 123, 255, 0.15);
}

.message-item.unread {
  border-left: 4px solid #007bff;
  background: #f8f9ff;
}

.message-item.read {
  background: #f8f9fa;
  border-color: #dee2e6;
}

.message-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 1rem;
}

.sender-info {
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.sender-icon {
  font-size: 1.25rem;
}

.sender-id {
  font-weight: 600;
  color: #333;
}

.message-meta {
  display: flex;
  align-items: center;
  gap: 1rem;
}

.status-badge {
  padding: 0.25rem 0.75rem;
  border-radius: 16px;
  font-size: 0.75rem;
  font-weight: 500;
}

.status-blue { background: #cce7ff; color: #004085; }
.status-green { background: #d4edda; color: #155724; }
.status-gray { background: #f8f9fa; color: #6c757d; }

.sent-time {
  color: #6c757d;
  font-size: 0.875rem;
}

.message-content {
  margin-bottom: 1rem;
}

.message-text {
  color: #333;
  font-size: 1rem;
  line-height: 1.5;
  margin-bottom: 0.5rem;
}

.message-details {
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.tone-badge {
  padding: 0.25rem 0.5rem;
  border-radius: 12px;
  font-size: 0.75rem;
  font-weight: 500;
}

.tone-gentle { background: #f3e5f5; color: #7b1fa2; }
.tone-constructive { background: #e8f5e8; color: #2e7d32; }
.tone-casual { background: #fff3e0; color: #e65100; }

.message-actions {
  text-align: right;
}

.mark-read-btn {
  padding: 0.5rem 1rem;
  background: #28a745;
  color: white;
  border: none;
  border-radius: 6px;
  cursor: pointer;
  font-size: 0.875rem;
  transition: background-color 0.3s ease;
}

.mark-read-btn:hover:not(:disabled) {
  background: #218838;
}

.mark-read-btn:disabled {
  background: #6c757d;
  cursor: not-allowed;
}

.pagination {
  display: flex;
  justify-content: center;
  align-items: center;
  gap: 1rem;
  margin-top: 2rem;
  padding: 1rem;
}

.page-btn {
  padding: 0.5rem 1rem;
  background: #007bff;
  color: white;
  border: none;
  border-radius: 6px;
  cursor: pointer;
  transition: background-color 0.3s ease;
}

.page-btn:hover:not(:disabled) {
  background: #0056b3;
}

.page-btn:disabled {
  background: #6c757d;
  cursor: not-allowed;
}

.page-info {
  color: #6c757d;
  font-size: 0.875rem;
}

.empty-state {
  text-align: center;
  padding: 4rem 2rem;
  color: #6c757d;
}

.empty-icon {
  font-size: 4rem;
  margin-bottom: 1rem;
}

.empty-state h3 {
  margin: 1rem 0;
  color: #495057;
}

.empty-state p {
  line-height: 1.6;
}

@media (max-width: 768px) {
  .inbox-list {
    padding: 1rem;
  }
  
  .inbox-header {
    flex-direction: column;
    gap: 1rem;
    align-items: stretch;
  }
  
  .header-actions {
    justify-content: space-between;
  }
  
  .message-header {
    flex-direction: column;
    gap: 0.5rem;
    align-items: stretch;
  }
  
  .message-meta {
    justify-content: space-between;
  }
  
  .pagination {
    flex-direction: column;
    gap: 0.5rem;
  }
}
</style>