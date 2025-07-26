<template>
  <div class="schedule-wizard">
    <h2>📅 送信スケジュール設定</h2>
    
    <!-- メッセージプレビュー -->
    <div class="message-preview-section">
      <h3>📝 送信予定メッセージ</h3>
      <div class="message-card">
        <div class="message-header">
          <span class="recipient-badge">📧 {{ recipientEmail }}</span>
          <span class="tone-badge" :class="`tone-${selectedTone}`">
            🎭 {{ getToneLabel(selectedTone) }}
          </span>
        </div>
        <div class="message-content">
          <p class="original-text">{{ messageText }}</p>
          <p v-if="finalText" class="final-text">{{ finalText }}</p>
        </div>
      </div>
    </div>

    <!-- AI時間提案セクション -->
    <div class="ai-suggestion-section">
      <h3>🤖 AI時間提案</h3>
      
      <div v-if="isLoadingSuggestion" class="loading-state">
        <div class="spinner"></div>
        <p>メッセージを分析中...</p>
      </div>
      
      <div v-else-if="suggestion" class="suggestion-result">
        <div class="analysis-summary">
          <div class="analysis-item">
            <span class="label">📋 メッセージ種別:</span>
            <span class="value">{{ suggestion.message_type }}</span>
          </div>
          <div class="analysis-item">
            <span class="label">⚡ 緊急度:</span>
            <span class="value urgency" :class="`urgency-${getUrgencyLevel(suggestion.urgency_level)}`">
              {{ suggestion.urgency_level }}
            </span>
          </div>
          <div class="analysis-item">
            <span class="label">💡 推奨タイミング:</span>
            <span class="value recommended">{{ suggestion.recommended_timing }}</span>
          </div>
        </div>
        
        <div class="reasoning">
          <p><strong>📖 理由:</strong> {{ suggestion.reasoning }}</p>
        </div>
        
        <div class="time-options">
          <h4>⏰ 送信時間の選択肢</h4>
          <div class="options-grid">
            <div 
              v-for="(option, index) in suggestion.suggested_options" 
              :key="index"
              @click="selectTimeOption(option)"
              class="time-option"
              :class="{ 
                'selected': selectedOption?.option === option.option,
                'primary': option.priority === '最推奨',
                'recommended': option.priority === '推奨'
              }"
            >
              <div class="option-header">
                <span class="option-title">{{ option.option }}</span>
                <span class="priority-badge" :class="`priority-${getPriorityClass(option.priority)}`">
                  {{ option.priority }}
                </span>
              </div>
              <div class="option-details">
                <p class="schedule-time">{{ formatOptionTime(option) }}</p>
                <p class="option-reason">{{ option.reason }}</p>
              </div>
            </div>
          </div>
        </div>
      </div>
      
      <div v-else-if="suggestionError" class="error-state">
        <p>❌ AI提案の取得に失敗しました: {{ suggestionError }}</p>
        <button @click="loadAISuggestion" class="retry-btn">🔄 再試行</button>
      </div>
      
      <div v-else class="suggestion-prompt">
        <button @click="loadAISuggestion" class="get-suggestion-btn">
          🤖 AI時間提案を取得
        </button>
      </div>
    </div>

    <!-- カスタム時間設定 -->
    <div class="custom-schedule-section">
      <h3>🕒 カスタム時間設定</h3>
      
      <div class="schedule-form">
        <div class="form-row">
          <div class="form-group">
            <label for="customDate">📅 送信日</label>
            <input
              id="customDate"
              v-model="customSchedule.date"
              type="date"
              :min="minDate"
            />
          </div>
          
          <div class="form-group">
            <label for="customTime">🕐 送信時刻</label>
            <input
              id="customTime"
              v-model="customSchedule.time"
              type="time"
            />
          </div>
        </div>
        
        <div class="custom-preview" v-if="customSchedule.date && customSchedule.time">
          <p><strong>📋 カスタム送信予定:</strong></p>
          <p class="custom-time">{{ formatCustomTime() }}</p>
        </div>
      </div>
    </div>

    <!-- アクションボタン -->
    <div class="action-section">
      <div class="selected-schedule" v-if="getSelectedScheduleTime()">
        <p><strong>🎯 選択された送信時間:</strong></p>
        <p class="selected-time">{{ getSelectedScheduleTime() }}</p>
      </div>
      
      <div class="action-buttons">
        <button 
          @click="scheduleMessage"
          :disabled="!canSchedule || isScheduling"
          class="schedule-btn primary"
        >
          {{ isScheduling ? '⏳ 設定中...' : '📨 スケジュール設定' }}
        </button>
        
        <button @click="goBack" class="back-btn">
          ↩️ 戻る
        </button>
      </div>
    </div>
    
    <!-- メッセージ表示 -->
    <div v-if="error" class="message error-message">
      ❌ {{ error }}
    </div>
    
    <div v-if="successMessage" class="message success-message">
      ✅ {{ successMessage }}
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, computed, onMounted } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import scheduleService, { 
  type ScheduleSuggestionResponse,
  type ScheduleSuggestionRequest 
} from '../../services/scheduleService'

