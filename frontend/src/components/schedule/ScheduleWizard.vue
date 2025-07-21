<template>
  <div class="schedule-wizard">
    <!-- ページタイトル -->
    <h1 class="page-title">送信予約</h1>

    <!-- 時間選択オプション -->
    <div class="schedule-options">
      <!-- 今すぐ送信（左上） -->
      <div 
        class="schedule-card immediate-card"
        :class="{ selected: selectedOption?.id === 'immediate' }"
        @click="selectScheduleOption('immediate')"
      >
        <h3 class="card-title">今すぐ送信</h3>
        <div class="card-content">
          <!-- 日時表示なし -->
        </div>
      </div>

      <!-- AIおすすめ1 -->
      <div 
        class="schedule-card ai-card"
        :class="{ selected: selectedOption?.id === 'ai-1' }"
        @click="selectScheduleOption('ai-1', 0)"
      >
        <h3 class="card-title">AIおすすめ1</h3>
        <div class="card-content">
          <p class="time-display">{{ formatAIOption(0) }}</p>
        </div>
      </div>

      <!-- AIおすすめ2 -->
      <div 
        class="schedule-card ai-card"
        :class="{ selected: selectedOption?.id === 'ai-2' }"
        @click="selectScheduleOption('ai-2', 1)"
      >
        <h3 class="card-title">AIおすすめ2</h3>
        <div class="card-content">
          <p class="time-display">{{ formatAIOption(1) }}</p>
        </div>
      </div>

      <!-- AIおすすめ3 -->
      <div 
        class="schedule-card ai-card"
        :class="{ selected: selectedOption?.id === 'ai-3' }"
        @click="selectScheduleOption('ai-3', 2)"
      >
        <h3 class="card-title">AIおすすめ3</h3>
        <div class="card-content">
          <p class="time-display">{{ formatAIOption(2) }}</p>
        </div>
      </div>
    </div>

    <!-- 自分で設定する -->
    <div class="custom-section">
      <h3 class="custom-title">自分で設定する</h3>
      
      
      <!-- カレンダー -->
      <div class="calendar-container">
        <div class="calendar-header">
          <span>Su</span><span>Mo</span><span>Tu</span><span>We</span><span>Th</span><span>Fr</span><span>Sa</span>
        </div>
        <div class="calendar-grid">
          <div v-for="date in calendarDates" :key="date.value" 
               :class="['calendar-date', { 
                 selected: date.value === selectedDate, 
                 disabled: date.disabled 
               }]"
               @click="!date.disabled && selectDate(date.value)">
            {{ date.display }}
          </div>
        </div>
      </div>

      <!-- 時間選択 -->
      <div class="time-selection-container" :class="{ disabled: !selectedDate }">
        <div v-if="!selectedDate" class="time-placeholder">
          <p>まず日付を選択してください</p>
        </div>
        <div v-else class="time-selector">
          <div class="time-inputs">
            <div class="time-input-group">
              <select 
                v-model="customHour" 
                class="time-select" 
                @change="onTimeInput"
                :disabled="!selectedDate"
              >
                <option v-for="hour in 24" :key="hour-1" :value="hour-1">
                  {{ String(hour-1).padStart(2, '0') }}
                </option>
              </select>
              <span class="time-unit">時</span>
            </div>
            <div class="time-input-group">
              <select 
                v-model="customMinute" 
                class="time-select" 
                @change="onTimeInput"
                :disabled="!selectedDate"
              >
                <option value="0">00</option>
                <option value="5">05</option>
                <option value="10">10</option>
                <option value="15">15</option>
                <option value="20">20</option>
                <option value="25">25</option>
                <option value="30">30</option>
                <option value="35">35</option>
                <option value="40">40</option>
                <option value="45">45</option>
                <option value="50">50</option>
                <option value="55">55</option>
              </select>
              <span class="time-unit">分</span>
            </div>
          </div>
          
          <!-- 過去の時間エラー表示 -->
          <div v-if="isPastTime" class="time-error">
            ⚠️ 選択できません（現在より前の時間です）
          </div>
        </div>
      </div>
    </div>

    <!-- アクションボタン -->
    <div class="action-buttons">
      <button class="btn btn-secondary" @click="goBack">
        文章を編集
      </button>
      <button 
        class="btn btn-primary" 
        @click="scheduleMessage"
        :disabled="!canSchedule || isScheduling"
      >
        {{ isScheduling ? '設定中...' : 'この時刻に送信する' }}
      </button>
    </div>
    
    <!-- メッセージ表示 -->
    <div v-if="error" class="alert alert-error">
      ❌ {{ error }}
    </div>
    
    <div v-if="successMessage" class="alert alert-success">
      ✅ {{ successMessage }}
    </div>
    
    <!-- ローディング表示 -->
    <div v-if="isLoadingSuggestion" class="loading-overlay">
      <div class="loading-spinner"></div>
      <p>AI提案を生成中...</p>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import scheduleService, { 
  type ScheduleSuggestionResponse,
  type ScheduleSuggestionRequest 
} from '../../services/scheduleService'

