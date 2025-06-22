<template>
  <div class="schedule-list">
    <div class="header">
      <h2>📅 送信スケジュール一覧</h2>
      <div class="header-controls">
        <select v-model="statusFilter" @change="loadSchedules" class="status-filter">
          <option value="">すべて</option>
          <option value="pending">送信待ち</option>
          <option value="sent">送信済み</option>
          <option value="failed">送信失敗</option>
        </select>
        <button @click="loadSchedules" class="refresh-btn">🔄 更新</button>
      </div>
    </div>
    
    <div v-if="isLoading" class="loading-state">
      <div class="spinner"></div>
      <p>スケジュール一覧を読み込み中...</p>
    </div>
    
    <div v-else-if="schedules.length === 0" class="empty-state">
      <div class="empty-icon">📭</div>
      <h3>スケジュールが登録されていません</h3>
      <p>メッセージを作成してスケジュール設定を行ってください。</p>
      <router-link to="/compose" class="create-btn">📝 メッセージを作成</router-link>
    </div>
    
    <div v-else class="schedule-items">
      <div 
        v-for="schedule in schedules" 
        :key="schedule.id"
        class="schedule-item"
        :class="`status-${schedule.status}`"
      >
        <div class="schedule-header">
          <div class="schedule-time">
            <span class="time-label">📅 送信予定</span>
            <span class="time-value">{{ formatScheduleTime(schedule.scheduledAt) }}</span>
            <span class="status-badge" :class="`status-${schedule.status}`">
              {{ getStatusLabel(schedule.status) }}
            </span>
          </div>
          <div class="schedule-actions">
            <button 
              v-if="schedule.status === 'pending'"
              @click="editSchedule(schedule)"
              class="edit-btn"
            >
              ✏️ 編集
            </button>
            <button 
              v-if="schedule.status === 'pending'"
              @click="deleteSchedule(schedule.id)"
              class="delete-btn"
            >
              🗑️ 削除
            </button>
          </div>
        </div>
        
        <div class="schedule-content">
          <div class="message-info">
            <p class="message-id">📄 メッセージID: {{ schedule.messageId }}</p>
            <!-- TODO: メッセージ詳細を取得して表示 -->
          </div>
          
          <div class="schedule-meta">
            <div class="meta-item">
              <span class="meta-label">🕐 作成日時:</span>
              <span class="meta-value">{{ formatDateTime(schedule.createdAt) }}</span>
            </div>
            <div class="meta-item" v-if="schedule.status === 'failed'">
              <span class="meta-label">🔄 再試行回数:</span>
              <span class="meta-value">{{ schedule.retryCount }}</span>
            </div>
            <div class="meta-item">
              <span class="meta-label">🌍 タイムゾーン:</span>
              <span class="meta-value">{{ schedule.timezone }}</span>
            </div>
          </div>
        </div>
      </div>
    </div>
    
    <!-- ページネーション -->
    <div v-if="pagination && pagination.total > pagination.limit" class="pagination">
      <button 
        @click="goToPage(pagination.page - 1)"
        :disabled="pagination.page <= 1"
        class="page-btn"
      >
        ← 前のページ
      </button>
      
      <span class="page-info">
        {{ pagination.page }} / {{ Math.ceil(pagination.total / pagination.limit) }}
        （全 {{ pagination.total }} 件）
      </span>
      
      <button 
        @click="goToPage(pagination.page + 1)"
        :disabled="pagination.page >= Math.ceil(pagination.total / pagination.limit)"
        class="page-btn"
      >
        次のページ →
      </button>
    </div>
    
    <!-- エラーメッセージ -->
    <div v-if="error" class="error-message">
      ❌ {{ error }}
    </div>
    
    <!-- 成功メッセージ -->
    <div v-if="successMessage" class="success-message">
      ✅ {{ successMessage }}
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import scheduleService, { type Schedule } from '../../services/scheduleService'

const router = useRouter()

// 状態管理
const schedules = ref<Schedule[]>([])
const isLoading = ref(false)
const error = ref('')
const successMessage = ref('')
const statusFilter = ref('')

const pagination = reactive({
  page: 1,
  limit: 20,
  total: 0
})

// メソッド
const loadSchedules = async () => {
  isLoading.value = true
  error.value = ''
  
  try {
    const result = await scheduleService.getSchedules(
      pagination.page,
      pagination.limit,
      statusFilter.value || undefined
    )
    
    schedules.value = result.schedules
    Object.assign(pagination, result.pagination)
  } catch (err: any) {
    error.value = err.response?.data?.error || 'スケジュール一覧の取得に失敗しました'
  } finally {
    isLoading.value = false
  }
}

const formatScheduleTime = (isoString: string) => {
  return scheduleService.formatScheduleTime(isoString)
}

const formatDateTime = (isoString: string) => {
  const date = new Date(isoString)
  return date.toLocaleDateString('ja-JP') + ' ' + 
         date.toLocaleTimeString('ja-JP', { hour: '2-digit', minute: '2-digit' })
}

const getStatusLabel = (status: string) => {
  const labels: Record<string, string> = {
    pending: '⏳ 送信待ち',
    sent: '✅ 送信済み',
    failed: '❌ 送信失敗',
    cancelled: '⭕ キャンセル済み'
  }
  return labels[status] || status
}

