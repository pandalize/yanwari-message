<template>
  <div class="inbox-list">
    <!-- ページタイトル -->
    <div class="page-title">
      <h1>受信</h1>
    </div>

    <!-- メイン表示エリア -->
    <div class="main-display-area">
      <!-- 右上の表示設定 -->
      <div class="display-control">
        <select v-model="displayMode" @change="onDisplayModeChange">
          <option value="treemap">ツリーマップ</option>
          <option value="list-desc">一覧（新しい順）</option>
          <option value="list-asc">一覧（古い順）</option>
        </select>
      </div>

      <!-- メインコンテンツエリア -->
      <div class="main-content">
        <!-- ローディング状態 -->
        <div v-if="isLoadingData && inboxMessages.length === 0" class="loading-state">
          <div class="spinner"></div>
          <p>メッセージを読み込み中...</p>
        </div>

        <!-- エラー状態 -->
        <div v-else-if="dataError" class="error-state">
          <p>❌ {{ dataError }}</p>
          <button @click="refreshInboxData()" class="retry-btn">再試行</button>
        </div>

        <!-- メッセージ一覧モード -->
        <div v-else-if="viewMode === 'list' && inboxMessages.length > 0" class="messages-list-view">
          <div 
            v-for="message in paginatedListData" 
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

          <!-- ページネーション（制限なし版では非表示） -->
          <!-- 
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
          -->
        </div>

        <!-- ツリーマップモード -->
        <div v-else-if="viewMode === 'treemap'" class="treemap-container">
          <TreemapView
            :messages="treemapData"
            @message-selected="selectMessage"
          />
        </div>

        <!-- 空の状態 -->
        <div v-else class="empty-state">
          <div class="empty-icon">📭</div>
          <h3>受信メッセージはありません</h3>
          <p>まだメッセージを受信していません。</p>
        </div>
      </div>
    </div>

    <!-- メッセージ選択時のポップアップ -->
    <div v-if="selectedMessage" class="message-popup-overlay" @click="closePopup">
      <div class="message-popup" @click.stop>
        <!-- ポップアップヘッダー -->
        <div class="popup-header">
          <h3>メッセージ詳細</h3>
          <button @click="closePopup" class="close-btn">×</button>
        </div>
        
        <!-- メッセージ内容 -->
        <div class="popup-content">
          <div class="message-info">
            <div class="sender">{{ selectedMessage.senderName || selectedMessage.senderEmail || '不明' }}</div>
            <div class="time-info">
              <div class="sent-time">
                <span class="time-label">送信:</span>
                {{ formatDetailedTime(selectedMessage.sentAt) }}
              </div>
              <div v-if="selectedMessage.status !== 'read'" class="unread-status">
                <span class="time-label">状態:</span>
                <span class="unread-badge">未読</span>
              </div>
            </div>
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
        
        <!-- 評価エリア -->
        <div class="rating-area">
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
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, onUnmounted, computed, watch } from 'vue'
import { ratingService, type InboxMessageWithRating } from '../../services/ratingService'
import TreemapView from '../visualization/TreemapView.vue'

// ================================================
// 1. データ層（Data Layer）
// ================================================

// 生データの状態管理
const inboxMessages = ref<InboxMessageWithRating[]>([])
const isLoadingData = ref<boolean>(false)
const dataError = ref<string>('')

