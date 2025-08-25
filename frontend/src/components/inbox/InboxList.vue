<template>
  <div class="inbox-list">
    
    <!-- 初期化中 -->
    <div v-if="authStore.isInitializing" class="loading-state">
      <div class="spinner"></div>
      <p>認証を確認中...</p>
    </div>

    <!-- ツリーマップ表示 -->
    <div v-else-if="displayMode === 'treemap'" class="treemap-section">
      <!-- ツリーマップ用のヘッダー -->
      <div class="treemap-header">
        <select v-model="displayMode" @change="onDisplayModeChange" class="inline-select">
          <option value="treemap">ツリーマップ</option>
          <option value="list-desc">一覧（新しい順）</option>
          <option value="list-asc">一覧（古い順）</option>
        </select>
      </div>
      
      <div class="treemap-react">
        <TreemapView
          :messages="treemapData"
          @message-selected="selectMessage"
        />
      </div>
    </div>

    <!-- 一覧表示 -->
    <div v-else class="list-view">
      <div v-if="isLoadingData" class="loading-state">
        <div class="spinner"></div>
        <p>読み込み中...</p>
      </div>
      <div v-else-if="dataError" class="error-state">
        <p>❌ {{ dataError }}</p>
        <button @click="fetchInboxData()" class="retry-button">再試行</button>
      </div>
      <div v-else-if="!inboxMessages.length" class="empty-state">
        <p>📭 メッセージがありません</p>
        <button @click="fetchInboxData()" class="retry-button">再読み込み</button>
        <div class="debug-info">
          <p>デバッグ情報:</p>
          <pre>{{ JSON.stringify({
            isAuthenticated: authStore.isAuthenticated,
            hasToken: !!authStore.accessToken,
            userEmail: authStore.user?.email,
            messagesCount: inboxMessages.length
          }, null, 2) }}</pre>
        </div>
      </div>
      <div v-else>
        <!-- メッセージリストの直上にselectボタンを配置 -->
        <div class="message-list-header">
          <select v-model="displayMode" @change="onDisplayModeChange" class="inline-select">
            <option value="treemap">ツリーマップ</option>
            <option value="list-desc">一覧（新しい順）</option>
            <option value="list-asc">一覧（古い順）</option>
          </select>
        </div>
        
        <div class="message-list">
          <div 
            v-for="message in sortedListData" 
            :key="message.id"
            class="message-item"
            @click="selectMessage(message)"
          >
            <div class="sender">{{ message.senderName || message.senderEmail }}</div>
            <div class="text">{{ message.finalText || message.originalText }}</div>
            <div class="time">{{ formatSentTime(message.sentAt) }}</div>
          </div>
        </div>
      </div>
    </div>
    
    <!-- メッセージ詳細モーダル -->
    <div v-if="selectedMessage" class="message-detail-modal" @click.self="closeMessageDetail">
      <div class="message-detail-content">
        <button class="close-button" @click="closeMessageDetail">×</button>
        
        <div class="detail-header">
          <h3>メッセージ詳細</h3>
        </div>
        
        <div class="detail-body">
          <div class="detail-section">
            <label>送信者</label>
            <p>{{ selectedMessage.senderName || selectedMessage.senderEmail }}</p>
          </div>
          
          <div class="detail-section">
            <label>送信日時</label>
            <p>{{ formatDetailedTime(selectedMessage.sentAt) }}</p>
          </div>
          
          <div class="detail-section">
            <label>メッセージ</label>
            <div class="final-message">{{ selectedMessage.finalText || selectedMessage.originalText }}</div>
          </div>
          
          <div class="detail-section">
            <label>評価 
              <span v-if="selectedMessage.rating" class="current-rating">
                (現在: {{ selectedMessage.rating }}つ星)
              </span>
              <span v-else class="current-rating">
                (未評価)
              </span>
            </label>
            
            <!-- 評価可能なメッセージ -->
            <div v-if="canRateMessage(selectedMessage)" class="rating-stars" :class="{ disabled: isRatingMessage }">
              <span 
                v-for="star in 5" 
                :key="star"
                @click="!isRatingMessage && rateMessage(star)"
                :class="[
                  'star', 
                  { 
                    filled: selectedMessage.rating && selectedMessage.rating >= star,
                    hover: !isRatingMessage 
                  }
                ]"
                :title="`${star}つ星で評価`"
              >
                ★
              </span>
            </div>
            
            <!-- 評価不可能なメッセージ -->
            <div v-else class="rating-unavailable">
              <p class="rating-unavailable-text">
                このメッセージはまだ評価できません。配信済みまたは既読になってから評価可能です。
              </p>
              <div class="message-status-info">
                現在のステータス: <span class="status-badge" :class="`status-${selectedMessage.status}`">{{ getStatusText(selectedMessage.status) }}</span>
              </div>
            </div>
            
            <div v-if="isRatingMessage" class="rating-loading">
              評価を更新中...
            </div>
            <div v-if="canRateMessage(selectedMessage)" class="rating-help">
              ★をクリックして評価を変更できます
            </div>
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
import { useJWTAuthStore } from '@/stores/jwtAuth'

