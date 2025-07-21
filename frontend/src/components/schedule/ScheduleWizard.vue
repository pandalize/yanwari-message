<template>
  <div class="schedule-wizard">
    <!-- ページタイトル -->
    <h1 class="page-title">送信予約</h1>

    <!-- 時間選択グリッド（2x2レイアウト） -->
    <div class="time-selection-grid">
      <!-- 今すぐ送信 -->
      <div 
        class="time-option"
        :class="{ selected: selectedOption === 'immediate' }"
        @click="selectOption('immediate')"
      >
        <h3 class="option-title">今すぐ送信</h3>
        <div class="option-content">
          <p class="time-text">今日　{{ currentTime }}</p>
          <p class="recommendation-text">おすすめ度：　50</p>
        </div>
      </div>

      <!-- AIおすすめ1 -->
      <div 
        class="time-option"
        :class="{ selected: selectedOption?.option === 'AIおすすめ1' }"
        @click="selectTimeOption(suggestion?.suggested_options?.[0] || getDefaultOption(0))"
      >
        <h3 class="option-title">AIおすすめ1</h3>
        <div class="option-content">
          <p class="time-text">{{ formatOptionDisplay(suggestion?.suggested_options?.[0] || getDefaultOption(0)) }}</p>
          <p class="recommendation-text">おすすめ度：　{{ getRecommendationScore(suggestion?.suggested_options?.[0]?.priority || getDefaultOption(0).priority) }}</p>
        </div>
      </div>

      <!-- AIおすすめ2 -->
      <div 
        class="time-option default-selected"
        :class="{ selected: selectedOption?.option === 'AIおすすめ2' }"
        @click="selectTimeOption(suggestion?.suggested_options?.[1] || getDefaultOption(1))"
      >
        <h3 class="option-title">AIおすすめ2</h3>
        <div class="option-content">
          <p class="time-text">{{ formatOptionDisplay(suggestion?.suggested_options?.[1] || getDefaultOption(1)) }}</p>
          <p class="recommendation-text">おすすめ度：　{{ getRecommendationScore(suggestion?.suggested_options?.[1]?.priority || getDefaultOption(1).priority) }}</p>
        </div>
      </div>

      <!-- AIおすすめ3 -->
      <div 
        class="time-option"
        :class="{ selected: selectedOption?.option === 'AIおすすめ3' }"
        @click="selectTimeOption(suggestion?.suggested_options?.[2] || getDefaultOption(2))"
      >
        <h3 class="option-title">AIおすすめ3</h3>
        <div class="option-content">
          <p class="time-text">{{ formatOptionDisplay(suggestion?.suggested_options?.[2] || getDefaultOption(2)) }}</p>
          <p class="recommendation-text">おすすめ度：　{{ getRecommendationScore(suggestion?.suggested_options?.[2]?.priority || getDefaultOption(2).priority) }}</p>
        </div>
      </div>
    </div>

    <!-- 自分で設定する -->
    <div class="custom-section">
      <h3 class="custom-title">自分で設定する</h3>
      
      <!-- カレンダー -->
      <div class="calendar-grid">
        <div class="calendar-header">
          <span>Su</span><span>Mo</span><span>Tu</span><span>We</span><span>Th</span><span>Fr</span><span>Sa</span>
        </div>
        <div class="calendar-dates">
          <span v-for="date in calendarDates" :key="date" 
                :class="{ selected: date === selectedDate }"
                @click="selectDate(date)">
            {{ date }}
          </span>
        </div>
      </div>

      <!-- 時間選択 -->
      <div class="time-inputs">
        <div class="time-input">
          <input type="number" v-model="customHour" min="0" max="23" class="time-field">
          <span class="time-label">時</span>
        </div>
        <div class="time-input">
          <input type="number" v-model="customMinute" min="0" max="59" class="time-field">
          <span class="time-label">分</span>
        </div>
      </div>
    </div>

    <!-- アクションボタン -->
    <div class="action-buttons">
      <button class="action-btn back-btn" @click="goBack">
        文章を編集
      </button>
      <button 
        class="action-btn schedule-btn" 
        @click="scheduleMessage"
        :disabled="!canSchedule || isScheduling"
      >
        {{ isScheduling ? '設定中...' : 'この時刻に送信する' }}
      </button>
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
const messageId = ref('')
const messageText = ref('')
const selectedTone = ref('gentle')
const finalText = ref('')
const recipientEmail = ref('')