// データ取得関数
const fetchInboxData = async (): Promise<void> => {
  // 重複リクエストの防止
  if (isLoadingData.value) {
    console.log('⏸️ fetchInboxData: 既に実行中のため中断')
    return
  }
  
  console.log('🔄 fetchInboxData: データ取得開始')
  isLoadingData.value = true
  dataError.value = ''
  
  try {
    let allData: InboxMessageWithRating[] = []
    let page = 1
    const pageLimit = 100 // 一度に多めに取得
    
    // 全ページのデータを取得
    while (true) {
      console.log(`📡 API取得: ページ ${page}, 上限 ${pageLimit}`)
      const response = await ratingService.getInboxWithRatings(page, pageLimit)
      console.log(`📦 API応答: ${response.messages.length}件取得, 総数 ${response.pagination.total}`)
      
      allData = allData.concat(response.messages)
      console.log(`📊 累積データ: ${allData.length}件`)
      
      if (response.messages.length < pageLimit || allData.length >= response.pagination.total) {
        console.log('✅ 全データ取得完了')
        break
      }
      page++
    }
    
    // データの一意性をチェック・保証
    const uniqueIds = new Set(allData.map(m => m.id))
    if (uniqueIds.size !== allData.length) {
      console.warn(`⚠️ 重複データ検出: 総数 ${allData.length}, ユニーク ${uniqueIds.size}`)
      
      // 重複を削除（最新のデータを保持）
      const uniqueMessages = Array.from(
        new Map(allData.map(m => [m.id, m])).values()
      )
      allData = uniqueMessages
      console.log(`🔧 重複削除後: ${allData.length}件`)
    } else {
      console.log(`✅ データ一意性確認: ${uniqueIds.size}件すべてユニーク`)
    }
    
    // 生データを保存
    inboxMessages.value = allData
    console.log(`💾 保存完了: inboxMessages = ${inboxMessages.value.length}件`)
    
  } catch (err: any) {
    console.error('❌ 受信データ取得エラー:', err)
    dataError.value = err.response?.data?.error || 'メッセージの取得に失敗しました'
  } finally {
    isLoadingData.value = false
    console.log('🔄 fetchInboxData: 処理完了')
  }
}

// データリフレッシュ関数
const refreshInboxData = (): void => {
  fetchInboxData()
}

// ================================================
// 2. 表示層（Display Layer）
// ================================================

// 表示モード設定
const displayMode = ref<'list-desc' | 'list-asc' | 'treemap'>('treemap')
const selectedMessage = ref<InboxMessageWithRating | null>(null)
const isMarkingRead = ref<string | null>(null)

// ページネーション設定（一覧表示用）
const currentPage = ref<number>(1)
const limit = ref<number>(100) // 20件 → 100件に増加（または制限なしにする場合は非常に大きな数値）

// 便利な計算プロパティ
const unreadCount = computed(() => inboxMessages.value.filter(m => m.status !== 'read').length)
const totalPages = computed(() => Math.ceil(inboxMessages.value.length / limit.value))
const hasPrevPage = computed(() => currentPage.value > 1)
const hasNextPage = computed(() => currentPage.value < totalPages.value)

// 表示決定の計算プロパティ
const viewMode = computed(() => displayMode.value === 'treemap' ? 'treemap' : 'list')
const sortOrder = computed(() => {
  if (displayMode.value === 'list-asc') return 'asc'
  return 'desc'
})

// ツリーマップ表示用データ（生データをそのまま使用）
const treemapData = computed(() => {
  const data = inboxMessages.value
  console.log(`🗺️ ツリーマップデータ: ${data.length}件 (元データ: ${inboxMessages.value.length}件)`)
  return data
})

// 一覧表示用データ（ソート済み）
const listData = computed(() => {
  const source = inboxMessages.value
  console.log(`📋 一覧ソート前: ${source.length}件 (ソートモード: ${sortOrder.value})`)
  
  const sorted = [...source].sort((a, b) => {
    const dateA = new Date(a.sentAt || a.createdAt).getTime()
    const dateB = new Date(b.sentAt || b.createdAt).getTime()
    
    return sortOrder.value === 'desc' ? dateB - dateA : dateA - dateB
  })
  
  console.log(`📋 一覧ソート後: ${sorted.length}件`)
  return sorted
})

// ページネーション済み一覧データ（制限なし版）
const paginatedListData = computed(() => {
  const source = listData.value
  
  // 制限なしで全件表示
  console.log(`📄 一覧表示: 全 ${source.length}件を表示（ページネーション無効）`)
  return source
  
  // ページネーション有効版（コメントアウト）
  /*
  const startIndex = (currentPage.value - 1) * limit.value
  const endIndex = startIndex + limit.value
  const paginated = source.slice(startIndex, endIndex)
  
  console.log(`📄 ページネーション: 元 ${source.length}件 → ${startIndex}-${endIndex} → 表示 ${paginated.length}件 (ページ ${currentPage.value}/${totalPages.value})`)
  return paginated
  */
})

