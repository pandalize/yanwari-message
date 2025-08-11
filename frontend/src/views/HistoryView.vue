<template>
  <PageContainer>
    <!-- ページタイトル -->
    <PageTitle>送信履歴</PageTitle>

    <!-- 検索・フィルター -->
    <div class="filter-bar">
      <div class="search-wrapper">
        <input 
          v-model="searchQuery" 
          type="text" 
          placeholder="検索" 
          class="search-input"
        />
      </div>
      <button class="sort-button" @click="toggleSort">順番切替</button>
    </div>

    <!-- 送信予定セクション -->
    <div class="section">
      <h2 class="section-title">送信予定</h2>
      <MessageContainer 
        width="100%" 
        min-height="200px"
        margin-bottom="var(--spacing-2xl)"
      >
        <div v-if="filteredScheduledMessages.length === 0" class="empty-state">
          送信予定のメッセージがありません
        </div>
        <MessageListItem 
          v-for="message in filteredScheduledMessages" 
          :key="message.id" 
          :clickable="true"
          min-height="80px"
          padding="var(--spacing-lg)"
          @click="showScheduleDetail(message.id)"
        >
          <template #left>
            <div class="recipient-name">{{ message.recipientName }}</div>
          </template>
          <template #center>
            <div class="message-time">{{ formatDateTime(message.scheduledAt) }}</div>
          </template>
          <template #right>
            <div class="action-buttons" @click.stop>
              <button 
                @click.stop="editMessage(message.id)" 
                class="action-button edit-button"
                title="メッセージを編集"
              >
                編集
              </button>
              <button 
                @click.stop="cancelSchedule(message.id)" 
                class="action-button cancel-button"
                title="送信をキャンセル"
              >
                キャンセル
              </button>
            </div>
          </template>
        </MessageListItem>
      </MessageContainer>
    </div>

    <!-- 送信済セクション -->
    <div class="section">
      <h2 class="section-title">送信済</h2>
      <MessageContainer 
        width="100%" 
        min-height="200px"
      >
        <div v-if="filteredSentMessages.length === 0" class="empty-state">
          送信済みのメッセージがありません
        </div>
        <MessageListItem 
          v-for="message in filteredSentMessages" 
          :key="message.id" 
          :clickable="true"
          min-height="80px"
          padding="var(--spacing-lg)"
          @click="showSentMessageDetail(message.id)"
        >
          <template #left>
            <div class="recipient-name">{{ message.recipientName }}</div>
          </template>
          <template #center>
            <div class="message-time">{{ formatDateTime(message.sentAt) }}</div>
          </template>
          <template #right>
            <div v-if="message.isRead" class="read-badge">既読</div>
          </template>
        </MessageListItem>
      </MessageContainer>
    </div>
    
    <!-- メッセージ詳細モーダル -->
    <div v-if="showModal" class="modal-overlay" @click="closeModal">
      <div class="modal-content" @click.stop>
        <div class="modal-header">
          <h3 class="modal-title">メッセージ詳細</h3>
          <button class="close-btn" @click="closeModal">×</button>
        </div>
        
        <div v-if="isLoadingDetail" class="loading-state">
          <div class="spinner"></div>
          <p>メッセージを読み込み中...</p>
        </div>
        
        <div v-else-if="selectedMessage" class="modal-body">
          <div class="detail-section">
            <h4 class="detail-label">送信先</h4>
            <p class="detail-value recipient-name">{{ selectedMessage.recipientName }}</p>
          </div>
          
          <div class="detail-section">
            <h4 class="detail-label">送信日時</h4>
            <p class="detail-value">{{ formatDateTime(selectedMessage.scheduledAt || selectedMessage.sentAt) }}</p>
          </div>
          
          <div class="detail-section">
            <h4 class="detail-label">ステータス</h4>
            <p class="detail-value status" :class="`status-${selectedMessage.status}`">
              {{ getStatusLabel(selectedMessage.status) }}
            </p>
          </div>
          
          <div class="detail-section" v-if="selectedMessage.finalText">
            <h4 class="detail-label">送信メッセージ</h4>
            <p class="detail-value message-text final-message">{{ selectedMessage.finalText }}</p>
          </div>
          
          <div class="detail-section" v-if="selectedMessage.selectedTone">
            <h4 class="detail-label">選択したトーン</h4>
            <p class="detail-value">{{ getToneLabel(selectedMessage.selectedTone) }}</p>
          </div>
        </div>
        
        <div v-if="detailError" class="error-state">
          <p class="error-message">{{ detailError }}</p>
          <button class="retry-btn" @click="retryLoadDetail">再試行</button>
        </div>
      </div>
    </div>
  </PageContainer>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { useRouter } from 'vue-router'
