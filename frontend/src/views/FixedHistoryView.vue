<template>
  <div class="history-page">
    <h1 class="page-title">送信履歴</h1>

    <!-- ローディング表示 -->
    <div v-if="isLoading" class="loading-state">
      <div class="spinner"></div>
      <p>履歴を読み込み中...</p>
    </div>

    <!-- エラー表示 -->
    <div v-else-if="error" class="error-state">
      <p class="error-message">{{ error }}</p>
      <button @click="retryLoad" class="retry-btn">再試行</button>
    </div>

    <!-- メイン表示 -->
    <div v-else class="history-content">
      <!-- 送信予定セクション -->
      <div class="section">
        <h2 class="section-title">送信予定 ({{ scheduledMessages.length }}件)</h2>
        <div class="message-container">
          <div v-if="scheduledMessages.length === 0" class="empty-state">
            送信予定のメッセージがありません
          </div>
          <div 
            v-for="message in scheduledMessages" 
            :key="message.id" 
            class="message-item"
          >
            <div class="message-info">
              <div class="recipient">宛先: {{ message.recipientName || message.recipientEmail || '不明' }}</div>
              <div class="scheduled-time">送信予定: {{ formatDateTime(message.scheduledAt) }}</div>
            </div>
            <div class="message-actions">
              <button @click="cancelSchedule(message.id)" class="cancel-btn">
                キャンセル
              </button>
            </div>
          </div>
        </div>
      </div>

      <!-- 送信済セクション -->
      <div class="section">
        <h2 class="section-title">送信済 ({{ sentMessages.length }}件)</h2>
        <div class="message-container">
          <div v-if="sentMessages.length === 0" class="empty-state">
            送信済みのメッセージがありません
          </div>
          <div 
            v-for="message in sentMessages" 
            :key="message.id" 
            class="message-item"
          >
            <div class="message-info">
              <div class="recipient">宛先: {{ message.recipientName || message.recipientEmail || '不明' }}</div>
              <div class="sent-time">送信済: {{ formatDateTime(message.sentAt) }}</div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { apiService } from '@/services/api'
import scheduleService from '@/services/scheduleService'
import { getUserInfo } from '@/services/messageService'

interface HistoryMessage {
  id: string
  recipientName?: string
  recipientEmail?: string
  scheduledAt?: string
  sentAt?: string
  status: string
}

// 状態管理
const isLoading = ref(true)
const error = ref('')
const scheduledMessages = ref<HistoryMessage[]>([])
const sentMessages = ref<HistoryMessage[]>([])

// 日時フォーマット関数
const formatDateTime = (dateString?: string) => {
  if (!dateString) return ''
  const date = new Date(dateString)
  return date.toLocaleString('ja-JP')
}

// ステータスラベル
const getStatusLabel = (status: string) => {
  const labels: Record<string, string> = {
    scheduled: '送信予定',
    sent: '送信済み',
    delivered: '配信済み',
    read: '既読'
  }
  return labels[status] || status
}

// スケジュールキャンセル
const cancelSchedule = async (scheduleId: string) => {
  if (!confirm('このスケジュールをキャンセルしますか？')) return
  
  try {
    await scheduleService.deleteSchedule(scheduleId)
    await loadData()
    alert('スケジュールをキャンセルしました')
  } catch (err) {
    console.error('スケジュールキャンセルエラー:', err)
    alert('スケジュールのキャンセルに失敗しました')
  }
}