// ================================================
// 1. データ層（Data Layer）
// ================================================

// 認証ストア
const authStore = useJWTAuthStore()

// データ状態
const inboxMessages = ref<InboxMessageWithRating[]>([])
const isLoadingData = ref<boolean>(false)
const dataError = ref<string | null>(null)

// データ取得関数（キャッシュ機能を含む）
const fetchInboxData = async (): Promise<void> => {
  isLoadingData.value = true
  dataError.value = null
  
  try {
    console.log('🔄 fetchInboxData: 処理開始')
    console.log('🔑 認証状態:', {
      isAuthenticated: authStore.isAuthenticated,
      isInitializing: authStore.isInitializing,
      hasUser: !!authStore.user,
      hasAccessToken: !!authStore.accessToken,
      userEmail: authStore.user?.email,
      tokenLength: authStore.accessToken?.length
    })
    
    // 認証チェック
    if (!authStore.isAuthenticated) {
      console.log('⚠️ 認証されていません。認証待機中...')
      // 認証を待つ
      await new Promise((resolve) => {
        const checkAuth = setInterval(() => {
          if (authStore.isAuthenticated || !authStore.isInitializing) {
            clearInterval(checkAuth)
            resolve(true)
          }
        }, 100)
      })
    }
    
    // API呼び出し前にトークンを再設定
    if (authStore.accessToken) {
      console.log('🔑 APIサービスにトークンを設定中...')
      const { apiService } = await import('../../services/api')
      apiService.setAuthToken(authStore.accessToken)
    }
    
    console.log('📡 API呼び出し開始: /messages/inbox-with-ratings')
    
    // API呼び出し
    let response
    try {
      response = await ratingService.getInboxWithRatings()
    } catch (apiError: any) {
      console.error('❌ API呼び出しエラー:', apiError)
      console.error('❌ エラー詳細:', {
        message: apiError.message,
        response: apiError.response,
        status: apiError.response?.status,
        data: apiError.response?.data
      })
      
      // エラーを再スロー
      throw apiError
    }
    
    console.log('📧 API Response:', {
      status: response?.status,
      hasData: !!response?.data,
      hasMessages: !!response?.data?.messages,
      messagesLength: response?.data?.messages?.length,
      fullResponse: response
    })
    
    if (response.status === 'success') {
      console.log('📦 レスポンスデータ構造:', {
        hasData: !!response.data,
        dataKeys: response.data ? Object.keys(response.data) : [],
        hasMessages: !!response.data?.messages,
        messageType: response.data?.messages ? typeof response.data.messages : 'undefined',
        messageLength: Array.isArray(response.data?.messages) ? response.data.messages.length : 'not array'
      })
      
      if (response.data?.messages && Array.isArray(response.data.messages)) {
        // データの整形
        const processedMessages = response.data.messages.map((msg: any) => ({
          id: msg.id,
          senderId: msg.senderId || '',
          senderEmail: msg.senderEmail || '',
          senderName: msg.senderName || 'Unknown User',
          recipientId: msg.recipientId || '',
          recipientEmail: msg.recipientEmail || '',
          originalText: msg.originalText || '',
          finalText: msg.finalText || '',
          selectedTone: msg.selectedTone || '',
          scheduledAt: msg.scheduledAt || null,
          sentAt: msg.sentAt || null,
          status: msg.status || 'sent',
          rating: msg.rating || null,
          readAt: msg.readAt || null
        }))
        
        // ステート更新
        inboxMessages.value = processedMessages
        console.log(`✅ 処理成功: ${processedMessages.length}件のメッセージ`)
        
        if (processedMessages.length > 0) {
          console.log('📧 最初のメッセージ:', processedMessages[0])
        }
      } else {
        console.warn('⚠️ メッセージ配列が見つかりません')
        inboxMessages.value = []
      }
    } else {
      console.warn('⚠️ API応答が成功ではありません:', response)
      inboxMessages.value = []
    }
  } catch (error) {
    console.error('❌ fetchInboxData エラー:', error)
    dataError.value = 'メッセージの取得に失敗しました'
    inboxMessages.value = []
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
const isRatingMessage = ref<boolean>(false)

// ページネーション設定（一覧表示用）
const currentPage = ref<number>(1)
const itemsPerPage = 10000 // 実質無制限

// viewMode計算プロパティ
const viewMode = computed<'list' | 'treemap'>(() => {
  return displayMode.value === 'treemap' ? 'treemap' : 'list'
})

// ソートされたデータ
const sortedListData = computed<InboxMessageWithRating[]>(() => {
  const messages = [...inboxMessages.value]
  
  if (displayMode.value === 'list-asc') {
    // 古い順（sentAtの昇順）
    return messages.sort((a, b) => {
      const dateA = a.sentAt ? new Date(a.sentAt).getTime() : 0
      const dateB = b.sentAt ? new Date(b.sentAt).getTime() : 0
      return dateA - dateB
    })
  } else {
    // 新しい順（sentAtの降順）- デフォルト
    return messages.sort((a, b) => {
      const dateA = a.sentAt ? new Date(a.sentAt).getTime() : 0
      const dateB = b.sentAt ? new Date(b.sentAt).getTime() : 0
      return dateB - dateA
    })
  }
})

// ページネーション適用後のデータ
const paginatedListData = computed<InboxMessageWithRating[]>(() => {
  const start = (currentPage.value - 1) * itemsPerPage
  const end = start + itemsPerPage
  return sortedListData.value.slice(start, end)
})

// ツリーマップ用データ
const treemapData = computed<InboxMessageWithRating[]>(() => {
  console.log('📊 treemapData computed:', inboxMessages.value.length, 'messages')
  return inboxMessages.value
})

// 表示モード変更
const onDisplayModeChange = (): void => {
  currentPage.value = 1
  selectedMessage.value = null
}

// メッセージ選択（自動既読処理付き）
const selectMessage = async (message: InboxMessageWithRating): Promise<void> => {
  selectedMessage.value = message
  
  // 未読の場合は自動的に既読にする
  if (message.status !== 'read') {
    console.log('📖 メッセージ詳細を開いたため自動既読処理を実行:', message.id)
    await markAsRead(message.id)
  }
}

// ポップアップを閉じる
const closePopup = (): void => {
  selectedMessage.value = null
}

// メッセージ詳細を閉じる
const closeMessageDetail = (): void => {
  selectedMessage.value = null
}

// ================================================
// 3. 操作層（Interaction Layer）
// ================================================

// 既読処理
const markAsRead = async (messageId: string): Promise<void> => {
  if (!messageId || isMarkingRead.value === messageId) return
  
  isMarkingRead.value = messageId
  
  try {
    const response = await ratingService.markMessageAsRead(messageId)
    
    if (response.status === 'success') {
      // ローカルデータを更新
      const messageIndex = inboxMessages.value.findIndex(m => m.id === messageId)
      if (messageIndex !== -1) {
        inboxMessages.value[messageIndex] = {
          ...inboxMessages.value[messageIndex],
          status: 'read',
          readAt: new Date().toISOString()
        }
      }
      
      // 選択中のメッセージも更新
      if (selectedMessage.value?.id === messageId) {
        selectedMessage.value = {
          ...selectedMessage.value,
          status: 'read',
          readAt: new Date().toISOString()
        }
      }
    }
  } catch (error) {
    console.error('❌ 既読処理エラー:', error)
  } finally {
    isMarkingRead.value = null
  }
}

// 評価処理
const rateMessage = async (rating: number): Promise<void> => {
  if (!selectedMessage.value || isRatingMessage.value) return
  
  isRatingMessage.value = true
  
  try {
    console.log('⭐ 評価処理開始:', { messageId: selectedMessage.value.id, rating, currentRating: selectedMessage.value.rating })
    
    const response = await ratingService.createRating({
      messageId: selectedMessage.value.id,
      rating
    })
    
    console.log('⭐ 評価API応答:', response)
    
    if (response.status === 'success') {
      // ローカルデータを更新
      const messageIndex = inboxMessages.value.findIndex(m => m.id === selectedMessage.value?.id)
      if (messageIndex !== -1) {
        inboxMessages.value[messageIndex] = {
          ...inboxMessages.value[messageIndex],
          rating
        }
        console.log('⭐ inboxMessages更新完了')
      }
      
      // 選択中のメッセージも更新
      if (selectedMessage.value) {
        selectedMessage.value = {
          ...selectedMessage.value,
          rating
        }
        console.log('⭐ selectedMessage更新完了:', selectedMessage.value.rating)
      }
      
      console.log('✅ 評価処理成功:', rating)
    }
  } catch (error: any) {
    console.error('❌ 評価処理エラー:', error)
    console.error('❌ エラー詳細:', {
      message: error.message,
      response: error.response?.data,
      status: error.response?.status
    })
  } finally {
    isRatingMessage.value = false
  }
}

// ================================================
// 4. フォーマット関数
// ================================================

// 送信時刻のフォーマット（一覧表示用）
const formatSentTime = (sentAt: string | null): string => {
  if (!sentAt) return '時刻不明'
  
  const date = new Date(sentAt)
  const now = new Date()
  const diffMs = now.getTime() - date.getTime()
  const diffDays = Math.floor(diffMs / (1000 * 60 * 60 * 24))
  
  if (diffDays === 0) {
    // 今日の場合は時刻のみ
    return date.toLocaleTimeString('ja-JP', { 
      hour: '2-digit', 
      minute: '2-digit' 
    })
  } else if (diffDays === 1) {
    // 昨日
    return '昨日 ' + date.toLocaleTimeString('ja-JP', { 
      hour: '2-digit', 
      minute: '2-digit' 
    })
  } else if (diffDays < 7) {
    // 1週間以内
    return `${diffDays}日前`
  } else {
    // それ以前は日付を表示
    return date.toLocaleDateString('ja-JP', { 
      month: 'numeric', 
      day: 'numeric' 
    })
  }
}

// 詳細時刻のフォーマット（ポップアップ用）
const formatDetailedTime = (dateStr: string | null): string => {
  if (!dateStr) return '時刻不明'
  
  const date = new Date(dateStr)
  return date.toLocaleString('ja-JP', {
    year: 'numeric',
    month: 'numeric',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit'
  })
}

// ================================================
// 5. ライフサイクル
// ================================================

// 定期更新タイマー
let updateTimer: number | null = null

// 定期更新の開始
const startPeriodicUpdate = (): void => {
  updateTimer = window.setInterval(() => {
    fetchInboxData()
  }, 30000) // 30秒ごと
}

// 定期更新の停止
const stopPeriodicUpdate = (): void => {
  if (updateTimer !== null) {
    clearInterval(updateTimer)
    updateTimer = null
  }
}

// キーボードショートカット
const handleKeydown = (e: KeyboardEvent): void => {
  if (e.key === 'Escape' && selectedMessage.value) {
    closePopup()
  }
}

// マウント時
onMounted(async () => {
  console.log('📧 InboxList マウント')
  
  // 認証状態を待つ
  if (authStore.isInitializing) {
    console.log('🔄 認証初期化中...')
    // 認証初期化が完了するまで待つ
    const unwatch = watch(() => authStore.isInitializing, async (initializing) => {
      if (!initializing) {
        console.log('✅ 認証初期化完了')
        console.log('🔑 認証状態:', {
          isAuthenticated: authStore.isAuthenticated,
          hasUser: !!authStore.user,
          hasAccessToken: !!authStore.accessToken
        })
        
        // 少し待機してから実行
        setTimeout(() => {
          fetchInboxData()
          startPeriodicUpdate()
        }, 500)
        
        unwatch() // watchを停止
      }
    })
  } else {
    // 既に初期化済み
    console.log('✅ 既に認証初期化済み')
    console.log('🔑 認証状態:', {
      isAuthenticated: authStore.isAuthenticated,
      hasUser: !!authStore.user,
      hasAccessToken: !!authStore.accessToken
    })
    
    // 少し待機してから実行
    setTimeout(() => {
      fetchInboxData()
      startPeriodicUpdate()
    }, 500)
  }
  
  document.addEventListener('keydown', handleKeydown)
})

// アンマウント時
onUnmounted(() => {
  console.log('📧 InboxList アンマウント')
  stopPeriodicUpdate()
  document.removeEventListener('keydown', handleKeydown)
})

// データ変更の監視
watch(inboxMessages, (newMessages) => {
  console.log(`📊 メッセージ数: ${newMessages.length}`)
}, { deep: true })

// ================================================
// 6. ヘルパー関数
// ================================================

// メッセージが評価可能かどうかを判定
const canRateMessage = (message: InboxMessageWithRating | null): boolean => {
  if (!message) return false
  // 配信済み（delivered）または既読（read）のメッセージのみ評価可能
  return message.status === 'delivered' || message.status === 'read'
}

// ステータステキストを取得
const getStatusText = (status: string): string => {
  switch (status) {
    case 'draft':
      return '下書き'
    case 'processing':
      return 'AI変換中'
    case 'scheduled':
      return '送信予定'
    case 'sent':
      return '送信済み'
    case 'delivered':
      return '配信済み'
    case 'read':
      return '既読'
    default:
      return status
  }
}
</script>

<style scoped>
/* インボックス全体のレイアウト調整 */
.inbox-list {
  position: relative;
  height: calc(100vh - 140px); /* PageTitleとパディングを考慮 */
  width: 100%;
}

/* ツリーマップセクション */
.treemap-section {
  width: 100%;
  height: 100%;
  display: flex;
  flex-direction: column;
  padding: 0 1rem 1rem 1rem;
}

/* ツリーマップヘッダー */
.treemap-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 1rem 0 1rem 0;
  border-bottom: 1px solid #e5e7eb;
  margin-bottom: 1rem;
  background: white;
  flex-shrink: 0;
}

.treemap-header h3 {
  margin: 0;
  font-size: 1.125rem;
  font-weight: 600;
  color: #111827;
}

/* ツリーマップコンテナ */
.treemap-react {
  width: 100%;
  flex: 1;
  min-height: 0;
}

/* メッセージリストヘッダー */
.message-list-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 1rem 0 1rem 0;
  border-bottom: 1px solid #e5e7eb;
  margin-bottom: 1rem;
}