import PageContainer from '@/components/layout/PageContainer.vue'
import PageTitle from '@/components/layout/PageTitle.vue'
import { messageService, getUserInfo, clearUserCache } from '@/services/messageService'
import scheduleService from '@/services/scheduleService'
import { apiService } from '@/services/api'
import MessageContainer from '@/components/common/MessageContainer.vue'
import MessageListItem from '@/components/common/MessageListItem.vue'

interface HistoryMessage {
  id: string
  messageId?: string
  recipientName?: string
  recipientEmail?: string
  scheduledAt?: string
  sentAt?: string
  isRead?: boolean
  status: 'scheduled' | 'sent' | 'delivered' | 'read'
  originalText?: string
  finalText?: string
  selectedTone?: string
}

const router = useRouter()

// 状態管理
const searchQuery = ref('')
const sortOrder = ref<'asc' | 'desc'>('desc')
const scheduledMessages = ref<HistoryMessage[]>([])
const sentMessages = ref<HistoryMessage[]>([])
const isLoading = ref(false)

// モーダル関連の状態
const showModal = ref(false)
const selectedMessage = ref<HistoryMessage | null>(null)
const selectedMessageId = ref('')
const isLoadingDetail = ref(false)
const detailError = ref('')

// 計算プロパティ
const filteredScheduledMessages = computed(() => {
  let filtered = scheduledMessages.value
  
  // TODO: 将来的にはスケジュールとメッセージのステータス同期を実装
  // 現時点では全てのスケジュールを表示（ユーザーが送信予定として確認できるように）
  // filtered = filtered (フィルタリングなし)
  
  if (searchQuery.value) {
    filtered = filtered.filter(msg => 
      msg.recipientName?.toLowerCase().includes(searchQuery.value.toLowerCase()) ||
      msg.recipientEmail?.toLowerCase().includes(searchQuery.value.toLowerCase())
    )
  }
  
  return filtered.sort((a, b) => {
    const dateA = new Date(a.scheduledAt || 0)
    const dateB = new Date(b.scheduledAt || 0)
    return sortOrder.value === 'desc' ? dateB.getTime() - dateA.getTime() : dateA.getTime() - dateB.getTime()
  })
})

const filteredSentMessages = computed(() => {
  let filtered = sentMessages.value
  
  if (searchQuery.value) {
    filtered = filtered.filter(msg => 
      msg.recipientName?.toLowerCase().includes(searchQuery.value.toLowerCase()) ||
      msg.recipientEmail?.toLowerCase().includes(searchQuery.value.toLowerCase())
    )
  }
  
  return filtered.sort((a, b) => {
    const dateA = new Date(a.sentAt || 0)
    const dateB = new Date(b.sentAt || 0)
    return sortOrder.value === 'desc' ? dateB.getTime() - dateA.getTime() : dateA.getTime() - dateB.getTime()
  })
})

// メソッド
const formatDateTime = (dateString?: string) => {
  if (!dateString) return ''
  
  const date = new Date(dateString)
  const year = date.getFullYear()
  const month = String(date.getMonth() + 1).padStart(2, '0')
  const day = String(date.getDate()).padStart(2, '0')
  const hours = String(date.getHours()).padStart(2, '0')
  const minutes = String(date.getMinutes()).padStart(2, '0')
  
  return `${month}/${day}/${year} ${hours}:${minutes}`
}

const toggleSort = () => {
  sortOrder.value = sortOrder.value === 'desc' ? 'asc' : 'desc'
}

