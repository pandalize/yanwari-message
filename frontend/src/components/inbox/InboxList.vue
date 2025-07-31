<template>
  <div class="inbox-list">
    <!-- ページタイトル -->
    <div class="page-title">
      <h1>受信</h1>
    </div>

    <!-- メイン表示エリア -->
    <div class="main-display-area">
      <!-- 右上の表示切替ボタン -->
      <div class="view-toggle-container">
        <button 
          @click="toggleViewMode()" 
          class="view-toggle-btn"
        >
          {{ viewMode === 'treemap' ? '一覧' : 'ツリーマップ' }}
        </button>
      </div>

      <!-- メインコンテンツエリア -->
      <div class="main-content">
        <!-- ローディング状態 -->
        <div v-if="isLoading && messages.length === 0" class="loading-state">
          <div class="spinner"></div>
          <p>メッセージを読み込み中...</p>
        </div>

        <!-- エラー状態 -->
        <div v-else-if="error" class="error-state">
          <p>❌ {{ error }}</p>
          <button @click="refreshMessages()" class="retry-btn">再試行</button>
        </div>

        <!-- メッセージ一覧モード -->
        <div v-else-if="viewMode === 'list' && messages.length > 0" class="messages-list-view">
          <div 
            v-for="message in messages" 
            :key="message.id"
            @click="selectMessage(message)"
            class="message-list-item"
            :class="{ 
              'unread': message.status !== 'read',
              'read': message.status === 'read',
              'selected': selectedMessage?.id === message.id
            }"
          >
            <div class="message-preview">
              <div class="sender-name">{{ message.senderName || message.senderEmail || '不明' }}</div>
              <div class="message-snippet">{{ (message.finalText || message.originalText || '').substring(0, 50) }}...</div>
            </div>
            <div class="message-time">{{ formatSentTime(message.sentAt) }}</div>
          </div>

          <!-- ページネーション -->
          <div class="pagination" v-if="totalPages > 1">
            <button 
              @click="prevPage()" 
              :disabled="!hasPrevPage || isLoading"
              class="page-btn"
            >
              ← 前へ
            </button>
            
            <span class="page-info">
              {{ currentPage }} / {{ totalPages }} ページ
            </span>
            
            <button 
              @click="nextPage()" 
              :disabled="!hasNextPage || isLoading"
              class="page-btn"
            >
              次へ →
            </button>
          </div>
        </div>

        <!-- ツリーマップモード -->
        <div v-else-if="viewMode === 'treemap'" class="treemap-container">
          <TreemapView
            :messages="allMessages"
            @message-selected="selectMessage"
          />
          
          <div v-if="!isLoadingAll && allMessages.length < totalMessages" class="load-more-section">
            <button 
              @click="loadAllMessages" 
              :disabled="isLoadingAll"
              class="load-more-btn"
            >
              {{ isLoadingAll ? '全データ読み込み中...' : `全 ${totalMessages} 件のデータを読み込む` }}
            </button>
          </div>
        </div>

        <!-- 空の状態 -->
        <div v-else class="empty-state">
          <div class="empty-icon">📭</div>
          <h3>受信メッセージはありません</h3>
          <p>まだメッセージを受信していません。</p>
        </div>
      </div>
    </div>

    <!-- 選択したメッセージエリア -->
    <div v-if="selectedMessage" class="selected-message-area">
      <h3>選択したメッセージ</h3>
      <div class="selected-message-content">
        <div class="message-info">
          <div class="sender">{{ selectedMessage.senderName || selectedMessage.senderEmail || '不明' }}</div>
          <div class="sent-time">{{ formatSentTime(selectedMessage.sentAt) }}</div>
        </div>
        <div class="message-text">
          {{ selectedMessage.finalText || selectedMessage.originalText }}
        </div>
        <div class="message-actions">
          <button 
            v-if="selectedMessage.status !== 'read'"
            @click="markAsRead(selectedMessage.id)"
            class="mark-read-btn"
            :disabled="isMarkingRead === selectedMessage.id"
          >
            {{ isMarkingRead === selectedMessage.id ? '既読中...' : '既読にする' }}
          </button>
        </div>
      </div>
    </div>

    <!-- 評価エリア -->
    <div v-if="selectedMessage" class="rating-area">
      <div class="rating-bar">
        <div class="emoji-left">😢</div>
        <div class="rating-circles">
          <button
            v-for="rating in 5"
            :key="rating"
            @click="rateMessage(rating)"
            class="rating-circle"
            :class="{ 'active': selectedMessage.rating === rating }"
          />
        </div>
        <div class="emoji-right">😊</div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import { ratingService, type InboxMessageWithRating } from '../../services/ratingService'