.message-list-header h3 {
  margin: 0;
  font-size: 1.125rem;
  font-weight: 600;
  color: #111827;
}

.inline-select {
  padding: 0.5rem 1rem;
  border: 2px solid #d1d5db;
  border-radius: 8px;
  font-size: 0.875rem;
  background: white;
  cursor: pointer;
  min-width: 140px;
  transition: all 0.2s ease;
}

.inline-select {
  border: 2px solid #d1d5db;
  border-radius: 8px;
  font-size: 0.875rem;
  background: white;
  cursor: pointer;
  min-width: 140px;
  transition: all 0.2s ease;
  padding: 0.5rem 1rem;
}

.inline-select:hover {
  background: #f3f4f6;
  border-color: #9CA3AF;
}

.inline-select:focus {
  outline: none;
  border-color: #3b82f6;
  box-shadow: 0 0 0 1px #3b82f6;
}

/* 認証が必要な場合のスタイル */
.auth-required {
  display: flex;
  align-items: center;
  justify-content: center;
  height: calc(100% - 60px);
  margin-top: 60px;
}

.auth-message {
  text-align: center;
  padding: 2rem;
  background: white;
  border-radius: 12px;
  box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
  max-width: 400px;
}

.auth-message h3 {
  margin: 0 0 1rem 0;
  color: #1f2937;
}

