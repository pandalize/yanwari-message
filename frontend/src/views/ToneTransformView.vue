<template>
  <PageContainer>
    <div class="tone-transform-view">
    <!-- エラー状態 -->
    <div v-if="error" class="error-container">
      <h2>エラーが発生しました</h2>
      <p>{{ error }}</p>
      <UnifiedButton @click="$router.go(-1)">
        戻る
      </UnifiedButton>
    </div>

    <!-- メイン画面 -->
    <div v-else class="main-content">
      <!-- ページタイトル -->
      <PageTitle>トーン変換</PageTitle>

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
          <!-- デバッグ情報 -->
          <div v-if="true" class="debug-info" style="background: #f0f0f0; padding: 1rem; margin-bottom: 1rem; font-size: 0.8rem;">
            <details>
              <summary>デバッグ情報</summary>
              <pre>{{ JSON.stringify({ 
                toneOptionsLength: toneOptions.length,
                storeVariations: transformStore.variations,
                storeError: transformStore.error,
                toneOptions: toneOptions.map(opt => ({ tone: opt.tone, hasText: !!opt.text, textLength: opt.text.length }))
              }, null, 2) }}</pre>
            </details>
          </div>
          
          <div 
            v-for="option in toneOptions" 
            :key="option.tone"
            class="tone-option"
            :class="{ selected: selectedTone === option.tone, 'no-text': !option.text }"
            @click="option.text && selectTone(option.tone, option.text)"
          >
            <div class="tone-header">
              <h3 class="tone-title">{{ option.title }}</h3>
            </div>
            <div class="tone-content">
              <p v-if="option.text" class="tone-text">{{ option.text }}</p>
              <p v-else class="tone-text placeholder">変換中...</p>
            </div>
          </div>
        </div>
      </section>

      <!-- 次へボタンセクション -->
      <div v-if="!isLoading" class="action-section">
        <!-- 次へボタン -->
        <UnifiedButton 
          variant="primary"
          size="standard"
          @click="proceedToSchedule"
          :disabled="!selectedTone || isSaving"
        >
          <span v-if="isSaving">保存中...</span>
          <span v-else-if="!selectedTone">トーンを選択してください</span>
          <span v-else>送信日時の選択に進む</span>
        </UnifiedButton>
      </div>
    </div>
    </div>
  </PageContainer>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useMessageStore } from '@/stores/messages'