import TreemapView from '../visualization/TreemapView.vue'

// State
const viewMode = ref<'list' | 'treemap'>('list')
const messages = ref<InboxMessageWithRating[]>([])
const allMessages = ref<InboxMessageWithRating[]>([])
const selectedMessage = ref<InboxMessageWithRating | null>(null)
const isMarkingRead = ref<string | null>(null)
const isLoading = ref<boolean>(false)
const isLoadingAll = ref<boolean>(false)
const error = ref<string>('')

// Pagination
const currentPage = ref<number>(1)
const limit = ref<number>(20)
const totalMessages = ref<number>(0)
const totalPages = computed(() => Math.ceil(totalMessages.value / limit.value))
const hasPrevPage = computed(() => currentPage.value > 1)
const hasNextPage = computed(() => currentPage.value < totalPages.value)
const unreadCount = computed(() => messages.value.filter(m => m.status !== 'read').length)

// Methods
const toggleViewMode = () => {
  viewMode.value = viewMode.value === 'list' ? 'treemap' : 'list'
  if (viewMode.value === 'treemap' && allMessages.value.length === 0) {
    loadAllMessages()
  }
}

const selectMessage = (message: InboxMessageWithRating) => {
  selectedMessage.value = message
  
  // 未読の場合は自動的に既読にする
  if (message.status !== 'read') {
    markAsRead(message.id, false)
  }
}

const rateMessage = async (rating: number) => {
  if (!selectedMessage.value) return
  
  try {
    if (selectedMessage.value.rating === rating) {
      // 同じ評価をクリックした場合は削除
      await ratingService.deleteMessageRating(selectedMessage.value.id)
      selectedMessage.value.rating = undefined
      selectedMessage.value.ratingId = undefined
    } else {
      // 新しい評価を設定
      const result = await ratingService.rateMessage(selectedMessage.value.id, rating)
      selectedMessage.value.rating = rating
      selectedMessage.value.ratingId = result.id
    }
    
    // メッセージリストも更新
    const messageInList = messages.value.find(m => m.id === selectedMessage.value?.id)
    if (messageInList) {
      messageInList.rating = selectedMessage.value.rating
      messageInList.ratingId = selectedMessage.value.ratingId
    }
  } catch (error) {
    console.error('評価エラー:', error)
  }
}


const fetchMessages = async () => {
  isLoading.value = true
  error.value = ''
  
  try {
    const response = await ratingService.getInboxWithRatings(currentPage.value, limit.value)
    messages.value = response.messages
    totalMessages.value = response.pagination.total
    
    // ツリーマップ用データも更新（初回のみ）
    if (currentPage.value === 1 && allMessages.value.length === 0) {
      allMessages.value = response.messages
    }
  } catch (err: any) {
    console.error('メッセージ取得エラー:', err)
    error.value = err.response?.data?.error || 'メッセージの取得に失敗しました'
  } finally {
    isLoading.value = false
  }
}

const refreshMessages = () => {
  fetchMessages()
}

const prevPage = () => {
  if (hasPrevPage.value && !isLoading.value) {
    currentPage.value--
    fetchMessages()
  }
}

const nextPage = () => {
  if (hasNextPage.value && !isLoading.value) {
    currentPage.value++
    fetchMessages()
  }
}


// 既読にする
const markAsRead = async (messageId: string, showFeedback = true) => {
  if (isMarkingRead.value === messageId) return
  
  isMarkingRead.value = messageId
  
  try {
    // TODO: 既読APIの実装が必要
    // await messageService.markAsRead(messageId)
    
    // 仮の実装: ローカル状態を更新
    const message = messages.value.find(m => m.id === messageId)
    if (message) {
      message.status = 'read'
      message.readAt = new Date().toISOString()
    }
    
    if (showFeedback) {
      console.log('既読にしました')
    }
  } catch (error) {
    console.error('既読処理エラー:', error)
  } finally {
    isMarkingRead.value = null
  }
}