// データ読み込み
const loadData = async () => {
  isLoading.value = true
  error.value = ''
  
  try {
    console.log('HistoryView: データ読み込み開始')
    
    // 送信予定メッセージを取得
    try {
      const schedulesResponse = await apiService.get('/schedules/?page=1&limit=100&status=pending')
      const schedulesData = schedulesResponse.data.data
      
      if (schedulesData?.schedules) {
        // 各スケジュールの受信者情報を取得
        const schedulesWithRecipientInfo = await Promise.all(
          schedulesData.schedules.map(async (schedule: any) => {
            let recipientName = 'Unknown User'
            let recipientEmail = 'unknown@example.com'
            
            // メッセージIDから受信者情報を取得
            if (schedule.messageId) {
              try {
                const messageResponse = await apiService.get(`/messages/${schedule.messageId}`)
                const message = messageResponse.data.data
                
                if (message?.recipientId && message.recipientId !== '000000000000000000000000') {
                  const userInfo = await getUserInfo(message.recipientId)
                  recipientName = userInfo.name || userInfo.email || '未登録の受信者'
                  recipientEmail = userInfo.email || 'unknown@example.com'
                }
              } catch (error) {
                console.warn('受信者情報の取得に失敗:', error)
              }
            }
            
            return {
              id: schedule.id,
              recipientName,
              recipientEmail,
              scheduledAt: schedule.scheduledAt,
              status: 'scheduled'
            }
          })
        )
        scheduledMessages.value = schedulesWithRecipientInfo
        console.log('送信予定メッセージ取得成功:', scheduledMessages.value.length, '件')
      } else {
        scheduledMessages.value = []
      }
    } catch (scheduleError) {
      console.error('送信予定メッセージ取得エラー:', scheduleError)
      scheduledMessages.value = []
    }

    // 送信済みメッセージを取得
    try {
      const messagesResponse = await apiService.get('/messages/drafts?page=1&limit=100')
      const allMessages = messagesResponse.data.data?.messages || []
      
      const sentMessages = allMessages.filter((msg: any) => 
        ['sent', 'delivered', 'read'].includes(msg.status)
      )
      
      // 送信済みメッセージを表示用に変換（受信者情報を取得）
      const formattedMessages = await Promise.all(
        sentMessages.map(async (message: any) => {
          let recipientName = '未登録の受信者'
          let recipientEmail = 'unknown@example.com'
          
          if (message.recipientId && message.recipientId !== '000000000000000000000000') {
            try {
              const userInfo = await getUserInfo(message.recipientId)
              recipientName = userInfo.name || userInfo.email || '未登録の受信者'
              recipientEmail = userInfo.email || 'unknown@example.com'
            } catch (error) {
              console.warn('受信者情報の取得に失敗:', error)
            }
          }
          
          return {
            id: message.id,
            recipientName,
            recipientEmail,
            sentAt: message.sentAt,
            status: message.status
          }
        })
      )
      sentMessages.value = formattedMessages
      console.log('送信済みメッセージ取得成功:', sentMessages.value.length, '件')
    } catch (messageError) {
      console.error('送信済みメッセージ取得エラー:', messageError)
      sentMessages.value = []
    }

    console.log('HistoryView: データ読み込み完了')
  } catch (err) {
    console.error('データ読み込みエラー:', err)
    error.value = 'データの読み込みに失敗しました'
  } finally {
    isLoading.value = false
  }
}

const retryLoad = () => {
  loadData()
}

// 初期化
onMounted(() => {
  console.log('FixedHistoryView mounted')
  loadData()
})
</script>

<style scoped>
.history-page {
  padding: 20px;
  background: #f5f5f5;
  min-height: 100vh;
}

.page-title {
  font-size: 24px;
  font-weight: 600;
  margin-bottom: 24px;
  color: #333;
}

.loading-state, .error-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 40px;
  background: white;
  border-radius: 8px;
  margin-bottom: 24px;
}

.spinner {
  width: 32px;
  height: 32px;
  border: 3px solid #f0f0f0;
  border-top: 3px solid #007bff;
  border-radius: 50%;
  animation: spin 1s linear infinite;
  margin-bottom: 16px;
}

@keyframes spin {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}

.error-message {
  color: #dc3545;
  margin-bottom: 16px;
}

.retry-btn {
  background: #007bff;
  color: white;
  border: none;
  border-radius: 4px;
  padding: 8px 16px;
  cursor: pointer;
}

.retry-btn:hover {
  background: #0056b3;
}

.section {
  margin-bottom: 32px;
}

.section-title {
  font-size: 18px;
  font-weight: 600;
  margin-bottom: 16px;
  color: #333;
}

.message-container {
  background: white;
  border-radius: 8px;
  border: 1px solid #ddd;
  overflow: hidden;
}

.empty-state {
  padding: 40px;
  text-align: center;
  color: #666;
}

.message-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 16px 20px;
  border-bottom: 1px solid #f0f0f0;
}

.message-item:last-child {
  border-bottom: none;
}

.message-info {
  flex: 1;
}

.recipient {
  font-weight: 500;
  margin-bottom: 4px;
}

.scheduled-time, .sent-time {
  font-size: 14px;
  color: #666;
  margin-bottom: 4px;
}


.message-actions {
  display: flex;
  gap: 8px;
}

.cancel-btn {
  background: #dc3545;
  color: white;
  border: none;
  border-radius: 4px;
  padding: 6px 12px;
  font-size: 14px;
  cursor: pointer;
}

.cancel-btn:hover {
  background: #c82333;
}
</style>