const router = useRouter()
const route = useRoute()

// Props（ルートパラメータまたはクエリから取得）
const messageId = ref(route.params.messageId as string || route.query.messageId as string)
const messageText = ref(route.query.messageText as string || '')
const selectedTone = ref(route.query.selectedTone as string || 'gentle')
const finalText = ref(route.query.finalText as string || '')
const recipientEmail = ref(route.query.recipientEmail as string || '')

// AI提案関連の状態
const suggestion = ref<ScheduleSuggestionResponse | null>(null)
const isLoadingSuggestion = ref(false)
const suggestionError = ref('')
const selectedOption = ref<any>(null)

// カスタムスケジュール
const customSchedule = reactive({
  date: '',
  time: ''
})


// その他の状態
const isScheduling = ref(false)
const error = ref('')
const successMessage = ref('')

// 計算プロパティ
const minDate = computed(() => {
  const today = new Date()
  return today.toISOString().split('T')[0]
})

const canSchedule = computed(() => {
  return selectedOption.value || (customSchedule.date && customSchedule.time)
})

// メソッド
const getToneLabel = (tone: string) => {
  const labels: Record<string, string> = {
    gentle: 'やんわり',
    constructive: '建設的',
    casual: 'カジュアル'
  }
  return labels[tone] || tone
}

const getUrgencyLevel = (urgency: string) => {
  const mapping: Record<string, string> = {
    '高': 'high',
    '中': 'medium', 
    '低': 'low'
  }
  return mapping[urgency] || 'medium'
}

const getPriorityClass = (priority: string) => {
  const mapping: Record<string, string> = {
    '最推奨': 'primary',
    '推奨': 'recommended',
    '選択肢': 'option'
  }
  return mapping[priority] || 'option'
}

const formatOptionTime = (option: any) => {
  if (option.delay_minutes === 0) {
    return '今すぐ送信'
  }
  
  // delay_minutesが文字列の場合は直接表示
  if (typeof option.delay_minutes === 'string') {
    if (option.delay_minutes === 'next_business_day_8:30am') {
      return '明日の朝 8:30'
    } else if (option.delay_minutes === 'next_business_day_9am') {
      return '明日の朝 9:00'
    } else {
      return option.delay_minutes
    }
  }
  
  // 数値の場合は既存の計算を使用
  const scheduledTime = scheduleService.calculateScheduleTime(option.delay_minutes)
  return scheduleService.formatScheduleTime(scheduledTime)
}

const formatCustomTime = () => {
  if (!customSchedule.date || !customSchedule.time) return ''
  
  const dateTime = new Date(`${customSchedule.date}T${customSchedule.time}`)
  return scheduleService.formatScheduleTime(dateTime.toISOString())
}

const getSelectedScheduleTime = () => {
  if (selectedOption.value) {
    return formatOptionTime(selectedOption.value)
  }
  
  if (customSchedule.date && customSchedule.time) {
    return formatCustomTime()
  }
  
  return null
}

const loadAISuggestion = async () => {
  if (!messageId.value || !messageText.value) {
    suggestionError.value = 'メッセージ情報が不足しています'
    return
  }
  
  isLoadingSuggestion.value = true
  suggestionError.value = ''
  
  try {
    console.log('AI提案リクエスト開始:', {
      messageId: messageId.value,
      messageText: messageText.value,
      selectedTone: selectedTone.value
    })
    
    const request: ScheduleSuggestionRequest = {
      messageId: messageId.value,
      messageText: messageText.value,
      selectedTone: selectedTone.value
    }
    
    suggestion.value = await scheduleService.getSuggestion(request)
    console.log('AI提案レスポンス成功:', suggestion.value)
    console.log('提案オプション:', suggestion.value.suggested_options)
  } catch (err: any) {
    console.error('AI提案エラー:', err)
    console.error('エラー詳細:', {
      status: err.response?.status,
      data: err.response?.data,
      message: err.message
    })
    
    let errorMessage = 'AI提案の取得に失敗しました'
    if (err.code === 'ECONNABORTED') {
      errorMessage = 'AI提案の処理に時間がかかりすぎています。もう一度お試しください。'
    } else if (err.response?.status === 500) {
      errorMessage = 'サーバーエラーが発生しました。しばらく待ってからお試しください。'
    } else if (err.response?.data?.error) {
      errorMessage = err.response.data.error
    }
    
    suggestionError.value = errorMessage
  } finally {
    isLoadingSuggestion.value = false
  }
}

