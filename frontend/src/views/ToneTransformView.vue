<template>
  <div class="tone-transform-view">
    <!-- ローディング中 -->
    <div v-if="isLoading" class="loading-container">
      <div class="loading-spinner"></div>
      <p>メッセージを読み込み中...</p>
    </div>

    <!-- エラー状態 -->
    <div v-else-if="error" class="error-container">
      <h2>❌ エラーが発生しました</h2>
      <p>{{ error }}</p>
      <button @click="$router.go(-1)" class="btn btn-secondary">
        ← 戻る
      </button>
    </div>

    <!-- メイン画面 -->
    <div v-else-if="message" class="transform-container">
      <!-- ヘッダー -->
      <div class="transform-header">
        <button @click="$router.go(-1)" class="back-btn">
          ← 戻る
        </button>
        <div class="header-content">
          <h1>🎭 トーン変換</h1>
          <p>メッセージを3つのトーンで変換します</p>
        </div>
      </div>

      <!-- 元のメッセージ表示 -->
      <div class="original-message">
        <h3>📝 元のメッセージ</h3>
        <div class="message-text">
          "{{ message.originalText }}"
        </div>
        <div v-if="message.recipientId" class="recipient-info">
          <span class="recipient-label">送信先:</span>
          <span class="recipient-email">{{ recipientEmail }}</span>
        </div>
      </div>

      <!-- トーン選択コンポーネント -->
      <ToneSelector
        :message-id="message.id"
        :original-text="message.originalText"
        @tone-selected="handleToneSelected"
      />

      <!-- 次へボタン -->
      <div v-if="selectedTone && selectedText" class="action-section">
        <div class="selected-summary">
          <h4>✅ 選択したトーン</h4>
          <div class="summary-content">
            <div class="tone-badge">{{ transformStore.toneLabels[selectedTone] }}</div>
            <div class="final-message">"{{ selectedText }}"</div>
          </div>
        </div>
        
        <div class="action-buttons">
          <button 
            @click="saveAndProceed" 
            class="btn btn-primary"
            :disabled="isSaving"
          >
            <span v-if="isSaving">⏳ 保存中...</span>
            <span v-else>📅 配信設定へ</span>
          </button>
          
          <button 
            @click="backToSelection" 
            class="btn btn-secondary"
          >
            🔄 トーンを変更
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useMessageStore } from '@/stores/messages'
import { useTransformStore } from '@/stores/transform'
import ToneSelector from '@/components/transform/ToneSelector.vue'

const route = useRoute()
const router = useRouter()
const messageStore = useMessageStore()
const transformStore = useTransformStore()

// State
const isLoading = ref(true)
const isSaving = ref(false)
const error = ref<string | null>(null)
const selectedTone = ref('')
const selectedText = ref('')

// Computed
const message = computed(() => messageStore.currentDraft)
const recipientEmail = computed(() => {
  // 受信者情報の取得（実装は後で）
  return 'recipient@example.com'
})

// Methods
const loadMessage = async () => {
  const messageId = route.params.id as string
  
  if (!messageId) {
    error.value = 'メッセージIDが指定されていません'
    isLoading.value = false
    return
  }

  try {
    await messageStore.fetchMessage(messageId)
    
    if (!messageStore.currentDraft) {
      error.value = 'メッセージが見つかりません'
    }
  } catch (err: any) {
    error.value = err.message || 'メッセージの読み込みに失敗しました'
  } finally {
    isLoading.value = false
  }
}

const handleToneSelected = (tone: string, text: string) => {
  selectedTone.value = tone
  selectedText.value = text
}

const saveAndProceed = async () => {
  if (!message.value || !selectedTone.value || !selectedText.value) return
  
  isSaving.value = true
  
  try {
    // メッセージに選択したトーンを保存
    const success = await messageStore.updateMessage(message.value.id!, {
      selectedTone: selectedTone.value,
      variations: {
        [selectedTone.value]: selectedText.value
      }
    })
    
    if (success) {
      // 配信設定画面に遷移（次のフェーズで実装）
      router.push(`/messages/${message.value.id}/schedule`)
    }
  } catch (err: any) {
    error.value = 'トーンの保存に失敗しました'
  } finally {
    isSaving.value = false
  }
}

const backToSelection = () => {
  selectedTone.value = ''
  selectedText.value = ''
  transformStore.reset()
}