const editSchedule = (schedule: Schedule) => {
  // スケジュール編集画面に遷移
  router.push({
    name: 'ScheduleEdit',
    params: { id: schedule.id },
    query: {
      messageId: schedule.messageId,
      currentTime: schedule.scheduledAt
    }
  })
}

const deleteSchedule = async (scheduleId: string) => {
  if (!confirm('このスケジュールを削除しますか？')) {
    return
  }
  
  try {
    await scheduleService.deleteSchedule(scheduleId)
    successMessage.value = 'スケジュールを削除しました'
    loadSchedules() // リロード
    
    setTimeout(() => {
      successMessage.value = ''
    }, 3000)
  } catch (err: any) {
    error.value = err.response?.data?.error || 'スケジュールの削除に失敗しました'
  }
}

const goToPage = (page: number) => {
  pagination.page = page
  loadSchedules()
}

// 初期化
onMounted(() => {
  loadSchedules()
})
</script>

<style scoped>
.schedule-list {
  max-width: 1000px;
  margin: 0 auto;
  padding: 2rem;
}

.header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 2rem;
}

.header-controls {
  display: flex;
  gap: 1rem;
  align-items: center;
}

.status-filter {
  padding: 0.5rem 1rem;
  border: 1px solid #ddd;
  border-radius: 6px;
  font-size: 0.875rem;
}

.refresh-btn {
  padding: 0.5rem 1rem;
  background: #007bff;
  color: white;
  border: none;
  border-radius: 6px;
  font-size: 0.875rem;
  cursor: pointer;
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

@keyframes spin {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}

.empty-state {
  text-align: center;
  padding: 4rem 2rem;
  color: #666;
}

.empty-icon {
  font-size: 4rem;
  margin-bottom: 1rem;
}

.create-btn {
  display: inline-block;
  padding: 0.75rem 1.5rem;
  background: #28a745;
  color: white;
  text-decoration: none;
  border-radius: 8px;
  margin-top: 1rem;
  transition: background 0.3s;
}

.create-btn:hover {
  background: #218838;
}

.schedule-items {
  display: grid;
  gap: 1rem;
}

.schedule-item {
  border: 1px solid #e0e0e0;
  border-radius: 12px;
  padding: 1.5rem;
  background: white;
  transition: box-shadow 0.3s;
}

.schedule-item:hover {
  box-shadow: 0 2px 8px rgba(0,0,0,0.1);
}

.schedule-item.status-pending {
  border-left: 4px solid #ffc107;
}

.schedule-item.status-sent {
  border-left: 4px solid #28a745;
}

.schedule-item.status-failed {
  border-left: 4px solid #dc3545;
}

.schedule-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 1rem;
}

.schedule-time {
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
}

.time-label {
  font-size: 0.875rem;
  color: #666;
}

.time-value {
  font-size: 1.125rem;
  font-weight: 600;
  color: #333;
}

.status-badge {
  padding: 0.25rem 0.75rem;
  border-radius: 12px;
  font-size: 0.75rem;
  font-weight: 500;
}

.status-badge.status-pending {
  background: #fff3cd;
  color: #856404;
}

.status-badge.status-sent {
  background: #d4edda;
  color: #155724;
}

.status-badge.status-failed {
  background: #f8d7da;
  color: #721c24;
}

.schedule-actions {
  display: flex;
  gap: 0.5rem;
}

.edit-btn,
.delete-btn {
  padding: 0.5rem 0.75rem;
  border: none;
  border-radius: 6px;
  font-size: 0.75rem;
  cursor: pointer;
}

.edit-btn {
  background: #007bff;
  color: white;
}

.delete-btn {
  background: #dc3545;
  color: white;
}

.schedule-content {
  display: grid;
  gap: 1rem;
}

.message-id {
  font-family: 'Courier New', monospace;
  font-size: 0.875rem;
  color: #666;
  margin: 0;
}

.schedule-meta {
  display: grid;
  gap: 0.5rem;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
}

.meta-item {
  display: flex;
  gap: 0.5rem;
}

.meta-label {
  font-weight: 500;
  min-width: 80px;
}

.meta-value {
  color: #666;
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
}

.page-btn:disabled {
  background: #6c757d;
  cursor: not-allowed;
}

.page-info {
  font-weight: 500;
  color: #666;
}

.error-message,
.success-message {
  padding: 1rem;
  border-radius: 8px;
  margin-top: 1rem;
  text-align: center;
}

.error-message {
  background: #f8d7da;
  color: #721c24;
  border: 1px solid #f5c6cb;
}

.success-message {
  background: #d4edda;
  color: #155724;
  border: 1px solid #c3e6cb;
}

@media (max-width: 768px) {
  .header {
    flex-direction: column;
    gap: 1rem;
    align-items: stretch;
  }
  
  .header-controls {
    justify-content: center;
  }
  
  .schedule-header {
    flex-direction: column;
    gap: 1rem;
  }
  
  .schedule-actions {
    justify-content: center;
  }
  
  .schedule-meta {
    grid-template-columns: 1fr;
  }
  
  .pagination {
    flex-direction: column;
    gap: 0.5rem;
  }
}
</style>