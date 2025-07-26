<template>
  <div class="history-page">
    <!-- ページタイトル -->
    <h1 class="page-title">送信履歴</h1>

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
      <div class="message-container">
        <div v-if="filteredScheduledMessages.length === 0" class="empty-state">
          送信予定のメッセージがありません
        </div>
        <div 
          v-for="message in filteredScheduledMessages" 
          :key="message.id" 
          class="message-item clickable"
          @click="showScheduleDetail(message.id)"
        >
          <div class="message-left">
            <div class="recipient-name">{{ message.recipientName || '' }}</div>
          </div>
          <div class="message-center">
            <div class="message-time">{{ formatDateTime(message.scheduledAt) }}</div>
          </div>
          <div class="message-right">
            <button class="edit-btn" @click.stop="editMessage(message.id)">
              編集
            </button>
          </div>
        </div>
      </div>
    </div>

    <!-- 送信済セクション -->
    <div class="section">
      <h2 class="section-title">送信済</h2>
      <div class="message-container">
        <div v-if="filteredSentMessages.length === 0" class="empty-state">
          送信済みのメッセージがありません
        </div>
        <div 
          v-for="message in filteredSentMessages" 
          :key="message.id" 
          class="message-item clickable"
          @click="showSentMessageDetail(message.id)"
        >
          <div class="message-left">
            <div class="recipient-name">{{ message.recipientName || '' }}</div>
          </div>
          <div class="message-center">
            <div class="message-time">{{ formatDateTime(message.sentAt) }}</div>
          </div>
          <div class="message-right">
            <div v-if="message.isRead" class="read-badge">既読</div>
          </div>
        </div>
      </div>
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
            <p class="detail-value">{{ selectedMessage.recipientName || selectedMessage.recipientEmail || '未設定' }}</p>
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
          
          <div class="detail-section" v-if="selectedMessage.originalText">
            <h4 class="detail-label">元のメッセージ</h4>
            <p class="detail-value message-text">{{ selectedMessage.originalText }}</p>
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
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { messageService, getUserInfo } from '@/services/messageService'
import scheduleService from '@/services/scheduleService'
import { apiService } from '@/services/api'

interface HistoryMessage {
  id: string
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

const editMessage = (messageId: string) => {
  router.push({
    name: 'message-compose',
    query: { editId: messageId }
  })
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
    const response = await scheduleService.getScheduleDetail(scheduleId)
    selectedMessage.value = {
      id: response.schedule.id,
      
    : response.schedule.recipientName || response.schedule.recipientEmail,
      recipientEmail: response.schedule.recipientEmail,
      scheduledAt: response.schedule.scheduledAt,
      sentAt: undefined,
      isRead: false,
      status: response.schedule.status as any,
      originalText: response.schedule.originalText,
      finalText: response.schedule.finalText,
      selectedTone: response.schedule.selectedTone
    }
  } catch (error) {
    console.error('スケジュール詳細の取得に失敗:', error)
    // フォールバック：キャッシュされたデータから取得
    const cachedMessage = scheduledMessages.value.find(m => m.id === scheduleId)
    if (cachedMessage) {
      selectedMessage.value = cachedMessage
    } else {
      detailError.value = 'スケジュールの詳細を取得できませんでした'
    }
  } finally {
    isLoadingDetail.value = false
  }
}