.auth-message p {
  margin: 0 0 2rem 0;
  color: #6b7280;
}

.login-button {
  display: inline-block;
  padding: 0.75rem 2rem;
  background: #3b82f6;
  color: white;
  text-decoration: none;
  border-radius: 8px;
  font-weight: 500;
  transition: all 0.2s ease;
}

.login-button:hover {
  background: #2563eb;
  transform: translateY(-1px);
}

/* 一覧表示スタイル */
.list-view {
  width: 100%;
  height: calc(100% - 80px);
  overflow-y: auto;
  padding: 0 1rem 1rem 1rem;
}

.loading-state, .empty-state, .error-state {
  text-align: center;
  padding: 2rem;
  color: #6b7280;
}

.error-state {
  color: #dc2626;
}

.retry-button {
  margin-top: 1rem;
  padding: 0.5rem 1rem;
  background: #3b82f6;
  color: white;
  border: none;
  border-radius: 6px;
  cursor: pointer;
  transition: all 0.2s ease;
}

.retry-button:hover {
  background: #2563eb;
}

.spinner {
  display: inline-block;
  width: 40px;
  height: 40px;
  border: 3px solid #e5e7eb;
  border-radius: 50%;
  border-top-color: #3b82f6;
  animation: spin 1s ease-in-out infinite;
}

