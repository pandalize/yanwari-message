<template>
  <div class="draft-editor">
    <h2>やんわり伝言作成</h2>
    
    <div class="editor-container">
      <div class="input-section">
        <h3>元の文章</h3>
        <textarea
          v-model="originalText"
          placeholder="伝えたい内容を入力してください..."
          rows="6"
          class="original-text"
        ></textarea>
        
        <div class="tone-selection">
          <h4>トーン選択</h4>
          <div class="tone-options">
            <label v-for="tone in toneOptions" :key="tone.value">
              <input
                v-model="selectedTone"
                type="radio"
                :value="tone.value"
              />
              <span class="tone-label">
                {{ tone.label }}
                <small>{{ tone.description }}</small>
              </span>
            </label>
          </div>
        </div>
        
        <button
          @click="transformTone"
          :disabled="!originalText || isTransforming"
          class="transform-btn"
        >
          {{ isTransforming ? '変換中...' : 'やんわり変換' }}
        </button>
      </div>
      
      <div class="output-section">
        <h3>変換後の文章</h3>
        <div class="transformed-text">
          <textarea
            v-model="transformedText"
            placeholder="変換された文章がここに表示されます"
            rows="6"
            readonly
          ></textarea>
        </div>
        
        <div v-if="transformedText" class="action-buttons">
          <button @click="saveDraft" :disabled="isSaving" class="save-btn">
            {{ isSaving ? '保存中...' : '下書き保存' }}
          </button>
          <button @click="scheduleMessage" class="schedule-btn">
            送信スケジュール設定
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
import { ref, reactive } from 'vue'
import { useRouter } from 'vue-router'

// TODO: F-02 下書き・トーン変換機能実装
// - Anthropic API連携
// - リアルタイムプレビュー
// - 下書き保存機能
// - エラーハンドリング

const router = useRouter()

const originalText = ref('')
const transformedText = ref('')
const selectedTone = ref('gentle')
const isTransforming = ref(false)
const isSaving = ref(false)
const error = ref('')
const successMessage = ref('')

const toneOptions = [
  {
    value: 'gentle',
    label: 'やんわり',
    description: '優しく丁寧な表現に変換'
  },
  {
    value: 'constructive',
    label: '建設的',
    description: '前向きで建設的な表現に変換'
  },
  {
    value: 'casual',
    label: 'カジュアル',
    description: 'フランクで親しみやすい表現に変換'
  }
]

const transformTone = async () => {
  if (!originalText.value.trim()) return
  
  isTransforming.value = true
  error.value = ''
  
  try {
    // TODO: Anthropic API呼び出し
    console.log('F-02: トーン変換処理 - 実装予定', {
      originalText: originalText.value,
      tone: selectedTone.value
    })
    
    // 仮の変換処理
    await new Promise(resolve => setTimeout(resolve, 2000))
    transformedText.value = `[${selectedTone.value}トーンで変換] ${originalText.value}`
    
  } catch (err) {
    error.value = 'トーン変換に失敗しました'
  } finally {
    isTransforming.value = false
  }
}

const saveDraft = async () => {
  isSaving.value = true
  error.value = ''
  
  try {
    // TODO: 下書き保存API呼び出し
    console.log('F-02: 下書き保存処理 - 実装予定', {
      originalText: originalText.value,
      transformedText: transformedText.value,
      tone: selectedTone.value
    })
    
    await new Promise(resolve => setTimeout(resolve, 1000))
    successMessage.value = '下書きを保存しました'
    
  } catch (err) {
    error.value = '下書きの保存に失敗しました'
  } finally {
    isSaving.value = false
  }
}

const scheduleMessage = () => {
  // TODO: スケジュール設定画面への遷移
  console.log('F-03: スケジュール設定画面へ遷移 - 実装予定')
  router.push('/schedule')
}
</script>

<style scoped>
.draft-editor {
  max-width: 1200px;
  margin: 0 auto;
  padding: 2rem;
}

.editor-container {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 2rem;
  margin-top: 2rem;
}

.input-section,
.output-section {
  border: 1px solid #ddd;
  border-radius: 8px;
  padding: 1.5rem;
}

.original-text,
.transformed-text textarea {
  width: 100%;
  padding: 1rem;
  border: 1px solid #ddd;
  border-radius: 4px;
  font-size: 1rem;
  resize: vertical;
}

.tone-selection {
  margin: 1.5rem 0;
}

.tone-options {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.tone-label {
  display: flex;
  flex-direction: column;
  margin-left: 0.5rem;
}

.tone-label small {
  color: #666;
  font-size: 0.8rem;
}

.transform-btn,
.save-btn,
.schedule-btn {
  padding: 0.75rem 1.5rem;
  border: none;
  border-radius: 4px;
  font-size: 1rem;
  cursor: pointer;
  margin-right: 1rem;
}

.transform-btn {
  background-color: #28a745;
  color: white;
  width: 100%;
}

.save-btn {
  background-color: #007bff;
  color: white;
}

.schedule-btn {
  background-color: #ffc107;
  color: #212529;
}

.transform-btn:disabled,
.save-btn:disabled {
  background-color: #6c757d;
  cursor: not-allowed;
}

.action-buttons {
  margin-top: 1rem;
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
  .editor-container {
    grid-template-columns: 1fr;
  }
}
</style>