const selectTimeOption = (option: any) => {
  selectedOption.value = option
  // カスタム設定をクリア
  customSchedule.date = ''
  customSchedule.time = ''
}

const scheduleMessage = async () => {
  isScheduling.value = true
  error.value = ''
  
  try {
    let scheduledAt: string
    
    if (selectedOption.value) {
      // delay_minutesが文字列の場合の処理
      if (typeof selectedOption.value.delay_minutes === 'string') {
        const now = new Date()
        const tomorrow = new Date(now)
        tomorrow.setDate(tomorrow.getDate() + 1)
        
        if (selectedOption.value.delay_minutes === 'next_business_day_8:30am') {
          tomorrow.setHours(8, 30, 0, 0)
          scheduledAt = tomorrow.toISOString()
        } else if (selectedOption.value.delay_minutes === 'next_business_day_9am') {
          tomorrow.setHours(9, 0, 0, 0)
          scheduledAt = tomorrow.toISOString()
        } else {
          throw new Error(`未対応の時間形式: ${selectedOption.value.delay_minutes}`)
        }
      } else {
        // 数値の場合は既存の計算を使用
        scheduledAt = scheduleService.calculateScheduleTime(selectedOption.value.delay_minutes)
      }
    } else if (customSchedule.date && customSchedule.time) {
      // JST時間として正しく処理（UTC+9の時差を考慮）
      const inputDateTime = `${customSchedule.date}T${customSchedule.time}:00`
      console.log('カスタム時間入力:', inputDateTime)
      
      // 日本時間として明示的に作成（ブラウザのローカルタイムゾーン使用）
      const localDateTime = new Date(inputDateTime)
      console.log('ローカル時間として解釈:', localDateTime.toString())
      
      // 現在時刻より未来かチェック（ローカル時刻で比較）
      const now = new Date()
      console.log('現在時刻:', now.toString())
      
      if (localDateTime <= now) {
        const diffMinutes = Math.round((localDateTime.getTime() - now.getTime()) / (1000 * 60))
        console.log('時刻差分（分）:', diffMinutes)
        throw new Error(`送信時刻は現在より未来である必要があります（現在から${diffMinutes}分後の設定です）`)
      }
      
      // ISOString変換（自動的にUTCに変換される）
      scheduledAt = localDateTime.toISOString()
      console.log('サーバー送信用UTC時刻:', scheduledAt)
    } else {
      throw new Error('送信時間が選択されていません')
    }
    
    await scheduleService.createSchedule({
      messageId: messageId.value,
      scheduledAt
    })
    
    successMessage.value = 'スケジュールを設定しました！'
    
    setTimeout(() => {
      router.push('/schedules')
    }, 2000)
    
  } catch (err: any) {
    error.value = err.response?.data?.error || 'スケジュールの設定に失敗しました'
  } finally {
    isScheduling.value = false
  }
}

const goBack = () => {
  router.back()
}

// 初期化
onMounted(() => {
  // デフォルトの時間設定（5分後に変更）
  const fiveMinutesLater = new Date()
  fiveMinutesLater.setMinutes(fiveMinutesLater.getMinutes() + 5)
  
  // 日付と時刻を正しく設定
  const year = fiveMinutesLater.getFullYear()
  const month = String(fiveMinutesLater.getMonth() + 1).padStart(2, '0')
  const day = String(fiveMinutesLater.getDate()).padStart(2, '0')
  const hours = String(fiveMinutesLater.getHours()).padStart(2, '0')
  const minutes = String(fiveMinutesLater.getMinutes()).padStart(2, '0')
  
  customSchedule.date = `${year}-${month}-${day}`
  customSchedule.time = `${hours}:${minutes}`
  
  console.log('カスタム時刻デフォルト設定（5分後）:', customSchedule.date, customSchedule.time)
  
  // メッセージ情報があればAI提案を自動取得
  if (messageId.value && messageText.value) {
    loadAISuggestion()
  }
})
</script>