const router = useRouter()
const route = useRoute()

// ルートパラメータから取得
const messageId = ref('')
const messageText = ref('')
const selectedTone = ref('gentle')
const finalText = ref('')
const recipientEmail = ref('')

// AI提案データ
const suggestion = ref<ScheduleSuggestionResponse | null>(null)
const isLoadingSuggestion = ref(false)
const suggestionError = ref('')

// 選択状態
const selectedOption = ref<any>(null)
const selectedDate = ref<number | null>(null)
const customHour = ref(9)
const customMinute = ref(0)

// UI状態
const isScheduling = ref(false)
const error = ref('')
const successMessage = ref('')

// カスタム選択状態
const isTimeSelected = computed(() => {
  return selectedDate.value && customHour.value !== null && customMinute.value !== null
})

// 過去の時間チェック
const isPastTime = computed(() => {
  if (!selectedDate.value || customHour.value === null || customMinute.value === null) {
    return false
  }
  
  const now = new Date()
  const selectedDateTime = new Date(
    now.getFullYear(),
    now.getMonth(),
    selectedDate.value,
    customHour.value,
    customMinute.value
  )
  
  return selectedDateTime <= now
})

// 計算プロパティ
const currentTime = computed(() => {
  const now = new Date()
  const hours = String(now.getHours()).padStart(2, '0')
  const minutes = String(now.getMinutes()).padStart(2, '0')
  return `${hours}:${minutes}`
})

const calendarDates = computed(() => {
  const today = new Date()
  const currentMonth = today.getMonth()
  const currentYear = today.getFullYear()
  const daysInMonth = new Date(currentYear, currentMonth + 1, 0).getDate()
  const firstDayOfWeek = new Date(currentYear, currentMonth, 1).getDay()
  
  const dates = []
  
  // 前月の日付で埋める
  const prevMonth = new Date(currentYear, currentMonth, 0)
  const daysInPrevMonth = prevMonth.getDate()
  for (let i = firstDayOfWeek - 1; i >= 0; i--) {
    dates.push({
      value: null,
      display: daysInPrevMonth - i,
      disabled: true
    })
  }
  
  // 今月の日付（今日も選択可能）
  for (let i = 1; i <= daysInMonth; i++) {
    const date = new Date(currentYear, currentMonth, i)
    // 今日より前の日付を無効化（今日は含まない）
    const startOfToday = new Date(today.getFullYear(), today.getMonth(), today.getDate())
    const isPast = date < startOfToday
    dates.push({
      value: i,
      display: i,
      disabled: isPast
    })
  }
  
  // 次月の日付で埋める（6週間分）
  const remainingCells = 42 - dates.length
  for (let i = 1; i <= remainingCells; i++) {
    dates.push({
      value: null,
      display: i,
      disabled: true
    })
  }
  
  return dates
})

const canSchedule = computed(() => {
  if (selectedOption.value) {
    if (selectedOption.value.type === 'custom') {
      return selectedDate.value && 
             customHour.value !== null && 
             customMinute.value !== null && 
             !isPastTime.value // 過去の時間ではない
    }
    return true
  }
  return false
})

// デフォルトオプション
const defaultOptions = [
  {
    id: 'ai-1',
    title: 'AIおすすめ1',
    display: '明日の朝☀️　10:00',
    scheduledAt: null as string | null
  },
  {
    id: 'ai-2', 
    title: 'AIおすすめ2',
    display: '月曜日の朝☀️　10:00',
    scheduledAt: null as string | null
  },
  {
    id: 'ai-3',
    title: 'AIおすすめ3', 
    display: '明後日の夜🌙　18:00',
    scheduledAt: null as string | null
  }
]

