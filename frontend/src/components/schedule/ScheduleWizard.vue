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
      
      <div class="custom-content">
        <!-- カレンダー -->
        <div class="calendar-container">
          <!-- 月移動ヘッダー -->
          <div class="calendar-month-header">
            <button class="month-nav-btn" @click="previousMonth">
              ←
            </button>
            <span class="current-month">
              {{ currentYear }}年{{ currentMonth + 1 }}月
            </span>
            <button class="month-nav-btn" @click="nextMonth">
              →
            </button>
          </div>
          <div class="calendar-header">
            <span>Su</span><span>Mo</span><span>Tu</span><span>We</span><span>Th</span><span>Fr</span><span>Sa</span>
          </div>
          <div class="calendar-grid">
            <div v-for="date in calendarDates" :key="date.value || `empty-${date.display}`" 
                 :class="['calendar-date', { 
                   selected: date.value === selectedDate, 
                   disabled: date.disabled,
                   past: date.disabled && date.value !== null
                 }]"
                 @click="!date.disabled && date.value && selectDate(date.value)">
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
                  <option v-for="hour in 24" :key="hour - 1" :value="hour - 1">
                    {{ String(hour - 1).padStart(2, '0') }}
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
            
            <!-- 過去の時間エラー表示（ポップアップ） -->
            <div v-if="isPastTime" class="time-error-popup">
              <div class="error-popup-content">
                ⚠️ 選択できません（現在より前の時間です）
              </div>
            </div>
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
        @click="handleScheduleClick"
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
import { useMessageStore } from '@/stores/messages'
import scheduleService, { 
  type ScheduleSuggestionResponse,
  type ScheduleSuggestionRequest 
} from '../../services/scheduleService'

const router = useRouter()
const route = useRoute()
const messageStore = useMessageStore()

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

// カレンダー表示状態
const currentYear = ref(new Date().getFullYear())
const currentMonth = ref(new Date().getMonth())

// UI状態
const isScheduling = ref(false)
const error = ref('')
const successMessage = ref('')

// 過去の時間チェック
const isPastTime = computed(() => {
  if (!selectedDate.value || customHour.value === null || customMinute.value === null) {
    return false
  }
  
  const now = new Date()
  const selectedDateTime = new Date(
    currentYear.value,
    currentMonth.value,
    selectedDate.value,
    customHour.value,
    customMinute.value
  )
  
  const pastTime = selectedDateTime <= now
  
  // ポップアップが表示されたら2秒後に時間を再設定してポップアップを閉じる
  if (pastTime) {
    setTimeout(() => {
      const oneHourLater = new Date()
      oneHourLater.setHours(oneHourLater.getHours() + 1)
      customHour.value = oneHourLater.getHours()
      customMinute.value = 0
    }, 2000)
  }
  
  return pastTime
})