// ツリーマップ用メソッド
const loadAllMessages = async () => {
  isLoadingAll.value = true
  error.value = ''
  
  try {
    let allData: InboxMessageWithRating[] = []
    let page = 1
    const pageLimit = 100 // 一度に多めに取得
    
    while (true) {
      const response = await ratingService.getInboxWithRatings(page, pageLimit)
      allData = allData.concat(response.messages)
      
      if (response.messages.length < pageLimit || allData.length >= response.pagination.total) {
        break
      }
      page++
    }
    
    allMessages.value = allData
  } catch (err: any) {
    console.error('全メッセージ取得エラー:', err)
    error.value = err.response?.data?.error || '全メッセージの取得に失敗しました'
  } finally {
    isLoadingAll.value = false
  }
}


// ヘルパー関数
const formatSentTime = (sentAt?: string) => {
  if (!sentAt) return ''
  
  const date = new Date(sentAt)
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

// 送信者のイニシャルを取得
const getSenderInitial = (message: InboxMessageWithRating) => {
  if (message.senderName) {
    return message.senderName.charAt(0).toUpperCase()
  } else if (message.senderEmail) {
    return message.senderEmail.charAt(0).toUpperCase()
  }
  return '?'
}

// 初期化
onMounted(() => {
  fetchMessages()
  // 初期データをツリーマップ用にも設定
  allMessages.value = messages.value
})
</script>

<style scoped>
.inbox-list {
  background: #f8f9fa;
  height: 100vh;
  padding: 1rem;
  display: flex;
  flex-direction: column;
  gap: 1rem;
  overflow: hidden;
}

/* ページタイトル */
.page-title {
  text-align: left;
  flex-shrink: 0;
}

.page-title h1 {
  font-size: 1.5rem;
  font-weight: 600;
  color: #1a1a1a;
  margin: 0;
}

/* メイン表示エリア */
.main-display-area {
  position: relative;
  background: white;
  border: 2px solid #e5e7eb;
  border-radius: 12px;
  height: 40vh;
  padding: 1rem;
  display: flex;
  flex-direction: column;
  flex-shrink: 0;
}

/* 表示切替ボタン */
.view-toggle-container {
  position: absolute;
  top: 1rem;
  right: 1rem;
  z-index: 10;
}

.view-toggle-btn {
  background: white;
  border: 2px solid #d1d5db;
  border-radius: 8px;
  padding: 0.5rem 1rem;
  font-size: 0.875rem;
  cursor: pointer;
  transition: all 0.2s ease;
}

.view-toggle-btn:hover {
  background: #f3f4f6;
  border-color: #9CA3AF;
}

/* メインコンテンツエリア */
.main-content {
  flex: 1;
  padding-top: 3rem; /* ボタンのスペースを確保 */
  overflow: hidden;
  display: flex;
  flex-direction: column;
}

/* メッセージ一覧表示 */
.messages-list-view {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
  flex: 1;
  overflow-y: auto;
}

.message-list-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 0.75rem;
  border: 1px solid #e5e7eb;
  border-radius: 6px;
  cursor: pointer;
  transition: all 0.2s ease;
  background: white;
}

.message-list-item:hover {
  background: #f9fafb;
  border-color: #d1d5db;
}

.message-list-item.selected {
  background: #eff6ff;
  border-color: #3b82f6;
}

.message-list-item.unread {
  border-left: 4px solid #3b82f6;
  background: #f0f9ff;
}

.message-preview {
  flex: 1;
}

.sender-name {
  font-weight: 600;
  color: #111827;
  font-size: 0.875rem;
  margin-bottom: 0.25rem;
}

.message-snippet {
  color: #6b7280;
  font-size: 0.75rem;
  line-height: 1.4;
}

.message-time {
  color: #9ca3af;
  font-size: 0.75rem;
  flex-shrink: 0;
  margin-left: 1rem;
}

/* ツリーマップコンテナ */
.treemap-container {
  flex: 1;
  width: 100%;
  overflow: hidden;
}

/* 選択したメッセージエリア */
.selected-message-area {
  background: white;
  border: 2px solid #e5e7eb;
  border-radius: 12px;
  padding: 1rem;
  flex-shrink: 0;
  height: 25vh;
  overflow-y: auto;
}

.selected-message-area h3 {
  margin: 0 0 0.75rem 0;
  font-size: 1rem;
  font-weight: 600;
  color: #111827;
}

