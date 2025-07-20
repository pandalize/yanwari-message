<template>
  <div class="message-composer">
    <!-- ページタイトル -->
    <div class="page-header">
      <h1 class="page-title">送信</h1>
    </div>

    <!-- 新規作成セクション -->
    <div class="compose-section">
      <h2 class="section-title">新規作成</h2>
      
      <!-- メッセージ入力エリア -->
      <div class="message-input-area">
        <textarea
          v-model="form.originalText"
          placeholder="メッセージを入力 / 変換前のメッセージ&#10;送りたい理由も教えてね"
          class="message-textarea"
          :class="{ 'error': hasError }"
          maxlength="1000"
        ></textarea>
      </div>

      <!-- アクションボタン -->
      <div class="action-buttons">
        <button
          type="button"
          @click="saveDraft"
          :disabled="!canSave || messageStore.isLoading"
          class="action-btn draft-btn"
        >
          下書きに入れる
        </button>
        
        <button
          type="button"
          @click="handleCreateDraft"
          :disabled="!canProceed || messageStore.isLoading"
          class="action-btn transform-btn"
        >
          <span v-if="messageStore.isLoading">処理中...</span>
          <span v-else>トーン変換を行う</span>
        </button>
      </div>
    </div>

    <!-- 下書きセクション -->
    <div class="drafts-section">
      <h2 class="section-title">下書き</h2>
      
      <div class="drafts-container">
        <div v-if="!messageStore.hasDrafts" class="no-drafts">
          下書きはありません
        </div>
        
        <div v-else class="drafts-list">
          <div
            v-for="draft in recentDrafts"
            :key="draft.id"
            class="draft-item"
            @click="loadDraft(draft)"
          >
            <div class="draft-content">
              <p class="draft-text">{{ truncateText(draft.originalText, 100) }}</p>
              <small class="draft-date">{{ formatDate(draft.updatedAt) }}</small>
            </div>
            <button
              @click.stop="deleteDraft(draft.id!)"
              class="draft-delete"
              title="削除"
            >
              ×
            </button>
          </div>
        </div>
      </div>
    </div>

    <!-- エラー表示 -->
    <div v-if="messageStore.error && !hasError" class="error-message">
      {{ messageStore.error }}
    </div>
  </div>
</template>

<script setup lang="ts">
import { reactive, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useMessageStore } from '@/stores/messages'
import RecipientSelector from './RecipientSelector.vue'
import type { User } from '@/services/userService'

const router = useRouter()
const messageStore = useMessageStore()

const form = reactive({
  recipient: null as User | null,
  originalText: ''
})

const hasError = computed(() => {
  return messageStore.error && messageStore.error.includes('メッセージ')
})

const canSave = computed(() => {
  return form.originalText.trim().length > 0
})

const canProceed = computed(() => {
  return form.originalText.trim().length >= 5
})

const recentDrafts = computed(() => {
  return messageStore.drafts.slice(0, 5)
})

const currentDraftId = computed(() => {
  return messageStore.currentDraft?.id
})


// 下書き作成またはトーン変換画面へ
const handleCreateDraft = async () => {
  console.log('handleCreateDraft called', { 
    canProceed: canProceed.value, 
    originalText: form.originalText,
    currentDraft: messageStore.currentDraft 
  })
  
  if (!canProceed.value) {
    console.log('Cannot proceed - validation failed')
    return
  }

  // 既に下書きがある場合は更新、ない場合は新規作成
  let success = false
  let draftId = ''
  
  if (messageStore.currentDraft?.id) {
    console.log('Updating existing draft:', messageStore.currentDraft.id)
    success = await messageStore.updateDraft(messageStore.currentDraft.id, {
      originalText: form.originalText.trim(),
      recipientEmail: form.recipient?.email
    })
    draftId = messageStore.currentDraft.id
  } else {
    console.log('Creating new draft')
    success = await messageStore.createDraft({
      originalText: form.originalText.trim(),
      recipientEmail: form.recipient?.email
    })
    // 作成成功後、currentDraftが設定されるまで少し待つ
    await new Promise(resolve => setTimeout(resolve, 100))
    draftId = messageStore.currentDraft?.id || ''
  }

  console.log('Operation result:', { success, draftId, currentDraft: messageStore.currentDraft })

  if (success && draftId) {
    const route = `/messages/${draftId}/transform`
    console.log('Navigating to:', route)
    await router.push(route)
  } else {
    console.error('Failed to create/update draft or draftId is empty', { success, draftId })
    if (!messageStore.error) {
      // エラーが設定されていない場合のみ手動でエラー表示
      alert('ルーティングに失敗しました。もう一度お試しください。')
    }
  }
}