// AI提案のフォーマット
const formatAIOption = (index: number) => {
  if (suggestion.value?.suggested_options?.[index]) {
    const option = suggestion.value.suggested_options[index]
    return formatOptionTime(option)
  }
  return defaultOptions[index]?.display || ''
}

const formatOptionTime = (option: any) => {
  if (!option) return ''
  
  if (typeof option.delay_minutes === 'string') {
    if (option.delay_minutes.includes('next_business_day')) {
      return '明日の朝☀️　10:00'
    }
    return option.delay_minutes
  }
  
  const now = new Date()
  const scheduledTime = new Date(now.getTime() + option.delay_minutes * 60000)
  const hours = String(scheduledTime.getHours()).padStart(2, '0')
  const minutes = String(scheduledTime.getMinutes()).padStart(2, '0')
  const dateStr = scheduledTime.toLocaleDateString('ja-JP', { 
    month: 'numeric', 
    day: 'numeric' 
  })
  
  const timeIcon = scheduledTime.getHours() < 12 ? '☀️' : '🌙'
  return `${dateStr}　${hours}:${minutes}${timeIcon}`
}

// ルートから値を初期化
const initializeFromRoute = () => {
  messageId.value = (route.params.messageId as string) || (route.query.messageId as string) || ''
  messageText.value = (route.query.messageText as string) || ''
  selectedTone.value = (route.query.selectedTone as string) || 'gentle'
  finalText.value = (route.query.finalText as string) || ''
  recipientEmail.value = (route.query.recipientEmail as string) || ''
}

// 統一された選択メソッド
const selectScheduleOption = (optionId: string, aiIndex?: number) => {
  // 他の選択をクリア
  selectedDate.value = null
  
  if (optionId === 'immediate') {
    selectedOption.value = { id: 'immediate', type: 'immediate' }
    sendImmediately()
  } else if (optionId.startsWith('ai-') && aiIndex !== undefined) {
    const aiOption = suggestion.value?.suggested_options?.[aiIndex]
    selectedOption.value = {
      id: optionId,
      type: 'ai',
      data: aiOption || defaultOptions[aiIndex]
    }
  }
}

const selectDate = (date: number) => {
  selectedDate.value = date
  // AI/即座選択をクリア
  selectedOption.value = {
    id: 'custom',
    type: 'custom'
  }
  
  // 日付選択後にデフォルト時間を設定（1時間後、5分単位）
  const oneHourLater = new Date()
  oneHourLater.setHours(oneHourLater.getHours() + 1)
  customHour.value = oneHourLater.getHours()
  customMinute.value = 0 // 0分に設定（5分単位の最初）
}

// 時間入力時にもカスタム選択をアクティブに
const onTimeInput = () => {
  if (selectedDate.value) {
    // AI/即座選択をクリア
    selectedOption.value = {
      id: 'custom',
      type: 'custom'
    }
  }
}



// AI提案を取得
const loadAISuggestion = async () => {
  if (!messageId.value || !messageText.value) {
    console.log('AI提案スキップ - 必要情報不足')
    return
  }
  
  isLoadingSuggestion.value = true
  suggestionError.value = ''
  
  try {
    const request: ScheduleSuggestionRequest = {
      messageId: messageId.value,
      messageText: messageText.value,
      selectedTone: selectedTone.value
    }
    
    suggestion.value = await scheduleService.getSuggestion(request)
    console.log('AI提案取得成功:', suggestion.value)
  } catch (err: any) {
    console.error('AI提案エラー:', err)
    suggestionError.value = 'AI提案の取得に失敗しました'
  } finally {
    isLoadingSuggestion.value = false
  }
}

// 即座送信
const sendImmediately = async () => {
  isScheduling.value = true
  error.value = ''
  
  try {
    const now = new Date()
    await scheduleService.createSchedule({
      messageId: messageId.value,
      scheduledAt: now.toISOString()
    })
    
    successMessage.value = 'メッセージを送信しました！'
    setTimeout(() => {
      router.push('/inbox')
    }, 2000)
    
  } catch (err: any) {
    console.error('即座送信エラー:', err)
    error.value = 'メッセージの送信に失敗しました'
  } finally {
    isScheduling.value = false
  }
}

