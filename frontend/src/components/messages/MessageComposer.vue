<template>
  <div class="message-composer">
    <div class="composer-header">
      <h2>📝 メッセージを作成</h2>
      <p class="subtitle">やんわり伝言で気持ちを優しく伝えましょう</p>
    </div>

    <form @submit.prevent class="composer-form">
      <!-- 送信先選択 -->
      <RecipientSelector 
        v-model="form.recipient"
        :disabled="messageStore.isLoading"
      />

      <!-- メッセージ入力 -->
      <div class="form-group">
        <label for="message">💬 伝えたいメッセージ</label>
        <textarea
          id="message"
          v-model="form.originalText"
          placeholder="例: 明日の会議、準備が間に合わないので延期してもらえませんか？"
          required
          maxlength="1000"
          class="form-textarea"
          :class="{ 'error': hasError }"
        ></textarea>
        <div class="textarea-footer">
          <small class="char-count">{{ form.originalText.length }}/1000文字</small>
          <small v-if="hasError" class="error-text">{{ messageStore.error }}</small>
        </div>
      </div>

      <!-- アクションボタン -->
      <div class="form-actions">
        <button
          v-if="currentDraftId"
          type="button"
          @click="startNewMessage"
          class="btn btn-outline"
        >
          ✨ 新しいメッセージ
        </button>
        
        <button
          type="button"
          @click="saveDraft"
          :disabled="!canSave || messageStore.isLoading"
          class="btn btn-secondary"
        >
          💾 下書き保存
        </button>
        
        <button
          type="button"
          @click="handleCreateDraft"
          :disabled="!canProceed || messageStore.isLoading"
          class="btn btn-primary"
        >
          <span v-if="messageStore.isLoading">⏳ 処理中...</span>
          <span v-else>🎭 トーン変換へ</span>
        </button>
        
        <button
          v-if="currentDraftId"
          type="button"
          @click="proceedToToneSelection"
          :disabled="!canProceed || messageStore.isLoading"
          class="btn btn-accent"
        >
          ✨ 変換画面へ
        </button>
      </div>
    </form>

    <!-- エラー表示 -->
    <div v-if="messageStore.error && !hasError" class="error-message">
      {{ messageStore.error }}
    </div>

    <!-- 下書き一覧 -->
    <div v-if="messageStore.hasDrafts" class="drafts-section">
      <h3>📄 最近の下書き</h3>
      <div class="drafts-list">
        <div
          v-for="draft in recentDrafts"
          :key="draft.id"
          class="draft-item"
          @click="loadDraft(draft)"
        >
          <div class="draft-content">
            <p class="draft-text">{{ truncateText(draft.originalText, 60) }}</p>
            <small class="draft-date">{{ formatDate(draft.updatedAt) }}</small>
          </div>
          <button
            @click.stop="deleteDraft(draft.id!)"
            class="draft-delete"
            title="削除"
          >
            🗑️
          </button>
        </div>
      </div>
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
  max-width: 800px;
  margin: 0 auto;
  padding: 2rem;
}

.composer-header {
  text-align: center;
  margin-bottom: 2rem;
}

.composer-header h2 {
  margin: 0 0 0.5rem 0;
  color: #333;
  font-size: 1.8rem;
}

.subtitle {
  color: #666;
  margin: 0;
  font-size: 1rem;
}

.composer-form {
  background: #fff;
  border: 1px solid #e0e0e0;
  border-radius: 8px;
  padding: 2rem;
  margin-bottom: 2rem;
}

.form-group {
  margin-bottom: 1.5rem;
}

.form-group label {
  display: block;
  margin-bottom: 0.5rem;
  font-weight: 600;
  color: #333;
}

.form-input {
  width: 100%;
  padding: 0.75rem;
  border: 1px solid #ddd;
  border-radius: 4px;
  font-size: 1rem;
  transition: border-color 0.2s;
}

.form-input:focus {
  outline: none;
  border-color: #007bff;
  box-shadow: 0 0 0 2px rgba(0, 123, 255, 0.25);
}

.form-textarea {
  width: 100%;
  min-height: 120px;
  padding: 0.75rem;
  border: 1px solid #ddd;
  border-radius: 4px;
  font-size: 1rem;
  font-family: inherit;
  resize: vertical;
  transition: border-color 0.2s;
}

.form-textarea:focus {
  outline: none;
  border-color: #007bff;
  box-shadow: 0 0 0 2px rgba(0, 123, 255, 0.25);
}

.form-textarea.error {
  border-color: #dc3545;
}

.textarea-footer {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-top: 0.5rem;
}

.char-count {
  color: #666;
}

.error-text {
  color: #dc3545;
}

.form-hint {
  display: block;
  margin-top: 0.25rem;
  color: #666;
  font-size: 0.875rem;
}

.form-actions {
  display: flex;
  gap: 1rem;
  justify-content: flex-end;
}

.btn {
  padding: 0.75rem 1.5rem;
  border: none;
  border-radius: 4px;
  font-size: 1rem;
  cursor: pointer;
  transition: all 0.2s;
  font-weight: 500;
}

.btn:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.btn-outline {
  background-color: transparent;
  color: #2563eb;
  border: 1px solid #2563eb;
}

.btn-outline:hover {
  background-color: #2563eb;
  color: white;
}

.btn-accent {
  background-color: #7c3aed;
  color: white;
}

.btn-accent:hover {
  background-color: #6d28d9;
}

.btn-primary {
  background-color: #007bff;
  color: white;
}

.btn-primary:hover:not(:disabled) {
  background-color: #0056b3;
}

.btn-secondary {
  background-color: #6c757d;
  color: white;
}

.btn-secondary:hover:not(:disabled) {
  background-color: #545b62;
}

.error-message {
  background-color: #f8d7da;
  color: #721c24;
  padding: 0.75rem;
  border-radius: 4px;
  margin-bottom: 1rem;
  border: 1px solid #f5c6cb;
}

.drafts-section {
  background: #f8f9fa;
  border-radius: 8px;
  padding: 1.5rem;
}

.drafts-section h3 {
  margin: 0 0 1rem 0;
  color: #333;
  font-size: 1.2rem;
}

.drafts-list {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.draft-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  background: white;
  border: 1px solid #e0e0e0;
  border-radius: 4px;
  padding: 1rem;
  cursor: pointer;
  transition: all 0.2s;
}

.draft-item:hover {
  border-color: #007bff;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
}

.draft-content {
  flex: 1;
}

.draft-text {
  margin: 0 0 0.25rem 0;
  color: #333;
  line-height: 1.4;
}

.draft-date {
  color: #666;
  font-size: 0.875rem;
}

.draft-delete {
  background: none;
  border: none;
  cursor: pointer;
  padding: 0.5rem;
  border-radius: 4px;
  transition: background-color 0.2s;
}

.draft-delete:hover {
  background-color: #f8f9fa;
}
</style>