const editMessage = async (messageId: string) => {
  console.log('📝 編集ボタンがクリックされました:', messageId)
  
  try {
    // スケジュール情報からメッセージIDを取得
    const schedule = scheduledMessages.value.find(s => s.id === messageId)
    if (!schedule || !schedule.messageId) {
      console.error('スケジュールまたはメッセージIDが見つかりません')
      alert('編集対象のメッセージが見つかりません')
      return
    }
    
    // メッセージの詳細を取得
    if (!schedule.messageId || schedule.messageId === '000000000000000000000000') {
      console.error('無効なメッセージIDです:', schedule.messageId)
      alert('編集対象のメッセージIDが無効です')
      return
    }
    const messageResponse = await apiService.get(`/messages/${schedule.messageId}`)
    const message = messageResponse.data.data
    
    console.log('編集対象メッセージ:', message)
    
    // メッセージ編集画面に遷移（元のメッセージと受信者情報を渡す）
    router.push({
      name: 'message-compose',
      query: { 
        editId: messageId,
        originalText: message.originalText || '',
        recipientEmail: schedule.recipientEmail || '',
        recipientName: schedule.recipientName || '',
        editScheduleId: messageId // スケジュールIDも渡す
      }
    })
  } catch (error) {
    console.error('メッセージ編集準備エラー:', error)
    alert('メッセージの編集準備に失敗しました')
  }
}

const cancelSchedule = async (scheduleId: string) => {
  console.log('🗑️ キャンセルボタンがクリックされました:', scheduleId)
  if (!confirm('このスケジュールをキャンセルしますか？')) {
    return
  }
  
  try {
    await scheduleService.deleteSchedule(scheduleId)
    // スケジュール一覧を更新
    await loadScheduledMessages()
    // 成功メッセージ（簡易版）
    alert('スケジュールをキャンセルしました')
  } catch (error) {
    console.error('スケジュールキャンセルエラー:', error)
    alert('スケジュールのキャンセルに失敗しました')
  }
}

// モーダル関連のメソッド
const showScheduleDetail = async (scheduleId: string) => {
  selectedMessageId.value = scheduleId
  showModal.value = true
  await loadScheduleDetail(scheduleId)
}

const showSentMessageDetail = async (messageId: string) => {
  selectedMessageId.value = messageId
  showModal.value = true
  await loadMessageDetail(messageId)
}

const closeModal = () => {
  showModal.value = false
  selectedMessage.value = null
  selectedMessageId.value = ''
  detailError.value = ''
}

const loadScheduleDetail = async (scheduleId: string) => {
  isLoadingDetail.value = true
  detailError.value = ''
  
  try {
    // まずキャッシュされたデータから取得を試行
    const cachedMessage = scheduledMessages.value.find(m => m.id === scheduleId)
    if (cachedMessage) {
      // キャッシュからメッセージ詳細を追加で取得
      try {
        // 無効なObjectIDや空値をチェック
        const messageIdToFetch = cachedMessage.messageId || scheduleId
        if (!messageIdToFetch || messageIdToFetch === '000000000000000000000000') {
          console.warn('無効なメッセージIDのためAPI呼び出しをスキップ:', messageIdToFetch)
          selectedMessage.value = cachedMessage
          return
        }
        const messageResponse = await apiService.get(`/messages/${messageIdToFetch}`)
        const message = messageResponse.data.data
        
        selectedMessage.value = {
          ...cachedMessage,
          originalText: message.originalText || cachedMessage.originalText,
          finalText: message.finalText || message.originalText || cachedMessage.finalText,
          selectedTone: message.selectedTone || cachedMessage.selectedTone
        }
      } catch (messageError) {
        console.warn('メッセージ詳細の取得に失敗、キャッシュデータを使用:', messageError)
        selectedMessage.value = cachedMessage
      }
    } else {
      // キャッシュにない場合は直接APIから取得
      try {
        const response = await apiService.get(`/schedules/${scheduleId}`)
        const schedule = response.data.data
        
        // スケジュールに関連するメッセージから受信者情報を取得
        let recipientName = 'Unknown User'
        let recipientEmail = 'unknown@example.com'
        
        if (schedule.messageId && schedule.messageId !== '000000000000000000000000') {
          try {
            const messageResponse = await apiService.get(`/messages/${schedule.messageId}`)
            const message = messageResponse.data.data
            
            if (message?.recipientId && message.recipientId !== '000000000000000000000000') {
              const userInfo = await getUserInfo(message.recipientId)
              recipientName = userInfo.name || userInfo.email || '未登録の受信者'
              recipientEmail = userInfo.email || 'unknown@example.com'
            }
          } catch (messageError) {
            console.warn('メッセージから受信者情報の取得に失敗:', messageError)
          }
        }
        
        selectedMessage.value = {
          id: schedule.id,
          recipientName,
          recipientEmail,
          scheduledAt: schedule.scheduledAt,
          sentAt: undefined,
          isRead: false,
          status: schedule.status as any,
          originalText: 'スケジュールされたメッセージ',
          finalText: 'スケジュールされたメッセージ',
          selectedTone: 'gentle'
        }
      } catch (apiError) {
        console.error('API からのスケジュール詳細取得失敗:', apiError)
        detailError.value = 'スケジュールの詳細を取得できませんでした'
      }
    }
  } catch (error) {
    console.error('スケジュール詳細の取得に失敗:', error)
    detailError.value = 'スケジュールの詳細を取得できませんでした'
  } finally {
    isLoadingDetail.value = false
  }
}

