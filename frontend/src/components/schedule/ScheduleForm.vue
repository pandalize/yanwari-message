<template>
  <div class="schedule-form">
    <h2>送信スケジュール設定</h2>
    
    <div class="form-container">
      <div class="draft-preview">
        <h3>送信予定メッセージ</h3>
        <div class="message-preview">
          <p><strong>元の文章:</strong></p>
          <p class="original">{{ draft.originalText }}</p>
          
          <p><strong>変換後の文章:</strong></p>
          <p class="transformed">{{ draft.transformedText }}</p>
          
          <p><strong>トーン:</strong> {{ getToneLabel(draft.tone) }}</p>
        </div>
      </div>
      
      <div class="schedule-settings">
        <h3>送信設定</h3>
        
        <div class="form-group">
          <label for="sendDate">送信日</label>
          <input
            id="sendDate"
            v-model="scheduleForm.date"
            type="date"
            :min="minDate"
            required
          />
        </div>
        
        <div class="form-group">
          <label for="sendTime">送信時刻</label>
          <input
            id="sendTime"
            v-model="scheduleForm.time"
            type="time"
            required
          />
        </div>
        
        <div class="form-group">
          <label for="timezone">タイムゾーン</label>
          <select id="timezone" v-model="scheduleForm.timezone">
            <option value="Asia/Tokyo">日本標準時 (JST)</option>
            <option value="UTC">協定世界時 (UTC)</option>
            <option value="America/New_York">東部標準時 (EST)</option>
            <option value="Europe/London">グリニッジ標準時 (GMT)</option>
          </select>
        </div>
        
        <div class="form-group">
          <label for="recipient">送信先 (オプション)</label>
          <input
            id="recipient"
            v-model="scheduleForm.recipient"
            type="email"
            placeholder="example@email.com"
          />
          <small>空欄の場合は下書きとして保存されます</small>
        </div>
        
        <div class="schedule-preview">
          <h4>送信予定時刻</h4>
          <p class="scheduled-time">
            {{ formatScheduledTime() }}
          </p>
        </div>
        
        <div class="action-buttons">
          <button
            @click="scheduleMessage"
            :disabled="!isFormValid || isScheduling"
            class="schedule-btn"
          >
            {{ isScheduling ? 'スケジュール設定中...' : 'スケジュール設定' }}
          </button>
          
          <button @click="saveDraft" class="draft-btn">
            下書きとして保存
          </button>
          
          <button @click="goBack" class="back-btn">
            戻る
          </button>
        </div>
      </div>
    </div>
    
    <div v-if="error" class="error-message">
      {{ error }}
    </div>
    
    <div v-if="successMessage" class="success-message">
      {{ successMessage }}
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'

// TODO: F-03 スケジュール機能実装
// - ISO8601形式での時刻処理
// - タイムゾーン変換
// - スケジュール作成API呼び出し
// - バリデーション強化

const router = useRouter()

// 仮の下書きデータ
const draft = reactive({
  id: '1',
  originalText: 'サンプルの元文章です',
  transformedText: 'やんわりと変換されたサンプル文章です',
  tone: 'gentle'
})

const scheduleForm = reactive({
  date: '',
  time: '',
  timezone: 'Asia/Tokyo',
  recipient: ''
})

const isScheduling = ref(false)
const error = ref('')
const successMessage = ref('')

const minDate = computed(() => {
  const today = new Date()
  return today.toISOString().split('T')[0]
})

const isFormValid = computed(() => {
  return scheduleForm.date && scheduleForm.time
})

const toneLabels = {
  gentle: 'やんわり',
  constructive: '建設的',
  casual: 'カジュアル'
}

const getToneLabel = (tone: string) => {
  return toneLabels[tone as keyof typeof toneLabels] || tone
}