// ルートパラメータからの値を設定
const initializeFromRoute = () => {
  messageId.value = (route.params.messageId as string) || (route.query.messageId as string) || ''
  messageText.value = (route.query.messageText as string) || ''
  selectedTone.value = (route.query.selectedTone as string) || 'gentle'
  finalText.value = (route.query.finalText as string) || ''
  recipientEmail.value = (route.query.recipientEmail as string) || ''
  
  console.log('ルートから初期化された値:', {
    messageId: messageId.value,
    messageText: messageText.value,
    selectedTone: selectedTone.value,
    finalText: finalText.value,
    recipientEmail: recipientEmail.value
  })
}

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
const customHour = ref(9)
const customMinute = ref(0)
const selectedDate = ref(new Date().getDate())
const isScheduling = ref(false)
const isSending = ref(false)
const error = ref('')
const successMessage = ref('')

// 計算プロパティ
const minDate = computed(() => {
  const today = new Date()
  return today.toISOString().split('T')[0]
})

const canSchedule = computed(() => {
  return selectedOption.value || (customHour.value !== null && customMinute.value !== null && selectedDate.value)
})

const currentTime = computed(() => {
  const now = new Date()
  const hours = String(now.getHours()).padStart(2, '0')
  const minutes = String(now.getMinutes()).padStart(2, '0')
  return `${hours}:${minutes}`
})

const calendarDates = computed(() => {
  // 簡易カレンダー用の日付配列（1-31）
  return Array.from({ length: 31 }, (_, i) => i + 1)
})

// デフォルトオプションを取得
const getDefaultOption = (index: number) => {
  const options = [
    {
      option: 'AIおすすめ1',
      priority: '推奨',
      reason: '明日の朝の時間帯',
      delay_minutes: 'next_business_day_10am'
    },
    {
      option: 'AIおすすめ2',
      priority: '最推奨',
      reason: '月曜日の朝の時間帯',
      delay_minutes: 'next_business_day_10am'
    },
    {
      option: 'AIおすすめ3',
      priority: '選択肢',
      reason: '明後日の夜の時間帯',
      delay_minutes: 1080
    }
  ]
  return options[index] || options[0]
}

// オプション表示用のフォーマット
const formatOptionDisplay = (option: any) => {
  if (!option) return ''
  
  if (option.delay_minutes === 'next_business_day_10am') {
    return option.option === 'AIおすすめ1' ? '明日の朝☀️　10:00' : '月曜日の朝☀️　10:00'
  }
  
  if (option.delay_minutes === 1080) {
    return '明後日の夜🌙️　18:00'
  }
  
  return formatOptionTime(option)
}