// 戻るボタン
const goBack = () => {
  if (messageId.value) {
    router.push({
      name: 'tone-transform',
      params: { id: messageId.value }
    })
  } else {
    router.back()
  }
}

// スケジュール設定
const scheduleMessage = async () => {
  if (!selectedOption.value) {
    error.value = '送信時間を選択してください'
    return
  }
  
  isScheduling.value = true
  error.value = ''
  
  try {
    let scheduledAt: string
    
    if (selectedOption.value.type === 'immediate') {
      scheduledAt = new Date().toISOString()
    } else if (selectedOption.value.type === 'ai') {
      const option = selectedOption.value.data
      if (typeof option.delay_minutes === 'string') {
        const tomorrow = new Date()
        tomorrow.setDate(tomorrow.getDate() + 1)
        tomorrow.setHours(10, 0, 0, 0)
        scheduledAt = tomorrow.toISOString()
      } else {
        const now = new Date()
        const delay = option.delay_minutes || 60
        const scheduled = new Date(now.getTime() + delay * 60000)
        scheduledAt = scheduled.toISOString()
      }
    } else if (selectedOption.value.type === 'custom') {
      if (!selectedDate.value) {
        throw new Error('日付を選択してください')
      }
      
      const now = new Date()
      const scheduled = new Date(
        now.getFullYear(),
        now.getMonth(),
        selectedDate.value,
        customHour.value,
        customMinute.value
      )
      
      if (scheduled <= now) {
        throw new Error('送信時刻は現在より未来である必要があります')
      }
      
      scheduledAt = scheduled.toISOString()
    } else {
      throw new Error('無効な選択です')
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
    console.error('スケジュール設定エラー:', err)
    error.value = err.message || 'スケジュールの設定に失敗しました'
  } finally {
    isScheduling.value = false
  }
}

// 初期化
onMounted(() => {
  initializeFromRoute()
  
  // 初期状態では何も選択されていない
  selectedOption.value = null
  selectedDate.value = null
  
  // デフォルト時刻は設定しておく（日付選択時に使用）
  const defaultTime = new Date()
  defaultTime.setMinutes(defaultTime.getMinutes() + 60) // 1時間後
  customHour.value = defaultTime.getHours()
  customMinute.value = 0 // 0分に設定
  
  // AI提案を取得
  loadAISuggestion()
})
</script>


<style scoped>
.schedule-wizard {
  background: #ffffff;
  font-family: var(--font-family-main);
  position: relative;
  width: 1280px;
  height: 832px;
  margin: 0 auto;
  overflow: hidden;
}

/* ページタイトル */
.page-title {
  position: absolute;
  left: 93px;
  top: 33px;
  color: #000000;
  font-size: 18px;
  font-weight: 400;
  font-family: var(--font-family-main);
  line-height: 100%;
  margin: 0;
}

/* スケジュールオプション（2x2グリッド） */
.schedule-options {
  position: absolute;
  left: 288px;
  top: 61px;
  display: grid;
  grid-template-columns: 234px 234px;
  grid-template-rows: 177px 177px;
  gap: 25px 25px;
}

/* スケジュールカード */
.schedule-card {
  background: #ffffff;
  border: 3px solid #d9d9d9;
  border-radius: 10px;
  width: 234px;
  height: 177px;
  position: relative;
  cursor: pointer;
  transition: all 0.3s ease;
}

.schedule-card.selected {
  background: var(--success-color);
  border-color: var(--success-color);
}

/* カードタイトル */
.card-title {
  position: absolute;
  left: 16px;
  top: 16px;
  color: #000000;
  font-size: 18px;
  font-weight: 400;
  font-family: var(--font-family-main);
  line-height: 100%;
  margin: 0;
}

.card-content {
  position: absolute;
  left: 16px;
  bottom: 16px;
  right: 16px;
}

.time-display {
  color: #000000;
  font-size: 20px;
  font-weight: 400;
  font-family: var(--font-family-main);
  line-height: 15px;
  margin: 0;
}

/* カスタム設定セクション */
.custom-section {
  position: absolute;
  left: 541px;
  top: 342px;
}

.custom-title {
  color: #000000;
  font-size: 18px;
  font-weight: 400;
  font-family: var(--font-family-main);
  line-height: 100%;
  text-align: center;
  margin: 0 0 24px 0;
  width: 200px;
}

/* カレンダー */
.calendar-container {
  margin-bottom: 24px;
}

.calendar-header {
  display: grid;
  grid-template-columns: repeat(7, 1fr);
  gap: 1px;
  margin-bottom: 12px;
  width: 294px;
}

.calendar-header span {
  color: #666666;
  font-size: 12px;
  font-weight: 400;
  font-family: var(--font-family-main);
  text-align: center;
  padding: 4px 2px;
}

.calendar-grid {
  display: grid;
  grid-template-columns: repeat(7, 1fr);
  gap: 1px;
  width: 294px;
}

.calendar-date {
  width: 40px;
  height: 32px;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  border-radius: 3px;
  color: #000000;
  font-size: 12px;
  font-weight: 400;
  font-family: var(--font-family-main);
  transition: all 0.2s ease;
}

.calendar-date:hover:not(.disabled) {
  background: #f0f0f0;
}

.calendar-date.selected {
  background: var(--success-color);
  border-radius: 50%;
}

.calendar-date.disabled {
  color: #cccccc;
  cursor: not-allowed;
}

/* 時間選択 */
.time-selection-container {
  transition: opacity 0.3s ease;
}

.time-selection-container.disabled {
  opacity: 0.5;
  pointer-events: none;
}

.time-placeholder {
  text-align: center;
  padding: 48px 0;
  color: #999999;
  font-size: 16px;
  font-family: var(--font-family-main);
}

.time-selector {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 16px;
  margin-top: 16px;
}

.time-inputs {
  display: flex;
  align-items: center;
  gap: 70px;
}

.time-input-group {
  display: flex;
  align-items: center;
  gap: 8px;
}

.time-select {
  width: 70px;
  height: 70px;
  background: #ffffff;
  border: 3px solid #d9d9d9;
  border-radius: 15px;
  font-size: 16px;
  font-weight: 400;
  font-family: var(--font-family-main);
  text-align: center;
  cursor: pointer;
  appearance: none;
  padding: 0;
}

.time-unit {
  color: #000000;
  font-size: 30px;
  font-weight: 400;
  font-family: var(--font-family-main);
  line-height: 100%;
}

/* 時間エラー */
.time-error {
  position: absolute;
  left: 50%;
  top: 100%;
  transform: translateX(-50%);
  margin-top: 16px;
  padding: 12px 16px;
  background: var(--error-color);
  border-radius: 8px;
  color: #000000;
  font-size: 14px;
  font-family: var(--font-family-main);
  white-space: nowrap;
}

/* アクションボタン */
.action-buttons {
  position: absolute;
  left: 304px;
  top: 570px;
  display: flex;
  gap: 177px;
}

.btn {
  height: 60px;
  border: none;
  border-radius: 30px;
  color: #000000;
  font-size: 18px;
  font-weight: 400;
  font-family: var(--font-family-main);
  line-height: 100%;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.3s ease;
}

.btn-secondary {
  width: 150px;
  background: var(--primary-color);
}

.btn-primary {
  width: 250px;
  background: var(--primary-color);
}

.btn:hover {
  background: var(--primary-color-dark);
}

.btn:disabled {
  background: #d9d9d9;
  color: #999999;
  cursor: not-allowed;
}

/* アラート */
.alert {
  position: absolute;
  left: 304px;
  top: 650px;
  width: 577px;
  padding: 16px;
  border-radius: 8px;
  text-align: center;
  font-size: 16px;
  font-weight: 400;
  font-family: var(--font-family-main);
}

.alert-error {
  background: var(--error-color);
  color: #000000;
}

.alert-success {
  background: var(--success-color);
  color: #000000;
}

/* ローディング */
.loading-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0,0,0,0.7);
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  z-index: 1000;
  color: white;
  font-family: var(--font-family-main);
}

.loading-spinner {
  width: 40px;
  height: 40px;
  border: 4px solid rgba(255,255,255,0.3);
  border-top: 4px solid white;
  border-radius: 50%;
  animation: spin 1s linear infinite;
  margin-bottom: 16px;
}

@keyframes spin {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}
</style>