.selected-message-content {
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
}

.message-info {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding-bottom: 0.5rem;
  border-bottom: 1px solid #e5e7eb;
}

.sender {
  font-weight: 600;
  color: #111827;
}

.sent-time {
  color: #6b7280;
  font-size: 0.875rem;
}

.message-text {
  color: #374151;
  line-height: 1.6;
  font-size: 1rem;
}

.message-actions {
  display: flex;
  justify-content: flex-end;
}

.mark-read-btn {
  background: #10b981;
  color: white;
  border: none;
  border-radius: 8px;
  padding: 0.5rem 1rem;
  font-size: 0.875rem;
  cursor: pointer;
  transition: all 0.2s ease;
}

.mark-read-btn:hover:not(:disabled) {
  background: #059669;
}

.mark-read-btn:disabled {
  background: #d1d5db;
  cursor: not-allowed;
}

/* 評価エリア */
.rating-area {
  background: white;
  border: 2px solid #e5e7eb;
  border-radius: 12px;
  padding: 1rem;
  display: flex;
  justify-content: center;
  flex-shrink: 0;
  height: 15vh;
  align-items: center;
}

.rating-bar {
  display: flex;
  align-items: center;
  gap: 2rem;
  width: 100%;
  justify-content: center;
}

.emoji-left,
.emoji-right {
  font-size: 2rem;
  flex-shrink: 0;
}

.rating-circles {
  display: flex;
  gap: 1rem;
  align-items: center;
}

.rating-circle {
  width: 40px;
  height: 40px;
  border: 2px solid #d1d5db;
  border-radius: 50%;
  background: white;
  cursor: pointer;
  transition: all 0.2s ease;
}

.rating-circle:hover {
  border-color: #92C9FF;
  transform: scale(1.1);
}

.rating-circle.active {
  background: #92C9FF;
  border-color: #92C9FF;
  transform: scale(1.2);
}

/* 共通スタイル */
.loading-state, .error-state, .empty-state {
  text-align: center;
  padding: 2rem;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  height: 200px;
}

.spinner {
  width: 32px;
  height: 32px;
  border: 3px solid #f3f3f3;
  border-top: 3px solid #3b82f6;
  border-radius: 50%;
  animation: spin 1s linear infinite;
  margin-bottom: 1rem;
}

@keyframes spin {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}

.retry-btn {
  background: #ef4444;
  color: white;
  border: none;
  border-radius: 6px;
  padding: 0.5rem 1rem;
  cursor: pointer;
  margin-top: 1rem;
}

.empty-state .empty-icon {
  font-size: 3rem;
  margin-bottom: 1rem;
}

.pagination {
  display: flex;
  justify-content: center;
  align-items: center;
  gap: 1rem;
  margin-top: 1rem;
  padding: 1rem;
}

.page-btn {
  background: white;
  border: 1px solid #d1d5db;
  border-radius: 6px;
  padding: 0.5rem 1rem;
  cursor: pointer;
  font-size: 0.875rem;
}

.page-btn:hover:not(:disabled) {
  background: #f9fafb;
}

.page-btn:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.page-info {
  color: #6b7280;
  font-size: 0.875rem;
}

.load-more-section {
  text-align: center;
  padding: 1rem;
  border-top: 1px solid #e5e7eb;
}

.load-more-btn {
  background: #3b82f6;
  color: white;
  border: none;
  border-radius: 6px;
  padding: 0.5rem 1rem;
  cursor: pointer;
}

.load-more-btn:hover:not(:disabled) {
  background: #2563eb;
}

.load-more-btn:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

/* レスポンシブ対応 */
@media (max-width: 768px) {
  .inbox-list {
    padding: 0.5rem;
    gap: 0.5rem;
  }
  
  .page-title h1 {
    font-size: 1.25rem;
  }
  
  .main-display-area {
    height: 35vh;
  }
  
  .selected-message-area {
    height: 30vh;
    padding: 0.75rem;
  }
  
  .rating-area {
    height: 12vh;
    padding: 0.5rem;
  }
  
  .rating-bar {
    gap: 1rem;
  }
  
  .emoji-left,
  .emoji-right {
    font-size: 1.5rem;
  }
  
  .rating-circles {
    gap: 0.75rem;
  }
  
  .rating-circle {
    width: 32px;
    height: 32px;
  }
}
</style>