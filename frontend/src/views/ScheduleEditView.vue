<template>
  <div class="schedule-edit-view">
    <div class="container">
      <h2>📅 スケジュール編集</h2>
      
      <div v-if="isLoading" class="loading-state">
        <div class="spinner"></div>
        <p>スケジュール情報を読み込み中...</p>
      </div>
      
      <div v-else-if="schedule" class="edit-form">
        <div class="schedule-info">
          <h3>📄 スケジュール情報</h3>
          <div class="info-item">
            <span class="label">メッセージID:</span>
            <span class="value">{{ schedule.messageId }}</span>
          </div>
          <div class="info-item">
            <span class="label">現在の送信予定:</span>
            <span class="value">{{ formatScheduleTime(schedule.scheduledAt) }}</span>
          </div>
          <div class="info-item">
            <span class="label">ステータス:</span>
            <span class="value status" :class="`status-${schedule.status}`">
              {{ getStatusLabel(schedule.status) }}
            </span>
          </div>
        </div>
        
        <div class="edit-section">
          <h3>🕒 新しい送信時間</h3>
          
          <div class="form-group">
            <label for="newDate">📅 新しい送信日</label>
            <input
              id="newDate"
              v-model="editForm.date"
              type="date"
              :min="minDate"
              required
            />
          </div>
          
          <div class="form-group">
            <label for="newTime">🕐 新しい送信時刻</label>
            <input
              id="newTime"
              v-model="editForm.time"
              type="time"
              required
            />
          </div>
          
          <div class="preview" v-if="editForm.date && editForm.time">
            <p><strong>📋 更新後の送信予定:</strong></p>
            <p class="new-time">{{ formatNewTime() }}</p>
          </div>
          
          <div class="action-buttons">
            <button 
              @click="updateSchedule"
              :disabled="!canUpdate || isUpdating"
              class="update-btn"
            >
              {{ isUpdating ? '⏳ 更新中...' : '💾 スケジュール更新' }}
            </button>
            
            <button @click="goBack" class="back-btn">
              ↩️ 戻る
            </button>
          </div>
        </div>
      </div>
      
      <div v-else-if="error" class="error-state">
        <p>❌ {{ error }}</p>
        <button @click="loadSchedule" class="retry-btn">🔄 再読み込み</button>
      </div>
      
      <!-- メッセージ表示 -->
      <div v-if="updateError" class="message error-message">
        ❌ {{ updateError }}
      </div>
      
      <div v-if="successMessage" class="message success-message">
        ✅ {{ successMessage }}
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, computed, onMounted } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import scheduleService, { type Schedule } from '@/services/scheduleService'

const router = useRouter()
const route = useRoute()

const scheduleId = route.params.id as string

// 状態管理
const schedule = ref<Schedule | null>(null)
const isLoading = ref(false)
const isUpdating = ref(false)
const error = ref('')
const updateError = ref('')
const successMessage = ref('')

const editForm = reactive({
  date: '',
  time: ''
})

// 計算プロパティ
const minDate = computed(() => {
  const today = new Date()
  return today.toISOString().split('T')[0]
})

const canUpdate = computed(() => {
  return editForm.date && editForm.time && schedule.value?.status === 'pending'
})

// メソッド
const loadSchedule = async () => {
  isLoading.value = true
  error.value = ''
  
  try {
    // スケジュール一覧から該当のスケジュールを探す
    const result = await scheduleService.getSchedules(1, 100)
    const foundSchedule = result.schedules.find(s => s.id === scheduleId)
    
    if (!foundSchedule) {
      throw new Error('スケジュールが見つかりません')
    }
    
    schedule.value = foundSchedule
    
    // 現在の時間をフォームに設定
    const scheduledDate = new Date(foundSchedule.scheduledAt)
    editForm.date = scheduledDate.toISOString().split('T')[0]
    editForm.time = scheduledDate.toTimeString().slice(0, 5)
    
  } catch (err: any) {
    error.value = err.message || 'スケジュールの読み込みに失敗しました'
  } finally {
    isLoading.value = false
  }
}

const formatScheduleTime = (isoString: string) => {
  return scheduleService.formatScheduleTime(isoString)
}

const formatNewTime = () => {
  if (!editForm.date || !editForm.time) return ''
  
  const dateTime = new Date(`${editForm.date}T${editForm.time}`)
  return scheduleService.formatScheduleTime(dateTime.toISOString())
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

const updateSchedule = async () => {
  if (!schedule.value) return
  
  isUpdating.value = true
  updateError.value = ''
  
  try {
    const newScheduledAt = new Date(`${editForm.date}T${editForm.time}`).toISOString()
    
    await scheduleService.updateSchedule(schedule.value.id, {
      scheduledAt: newScheduledAt
    })
    
    successMessage.value = 'スケジュールを更新しました！'
    
    setTimeout(() => {
      router.push('/schedules')
    }, 2000)
    
  } catch (err: any) {
    updateError.value = err.response?.data?.error || 'スケジュールの更新に失敗しました'
  } finally {
    isUpdating.value = false
  }
}

const goBack = () => {
  router.back()
}

// 初期化
onMounted(() => {
  loadSchedule()
})
</script>

<style scoped>
.schedule-edit-view {
  min-height: 100vh;
  background-color: #f8f9fa;
  padding: 2rem 0;
}

.container {
  max-width: 600px;
  margin: 0 auto;
  padding: 0 1rem;
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

.schedule-info,
.edit-section {
  background: white;
  border-radius: 12px;
  padding: 1.5rem;
  margin-bottom: 1.5rem;
  border: 1px solid #e0e0e0;
}

.info-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 0.75rem;
}

.label {
  font-weight: 500;
  color: #666;
}

.value {
  font-weight: 600;
}

.status {
  padding: 0.25rem 0.75rem;
  border-radius: 12px;
  font-size: 0.875rem;
}

.status-pending {
  background: #fff3cd;
  color: #856404;
}

.status-sent {
  background: #d4edda;
  color: #155724;
}

.status-failed {
  background: #f8d7da;
  color: #721c24;
}

.form-group {
  margin-bottom: 1.5rem;
}

.form-group label {
  display: block;
  margin-bottom: 0.5rem;
  font-weight: 500;
}

.form-group input {
  width: 100%;
  padding: 0.75rem;
  border: 1px solid #ddd;
  border-radius: 6px;
  font-size: 1rem;
}

.preview {
  background: #f0f8ff;
  padding: 1rem;
  border-radius: 8px;
  margin-bottom: 1.5rem;
}

.new-time {
  font-size: 1.125rem;
  font-weight: 600;
  color: #007bff;
  margin: 0.5rem 0 0 0;
}

.action-buttons {
  display: flex;
  gap: 1rem;
  flex-wrap: wrap;
}

.update-btn,
.back-btn,
.retry-btn {
  padding: 0.75rem 1.5rem;
  border: none;
  border-radius: 8px;
  font-size: 1rem;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.3s ease;
}

.update-btn {
  background: #28a745;
  color: white;
}

.update-btn:disabled {
  background: #6c757d;
  cursor: not-allowed;
}

.back-btn,
.retry-btn {
  background: #6c757d;
  color: white;
}

.error-state {
  text-align: center;
  padding: 3rem;
  background: white;
  border-radius: 12px;
  border: 1px solid #f5c6cb;
}

.message {
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
  .info-item {
    flex-direction: column;
    align-items: flex-start;
    gap: 0.25rem;
  }
  
  .action-buttons {
    flex-direction: column;
  }
}
</style>