<style scoped>
.schedule-wizard {
  max-width: 900px;
  margin: 0 auto;
  padding: 2rem;
}

.message-preview-section,
.ai-suggestion-section,
.custom-schedule-section,
.action-section {
  margin-bottom: 2rem;
  padding: 1.5rem;
  border: 1px solid #e0e0e0;
  border-radius: 12px;
  background: white;
}

.message-card {
  background: #f8f9fa;
  border-radius: 8px;
  padding: 1rem;
}

.message-header {
  display: flex;
  gap: 1rem;
  margin-bottom: 1rem;
}

.recipient-badge,
.tone-badge {
  padding: 0.25rem 0.75rem;
  border-radius: 16px;
  font-size: 0.875rem;
  font-weight: 500;
}

.recipient-badge {
  background: #e3f2fd;
  color: #1976d2;
}

.tone-badge {
  background: #f3e5f5;
  color: #7b1fa2;
}

.original-text {
  color: #666;
  margin-bottom: 0.5rem;
}

.final-text {
  color: #2e7d32;
  font-weight: 500;
}

.loading-state {
  text-align: center;
  padding: 2rem;
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

.analysis-summary {
  display: grid;
  gap: 0.75rem;
  margin-bottom: 1rem;
}

.analysis-item {
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.label {
  font-weight: 500;
  min-width: 120px;
}



.reasoning {
  background: #f5f5f5;
  padding: 1rem;
  border-radius: 8px;
  margin-bottom: 1.5rem;
}

.options-grid {
  display: grid;
  gap: 1rem;
  grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
}

.time-option {
  border: 2px solid #e0e0e0;
  border-radius: 12px;
  padding: 1rem;
  cursor: pointer;
  transition: all 0.3s ease;
}

.time-option:hover {
  border-color: #007bff;
  box-shadow: 0 2px 8px rgba(0,123,255,0.15);
}

.time-option.selected {
  border-color: #007bff;
  background: #f8f9ff;
}

.time-option.primary {
  border-color: #28a745;
}

.time-option.primary.selected {
  border-color: #28a745;
  background: #f8fff9;
}

.option-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 0.5rem;
}

.option-title {
  font-weight: 600;
  color: #333;
}

.priority-badge {
  padding: 0.25rem 0.5rem;
  border-radius: 12px;
  font-size: 0.75rem;
  font-weight: 500;
}

.priority-primary {
  background: #d4edda;
  color: #155724;
}

.priority-recommended {
  background: #cce7ff;
  color: #004085;
}

.priority-option {
  background: #f8f9fa;
  color: #6c757d;
}

.schedule-time {
  font-weight: 500;
  color: #007bff;
  margin-bottom: 0.25rem;
}

.option-reason {
  font-size: 0.875rem;
  color: #666;
  margin: 0;
}

.form-row {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 1rem;
}

.form-group {
  margin-bottom: 1rem;
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

.custom-preview {
  background: #f0f8ff;
  padding: 1rem;
  border-radius: 8px;
  margin-top: 1rem;
}

.custom-time {
  font-weight: 600;
  color: #007bff;
  margin: 0.5rem 0 0 0;
}

.selected-schedule {
  background: #e8f5e8;
  padding: 1rem;
  border-radius: 8px;
  margin-bottom: 1rem;
}

.selected-time {
  font-size: 1.125rem;
  font-weight: 600;
  color: #2e7d32;
  margin: 0.5rem 0 0 0;
}

.action-buttons {
  display: flex;
  gap: 1rem;
  flex-wrap: wrap;
}

.schedule-btn,
.back-btn,
.get-suggestion-btn,
.retry-btn {
  padding: 0.75rem 1.5rem;
  border: none;
  border-radius: 8px;
  font-size: 1rem;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.3s ease;
}

.schedule-btn.primary {
  background: #28a745;
  color: white;
}

.schedule-btn:disabled {
  background: #6c757d;
  cursor: not-allowed;
}

.back-btn {
  background: #6c757d;
  color: white;
}

.get-suggestion-btn,
.retry-btn {
  background: #007bff;
  color: white;
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

.error-state {
  text-align: center;
  padding: 2rem;
  color: #d32f2f;
}

.suggestion-prompt {
  text-align: center;
  padding: 2rem;
}

@media (max-width: 768px) {
  .form-row {
    grid-template-columns: 1fr;
  }
  
  .message-header {
    flex-direction: column;
    gap: 0.5rem;
  }
  
  .options-grid {
    grid-template-columns: 1fr;
  }
  
  .action-buttons {
    flex-direction: column;
  }
}
</style>