// 現在の表示モードに応じたデータを返す
const currentDisplayData = computed(() => {
  switch (viewMode.value) {
    case 'treemap':
      return treemapData.value
    case 'list':
      return paginatedListData.value
    default:
      return []
  }
})

// ================================================
// 3. ユーザーアクション層（User Action Layer）
// ================================================

// 表示モード変更
const onDisplayModeChange = (): void => {
  console.log(`🔄 表示モード変更: ${displayMode.value} (viewMode: ${viewMode.value})`)
  
  // 表示モード切り替え時は現在のページを1に戻す
  const oldPage = currentPage.value
  currentPage.value = 1
  console.log(`📄 ページリセット: ${oldPage} → ${currentPage.value}`)
  
  // 現在の状態をログ出力
  console.log(`📊 現在の状態:`)
  console.log(`  - inboxMessages: ${inboxMessages.value.length}件`)
  console.log(`  - treemapData: ${treemapData.value.length}件`)
  console.log(`  - listData: ${listData.value.length}件`)
  console.log(`  - paginatedListData: ${paginatedListData.value.length}件`)
}

// メッセージ選択
const selectMessage = (message: InboxMessageWithRating): void => {
  selectedMessage.value = message
  
  // 未読の場合は自動的に既読にする
  if (message.status !== 'read') {
    markAsRead(message.id, false)
  }
}

// ポップアップを閉じる
const closePopup = (): void => {
  selectedMessage.value = null
}

// メッセージ評価
const rateMessage = async (rating: number): Promise<void> => {
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
    
    // 元データ（inboxMessages）を更新
    const messageInList = inboxMessages.value.find(m => m.id === selectedMessage.value?.id)
    if (messageInList) {
      const oldRating = messageInList.rating
      messageInList.rating = selectedMessage.value.rating
      messageInList.ratingId = selectedMessage.value.ratingId
      console.log(`⭐ 評価更新: ID ${selectedMessage.value.id} - ${oldRating} → ${selectedMessage.value.rating}`)
    } else {
      console.warn(`⚠️ 評価対象メッセージが見つからない: ID ${selectedMessage.value?.id}`)
    }

    // リアクティブ更新を強制するため、配列の参照を更新
    const oldLength = inboxMessages.value.length
    inboxMessages.value = [...inboxMessages.value]
    console.log(`🔄 配列参照更新: ${oldLength}件 → ${inboxMessages.value.length}件`)
  } catch (error) {
    console.error('評価エラー:', error)
  }
}


// ページネーション操作
const prevPage = (): void => {
  if (hasPrevPage.value) {
    currentPage.value--
  }
}

const nextPage = (): void => {
  if (hasNextPage.value) {
    currentPage.value++
  }
}

// 既読処理
const markAsRead = async (messageId: string, showFeedback = true): Promise<void> => {
  if (isMarkingRead.value === messageId) return
  
  isMarkingRead.value = messageId
  
  try {
    // APIを呼び出して既読状態を更新
    await ratingService.markAsRead(messageId)
    
    // 元データ（inboxMessages）を更新
    const message = inboxMessages.value.find(m => m.id === messageId)
    if (message) {
      const oldStatus = message.status
      message.status = 'read'
      message.readAt = new Date().toISOString()
      console.log(`📖 既読更新: ID ${messageId} - ${oldStatus} → read`)
    } else {
      console.warn(`⚠️ 既読対象メッセージが見つからない: ID ${messageId}`)
    }
    
    if (showFeedback) {
      console.log('既読にしました')
    }
  } catch (error) {
    console.error('既読処理エラー:', error)
    // エラーが発生した場合はユーザーに通知
    alert('既読処理に失敗しました。もう一度お試しください。')
  } finally {
    isMarkingRead.value = null
  }
}