// 下書き保存
const saveDraft = async () => {
  if (!canSave.value) return

  const success = await messageStore.createDraft({
    originalText: form.originalText.trim(),
    recipientEmail: form.recipient?.email
  })

  if (success) {
    form.originalText = ''
    form.recipient = null
    messageStore.clearCurrentDraft()
    messageStore.clearError()
  }
}

// 新しいメッセージ作成
const startNewMessage = () => {
  form.originalText = ''
  form.recipient = null
  messageStore.clearCurrentDraft()
  messageStore.clearError()
}

// トーン選択画面へ遷移
const proceedToToneSelection = () => {
  if (messageStore.currentDraft?.id) {
    router.push(`/messages/${messageStore.currentDraft.id}/transform`)
  }
}

// 下書き読み込み
const loadDraft = (draft: any) => {
  form.originalText = draft.originalText
  // recipientEmailがある場合は簡易的にUser形式に変換
  if (draft.recipientEmail) {
    form.recipient = {
      id: '',
      name: draft.recipientEmail.split('@')[0],
      email: draft.recipientEmail
    }
  } else {
    form.recipient = null
  }
  // 現在の下書きとして設定
  messageStore.setCurrentDraft(draft)
}

// 下書き削除
const deleteDraft = async (draftId: string) => {
  if (confirm('この下書きを削除しますか？')) {
    await messageStore.deleteDraft(draftId)
  }
}

// テキスト切り詰め
const truncateText = (text: string, maxLength: number): string => {
  if (text.length <= maxLength) return text
  return text.substring(0, maxLength) + '...'
}

// 日付フォーマット
const formatDate = (dateString?: string): string => {
  if (!dateString) return ''
  
  const date = new Date(dateString)
  const now = new Date()
  const diffMs = now.getTime() - date.getTime()
  const diffMins = Math.floor(diffMs / (1000 * 60))
  const diffHours = Math.floor(diffMs / (1000 * 60 * 60))
  const diffDays = Math.floor(diffMs / (1000 * 60 * 60 * 24))

  if (diffMins < 60) {
    return `${diffMins}分前`
  } else if (diffHours < 24) {
    return `${diffHours}時間前`
  } else if (diffDays < 7) {
    return `${diffDays}日前`
  } else {
    return date.toLocaleDateString('ja-JP')
  }
}

// 初期化
onMounted(() => {
  messageStore.loadDrafts()
  // 新しいメッセージ作成時は現在の下書きをクリア
  messageStore.clearCurrentDraft()
})
</script>

<style scoped>
.message-composer {
  padding: var(--spacing-3xl) var(--spacing-lg);
  max-width: 1200px;
  margin: 0 auto;
  background: var(--background-primary);
  min-height: 100vh;
}

/* ===== ページヘッダー ===== */
.page-header {
  margin-bottom: var(--spacing-3xl);
}

.page-title {
  font-size: var(--font-size-4xl);
  font-weight: 600;
  color: var(--text-primary);
  margin: 0;
  font-family: var(--font-family-main);
}

/* ===== セクションタイトル ===== */
.section-title {
  font-size: var(--font-size-2xl);
  font-weight: 500;
  color: var(--text-primary);
  margin: 0 0 var(--spacing-lg) 0;
  font-family: var(--font-family-main);
}

/* ===== 新規作成セクション ===== */
.compose-section {
  margin-bottom: var(--spacing-3xl);
}

.message-input-area {
  margin-bottom: var(--spacing-2xl);
}

.message-textarea {
  width: 100%;
  min-height: 280px;
  padding: var(--spacing-xl);
  border: 2px solid var(--border-color);
  border-radius: var(--radius-xl);
  font-size: var(--font-size-lg);
  font-family: var(--font-family-main);
  background: var(--neutral-color);
  color: var(--text-primary);
  resize: vertical;
  transition: all 0.3s ease;
  line-height: var(--line-height-relaxed);
}

.message-textarea::placeholder {
  color: var(--text-muted);
  line-height: var(--line-height-relaxed);
}

.message-textarea:focus {
  outline: none;
  border-color: var(--border-color-focus);
  box-shadow: 0 0 0 3px rgba(146, 201, 255, 0.2);
}

.message-textarea.error {
  border-color: var(--error-color);
}

