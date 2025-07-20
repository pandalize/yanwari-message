<template>
  <div class="tone-transform-view">
    <!-- エラー状態 -->
    <div v-if="error" class="error-container">
      <h2>エラーが発生しました</h2>
      <p>{{ error }}</p>
      <button @click="$router.go(-1)" class="error-back-btn">
        戻る
      </button>
    </div>

    <!-- メイン画面 -->
    <div v-else class="main-content">
      <!-- ページタイトル -->
      <h1 class="page-title">トーン変換</h1>

      <!-- 元のメッセージ表示 -->
      <section class="original-section">
        <h2 class="section-title">元のメッセージ</h2>
        <div class="message-container">
          <div v-if="isMessageLoading" class="message-loading">
            メッセージを読み込み中...
          </div>
          <div v-else class="message-text">{{ originalMessage }}</div>
        </div>
      </section>

      <!-- 変換結果表示 -->
      <section class="transform-results-section">
        <h2 class="section-title">変換結果</h2>
        
        <!-- ローディング中の表示 -->
        <div v-if="isLoading" class="transform-loading">
          <div class="loading-spinner"></div>
          <p>トーン変換中...</p>
        </div>
        
        <!-- 3つのトーン選択肢 -->
        <div v-else class="tone-options">
          <div 
            v-for="option in toneOptions" 
            :key="option.tone"
            class="tone-option"
            :class="{ selected: selectedTone === option.tone }"
            @click="selectTone(option.tone, option.text)"
          >
            <div class="tone-header">
              <h3 class="tone-title">{{ option.title }}</h3>
            </div>
            <div class="tone-content">
              <p class="tone-text">{{ option.text }}</p>
            </div>
          </div>
        </div>
      </section>

      <!-- 次へボタンセクション -->
      <div v-if="!isLoading" class="action-section">
        <!-- 次へボタン -->
        <button 
          class="proceed-btn"
          @click="proceedToSchedule"
          :disabled="!selectedTone || isSaving"
        >
          <span v-if="isSaving">保存中...</span>
          <span v-else-if="!selectedTone">トーンを選択してください</span>
          <span v-else>送信日時の選択に進む</span>
        </button>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useMessageStore } from '@/stores/messages'
import { useTransformStore } from '@/stores/transform'

const route = useRoute()
const router = useRouter()
const messageStore = useMessageStore()
const transformStore = useTransformStore()

// State
const isLoading = ref(false)
const isMessageLoading = ref(true)
const isSaving = ref(false)
const error = ref<string | null>(null)
const selectedTone = ref('')
const selectedText = ref('')
const originalMessage = ref('')
const toneOptions = ref([
  { tone: 'gentle', title: '💝 優しめトーン', text: '' },
  { tone: 'constructive', title: '🏗️ 建設的トーン', text: '' },
  { tone: 'casual', title: '🎯 カジュアルトーン', text: '' }
])

// Methods
const loadMessage = async () => {
  const messageId = route.params.id as string
  
  if (!messageId) {
    error.value = 'メッセージIDが指定されていません'
    isMessageLoading.value = false
    return
  }

  try {
    // メッセージを取得
    await messageStore.fetchMessage(messageId)
    
    if (!messageStore.currentDraft) {
      error.value = 'メッセージが見つかりません'
      isMessageLoading.value = false
      return
    }

    originalMessage.value = messageStore.currentDraft.originalText
    isMessageLoading.value = false

    // メッセージ表示後にトーン変換を開始
    startToneTransform(messageId)
  } catch (err: any) {
    error.value = err.message || 'メッセージの読み込みに失敗しました'
    isMessageLoading.value = false
  }
}

const startToneTransform = async (messageId: string) => {
  isLoading.value = true
  
  try {
    // 自動的にトーン変換を開始
    await transformStore.transformMessage(messageId, originalMessage.value)
    
    // 変換結果をtoneOptionsに設定
    if (transformStore.variations.length > 0) {
      transformStore.variations.forEach(variation => {
        const optionIndex = toneOptions.value.findIndex(opt => opt.tone === variation.tone)
        if (optionIndex !== -1) {
          toneOptions.value[optionIndex].text = variation.text
        }
      })
    }
  } catch (err: any) {
    error.value = err.message || 'トーン変換に失敗しました'
  } finally {
    isLoading.value = false
  }
}

const selectTone = (tone: string, text: string) => {
  selectedTone.value = tone
  selectedText.value = text
}

const proceedToSchedule = async () => {
  if (!selectedTone.value || !selectedText.value) return
  
  isSaving.value = true
  
  try {
    const messageId = route.params.id as string
    
    // 選択したトーンを保存
    const success = await messageStore.updateDraft(messageId, {
      originalText: originalMessage.value,
      selectedTone: selectedTone.value,
      variations: {
        [selectedTone.value]: selectedText.value
      }
    })

    if (success) {
      // 予約配信画面に遷移（必要な情報をすべてクエリパラメータで渡す）
      await router.push({
        name: 'schedule-wizard',
        query: { 
          messageId,
          messageText: originalMessage.value,
          selectedTone: selectedTone.value,
          finalText: selectedText.value,
          recipientEmail: messageStore.currentDraft?.recipientEmail || ''
        }
      })
    } else {
      throw new Error('保存に失敗しました')
    }
  } catch (err: any) {
    error.value = 'トーンの保存に失敗しました'
  } finally {
    isSaving.value = false
  }
}