const loadMessageDetail = async (messageId: string) => {
  isLoadingDetail.value = true
  detailError.value = ''
  
  try {
    const response = await messageService.getMessage(messageId)
    selectedMessage.value = {
      id: response.data.id,
      recipientName: response.data.recipientId || '受信者', // TODO: 実際の名前を取得
      recipientEmail: response.data.recipientId || 'unknown@example.com', // TODO: 実際のメールアドレスを取得
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
    delivered: '配信済み',
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
    console.log('Loading scheduled messages directly via API...')
    // scheduleServiceを使わずに直接APIを呼び出し
    const response = await apiService.get('/schedules/?page=1&limit=100&status=pending')
    console.log('Direct API response:', response)
    
    const schedulesData = response.data.data
    if (schedulesData && schedulesData.schedules) {
      // 各スケジュールの受信者情報を並行して取得
      const schedulesWithRecipientInfo = await Promise.all(
        schedulesData.schedules.map(async (schedule: any) => {
          let recipientName = '受信者'
          let recipientEmail = 'unknown@example.com'
          
          // メッセージIDからメッセージ詳細を取得し、受信者情報を取得
          if (schedule.messageId) {
            try {
              const messageResponse = await apiService.get(`/messages/${schedule.messageId}`)
              const message = messageResponse.data.data
              
              if (message && message.recipientId) {
                // recipientIdからユーザー情報を取得（キャッシュ機能付き）
                try {
                  const userInfo = await getUserInfo(message.recipientId)
                  recipientName = userInfo.name
                  recipientEmail = userInfo.email
                } catch (userError) {
                  console.warn('Failed to get user info for:', message.recipientId)
                  // フォールバック: IDの末尾を使用
                  recipientName = `User-${message.recipientId.slice(-6)}`
                  recipientEmail = `${message.recipientId}@example.com`
                }
              }
            } catch (messageError) {
              console.warn('Failed to get message info for:', schedule.messageId)
            }
          }
          
          return {
            id: schedule.id,
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
      
      scheduledMessages.value = schedulesWithRecipientInfo
      console.log('Successfully loaded', scheduledMessages.value.length, 'scheduled messages')
    } else {
      console.warn('No schedules found in API response:', schedulesData)
      scheduledMessages.value = []
    }
  
  } catch (error) {
    console.error('送信予定メッセージの取得に失敗:', error)
    scheduledMessages.value = []
  }
}

const loadSentMessages = async () => {
  try {
    console.log('Loading sent messages directly via API...')
    // messageServiceを使わずに直接APIを呼び出し
    const response = await apiService.get('/messages/drafts?page=1&limit=100')
    console.log('Direct messages API response:', response)
    
    const allMessages = response.data.data?.messages || []
    console.log('All messages count:', allMessages.length)
    
    // ステータス別の統計
    const statusCounts: Record<string, number> = {}
    allMessages.forEach((msg: any) => {
      statusCounts[msg.status] = (statusCounts[msg.status] || 0) + 1
    })
    console.log('Message status breakdown:', statusCounts)
    
    // 送信済みステータスのメッセージをフィルタリング
    const sentMessages = allMessages.filter((msg: any) => 
      ['sent', 'delivered', 'read'].includes(msg.status)
    )
    console.log('Filtered sent messages count:', sentMessages.length)
    
    if (sentMessages.length > 0) {
      sentMessages.value = sentMessages.map((message: any) => ({
        id: message.id || '',
        recipientName: message.recipientName || message.recipientEmail || message.recipientId || '受信者',
        recipientEmail: message.recipientEmail || message.recipientId || 'unknown@example.com',
        sentAt: message.sentAt,
        isRead: message.status === 'read',
        status: message.status as 'sent' | 'delivered' | 'read',
        originalText: message.originalText,
        finalText: message.finalText || message.originalText
      }))
      console.log('Successfully loaded', sentMessages.value.length, 'sent messages')
    } else {
      console.log('No sent messages found - all messages are in draft status')
      sentMessages.value = []
    }
  } catch (error) {
    console.error('送信済みメッセージの取得に失敗:', error)
    sentMessages.value = []
  }
}

// 初期化
onMounted(async () => {
  isLoading.value = true
  try {
    await Promise.all([
      loadScheduledMessages(),
      loadSentMessages()
    ])
  } finally {
    isLoading.value = false
  }
})
</script>

<style scoped>
.history-page {
  background: #f5f5f5;
  font-family: var(--font-family-main);
  position: relative;
  width: 1280px;
  min-height: 100vh;
  margin: 0 auto;
  padding: 32px 80px;
  box-sizing: border-box;
}

.page-title {
  color: #000000;
  font-size: 24px;
  font-weight: 600;
  font-family: var(--font-family-main);
  line-height: 100%;
  margin: 0 0 32px 0;
}

/* フィルターバー */
.filter-bar {
  display: flex;
  gap: 24px;
  align-items: center;
  width: 100%;
  max-width: 1104px;
  margin: 0 0 40px 0;
}

.search-wrapper {
  flex: 1;
  max-width: 520px;
}

.search-input {
  width: 100%;
  height: 56px;
  padding: 0 24px;
  background: #C4E3FF;
  border: none;
  border-radius: 28px;
  font-size: 16px;
  color: #000000;
  outline: none;
  box-sizing: border-box;
  font-family: var(--font-family-main);
}

.search-input::placeholder {
  color: #666666;
  font-family: var(--font-family-main);
}

.sort-button {
  height: 56px;
  padding: 0 24px;
  background: #FFFFFF;
  border: 1px solid #D9D9D9;
  border-radius: 8px;
  font-size: 16px;
  color: #000000;
  cursor: pointer;
  font-weight: 400;
  font-family: var(--font-family-main);
  transition: all 0.2s ease;
}

.sort-button:hover {
  background: #F0F0F0;
}

/* セクション */
.section {
  margin-bottom: 48px;
  width: 100%;
  max-width: 1104px;
}

.section-title {
  font-size: 18px;
  font-weight: 600;
  color: #000000;
  margin: 0 0 16px 0;
  font-family: var(--font-family-main);
}

/* メッセージコンテナ */
.message-container {
  background: #FFFFFF;
  border: 1px solid #D9D9D9;
  border-radius: 12px;
  overflow: hidden;
  min-height: 200px;
}

.empty-state {
  padding: 40px 24px;
  text-align: center;
  color: #666666;
  font-size: 16px;
  font-family: var(--font-family-main);
}

.message-item {
  display: flex;
  align-items: center;
  padding: 20px 24px;
  border-bottom: 1px solid #F0F0F0;
  min-height: 60px;
  transition: background-color 0.2s ease;
}

.message-item:hover {
  background: #FAFAFA;
}

.message-item.clickable {
  cursor: pointer;
}

.message-item:last-child {
  border-bottom: none;
}

.message-left {
  flex: 1;
  min-width: 200px;
}

.message-center {
  flex: 1;
  text-align: center;
}

.message-right {
  flex: 0 0 100px;
  text-align: right;
}

.recipient-name {
  font-size: 16px;
  font-weight: 500;
  color: #000000;
  margin: 0;
  font-family: var(--font-family-main);
}

.message-time {
  font-size: 16px;
  color: #000000;
  margin: 0;
  font-family: var(--font-family-main);
}

.edit-btn {
  padding: 8px 16px;
  background: #E8F4FD;
  border: 1px solid #B3D9F7;
  border-radius: 6px;
  font-size: 14px;
  color: #000000;
  cursor: pointer;
  font-weight: 500;
  font-family: var(--font-family-main);
  transition: all 0.2s ease;
}

.edit-btn:hover {
  background: #D1E8F7;
  border-color: #9BC9F0;
}

.read-badge {
  font-size: 14px;
  color: #000000;
  margin: 0;
  font-family: var(--font-family-main);
  padding: 4px 8px;
  background: #E8F5E8;
  border-radius: 4px;
  border: 1px solid #B8E6B8;
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
  padding: 20px;
}

.modal-content {
  background: #FFFFFF;
  border-radius: 12px;
  width: 100%;
  max-width: 600px;
  max-height: 80vh;
  overflow-y: auto;
  box-shadow: 0 10px 30px rgba(0, 0, 0, 0.3);
}

.modal-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 24px 24px 16px 24px;
  border-bottom: 1px solid #E0E0E0;
}

.modal-title {
  font-size: 20px;
  font-weight: 600;
  color: #000000;
  margin: 0;
  font-family: var(--font-family-main);
}

.close-btn {
  background: none;
  border: none;
  font-size: 24px;
  color: #666666;
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
  background: #F0F0F0;
  color: #000000;
}

.modal-body {
  padding: 24px;
}

.detail-section {
  margin-bottom: 24px;
}

.detail-section:last-child {
  margin-bottom: 0;
}

.detail-label {
  font-size: 14px;
  font-weight: 600;
  color: #666666;
  margin: 0 0 8px 0;
  font-family: var(--font-family-main);
  text-transform: uppercase;
  letter-spacing: 0.5px;
}

.detail-value {
  font-size: 16px;
  color: #000000;
  margin: 0;
  font-family: var(--font-family-main);
  line-height: 1.5;
}

.detail-value.message-text {
  background: #F8F9FA;
  border: 1px solid #E0E0E0;
  border-radius: 8px;
  padding: 16px;
  white-space: pre-wrap;
  word-wrap: break-word;
}

.detail-value.final-message {
  background: #E8F5E8;
  border-color: #B8E6B8;
}

.detail-value.status {
  display: inline-block;
  padding: 4px 12px;
  border-radius: 16px;
  font-size: 14px;
  font-weight: 500;
}

.status-scheduled {
  background: #FFF3CD;
  color: #856404;
}

.status-sent {
  background: #D1ECF1;
  color: #0C5460;
}

.status-delivered {
  background: #D4EDDA;
  color: #155724;
}

.status-read {
  background: #D4EDDA;
  color: #155724;
}

.loading-state {
  padding: 40px;
  text-align: center;
  color: #666666;
}

.spinner {
  width: 32px;
  height: 32px;
  border: 3px solid #F0F0F0;
  border-top: 3px solid #007BFF;
  border-radius: 50%;
  animation: spin 1s linear infinite;
  margin: 0 auto 16px;
}

@keyframes spin {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}

.error-state {
  padding: 24px;
  text-align: center;
}

.error-message {
  color: #DC3545;
  margin: 0 0 16px 0;
  font-size: 16px;
}

.retry-btn {
  background: #007BFF;
  color: white;
  border: none;
  border-radius: 6px;
  padding: 8px 16px;
  cursor: pointer;
  font-size: 14px;
  font-family: var(--font-family-main);
  transition: background 0.2s ease;
}

.retry-btn:hover {
  background: #0056B3;
}

/* レスポンシブ対応 */
@media (max-width: 1320px) {
  .history-page {
    width: 100%;
    padding: 32px 40px;
  }
}

@media (max-width: 768px) {
  .history-page {
    padding: 20px;
  }
  
  .filter-bar {
    flex-direction: column;
    gap: 16px;
    align-items: stretch;
  }
  
  .search-wrapper {
    max-width: none;
  }
  
  .message-item {
    flex-direction: column;
    align-items: flex-start;
    gap: 8px;
    padding: 16px;
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