import { useTransformStore } from '@/stores/transform'
import PageContainer from '@/components/layout/PageContainer.vue'
import PageTitle from '@/components/layout/PageTitle.vue'
import UnifiedButton from '@/components/ui/UnifiedButton.vue'

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
  console.log('[ToneTransform] トーン変換開始:', { messageId, originalMessage: originalMessage.value })
  
  try {
    // 自動的にトーン変換を開始
    await transformStore.transformMessage(messageId, originalMessage.value)
    
    console.log('[ToneTransform] Store変換結果:', {
      variations: transformStore.variations,
      storeError: transformStore.error,
      variationsLength: transformStore.variations.length
    })
    
    // Storeのエラーをチェック
    if (transformStore.error) {
      throw new Error(transformStore.error)
    }
    
    // 変換結果をtoneOptionsに設定
    if (transformStore.variations.length > 0) {
      console.log('[ToneTransform] 変換結果をUIに設定中...')
      transformStore.variations.forEach(variation => {
        const optionIndex = toneOptions.value.findIndex(opt => opt.tone === variation.tone)
        if (optionIndex !== -1) {
          toneOptions.value[optionIndex].text = variation.text
          console.log(`[ToneTransform] ${variation.tone}トーン設定完了:`, variation.text.substring(0, 50))
        } else {
          console.warn(`[ToneTransform] 未知のトーン: ${variation.tone}`)
        }
      })
      console.log('[ToneTransform] 最終toneOptions:', toneOptions.value)
    } else {
      console.warn('[ToneTransform] 変換結果が空です')
      error.value = 'トーン変換結果が取得できませんでした'
    }
  } catch (err: any) {
    console.error('[ToneTransform] エラー:', err)
    error.value = err.message || 'トーン変換に失敗しました'
  } finally {
    isLoading.value = false
    console.log('[ToneTransform] ローディング終了')
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
    
    console.log('Proceeding to schedule with:', {
      messageId,
      selectedTone: selectedTone.value,
      selectedText: selectedText.value,
      currentDraft: messageStore.currentDraft
    })
    
    // 選択したトーンを保存
    const success = await messageStore.updateDraft(messageId, {
      originalText: originalMessage.value,
      selectedTone: selectedTone.value,
      variations: {
        [selectedTone.value]: selectedText.value
      }
    })

    if (success) {
      // クエリパラメータから受信者情報を取得、フォールバックでcurrentDraftから取得
      const recipientEmail = route.query.recipientEmail as string || messageStore.currentDraft?.recipientEmail || ''
      const recipientName = route.query.recipientName as string || recipientEmail.split('@')[0]
      console.log('Navigating to schedule wizard with recipient:', recipientEmail)
      
      // 予約配信画面に遷移（必要な情報をすべてクエリパラメータで渡す）
      await router.push({
        name: 'schedule-wizard',
        query: { 
          messageId,
          messageText: originalMessage.value,
          selectedTone: selectedTone.value,
          finalText: selectedText.value,
          recipientEmail
        }
      })
    } else {
      throw new Error('保存に失敗しました')
    }
  } catch (err: any) {
    console.error('Schedule proceed error:', err)
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
  /* page-containerで統一されたスタイルを使用 */
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
  border-radius: var(--radius-lg);
  background: var(--neutral-color);
  margin: 0 auto;
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

.error-container .unified-btn {
  margin-top: var(--spacing-lg);
}

/* メインコンテンツ */
.main-content {
  width: 100%;
  display: flex;
  flex-direction: column;
  align-items: center;
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
  min-height: 120px;
  border: 3px solid var(--border-color);
  border-radius: var(--radius-lg);
  background: var(--neutral-color);
  padding: var(--spacing-xl);
  cursor: default;
  transition: all 0.3s ease;
  overflow-y: auto;
}

.message-text {
  color: var(--text-primary);
  font-size: var(--font-size-base);
  font-family: var(--font-family-main);
  line-height: var(--line-height-normal);
  word-wrap: break-word;
  word-break: break-word;
  white-space: pre-wrap;
  min-height: 1.5em;
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
  border-radius: var(--radius-lg);
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

.tone-option.no-text {
  opacity: 0.5;
  cursor: not-allowed;
}

.tone-text.placeholder {
  color: var(--text-muted);
  font-style: italic;
}

.debug-info {
  font-family: monospace;
  max-height: 200px;
  overflow-y: auto;
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
  word-wrap: break-word;
  word-break: break-word;
  white-space: pre-wrap;
  min-height: 1.5em;
}

/* アクションセクション */
.action-section {
  margin-top: var(--spacing-3xl);
  display: flex;
  justify-content: center;
}


/* レスポンシブ対応 */

/* 大画面対応 */
@media (min-width: 1400px) {
  
  .section-title {
    font-size: var(--font-size-xl);
    margin-bottom: var(--spacing-xl);
  }
  
  .message-container {
    max-width: 1000px;
    min-height: 200px;
    padding: var(--spacing-2xl);
  }
  
  .message-text {
    font-size: var(--font-size-lg);
  }
  
  .tone-options {
    max-width: 1000px;
    gap: var(--spacing-xl);
  }
  
  .tone-option {
    padding: var(--spacing-2xl);
  }
  
  .tone-text {
    font-size: var(--font-size-lg);
  }
  
}

@media (max-width: 768px) {
  
  .message-container,
  .tone-options {
    width: 100%;
    max-width: 900px;
  }
  
}

/* 440px以下の超小型モバイル対応 */
@media (max-width: 440px) {
  .tone-transform-view {
    padding: 16px 12px 80px 12px;
    margin: -16px -12px -76px -12px;
    box-sizing: border-box;
    overflow-x: hidden;
  }
  
  .message-container {
    width: auto;
    max-width: calc(100vw - 24px);
    margin: 0 auto;
    min-height: 80px;
    padding: 12px;
  }
  
  .tone-options {
    width: auto;
    max-width: calc(100vw - 24px);
    margin: 0 auto;
    gap: 12px;
  }
  
  .tone-option {
    padding: 12px;
    border-width: 2px;
  }
  
  .tone-title {
    font-size: 14px;
    margin-bottom: 8px;
  }
  
  .tone-text {
    font-size: 14px;
    line-height: 1.4;
  }
  
  .action-section {
    width: auto;
    max-width: calc(100vw - 24px);
    margin: 0 auto;
    margin-top: 16px;
  }
  
  
  .section-title {
    font-size: 16px;
    margin-bottom: 12px;
  }
  
  .debug-info {
    font-size: 12px;
    padding: 8px;
    margin-bottom: 8px;
  }
}
</style>