const loadMessageDetail = async (messageId: string) => {
  isLoadingDetail.value = true
  detailError.value = ''
  
  try {
    const response = await messageService.getMessage(messageId)
    
    // 受信者の名前を取得
    let recipientName = 'Unknown User'
    let recipientEmail = 'unknown@example.com'
    
    if (response.data.recipientId && response.data.recipientId !== '000000000000000000000000') {
      try {
        const userInfo = await getUserInfo(response.data.recipientId)
        recipientName = userInfo.name || userInfo.email || '未登録の受信者'
        recipientEmail = userInfo.email || 'unknown@example.com'
      } catch (userError) {
        console.warn('受信者情報の取得に失敗:', userError)
      }
    }
    
    selectedMessage.value = {
      id: response.data.id,
      recipientName,
      recipientEmail,
      scheduledAt: response.data.scheduledAt,
      sentAt: response.data.sentAt,
      isRead: response.data.status === 'read',
      status: response.data.status as any,
      originalText: response.data.originalText,
      finalText: response.data.finalText || response.data.originalText,
      selectedTone: response.data.selectedTone
    }
  } catch (error) {
    console.error('メッセージ詳細の取得に失敗:', error)
    // フォールバック：キャッシュされたデータから取得
    const cachedMessage = sentMessages.value.find(m => m.id === messageId)
    if (cachedMessage) {
      selectedMessage.value = cachedMessage
    } else {
      detailError.value = 'メッセージの詳細を取得できませんでした'
    }
  } finally {
    isLoadingDetail.value = false
  }
}

const getStatusLabel = (status: string) => {
  const labels: Record<string, string> = {
    scheduled: '送信予定',
    sent: '送信済み',
    delivered: '送信済み',
    read: '既読',
    draft: '下書き'
  }
  return labels[status] || status
}

const getToneLabel = (tone: string) => {
  const labels: Record<string, string> = {
    gentle: 'やんわり',
    constructive: '建設的',
    casual: 'カジュアル'
  }
  return labels[tone] || tone
}

const retryLoadDetail = async () => {
  if (!selectedMessageId.value) return
  
  // 送信予定メッセージか送信済みメッセージかを判定
  const isScheduledMessage = scheduledMessages.value.some(m => m.id === selectedMessageId.value)
  
  if (isScheduledMessage) {
    await loadScheduleDetail(selectedMessageId.value)
  } else {
    await loadMessageDetail(selectedMessageId.value)
  }
}