// メソッド
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
  console.log('loadAISuggestion 開始 - データチェック:', {
    messageId: messageId.value,
    messageText: messageText.value,
    selectedTone: selectedTone.value,
    hasMessageId: !!messageId.value,
    hasMessageText: !!messageText.value
  })
  
  if (!messageId.value || !messageText.value) {
    const missingFields = []
    if (!messageId.value) missingFields.push('messageId')
    if (!messageText.value) missingFields.push('messageText')
    
    console.error('AI提案エラー - 必要情報不足:', { 
      missingFields,
      messageId: messageId.value,
      messageText: messageText.value,
      routeQuery: route.query,
      routeParams: route.params
    })
    
    // メッセージ情報が不足している場合は、代替のサンプル提案を表示
    suggestion.value = {
      message_type: 'sample',
      urgency_level: '中',
      recommended_timing: 'サンプル提案',
      reasoning: 'メッセージ情報が不足しているため、サンプル時間を表示しています',
      suggested_options: [
        {
          option: '明日の朝',
          priority: '推奨',
          reason: '業務開始時間に配慮',
          delay_minutes: 'next_business_day_9am'
        },
        {
          option: '今日の夕方',
          priority: '選択肢',
          reason: '業務終了前の確認',
          delay_minutes: 480
        },
        {
          option: '来週月曜日',
          priority: '選択肢', 
          reason: '週の始まりでの対応',
          delay_minutes: 'next_business_day_9am'
        }
      ]
    }
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
    console.log('提案オプション数:', suggestion.value?.suggested_options?.length)
  } catch (err: any) {
    console.error('AI提案エラー:', err)
    console.error('エラー詳細:', {
      status: err.response?.status,
      statusText: err.response?.statusText,
      data: err.response?.data,
      message: err.message,
      code: err.code
    })
    
    let errorMessage = 'AI提案の取得に失敗しました'
    if (err.code === 'ECONNABORTED') {
      errorMessage = 'AI提案の処理に時間がかかりすぎています。もう一度お試しください。'
    } else if (err.response?.status === 400) {
      errorMessage = `リクエストエラー: ${err.response.data?.error || 'パラメータが正しくありません'}`
    } else if (err.response?.status === 404) {
      errorMessage = `メッセージが見つかりません: ${err.response.data?.error || 'メッセージIDが無効です'}`
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

const selectDate = (date: number) => {
  selectedDate.value = date
  console.log('選択された日付:', date)
}

const selectOption = (option: string) => {
  if (option === 'immediate') {
    sendImmediately()
  } else {
    selectedOption.value = option
    console.log('選択されたオプション:', option)
  }
}

const sendImmediately = async () => {
  isSending.value = true
  error.value = ''
  
  try {
    // 現在時刻で即座に送信スケジュールを作成
    const now = new Date()
    const scheduledAt = now.toISOString()
    
    console.log('即座送信:', {
      messageId: messageId.value,
      scheduledAt
    })
    
    await scheduleService.createSchedule({
      messageId: messageId.value,
      scheduledAt
    })
    
    successMessage.value = 'メッセージを送信しました！'
    
    // 送信完了後、受信トレイ画面に遷移
    setTimeout(() => {
      router.push('/inbox')
    }, 2000)
    
  } catch (err: any) {
    console.error('即座送信エラー:', err)
    error.value = err.response?.data?.error || 'メッセージの送信に失敗しました'
  } finally {
    isSending.value = false
  }
}

const goBack = () => {
  // トーン変換画面に戻る
  if (messageId.value) {
    router.push({
      name: 'tone-transform',
      params: { id: messageId.value }
    })
  } else {
    router.back()
  }
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

// 初期化
onMounted(() => {
  // ルートから値を初期化
  initializeFromRoute()
  
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
  
  // AI提案を自動取得（サンプルデータを表示）
  console.log('AI提案を自動実行')
  loadAISuggestion()
})
</script>

<style scoped>
.schedule-wizard {
  padding: 2rem;
  max-width: 800px;
  margin: 0 auto;
  background: #f5f5f5;
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
}

/* ページタイトル */
.page-title {
  font-size: 1.5rem;
  color: #333;
  font-weight: 500;
  margin: 0 0 2rem 0;
  text-align: left;
}

/* 時間選択グリッド（2x2） */
.time-selection-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 1rem;
  margin-bottom: 2rem;
}

/* 時間選択オプション */
.time-option {
  background: white;
  border: 2px solid #e0e0e0;
  border-radius: 12px;
  padding: 1.5rem;
  cursor: pointer;
  transition: all 0.3s ease;
  text-align: center;
  min-height: 120px;
  display: flex;
  flex-direction: column;
  justify-content: center;
}

.time-option:hover {
  border-color: #007bff;
  box-shadow: 0 2px 8px rgba(0,123,255,0.15);
}

.time-option.selected {
  border-color: #007bff;
  background: #f0f8ff;
}

.time-option.selected-default {
  background: #b5fcb0;
  border-color: #28a745;
}

.time-option.selected-default.selected {
  background: #a0f0a0;
  border-color: #1e7e34;
}

.option-title {
  font-size: 1rem;
  font-weight: 600;
  color: #333;
  margin: 0 0 0.5rem 0;
}

.option-content {
  margin: 0;
}

.time-text {
  font-size: 0.875rem;
  color: #666;
  margin: 0;
  line-height: 1.4;
}

/* カスタム設定セクション */
.custom-section {
  margin-bottom: 2rem;
  text-align: center;
}

.custom-title {
  font-size: 1rem;
  color: #333;
  font-weight: 500;
  margin: 0 0 1.5rem 0;
}

/* カレンダー */
.calendar-grid {
  margin-bottom: 1.5rem;
}

.calendar-header {
  display: grid;
  grid-template-columns: repeat(7, 1fr);
  gap: 0.5rem;
  margin-bottom: 0.5rem;
  text-align: center;
}

.calendar-header span {
  font-weight: 500;
  color: #666;
  font-size: 0.875rem;
  padding: 0.5rem;
}

.calendar-dates {
  display: grid;
  grid-template-columns: repeat(7, 1fr);
  gap: 0.25rem;
  max-width: 350px;
  margin: 0 auto;
}

.calendar-dates span {
  padding: 0.5rem;
  text-align: center;
  cursor: pointer;
  border-radius: 6px;
  transition: all 0.3s ease;
  font-size: 0.875rem;
  color: #333;
  min-height: 40px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.calendar-dates span:hover {
  background: #f0f0f0;
}

.calendar-dates span.selected {
  background: #007bff;
  color: white;
}

/* 時間入力 */
.time-inputs {
  display: flex;
  gap: 1rem;
  justify-content: center;
  align-items: center;
}

.time-input {
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.time-field {
  width: 60px;
  padding: 0.75rem;
  border: 2px solid #e0e0e0;
  border-radius: 8px;
  text-align: center;
  font-size: 1rem;
  font-weight: 500;
}

.time-field:focus {
  outline: none;
  border-color: #007bff;
}

.time-label {
  font-size: 1rem;
  color: #333;
  font-weight: 500;
}

/* アクションボタン */
.action-buttons {
  display: flex;
  gap: 1rem;
  justify-content: center;
  margin-top: 2rem;
}

.action-btn {
  padding: 0.875rem 2rem;
  border: none;
  border-radius: 25px;
  font-size: 1rem;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.3s ease;
  flex: 1;
  max-width: 200px;
}

.back-btn {
  background: #f0f0f0;
  color: #333;
  border: 2px solid #e0e0e0;
}

.back-btn:hover {
  background: #e0e0e0;
}

.schedule-btn {
  background: #007bff;
  color: white;
}

.schedule-btn:hover:not(:disabled) {
  background: #0056b3;
}

.schedule-btn:disabled {
  background: #6c757d;
  cursor: not-allowed;
}

/* メッセージ */
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

/* ===== レスポンシブ対応 ===== */
/* ===== 大画面対応 ===== */
@media (min-width: 1400px) {
  .schedule-wizard {
    max-width: 1000px;
    padding: var(--spacing-3xl) var(--spacing-2xl);
  }
  
  .page-title {
    font-size: 2rem;
    margin-bottom: var(--spacing-3xl);
  }
  
  .time-selection-grid {
    gap: var(--spacing-xl);
    margin-bottom: var(--spacing-3xl);
  }
  
  .time-option {
    min-height: 140px;
    padding: var(--spacing-2xl);
  }
  
  .option-title {
    font-size: var(--font-size-xl);
  }
  
  .time-text {
    font-size: var(--font-size-lg);
  }
  
  .calendar-dates {
    max-width: 400px;
    gap: var(--spacing-sm);
  }
  
  .calendar-dates span {
    min-height: 50px;
    font-size: var(--font-size-lg);
  }
  
  .time-field {
    width: 80px;
    padding: var(--spacing-lg);
    font-size: var(--font-size-xl);
  }
  
  .time-label {
    font-size: var(--font-size-xl);
  }
  
  .action-btn {
    max-width: 250px;
    padding: var(--spacing-lg) var(--spacing-2xl);
    font-size: var(--font-size-xl);
  }
  
  .custom-title {
    font-size: var(--font-size-xl);
    margin-bottom: var(--spacing-2xl);
  }
}

/* タブレット表示 */
@media (max-width: 1199px) {
  .schedule-wizard {
    max-width: 100%;
    padding: var(--spacing-2xl) var(--spacing-md);
  }
  
  .page-title {
    font-size: var(--font-size-2xl);
  }
  
  .time-option {
    min-height: 110px;
    padding: var(--spacing-lg);
  }
  
  .option-title {
    font-size: var(--font-size-lg);
  }
  
  .time-text {
    font-size: var(--font-size-md);
  }
  
  .calendar-dates {
    max-width: 320px;
  }
  
  .action-btn {
    max-width: 180px;
    padding: var(--spacing-md) var(--spacing-xl);
  }
}

/* モバイル表示 */
@media (max-width: 767px) {
  .schedule-wizard {
    padding: var(--spacing-xl) var(--spacing-sm);
  }
  
  .page-title {
    font-size: var(--font-size-xl);
  }
  
  .time-selection-grid {
    grid-template-columns: 1fr;
    gap: var(--spacing-md);
  }
  
  .time-option {
    min-height: 100px;
    padding: var(--spacing-md);
  }
  
  .option-title {
    font-size: var(--font-size-md);
  }
  
  .time-text {
    font-size: var(--font-size-sm);
  }
  
  .calendar-dates {
    max-width: 280px;
  }
  
  .calendar-dates span {
    min-height: 35px;
    font-size: var(--font-size-sm);
  }
  
  .time-field {
    width: 50px;
    padding: var(--spacing-sm);
    font-size: var(--font-size-sm);
  }
  
  .time-label {
    font-size: var(--font-size-sm);
  }
  
  .action-buttons {
    flex-direction: column;
    gap: var(--spacing-md);
  }
  
  .action-btn {
    max-width: none;
    width: 100%;
    padding: var(--spacing-lg) var(--spacing-xl);
    font-size: var(--font-size-lg);
  }
}

/* 小さいモバイル表示 */
@media (max-width: 479px) {
  .schedule-wizard {
    padding: var(--spacing-lg) var(--spacing-xs);
  }
  
  .page-title {
    font-size: var(--font-size-lg);
  }
  
  .time-option {
    min-height: 90px;
    padding: var(--spacing-sm);
  }
  
  .option-title {
    font-size: var(--font-size-sm);
  }
  
  .time-text {
    font-size: var(--font-size-xs);
  }
  
  .calendar-dates {
    max-width: 250px;
    gap: 0.125rem;
  }
  
  .calendar-dates span {
    min-height: 30px;
    padding: var(--spacing-xs);
    font-size: var(--font-size-xs);
  }
  
  .calendar-header span {
    font-size: var(--font-size-xs);
    padding: var(--spacing-xs);
  }
  
  .time-field {
    width: 45px;
    padding: var(--spacing-xs);
    font-size: var(--font-size-xs);
  }
  
  .time-label {
    font-size: var(--font-size-xs);
  }
  
  .action-btn {
    padding: var(--spacing-md) var(--spacing-lg);
    font-size: var(--font-size-md);
  }
  
  .custom-title {
    font-size: var(--font-size-sm);
  }
}
</style>