// Lifecycle
onMounted(() => {
  loadMessage()
})
</script>

<style scoped>
.tone-transform-view {
  padding: var(--spacing-2xl) var(--spacing-3xl);
  max-width: 1200px;
  margin: 0 auto;
  background: var(--background-primary);
  font-family: var(--font-family-main);
}

/* ローディング・エラー */
.loading-container {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  min-height: 400px;
  text-align: center;
}

.transform-loading {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  min-height: 200px;
  text-align: center;
  width: 700px;
  border: 3px solid var(--border-color);
  border-radius: 10px;
  background: var(--neutral-color);
}

.message-loading {
  color: var(--text-muted);
  font-size: var(--font-size-base);
  font-family: var(--font-family-main);
  text-align: center;
}

.loading-spinner {
  width: 40px;
  height: 40px;
  border: 4px solid var(--gray-color-light);
  border-top: 4px solid var(--secondary-color);
  border-radius: 50%;
  animation: spin 1s linear infinite;
  margin-bottom: var(--spacing-md);
}

@keyframes spin {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}

.error-container {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  min-height: 400px;
  text-align: center;
}

.error-back-btn {
  margin-top: var(--spacing-lg);
  padding: var(--spacing-md) var(--spacing-lg);
  background: var(--primary-color);
  border: none;
  border-radius: var(--radius-lg);
  color: var(--text-primary);
  font-family: var(--font-family-main);
  cursor: pointer;
}

/* メインコンテンツ */
.main-content {
  width: 100%;
}

.page-title {
  font-size: var(--font-size-base);
  color: var(--text-primary);
  font-family: var(--font-family-main);
  font-weight: var(--font-weight-regular);
  margin: 0 0 var(--spacing-lg) 0;
}

/* セクション */
.original-section,
.transform-results-section {
  margin-bottom: var(--spacing-3xl);
}

.section-title {
  font-size: var(--font-size-base);
  color: var(--text-primary);
  font-family: var(--font-family-main);
  font-weight: var(--font-weight-regular);
  margin: 0 0 var(--spacing-lg) 0;
}

/* メッセージコンテナ */
.message-container {
  width: 700px;
  min-height: 100px;
  border: 3px solid var(--border-color);
  border-radius: 10px;
  background: var(--neutral-color);
  padding: var(--spacing-xl);
}

.message-text {
  color: var(--text-primary);
  font-size: var(--font-size-base);
  font-family: var(--font-family-main);
  line-height: var(--line-height-normal);
}

/* トーン選択肢 */
.tone-options {
  display: flex;
  flex-direction: column;
  gap: var(--spacing-lg);
  width: 700px;
}

.tone-option {
  border: 3px solid var(--border-color);
  border-radius: 10px;
  background: var(--neutral-color);
  padding: var(--spacing-xl);
  cursor: pointer;
  transition: all 0.3s ease;
}

.tone-option:hover {
  border-color: var(--border-color-hover);
}

.tone-option.selected {
  border-color: var(--success-color);
  background: var(--success-color);
}

.tone-header {
  margin-bottom: var(--spacing-md);
}

.tone-title {
  font-size: var(--font-size-base);
  color: var(--text-primary);
  font-family: var(--font-family-main);
  font-weight: var(--font-weight-regular);
  margin: 0;
}

.tone-content {
  margin: 0;
}

.tone-text {
  color: var(--text-primary);
  font-size: var(--font-size-base);
  font-family: var(--font-family-main);
  line-height: var(--line-height-normal);
  margin: 0;
}

/* アクションセクション */
.action-section {
  margin-top: var(--spacing-3xl);
  display: flex;
  justify-content: center;
}

.proceed-btn {
  width: 280px;
  height: 60px;
  border-radius: 30px;
  border: none;
  background: var(--primary-color);
  color: var(--text-primary);
  font-size: var(--font-size-base);
  font-family: var(--font-family-main);
  font-weight: var(--font-weight-regular);
  cursor: pointer;
  transition: all 0.3s ease;
  display: flex;
  align-items: center;
  justify-content: center;
  white-space: nowrap;
}

.proceed-btn:hover:not(:disabled) {
  background: var(--primary-color-dark);
}

.proceed-btn:disabled {
  background: var(--gray-color-light);
  color: var(--text-muted);
  cursor: not-allowed;
}

/* レスポンシブ対応 */
@media (max-width: 768px) {
  .tone-transform-view {
    padding: var(--spacing-lg);
  }
  
  .message-container,
  .tone-options {
    width: 100%;
    max-width: 700px;
  }
  
  .proceed-btn {
    width: 100%;
  }
}
</style>