const loadScheduledMessages = async () => {
  try {
    // Clear any cached user info to get fresh data
    clearUserCache()
    // scheduleServiceを使わずに直接APIを呼び出し
    const response = await apiService.get('/schedules/?page=1&limit=100&status=pending')
    
    console.log('送信予定スケジュールAPI レスポンス:', response.data)
    const schedulesData = response.data.data
    if (schedulesData && schedulesData.schedules) {
      console.log('取得したpendingスケジュール数:', schedulesData.schedules.length)
      // 各スケジュールの受信者情報を取得
      const schedulesWithRecipientInfo = await Promise.all(
        schedulesData.schedules.map(async (schedule: any) => {
          let recipientName = 'Unknown User'
          let recipientEmail = 'unknown@example.com'
          
          // メッセージIDから受信者情報を取得（簡略化）
          if (schedule.messageId && schedule.messageId !== '000000000000000000000000') {
            try {
              const messageResponse = await apiService.get(`/messages/${schedule.messageId}`)
              const message = messageResponse.data.data

              // メッセージが実際に送信済み/配信済みの場合はnullを返す（除外する）
              if (message && ['sent', 'delivered', 'read'].includes(message.status)) {
                console.log(`スケジュール ${schedule.id} は既に配信済み (${message.status}) のためスキップ`)
                return null
              }

              if (message?.recipientId && message.recipientId !== '000000000000000000000000') {
                const userInfo = await getUserInfo(message.recipientId)
                console.log('スケジュール受信者情報:', userInfo)
                recipientName = userInfo.name || userInfo.email || '未登録の受信者'
                recipientEmail = userInfo.email || 'unknown@example.com'
              }
            } catch (error) {
              // エラー時はデフォルト値を使用
              console.warn('受信者情報の取得に失敗:', error)
            }
          }

          return {
            id: schedule.id,
            messageId: schedule.messageId, // メッセージIDを追加
            recipientName,
            recipientEmail,
            scheduledAt: schedule.scheduledAt,
            status: 'scheduled' as const,
            originalText: 'スケジュールされたメッセージ',
            finalText: 'スケジュールされたメッセージ',
            selectedTone: 'gentle'
          }
        })
      )
      
      // nullを除外（実際に配信済みのスケジュールを除く）
      const validSchedules = schedulesWithRecipientInfo.filter(schedule => schedule !== null)
      console.log('フィルタリング後の有効なスケジュール数:', validSchedules.length)
      console.log('有効なスケジュール:', validSchedules)
      scheduledMessages.value = validSchedules
    } else {
      scheduledMessages.value = []
    }
  
  } catch (error) {
    console.error('送信予定メッセージの取得に失敗:', error)
    scheduledMessages.value = []
  }
}

const loadSentMessages = async () => {
  try {
    // 送信済みメッセージAPIを使用
    const response = await apiService.get('/messages/sent?page=1&limit=100')
    
    console.log('送信済みメッセージAPI レスポンス:', response.data)
    const sentMessagesData = response.data.data?.messages || []
    console.log('取得した送信済みメッセージ数:', sentMessagesData.length)
    
    if (sentMessagesData.length > 0) {
      // 送信済みメッセージを表示用に変換（受信者情報を取得）
      const formattedMessages = await Promise.all(
        sentMessagesData.map(async (message: any) => {
          let recipientName = 'Unknown User'
          let recipientEmail = 'unknown@example.com'
          
          // 受信者情報を取得
          console.log('送信済みメッセージ受信者ID:', message.recipientId)
          if (message.recipientId && message.recipientId !== '000000000000000000000000') {
            try {
              const userInfo = await getUserInfo(message.recipientId)
              console.log('送信済み受信者情報:', userInfo)
              console.log('userInfo.name:', userInfo.name, 'userInfo.email:', userInfo.email)
              recipientName = userInfo.name || userInfo.email || '未登録の受信者'
              recipientEmail = userInfo.email || 'unknown@example.com'
            } catch (error) {
              console.warn('受信者情報の取得に失敗:', error)
            }
          }

          const formattedMessage = {
            id: message.id,
            recipientName,
            recipientEmail,
            sentAt: message.sentAt || message.updatedAt,
            isRead: message.status === 'read',
            status: message.status,
            originalText: message.originalText || 'メッセージ',
            finalText: message.finalText || message.originalText || 'メッセージ'
          }
          console.log('フォーマット済み送信済みメッセージ:', formattedMessage)
          return formattedMessage
        })
      )
      
      sentMessages.value = formattedMessages
    } else {
      sentMessages.value = []
    }
  } catch (error) {
    console.error('送信済みメッセージの取得に失敗:', error)
    sentMessages.value = []
  }
}

// データリロード関数
const reloadData = async () => {
  isLoading.value = true
  try {
    await Promise.all([
      loadScheduledMessages(),
      loadSentMessages()
    ])
  } finally {
    isLoading.value = false
  }
}

// 初期化
onMounted(async () => {
  try {
    await reloadData()
    setupVisibilityHandler()
  } catch (error) {
    console.error('HistoryView data loading failed:', error)
  }
})

// ページが表示される度にデータを更新（ナビゲーション後）
const refreshData = () => {
  // 少し遅延させてAPIが完了するのを待つ
  setTimeout(reloadData, 500)
}

// ページの可視性変更時にもデータを更新（修正版）
let visibilityHandler: (() => void) | null = null