@keyframes spin {
  to { transform: rotate(360deg); }
}

.message-list {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.message-item {
  background: white;
  border: 1px solid #e5e7eb;
  border-radius: 8px;
  padding: 1rem;
  cursor: pointer;
  transition: all 0.2s ease;
}

.message-item:hover {
  background: #f9fafb;
  border-color: #d1d5db;
}

.sender {
  font-weight: 600;
  color: #1f2937;
  margin-bottom: 0.25rem;
}

.text {
  color: #6b7280;
  font-size: 0.875rem;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.time {
  color: #9ca3af;
  font-size: 0.75rem;
  margin-top: 0.5rem;
}

.debug-info {
  margin-top: 2rem;
  padding: 1rem;
  background: #f3f4f6;
  border-radius: 8px;
  text-align: left;
}

.debug-info pre {
  margin: 0;
  font-size: 0.875rem;
  color: #374151;
}

/* メッセージ詳細モーダル */
.message-detail-modal {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.6);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
  padding: 2rem;
}

.message-detail-content {
  background: white;
  border-radius: 12px;
  box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1), 0 10px 10px -5px rgba(0, 0, 0, 0.04);
  max-width: 600px;
  width: 100%;
  max-height: 80vh;
  overflow-y: auto;
  position: relative;
}