// ================================================
// 4. ヘルパー関数（Helper Functions）
// ================================================
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

const formatDetailedTime = (dateString?: string) => {
  if (!dateString) return '不明'
  
  const date = new Date(dateString)
  const now = new Date()
  const diffInMinutes = (now.getTime() - date.getTime()) / (1000 * 60)
  const diffInHours = diffInMinutes / 60
  const diffInDays = diffInHours / 24
  
  // 相対時間表示
  let relativeTime = ''
  if (diffInMinutes < 1) {
    relativeTime = '今'
  } else if (diffInMinutes < 60) {
    relativeTime = `${Math.floor(diffInMinutes)}分前`
  } else if (diffInHours < 24) {
    relativeTime = `${Math.floor(diffInHours)}時間前`
  } else if (diffInDays < 7) {
    relativeTime = `${Math.floor(diffInDays)}日前`
  } else {
    relativeTime = '1週間以上前'
  }
  
  // 詳細な日時
  const detailedTime = date.toLocaleString('ja-JP', {
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit'
  })
  
  return `${detailedTime} (${relativeTime})`
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

// ================================================
// 5. 初期化（Initialization）
// ================================================

// データ変更の監視
watch(
  () => inboxMessages.value.length,
  (newLength, oldLength) => {
    console.log(`👀 inboxMessages変更監視: ${oldLength} → ${newLength}件`)
  }
)

watch(
  () => displayMode.value,
  (newMode, oldMode) => {
    console.log(`👀 displayMode変更監視: ${oldMode} → ${newMode}`)
  }
)

onMounted(() => {
  console.log('🚀 コンポーネント初期化開始')
  
  // ページスクロールを無効化
  document.body.style.overflow = 'hidden'
  document.documentElement.style.overflow = 'hidden'
  
  // アプリ起動時にデータを取得
  fetchInboxData()
})

onUnmounted(() => {
  // ページスクロールを復元
  document.body.style.overflow = ''
  document.documentElement.style.overflow = ''
  console.log('🔄 コンポーネント終了 - スクロール復元')
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

/* メイン表示エリア - 画面全体に拡大 */
.main-display-area {
  position: relative;
  background: white;
  border: 2px solid #e5e7eb;
  border-radius: 12px;
  height: calc(100vh - 8rem); /* 画面全体の高さから余白を引いた高さ */
  padding: 1rem;
  display: flex;
  flex-direction: column;
  flex-shrink: 0;
  width: 100%; /* 画面全体の幅 */
  margin: 0;
}

/* 表示設定 */
.display-control {
  position: absolute;
  top: 1rem;
  right: 1rem;
  z-index: 20;
}

.display-control select {
  padding: 0.5rem 1rem;
  border: 2px solid #d1d5db;
  border-radius: 8px;
  font-size: 0.875rem;
  background: white;
  cursor: pointer;
  min-width: 140px;
  transition: all 0.2s ease;
}

.display-control select:hover {
  background: #f3f4f6;
  border-color: #9CA3AF;
}

.display-control select:focus {
  outline: none;
  border-color: #3b82f6;
  box-shadow: 0 0 0 1px #3b82f6;
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
  /* スクロールバーのスタイリング */
  scrollbar-width: thin;
  scrollbar-color: #cbd5e1 #f1f5f9;
}

.messages-list-view::-webkit-scrollbar {
  width: 6px;
}

.messages-list-view::-webkit-scrollbar-track {
  background: #f1f5f9;
  border-radius: 3px;
}

.messages-list-view::-webkit-scrollbar-thumb {
  background: #cbd5e1;
  border-radius: 3px;
}

.messages-list-view::-webkit-scrollbar-thumb:hover {
  background: #94a3b8;
}

.message-list-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 0.5rem 0.75rem; /* 縦パディングを減少 */
  border: 1px solid #e5e7eb;
  border-radius: 6px;
  cursor: pointer;
  transition: all 0.2s ease;
  background: white;
  min-height: 60px; /* 最小高さを設定 */
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

/* ポップアップのオーバーレイ */
.message-popup-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.5);
  display: flex;
  justify-content: center;
  align-items: center;
  z-index: 1000;
  padding: 2rem;
}

/* ポップアップ本体 */
.message-popup {
  background: white;
  border-radius: 16px;
  box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1), 0 10px 10px -5px rgba(0, 0, 0, 0.04);
  max-width: 600px;
  width: 100%;
  max-height: 80vh;
  overflow: hidden;
  display: flex;
  flex-direction: column;
}