const setupVisibilityHandler = () => {
  if (visibilityHandler) {
    document.removeEventListener('visibilitychange', visibilityHandler)
  }
  
  visibilityHandler = () => {
    if (!document.hidden) {
      refreshData()
    }
  }
  
  document.addEventListener('visibilitychange', visibilityHandler)
}

// コンポーネントがアンマウントされる時にイベントリスナーを削除
onUnmounted(() => {
  if (visibilityHandler) {
    document.removeEventListener('visibilitychange', visibilityHandler)
    visibilityHandler = null
  }
})
</script>

<style scoped>

/* フィルターバー */
.filter-bar {
  display: flex;
  gap: var(--spacing-lg);
  align-items: center;
  width: 100%;
  max-width: 1104px;
  margin: 0 0 var(--spacing-2xl) 0;
}

.search-wrapper {
  flex: 1;
  max-width: 520px;
}

.search-input {
  width: 100%;
  height: 56px;
  padding: 0 var(--spacing-lg);
  background: var(--primary-color);
  border: none;
  border-radius: 28px;
  font-size: var(--font-size-md);
  color: var(--text-primary);
  outline: none;
  box-sizing: border-box;
  font-family: var(--font-family-main);
}

.search-input::placeholder {
  color: var(--text-secondary);
  font-family: var(--font-family-main);
}

.sort-button {
  height: 56px;
  padding: 0 var(--spacing-lg);
  background: var(--background-primary);
  border: 1px solid var(--border-color);
  border-radius: var(--radius-md);
  font-size: var(--font-size-md);
  color: var(--text-primary);
  cursor: pointer;
  font-weight: var(--font-weight-regular);
  font-family: var(--font-family-main);
  transition: all 0.2s ease;
}

.sort-button:hover {
  background: var(--background-muted);
}

/* セクション */
.section {
  margin-bottom: var(--spacing-2xl);
  width: 100%;
  max-width: 1104px;
}

/* メッセージアイテムの高さ統一 */
.section :deep(.message-list-item) {
  min-height: 80px !important;
  display: flex;
  align-items: center;
}

.section-title {
  font-size: var(--font-size-lg);
  font-weight: 600;
  color: var(--text-primary);
  margin: 0 0 var(--spacing-md) 0;
  font-family: var(--font-family-main);
}


.empty-state {
  padding: var(--spacing-2xl) var(--spacing-lg);
  text-align: center;
  color: var(--text-secondary);
  font-size: var(--font-size-md);
  font-family: var(--font-family-main);
}


.recipient-name {
  font-size: var(--font-size-md);
  font-weight: 500;
  color: var(--text-primary);
  margin: 0;
  font-family: var(--font-family-main);
}

.message-time {
  font-size: var(--font-size-md);
  color: var(--text-primary);
  margin: 0;
  font-family: var(--font-family-main);
}


.action-buttons {
  display: flex;
  gap: var(--spacing-sm);
  justify-content: flex-end;
  align-items: center;
  min-height: 32px; /* ボタンの高さを統一 */
  z-index: 10; /* ボタンが確実にクリックできるように */
  position: relative;
  pointer-events: auto;
}

.action-button {
  padding: var(--spacing-sm) var(--spacing-md);
  border: none;
  border-radius: var(--radius-sm);
  background: var(--primary-color);
  color: var(--text-primary);
  cursor: pointer;
  font-size: var(--font-size-sm);
  font-family: var(--font-family-main);
  font-weight: var(--font-weight-regular);
  pointer-events: auto;
  z-index: 11;
  position: relative;
  transition: background-color 0.2s ease;
}

.action-button:hover {
  background: var(--primary-color-dark);
}

.action-button:active {
  background: var(--primary-color-darker);
}



.read-badge {
  font-size: var(--font-size-sm);
  color: var(--text-primary);
  margin: 0;
  font-family: var(--font-family-main);
  padding: var(--spacing-xs) var(--spacing-sm);
  background: var(--success-color);
  border-radius: var(--radius-sm);
  border: 1px solid var(--success-color);
  display: flex;
  align-items: center;
  min-height: 32px; /* アクションボタンと同じ高さに統一 */
  box-sizing: border-box;
}

/* モーダルスタイル */
.modal-overlay {
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
  padding: var(--spacing-lg);
}