/* ===== アクションボタン ===== */
.action-buttons {
  display: flex;
  gap: var(--spacing-2xl);
  justify-content: center;
}

.action-btn {
  padding: var(--spacing-lg) var(--spacing-2xl);
  border: none;
  border-radius: var(--radius-xl);
  font-size: var(--font-size-xl);
  font-weight: 500;
  font-family: var(--font-family-main);
  cursor: pointer;
  transition: all 0.3s ease;
  min-width: 200px;
  box-shadow: var(--shadow-sm);
}

.action-btn:disabled {
  opacity: 0.6;
  cursor: not-allowed;
  transform: none !important;
}

.draft-btn {
  background: var(--secondary-color);
  color: var(--text-primary);
  border: 2px solid var(--secondary-color);
}

.draft-btn:hover:not(:disabled) {
  background: var(--secondary-color-dark);
  border-color: var(--secondary-color-dark);
  transform: translateY(-2px);
  box-shadow: var(--shadow-md);
}

.transform-btn {
  background: var(--primary-color);
  color: var(--text-primary);
  border: 2px solid var(--primary-color);
}

.transform-btn:hover:not(:disabled) {
  background: var(--primary-color-dark);
  border-color: var(--primary-color-dark);
  transform: translateY(-2px);
  box-shadow: var(--shadow-md);
}

/* ===== 下書きセクション ===== */
.drafts-section {
  margin-top: var(--spacing-3xl);
}

.drafts-container {
  background: var(--neutral-color);
  border: 2px solid var(--border-color);
  border-radius: var(--radius-xl);
  min-height: 250px;
  padding: var(--spacing-xl);
}

.no-drafts {
  display: flex;
  justify-content: center;
  align-items: center;
  height: 150px;
  color: var(--text-muted);
  font-size: var(--font-size-lg);
  font-family: var(--font-family-main);
}

.drafts-list {
  display: flex;
  flex-direction: column;
  gap: var(--spacing-md);
}

.draft-item {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  background: var(--background-secondary);
  border: 1px solid var(--border-color);
  border-radius: var(--radius-md);
  padding: var(--spacing-lg);
  cursor: pointer;
  transition: all 0.3s ease;
}

.draft-item:hover {
  border-color: var(--border-color-focus);
  background: var(--primary-color-light);
  transform: translateY(-1px);
  box-shadow: var(--shadow-sm);
}

.draft-content {
  flex: 1;
  margin-right: var(--spacing-md);
}

.draft-text {
  margin: 0 0 var(--spacing-xs) 0;
  color: var(--text-primary);
  font-size: var(--font-size-md);
  line-height: var(--line-height-normal);
  font-family: var(--font-family-main);
}

.draft-date {
  color: var(--text-secondary);
  font-size: var(--font-size-sm);
  font-family: var(--font-family-main);
}

.draft-delete {
  background: none;
  border: none;
  color: var(--text-muted);
  font-size: var(--font-size-xl);
  cursor: pointer;
  padding: var(--spacing-xs);
  border-radius: var(--radius-sm);
  transition: all 0.3s ease;
  line-height: 1;
  width: 24px;
  height: 24px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.draft-delete:hover {
  background: var(--error-color);
  color: var(--text-primary);
  transform: scale(1.1);
}

/* ===== エラーメッセージ ===== */
.error-message {
  background: var(--error-color);
  color: var(--text-primary);
  padding: var(--spacing-md);
  border-radius: var(--radius-md);
  margin-top: var(--spacing-lg);
  font-family: var(--font-family-main);
  border: 1px solid rgba(255, 155, 155, 0.5);
}

/* ===== レスポンシブ対応 ===== */
@media (max-width: 768px) {
  .message-composer {
    padding: var(--spacing-lg) var(--spacing-md);
  }
  
  .page-title {
    font-size: var(--font-size-3xl);
  }
  
  .section-title {
    font-size: var(--font-size-xl);
  }
  
  .message-textarea {
    min-height: 150px;
    font-size: var(--font-size-md);
  }
  
  .action-buttons {
    flex-direction: column;
    gap: var(--spacing-md);
  }
  
  .action-btn {
    width: 100%;
    min-width: auto;
  }
}

@media (max-width: 480px) {
  .message-composer {
    padding: var(--spacing-md);
  }
  
  .message-textarea {
    padding: var(--spacing-md);
    min-height: 120px;
  }
  
  .draft-item {
    padding: var(--spacing-md);
  }
}
</style>