/* ポップアップヘッダー */
.popup-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 1.5rem;
  border-bottom: 1px solid #e5e7eb;
  background: #f9fafb;
}

.popup-header h3 {
  margin: 0;
  font-size: 1.25rem;
  font-weight: 600;
  color: #111827;
}

.close-btn {
  background: none;
  border: none;
  font-size: 1.5rem;
  cursor: pointer;
  color: #6b7280;
  padding: 0.25rem;
  border-radius: 4px;
  width: 32px;
  height: 32px;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.2s ease;
}

.close-btn:hover {
  background: #e5e7eb;
  color: #374151;
}

/* ポップアップコンテンツ */
.popup-content {
  padding: 1.5rem;
  overflow-y: auto;
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.message-info {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  padding-bottom: 0.75rem;
  border-bottom: 1px solid #e5e7eb;
  gap: 1rem;
}

.sender {
  font-weight: 600;
  color: #111827;
  flex-shrink: 0;
}

.time-info {
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
  text-align: right;
  font-size: 0.75rem;
  min-width: 0;
}

.sent-time,
.read-time,
.unread-status {
  display: flex;
  align-items: center;
  gap: 0.25rem;
  color: #6b7280;
}

.time-label {
  font-weight: 500;
  color: #9ca3af;
  min-width: 2rem;
}

.unread-badge {
  background: #ef4444;
  color: white;
  padding: 0.125rem 0.375rem;
  border-radius: 0.25rem;
  font-size: 0.625rem;
  font-weight: 600;
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

/* 評価エリア（ポップアップ内） */
.rating-area {
  background: #f9fafb;
  border-top: 1px solid #e5e7eb;
  padding: 1.5rem;
  display: flex;
  justify-content: center;
  flex-shrink: 0;
  align-items: center;
}

.rating-bar {
  display: flex;
  align-items: center;
  gap: 1.5rem; /* gapを縮小 */
  width: 100%;
  justify-content: center;
}

.emoji-left,
.emoji-right {
  font-size: 1.75rem; /* フォントサイズを縮小 */
  flex-shrink: 0;
}

.rating-circles {
  display: flex;
  gap: 0.75rem; /* gapを縮小 */
  align-items: center;
}

.rating-circle {
  width: 36px; /* サイズを縮小 */
  height: 36px; /* サイズを縮小 */
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
    height: calc(100vh - 6rem); /* モバイル版でも画面全体 */
  }
  
  .display-control {
    top: 0.5rem;
    right: 0.5rem;
  }
  
  .display-control select {
    padding: 0.4rem 0.8rem;
    font-size: 0.75rem;
    min-width: 120px;
  }
  
  .message-popup-overlay {
    padding: 1rem;
  }
  
  .message-popup {
    max-height: 90vh;
  }
  
  .popup-header {
    padding: 1rem;
  }
  
  .popup-header h3 {
    font-size: 1.125rem;
  }
  
  .popup-content {
    padding: 1rem;
  }
  
  .message-info {
    flex-direction: column;
    align-items: flex-start;
    gap: 0.5rem;
  }
  
  .time-info {
    text-align: left;
    font-size: 0.7rem;
  }
  
  .time-label {
    min-width: 1.5rem;
  }
  
  .rating-area {
    padding: 1rem;
  }
  
  .rating-bar {
    gap: 0.75rem;
  }
  
  .emoji-left,
  .emoji-right {
    font-size: 1.25rem;
  }
  
  .rating-circles {
    gap: 0.5rem;
  }
  
  .rating-circle {
    width: 28px;
    height: 28px;
  }
}
</style>