.modal-content {
  background: var(--background-primary);
  border-radius: var(--radius-lg);
  width: 100%;
  max-width: 600px;
  max-height: 80vh;
  overflow-y: auto;
  box-shadow: var(--shadow-lg);
}

.modal-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: var(--spacing-lg) var(--spacing-lg) var(--spacing-md) var(--spacing-lg);
  border-bottom: 1px solid var(--border-color);
}

.modal-title {
  font-size: var(--font-size-xl);
  font-weight: 600;
  color: var(--text-primary);
  margin: 0;
  font-family: var(--font-family-main);
}

.close-btn {
  background: none;
  border: none;
  font-size: var(--font-size-2xl);
  color: var(--text-secondary);
  cursor: pointer;
  padding: 0;
  width: 32px;
  height: 32px;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 50%;
  transition: all 0.2s ease;
}

.close-btn:hover {
  background: var(--background-muted);
  color: var(--text-primary);
}

.modal-body {
  padding: var(--spacing-lg);
}

.detail-section {
  margin-bottom: var(--spacing-lg);
}

.detail-section:last-child {
  margin-bottom: 0;
}

.detail-label {
  font-size: var(--font-size-sm);
  font-weight: 600;
  color: var(--text-secondary);
  margin: 0 0 var(--spacing-sm) 0;
  font-family: var(--font-family-main);
  text-transform: uppercase;
  letter-spacing: 0.5px;
}

.detail-value {
  font-size: var(--font-size-md);
  color: var(--text-primary);
  margin: 0;
  font-family: var(--font-family-main);
  line-height: var(--line-height-normal);
}

.detail-value.message-text {
  background: var(--background-secondary);
  border: 1px solid var(--border-color);
  border-radius: var(--radius-md);
  padding: var(--spacing-md);
  white-space: pre-wrap;
  word-wrap: break-word;
}

.detail-value.final-message {
  background: var(--success-color);
  border-color: var(--success-color);
}

.detail-value.status {
  display: inline-block;
  padding: var(--spacing-xs) var(--spacing-md);
  border-radius: var(--radius-xl);
  font-size: var(--font-size-sm);
  font-weight: 500;
}

.status-scheduled {
  background: #FFF3CD;
  color: #856404;
}

.status-sent {
  background: var(--secondary-color-light);
  color: var(--text-primary);
}

.status-delivered {
  background: var(--secondary-color-light);
  color: var(--text-primary);
}

.status-read {
  background: var(--success-color);
  color: var(--text-primary);
}



.loading-state {
  padding: var(--spacing-2xl);
  text-align: center;
  color: var(--text-secondary);
}

.spinner {
  width: 32px;
  height: 32px;
  border: 3px solid var(--background-muted);
  border-top: 3px solid var(--secondary-color);
  border-radius: 50%;
  animation: spin 1s linear infinite;
  margin: 0 auto var(--spacing-md);
}

@keyframes spin {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}

.error-state {
  padding: var(--spacing-lg);
  text-align: center;
}

.error-message {
  color: var(--error-color);
  margin: 0 0 var(--spacing-md) 0;
  font-size: var(--font-size-md);
}

.retry-btn {
  background: var(--secondary-color);
  color: var(--text-primary);
  border: none;
  border-radius: var(--radius-sm);
  padding: var(--spacing-sm) var(--spacing-md);
  cursor: pointer;
  font-size: var(--font-size-sm);
  font-family: var(--font-family-main);
  transition: background 0.2s ease;
}

.retry-btn:hover {
  background: var(--secondary-color-dark);
}

/* レスポンシブ対応 */
@media (max-width: 1320px) {
  .history-page {
    width: 100%;
    padding: var(--spacing-xl) var(--spacing-2xl);
  }
}

@media (max-width: 768px) {
  .history-page {
    padding: var(--spacing-lg);
  }
  
  .filter-bar {
    flex-direction: column;
    gap: var(--spacing-md);
    align-items: stretch;
  }
  
  .search-wrapper {
    max-width: none;
  }
  
  .message-item {
    flex-direction: column;
    align-items: flex-start;
    gap: var(--spacing-sm);
    padding: var(--spacing-md);
  }
  
  .message-left,
  .message-center,
  .message-right {
    flex: none;
    text-align: left;
    width: 100%;
    min-width: auto;
  }
  
  .message-right {
    text-align: right;
  }
}
</style>