// Lifecycle
onMounted(() => {
  loadMessage()
  
  // コンポーネント離脱時にトーン変換状態をリセット
  return () => {
    transformStore.reset()
  }
})
</script>

<style scoped>
.tone-transform-view {
  min-height: 100vh;
  background-color: #f9fafb;
  padding: 20px;
}

/* ローディング・エラー */
.loading-container,
.error-container {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  min-height: 60vh;
  text-align: center;
}

.loading-spinner {
  width: 40px;
  height: 40px;
  border: 4px solid #f3f3f3;
  border-top: 4px solid #2563eb;
  border-radius: 50%;
  animation: spin 1s linear infinite;
  margin-bottom: 20px;
}

@keyframes spin {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}

.error-container h2 {
  color: #dc2626;
  margin-bottom: 10px;
}

.error-container p {
  color: #7f1d1d;
  margin-bottom: 20px;
}

/* メインコンテナ */
.transform-container {
  max-width: 900px;
  margin: 0 auto;
}

/* ヘッダー */
.transform-header {
  display: flex;
  align-items: center;
  gap: 20px;
  margin-bottom: 30px;
  padding: 20px;
  background-color: white;
  border-radius: 12px;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
}

.back-btn {
  background: none;
  border: 1px solid #d1d5db;
  border-radius: 8px;
  padding: 10px 16px;
  cursor: pointer;
  color: #6b7280;
  font-size: 14px;
  transition: all 0.2s ease;
}

.back-btn:hover {
  background-color: #f3f4f6;
  border-color: #9ca3af;
}

.header-content h1 {
  margin: 0 0 5px 0;
  color: #1f2937;
  font-size: 24px;
}

.header-content p {
  margin: 0;
  color: #6b7280;
  font-size: 14px;
}

/* 元のメッセージ */
.original-message {
  background-color: white;
  border-radius: 12px;
  padding: 24px;
  margin-bottom: 30px;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
}

.original-message h3 {
  margin: 0 0 16px 0;
  color: #1f2937;
  font-size: 18px;
}

.message-text {
  background-color: #f9fafb;
  border: 1px solid #e5e7eb;
  border-radius: 8px;
  padding: 16px;
  font-size: 16px;
  line-height: 1.6;
  color: #374151;
  margin-bottom: 16px;
}

.recipient-info {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 14px;
}

.recipient-label {
  color: #6b7280;
}

.recipient-email {
  color: #2563eb;
  font-weight: 500;
}

/* アクションセクション */
.action-section {
  background-color: white;
  border-radius: 12px;
  padding: 24px;
  margin-top: 30px;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
}

.selected-summary h4 {
  margin: 0 0 16px 0;
  color: #1f2937;
  font-size: 18px;
}

.summary-content {
  background-color: #f0fdf4;
  border: 1px solid #bbf7d0;
  border-radius: 8px;
  padding: 16px;
  margin-bottom: 24px;
}

.tone-badge {
  display: inline-block;
  background-color: #16a34a;
  color: white;
  padding: 4px 12px;
  border-radius: 6px;
  font-size: 12px;
  font-weight: 600;
  margin-bottom: 12px;
}

.final-message {
  font-size: 16px;
  line-height: 1.6;
  color: #166534;
}

.action-buttons {
  display: flex;
  gap: 12px;
  justify-content: flex-end;
}

/* ボタンスタイル */
.btn {
  padding: 12px 24px;
  border-radius: 8px;
  font-size: 16px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s ease;
  border: none;
}

.btn-primary {
  background-color: #2563eb;
  color: white;
}

.btn-primary:hover:not(:disabled) {
  background-color: #1d4ed8;
}

.btn-primary:disabled {
  background-color: #9ca3af;
  cursor: not-allowed;
}

.btn-secondary {
  background-color: #f3f4f6;
  color: #374151;
  border: 1px solid #d1d5db;
}

.btn-secondary:hover {
  background-color: #e5e7eb;
  border-color: #9ca3af;
}

/* レスポンシブ */
@media (max-width: 768px) {
  .tone-transform-view {
    padding: 15px;
  }
  
  .transform-header {
    flex-direction: column;
    align-items: flex-start;
    gap: 15px;
  }
  
  .action-buttons {
    flex-direction: column;
  }
  
  .btn {
    width: 100%;
  }
}
</style>