.close-button {
  position: absolute;
  top: 1rem;
  right: 1rem;
  background: none;
  border: none;
  font-size: 1.5rem;
  cursor: pointer;
  color: #6b7280;
  width: 32px;
  height: 32px;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 50%;
  transition: all 0.2s ease;
}

.close-button:hover {
  background: #f3f4f6;
  color: #374151;
}

.detail-header {
  padding: 2rem 2rem 1rem 2rem;
  border-bottom: 1px solid #e5e7eb;
}

.detail-header h3 {
  margin: 0;
  font-size: 1.25rem;
  font-weight: 600;
  color: #111827;
}

.detail-body {
  padding: 1.5rem 2rem 2rem 2rem;
}

.detail-section {
  margin-bottom: 1.5rem;
}

.detail-section:last-child {
  margin-bottom: 0;
}

.detail-section label {
  display: block;
  font-size: 0.875rem;
  font-weight: 500;
  color: #374151;
  margin-bottom: 0.5rem;
}

.detail-section p {
  margin: 0;
  color: #111827;
  font-size: 1rem;
}

.final-message,
.original-message {
  padding: 1rem;
  border-radius: 8px;
  font-size: 1rem;
  line-height: 1.5;
}

.final-message {
  background: #f0f9ff;
  border: 1px solid #0ea5e9;
  color: #0c4a6e;
}