// 計算プロパティ
const calendarDates = computed(() => {
  const today = new Date()
  const displayYear = currentYear.value
  const displayMonth = currentMonth.value
  const daysInMonth = new Date(displayYear, displayMonth + 1, 0).getDate()
  const firstDayOfWeek = new Date(displayYear, displayMonth, 1).getDay()
  
  const dates = []
  
  // 前月の日付で埋める
  const prevMonth = new Date(displayYear, displayMonth, 0)
  const daysInPrevMonth = prevMonth.getDate()
  for (let i = firstDayOfWeek - 1; i >= 0; i--) {
    dates.push({
      value: null,
      display: daysInPrevMonth - i,
      disabled: true
    })
  }
  
  // 今月の日付
  for (let i = 1; i <= daysInMonth; i++) {
    const date = new Date(displayYear, displayMonth, i)
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
    // 文字列形式のdelay_minutesを適切な表示に変換
    const now = new Date()
    const nextBusinessDay = getNextBusinessDay(now)
    
    switch (option.delay_minutes) {
      case 'next_business_day_9am':
        return `${formatDateJapanese(nextBusinessDay)} 9:00`
      case 'next_business_day_10am':
        return `${formatDateJapanese(nextBusinessDay)} 10:00`
      case 'next_business_day_8:30am':
        return `${formatDateJapanese(nextBusinessDay)} 8:30`
      case 'tomorrow_9am':
        const tomorrow = new Date(now)
        tomorrow.setDate(tomorrow.getDate() + 1)
        return `${formatDateJapanese(tomorrow)} 9:00`
      case 'tomorrow_morning':
        const tomorrowMorning = new Date(now)
        tomorrowMorning.setDate(tomorrowMorning.getDate() + 1)
        return `${formatDateJapanese(tomorrowMorning)} 9:00`
      default:
        return option.delay_minutes // フォールバック
    }
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
  // 既にスケジュール処理中の場合は無視
  if (isScheduling.value) {
    return
  }
  
  // 他の選択をクリア
  selectedDate.value = null
  
  if (optionId === 'immediate') {
    selectedOption.value = { id: 'immediate', type: 'immediate' }
    // 即座送信は選択のみ行い、実際の送信は「この時刻に送信する」ボタンで行う
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

// 月移動メソッド
const previousMonth = () => {
  if (currentMonth.value === 0) {
    currentMonth.value = 11
    currentYear.value--
  } else {
    currentMonth.value--
  }
  // 選択日付をクリア（異なる月になるため）
  selectedDate.value = null
}

const nextMonth = () => {
  if (currentMonth.value === 11) {
    currentMonth.value = 0
    currentYear.value++
  } else {
    currentMonth.value++
  }
  // 選択日付をクリア（異なる月になるため）
  selectedDate.value = null
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

// 即座送信（削除 - scheduleMessage統合）

// 翌営業日を取得するヘルパー関数
const getNextBusinessDay = (date: Date): Date => {
  const nextDay = new Date(date)
  nextDay.setDate(nextDay.getDate() + 1)
  
  // 土曜日(6)の場合は月曜日(+2日)、日曜日(0)の場合は月曜日(+1日)
  const dayOfWeek = nextDay.getDay()
  if (dayOfWeek === 0) { // 日曜日
    nextDay.setDate(nextDay.getDate() + 1)
  } else if (dayOfWeek === 6) { // 土曜日
    nextDay.setDate(nextDay.getDate() + 2)
  }
  
  return nextDay
}

// 日付を日本語形式で表示するヘルパー関数
const formatDateJapanese = (date: Date): string => {
  const month = date.getMonth() + 1
  const day = date.getDate()
  const dayOfWeek = ['日', '月', '火', '水', '木', '金', '土'][date.getDay()]
  
  const today = new Date()
  const tomorrow = new Date(today)
  tomorrow.setDate(tomorrow.getDate() + 1)
  
  if (date.toDateString() === today.toDateString()) {
    return '今日'
  } else if (date.toDateString() === tomorrow.toDateString()) {
    return '明日'
  } else {
    return `${month}/${day}(${dayOfWeek})`
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
  // 重複実行防止
  if (isScheduling.value) {
    console.log('スケジュール処理中のため、重複実行を防止しました')
    return
  }
  
  if (!selectedOption.value) {
    error.value = '送信時間を選択してください'
    return
  }
  
  isScheduling.value = true
  error.value = ''
  successMessage.value = ''
  
  try {
    let scheduledAt: string
    
    if (selectedOption.value.type === 'immediate') {
      scheduledAt = new Date().toISOString()
    } else if (selectedOption.value.type === 'ai') {
      const option = selectedOption.value.data
      if (typeof option.delay_minutes === 'string') {
        // 文字列形式のdelay_minutesを適切に処理
        const now = new Date()
        let scheduled: Date
        
        switch (option.delay_minutes) {
          case 'next_business_day_9am':
            scheduled = getNextBusinessDay(now)
            scheduled.setHours(9, 0, 0, 0)
            break
          case 'next_business_day_10am':
            scheduled = getNextBusinessDay(now)
            scheduled.setHours(10, 0, 0, 0)
            break
          case 'next_business_day_8:30am':
            scheduled = getNextBusinessDay(now)
            scheduled.setHours(8, 30, 0, 0)
            break
          case 'tomorrow_9am':
            scheduled = new Date(now)
            scheduled.setDate(scheduled.getDate() + 1)
            scheduled.setHours(9, 0, 0, 0)
            break
          case 'tomorrow_morning':
            scheduled = new Date(now)
            scheduled.setDate(scheduled.getDate() + 1)
            scheduled.setHours(9, 0, 0, 0)
            break
          default:
            // フォールバック: 翌営業日10時
            scheduled = getNextBusinessDay(now)
            scheduled.setHours(10, 0, 0, 0)
            console.warn('未知のdelay_minutes文字列:', option.delay_minutes)
        }
        
        scheduledAt = scheduled.toISOString()
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
        currentYear.value,
        currentMonth.value,
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
    
    console.log('スケジュール作成開始:', { messageId: messageId.value, scheduledAt })
    
    await scheduleService.createSchedule({
      messageId: messageId.value,
      scheduledAt
    })
    
    console.log('スケジュール作成完了')
    
    // 下書き一覧を更新（予約済みメッセージは下書きから除外される）
    await messageStore.loadDrafts()
    
    const isImmediate = selectedOption.value.type === 'immediate'
    successMessage.value = isImmediate ? 'メッセージを送信しました！' : 'スケジュールを設定しました！'
    
    setTimeout(() => {
      const targetPath = isImmediate ? '/inbox' : '/history'
      console.log(`ナビゲーション実行: ${targetPath}`)
      router.push(targetPath).then(() => {
        console.log(`ナビゲーション成功: ${targetPath}`)
      }).catch((error) => {
        console.error(`ナビゲーションエラー: ${targetPath}`, error)
      })
    }, 1500)
    
  } catch (err: any) {
    console.error('スケジュール設定エラー:', err)
    error.value = err.message || 'スケジュールの設定に失敗しました'
  } finally {
    isScheduling.value = false
  }
}

// ボタンクリックハンドラー（デバウンス処理付き）
let scheduleClickTimeout: NodeJS.Timeout | null = null
const handleScheduleClick = () => {
  // 既存のタイムアウトをクリア
  if (scheduleClickTimeout) {
    clearTimeout(scheduleClickTimeout)
  }
  
  // 300ms後に実行（重複クリック防止）
  scheduleClickTimeout = setTimeout(() => {
    scheduleMessage()
    scheduleClickTimeout = null
  }, 300)
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
  height: 100vh;
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
  grid-template-columns: 18.75rem 18.75rem; /* 300px 300px */
  grid-template-rows: 6rem 6rem; /* 96px 96px */
  gap: 1.5625rem 1.5625rem; /* 25px 25px */
}

/* スケジュールカード */
.schedule-card {
  width: 18.75rem; /* 300px */
  height: 6rem; /* 96px */
  flex-shrink: 0;
  border-radius: 0.625rem; /* 10px */
  border: 3px solid var(--gray-color, #D9D9D9);
  background: var(--neutral-color, #FFF);
  position: relative;
  cursor: pointer;
  transition: all 0.3s ease;
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
  text-align: center;
  padding: 12px;
  box-sizing: border-box;
}

.schedule-card.selected {
  background: var(--success-color, #28a745);
  border-color: var(--success-color, #28a745);
}

/* カードタイトル */
.card-title {
  color: #000000;
  font-size: 16px;
  font-weight: 400;
  font-family: var(--font-family-main);
  line-height: 100%;
  margin: 0 0 6px 0;
  position: static;
}

.card-content {
  position: static;
  width: 100%;
}

.time-display {
  color: #000000;
  font-size: 16px;
  font-weight: 400;
  font-family: var(--font-family-main);
  line-height: 15px;
  margin: 6px 0 0 0;
}

/* カスタム設定セクション */
.custom-section {
  position: absolute;
  left: 288px;
  top: 320px;
  width: 625px;
  display: flex;
  flex-direction: column;
}

.custom-title {
  color: #000000;
  font-size: 18px;
  font-weight: 400;
  font-family: var(--font-family-main);
  line-height: 100%;
  text-align: center;
  margin: 0 0 20px 0;
  width: 625px;
}

/* カレンダーと時間選択を横並びにするコンテナ */
.custom-content {
  display: flex;
  gap: 40px;
  align-items: flex-start;
}

/* カレンダー */
.calendar-container {
  width: 294px;
  flex-shrink: 0;
}

/* 月移動ヘッダー */
.calendar-month-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 12px;
  width: 294px;
}

.month-nav-btn {
  width: 32px;
  height: 32px;
  border: 1px solid #d9d9d9;
  border-radius: 50%;
  background: #ffffff;
  color: #000000;
  font-size: 16px;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.2s ease;
}

.month-nav-btn:hover {
  background: #f0f0f0;
  border-color: #999999;
}

.current-month {
  color: #000000;
  font-size: 16px;
  font-weight: 600;
  font-family: var(--font-family-main);
  text-align: center;
  min-width: 120px;
}

.calendar-header {
  display: grid;
  grid-template-columns: repeat(7, 1fr);
  gap: 2px;
  margin-bottom: 8px;
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
  gap: 2px;
  width: 294px;
}

.calendar-date {
  width: 40px;
  height: 32px;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  border-radius: 4px;
  color: #000000;
  font-size: 12px;
  font-weight: 400;
  font-family: var(--font-family-main);
  transition: all 0.2s ease;
}

.calendar-date:hover:not(.disabled) {
  background: #f0f0f0;
}

.calendar-date.disabled:hover {
  background: transparent !important;
  color: #cccccc !important;
}

.calendar-date.selected {
  background: var(--success-color, #28a745);
  color: white;
  border-radius: 4px;
}

.calendar-date.disabled {
  color: #cccccc !important;
  background: transparent !important;
  cursor: not-allowed;
  opacity: 0.5;
}

.calendar-date.past {
  opacity: 0.3;
  color: #cccccc;
}

/* 時間選択 */
.time-selection-container {
  flex: 1;
  min-width: 280px;
  transition: opacity 0.3s ease;
}

.time-selection-container.disabled {
  opacity: 0.5;
  pointer-events: none;
}

.time-placeholder {
  text-align: center;
  padding: 40px 20px;
  color: #999999;
  font-size: 16px;
  font-family: var(--font-family-main);
}

.time-selector {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 16px;
  margin-top: 0;
}

.time-inputs {
  display: flex;
  align-items: center;
  gap: 40px;
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
  font-size: 18px;
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

/* 時間エラーポップアップ */
.time-error-popup {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.5);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
  animation: fadeIn 0.3s ease;
}

.error-popup-content {
  background: #ffffff;
  padding: 24px 32px;
  border-radius: 12px;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.15);
  color: #e74c3c;
  font-size: 16px;
  font-weight: 500;
  font-family: var(--font-family-main);
  text-align: center;
  border: 2px solid #e74c3c;
  animation: slideIn 0.3s ease;
}

@keyframes fadeIn {
  from { opacity: 0; }
  to { opacity: 1; }
}

@keyframes slideIn {
  from { 
    opacity: 0;
    transform: scale(0.8) translateY(-20px);
  }
  to { 
    opacity: 1;
    transform: scale(1) translateY(0);
  }
}

/* アクションボタン */
.action-buttons {
  position: absolute;
  left: 304px;
  top: 670px;
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
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
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
  top: 750px;
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

/* 440px以下の超小型モバイル対応 */
@media (max-width: 440px) {
  .schedule-wizard {
    width: 100%;
    height: auto;
    padding: 16px 12px;
    overflow: visible;
    display: flex;
    flex-direction: column;
    gap: 20px;
    position: static;
  }
  
  .page-title {
    position: static;
    text-align: center;
    font-size: 18px;
    margin: 0;
  }
  
  /* スケジュールオプションを縦一列に */
  .schedule-options {
    position: static;
    display: flex;
    flex-direction: column;
    gap: 12px;
    width: 100%;
  }
  
  .schedule-card {
    width: 100%;
    height: 70px;
    margin: 0;
    padding: 8px;
  }
  
  .card-title {
    font-size: 14px;
  }
  
  .time-display {
    font-size: 14px;
  }
  
  /* カスタム設定セクション */
  .custom-section {
    position: static;
    width: 100%;
    margin-top: 0;
  }
  
  .custom-title {
    width: 100%;
    text-align: center;
    margin-bottom: 16px;
    font-size: 16px;
  }
  
  /* カレンダーと時間選択を縦並びに */
  .custom-content {
    flex-direction: column;
    gap: 20px;
    align-items: center;
  }
  
  .calendar-container {
    width: 100%;
    max-width: 300px;
  }
  
  .calendar-month-header {
    width: 100%;
    max-width: 300px;
  }
  
  .calendar-header {
    width: 100%;
    max-width: 300px;
  }
  
  .calendar-grid {
    width: 100%;
    max-width: 300px;
  }
  
  .calendar-date {
    width: 36px;
    height: 28px;
    font-size: 11px;
  }
  
  .time-selection-container {
    width: 100%;
    max-width: 300px;
  }
  
  .time-select {
    width: 60px;
    height: 60px;
    font-size: 16px;
  }
  
  .time-unit {
    font-size: 24px;
  }
  
  /* アクションボタン */
  .action-buttons {
    position: static;
    flex-direction: column;
    gap: 12px;
    width: 100%;
    margin-top: 20px;
  }
  
  .btn {
    width: 100%;
    height: 50px;
    font-size: 16px;
    max-width: 280px;
    margin: 0 auto;
  }
  
  /* アラート */
  .alert {
    position: static;
    width: 100%;
    margin-top: 16px;
    font-size: 14px;
  }
}
</style>