const formatScheduledTime = () => {
  if (!scheduleForm.date || !scheduleForm.time) {
    return '日時を選択してください'
  }
  
  const dateTime = new Date(`${scheduleForm.date}T${scheduleForm.time}`)
  return `${dateTime.toLocaleDateString('ja-JP')} ${dateTime.toLocaleTimeString('ja-JP')} (${scheduleForm.timezone})`
}

const scheduleMessage = async () => {
  isScheduling.value = true
  error.value = ''
  
  try {
    // TODO: スケジュール作成API呼び出し
    const scheduleData = {
      draftId: draft.id,
      sendAt: `${scheduleForm.date}T${scheduleForm.time}:00`,
      timezone: scheduleForm.timezone,
      recipient: scheduleForm.recipient || null
    }
    
    console.log('F-03: スケジュール作成処理 - 実装予定', scheduleData)
    
    await new Promise(resolve => setTimeout(resolve, 1500))
    successMessage.value = 'スケジュールを設定しました'
    
    setTimeout(() => {
      router.push('/schedules')
    }, 2000)
    
  } catch (err) {
    error.value = 'スケジュールの設定に失敗しました'
  } finally {
    isScheduling.value = false
  }
}

const saveDraft = async () => {
  try {
    // TODO: 下書き保存API呼び出し
    console.log('F-02: 下書き保存処理 - 実装予定', draft)
    successMessage.value = '下書きを保存しました'
  } catch (err) {
    error.value = '下書きの保存に失敗しました'
  }
}

const goBack = () => {
  router.back()
}

onMounted(() => {
  // 現在時刻の1時間後をデフォルトに設定
  const now = new Date()
  now.setHours(now.getHours() + 1)
  
  scheduleForm.date = now.toISOString().split('T')[0]
  scheduleForm.time = now.toTimeString().slice(0, 5)
})
</script>

<style scoped>
.schedule-form {
  max-width: 1000px;
  margin: 0 auto;
  padding: 2rem;
}

.form-container {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 2rem;
  margin-top: 2rem;
}

.draft-preview,
.schedule-settings {
  border: 1px solid #ddd;
  border-radius: 8px;
  padding: 1.5rem;
}

.message-preview {
  background-color: #f8f9fa;
  padding: 1rem;
  border-radius: 4px;
  margin-top: 1rem;
}

.original {
  color: #6c757d;
  font-style: italic;
}

.transformed {
  color: #28a745;
  font-weight: 500;
}

.form-group {
  margin-bottom: 1.5rem;
}

label {
  display: block;
  margin-bottom: 0.5rem;
  font-weight: bold;
}

input,
select {
  width: 100%;
  padding: 0.75rem;
  border: 1px solid #ddd;
  border-radius: 4px;
  font-size: 1rem;
}

small {
  color: #6c757d;
  font-size: 0.8rem;
}

.schedule-preview {
  background-color: #e3f2fd;
  padding: 1rem;
  border-radius: 4px;
  margin-bottom: 1.5rem;
}

.scheduled-time {
  font-size: 1.1rem;
  font-weight: bold;
  color: #1976d2;
  margin: 0.5rem 0 0 0;
}

.action-buttons {
  display: flex;
  gap: 1rem;
  flex-wrap: wrap;
}

.schedule-btn,
.draft-btn,
.back-btn {
  padding: 0.75rem 1.5rem;
  border: none;
  border-radius: 4px;
  font-size: 1rem;
  cursor: pointer;
}

.schedule-btn {
  background-color: #28a745;
  color: white;
}

.draft-btn {
  background-color: #007bff;
  color: white;
}

.back-btn {
  background-color: #6c757d;
  color: white;
}

.schedule-btn:disabled {
  background-color: #6c757d;
  cursor: not-allowed;
}

.error-message {
  color: #dc3545;
  margin-top: 1rem;
  text-align: center;
}

.success-message {
  color: #28a745;
  margin-top: 1rem;
  text-align: center;
}

@media (max-width: 768px) {
  .form-container {
    grid-template-columns: 1fr;
  }
  
  .action-buttons {
    flex-direction: column;
  }
}
</style>