.current-rating {
  font-weight: normal;
  color: #6b7280;
  font-size: 0.875rem;
}

.rating-stars {
  display: flex;
  gap: 0.25rem;
  margin: 0.75rem 0;
}

.rating-stars.disabled {
  opacity: 0.6;
  pointer-events: none;
}

.star {
  font-size: 1.75rem;
  cursor: pointer;
  color: #d1d5db;
  transition: all 0.2s ease;
  user-select: none;
  padding: 0.25rem;
  border-radius: 4px;
}

.star.filled {
  color: #fbbf24;
  text-shadow: 0 0 4px rgba(251, 191, 36, 0.3);
}

.star.hover:hover {
  color: #f59e0b;
  background: #fef3c7;
  transform: scale(1.1);
}

.rating-loading {
  color: #6b7280;
  font-size: 0.875rem;
  font-style: italic;
  margin-top: 0.5rem;
}

.rating-help {
  color: #9ca3af;
  font-size: 0.75rem;
  margin-top: 0.5rem;
}


/* レスポンシブデザイン */
@media (max-width: 768px) {
  .inbox-list {
    height: calc(100vh - 6rem); /* モバイル版でも画面全体 */
  }
  
  .inline-select {
    font-size: 0.75rem;
    padding: 0.375rem 0.75rem;
    min-width: 120px;
  }
  
  .treemap-header {
    flex-direction: column;
    align-items: flex-start;
    gap: 0.75rem;
    padding: 0.75rem 0;
  }
  
  .treemap-header h3 {
    font-size: 1rem;
  }
  
  .message-list-header {
    flex-direction: column;
    align-items: flex-start;
    gap: 0.75rem;
    padding: 0.75rem 0;
  }
  
  .message-list-header h3 {
    font-size: 1rem;
  }
  
  .message-detail-modal {
    padding: 1rem;
  }
  
  .message-detail-content {
    max-height: 90vh;
  }
  
  .detail-header {
    padding: 1.5rem 1.5rem 1rem 1.5rem;
  }
  
  .detail-body {
    padding: 1rem 1.5rem 1.5rem 1.5rem;
  }
  
  .close-button {
    top: 0.75rem;
    right: 0.75rem;
  }
}

/* 440px以下の超小型モバイル対応 */
@media (max-width: 440px) {
  .inbox-list {
    padding: 0;
    margin: 0;
  }
  
  .list-view {
    padding: 0 12px 1rem 12px;
    width: 100%;
    box-sizing: border-box;
  }
  
  .treemap-section {
    padding: 0 12px 1rem 12px;
    width: 100%;
    box-sizing: border-box;
  }
  
  .inline-select {
    min-width: 100px;
    padding: 0.25rem 0.5rem;
    font-size: 0.75rem;
  }
  
  .message-item {
    padding: 12px;
    margin-bottom: 8px;
    overflow: hidden;
  }
  
  .text {
    white-space: normal;
    max-width: 100%;
    overflow: hidden;
    text-overflow: ellipsis;
    display: -webkit-box;
    -webkit-line-clamp: 2;
    -webkit-box-orient: vertical;
  }
}
</style>