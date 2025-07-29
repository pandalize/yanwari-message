<template>
  <div class="message-compose-view">
    <!-- ページタイトル -->
    <h1 class="page-title">送信</h1>

    <!-- 受信者情報表示 -->
    <div v-if="recipientInfo" class="recipient-info">
      <h3 class="recipient-label">送信先:</h3>
      <div class="recipient-display">
        <div class="recipient-avatar">
          {{ recipientInfo.name.charAt(0).toUpperCase() }}
        </div>
        <div class="recipient-details">
          <span class="recipient-name">{{ recipientInfo.name }}</span>
          <span class="recipient-email">{{ recipientInfo.email }}</span>
        </div>
        <button @click="changeRecipient" class="change-recipient-btn">変更</button>
      </div>
    </div>

    <!-- 新規作成セクション -->
    <section class="compose-section">
      <h2 class="section-title">メッセージ作成</h2>
      
      <!-- メッセージ入力エリア -->
      <div class="message-input-container">
        <textarea
          v-model="messageText"
          placeholder="メッセージを入力 / 変換前のメッセージ&#10;送りたい理由も教えてね"
          class="message-textarea"
          maxlength="1000"
        ></textarea>
      </div>

      <!-- アクションボタン -->
      <div class="action-buttons">
        <button 
          class="action-btn draft-btn" 
          @click="saveDraft"
          :disabled="isLoading || !messageText.trim()"
        >
          <span v-if="isLoading && currentAction === 'draft'">保存中...</span>
          <span v-else>下書きに入れる</span>
        </button>
        <button 
          class="action-btn transform-btn" 
          @click="transformTone"
          :disabled="isLoading || !messageText.trim() || !recipientInfo?.email"
        >
          <span v-if="isLoading && currentAction === 'transform'">処理中...</span>
          <span v-else-if="!messageText.trim()">メッセージを入力してください</span>
          <span v-else-if="!recipientInfo?.email">送信先を選択してください</span>
          <span v-else>トーン変換を行う</span>
        </button>
      </div>
    </section>

    <!-- 下書きセクション -->
    <section class="drafts-section">
      <h2 class="section-title">下書き</h2>
      <div class="drafts-container">
        <div v-if="messageStore.isLoading" class="loading-state">
          <div class="loading-spinner"></div>
          <span>下書きを読み込み中...</span>
        </div>
        
        <div v-else-if="messageStore.drafts.length === 0" class="empty-state">
          <div class="empty-icon">📝</div>
          <p>保存された下書きはありません</p>
          <small>メッセージを作成して「下書きに入れる」ボタンを押すと、ここに表示されます</small>
        </div>
        
        <div v-else class="drafts-list">
          <div 
            v-for="draft in messageStore.drafts" 
            :key="draft.id"
            class="draft-item"
            @click="loadDraft(draft)"
          >
            <div class="draft-content">
              <div class="draft-text">
                {{ draft.originalText.length > 100 ? draft.originalText.substring(0, 100) + '...' : draft.originalText }}
              </div>
              <div class="draft-meta">
                <span class="draft-recipient" v-if="draft.recipientEmail">
                  宛先: {{ draft.recipientEmail }}
                </span>
                <span class="draft-date">
                  {{ formatDate(draft.updatedAt || draft.createdAt) }}
                </span>
              </div>
            </div>
            <div class="draft-actions">
              <button 
                @click.stop="editDraft(draft)"
                class="draft-action-btn edit-btn"
                title="編集"
              >
                ✏️
              </button>
              <button 
                @click.stop="deleteDraftConfirm(draft)"
                class="draft-action-btn delete-btn"
                title="削除"
              >
                🗑️
              </button>
            </div>
          </div>
        </div>
      </div>
    </section>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { useMessageStore } from '@/stores/messages'
import { getUserInfo } from '@/services/messageService'
import type { MessageDraft } from '@/services/messageService'

const router = useRouter()
const route = useRoute()
const messageStore = useMessageStore()
const messageText = ref('')
const isLoading = ref(false)
const currentAction = ref('')
const recipientInfo = ref<any>(null)

// 受信者を変更
const changeRecipient = () => {
  router.push('/recipient-select')
}

<<<<<<< HEAD
// 日付フォーマット関数
const formatDate = (dateString: string) => {
  const date = new Date(dateString)
  const now = new Date()
  const diffInMinutes = Math.floor((now.getTime() - date.getTime()) / (1000 * 60))
  
  if (diffInMinutes < 1) {
    return 'たった今'
  } else if (diffInMinutes < 60) {
    return `${diffInMinutes}分前`
  } else if (diffInMinutes < 1440) {
    const hours = Math.floor(diffInMinutes / 60)
    return `${hours}時間前`
  } else {
    const days = Math.floor(diffInMinutes / 1440)
    return `${days}日前`
  }
}

// 下書きを読み込んでテキストエリアに表示
const loadDraft = async (draft: MessageDraft) => {
  messageText.value = draft.originalText
  
  // 受信者情報も設定
  if (draft.recipientEmail) {
    try {
      const userInfo = await getUserInfo(draft.recipientEmail)
      recipientInfo.value = {
        email: draft.recipientEmail,
        name: userInfo.name
      }
    } catch (error) {
      console.warn('受信者情報の取得に失敗:', error)
      recipientInfo.value = {
        email: draft.recipientEmail,
        name: draft.recipientEmail.split('@')[0]
      }
    }
  }
  
  // 現在の下書きとして設定
  messageStore.setCurrentDraft(draft)
}

// 下書きを編集モードで開く
const editDraft = (draft: MessageDraft) => {
  loadDraft(draft)
}

// 下書き削除の確認
const deleteDraftConfirm = (draft: MessageDraft) => {
  if (confirm(`「${draft.originalText.substring(0, 50)}...」を削除しますか？`)) {
    deleteDraft(draft)
  }
}

// 下書きを削除
const deleteDraft = async (draft: MessageDraft) => {
  try {
    const success = await messageStore.deleteDraft(draft.id!)
    if (success) {
      // 削除した下書きが現在編集中の場合、テキストエリアをクリア
      if (messageStore.currentDraft?.id === draft.id) {
        messageText.value = ''
        recipientInfo.value = null
      }
    }
  } catch (error) {
    console.error('下書きの削除に失敗:', error)
    alert('下書きの削除に失敗しました')
  }
}

// クエリパラメータから編集対象のメッセージと受信者情報を読み込み
onMounted(async () => {
  const { originalText, recipientEmail, recipientName, editScheduleId } = route.query
  
  console.log('MessageCompose mounted with query:', { originalText, recipientEmail, recipientName, editScheduleId })
  
  // 下書き一覧を読み込み
  try {
    await messageStore.loadDrafts()
    console.log('下書き一覧読み込み完了:', messageStore.drafts.length, '件')
  } catch (error) {
    console.error('下書き一覧の読み込みに失敗:', error)
  }
  
  // 受信者情報の設定
  if (recipientEmail && typeof recipientEmail === 'string') {
    recipientInfo.value = {
      email: recipientEmail,
      name: (recipientName && typeof recipientName === 'string') ? recipientName : recipientEmail.split('@')[0]
    }
    console.log('受信者情報設定完了:', recipientInfo.value)
  }
  
  // メッセージテキストの設定
  if (originalText && typeof originalText === 'string') {
    messageText.value = originalText
    console.log('編集モード: メッセージを自動入力しました')
  }
  
  if (editScheduleId) {
    console.log('スケジュール編集モード:', editScheduleId)
  }
  
  // 受信者が選択されていない場合のみリダイレクト（編集モードでない場合）
  if (!recipientInfo.value && !originalText) {
    console.log('受信者が未選択かつ新規作成のため、受信者選択画面にリダイレクトします')
    router.replace('/recipient-select')
  }
  
  // デバッグ: 最終的な状態を表示
  console.log('MessageCompose mounted 完了:', {
    recipientInfo: recipientInfo.value,
    messageText: messageText.value,
    routeQuery: route.query,
    draftsCount: messageStore.drafts.length
  })
})

const saveDraft = async () => {
  if (!messageText.value.trim()) {
    alert('メッセージを入力してください')
    return
  }

  isLoading.value = true
  currentAction.value = 'draft'

  try {
    // 下書き保存API呼び出し
    const success = await messageStore.createDraft({
      originalText: messageText.value,
      recipientEmail: recipientInfo.value?.email || ''
    })
    
    if (success) {
      alert('下書きを保存しました')
      messageText.value = '' // 入力欄をクリア
      // 下書き一覧は自動的にストアで更新される
    }
  } catch (error) {
    console.error('下書き保存エラー:', error)
    alert('下書きの保存に失敗しました')
  } finally {
    isLoading.value = false
    currentAction.value = ''
  }
}

const transformTone = async () => {
  if (!messageText.value.trim()) {
    alert('メッセージを入力してください')
    return
  }

  if (!recipientInfo.value?.email) {
    alert('送信先を選択してください')
    return
  }

  isLoading.value = true
  currentAction.value = 'transform'

  try {
    console.log('トーン変換開始:', {
      messageText: messageText.value,
      recipientEmail: recipientInfo.value.email,
      recipientName: recipientInfo.value.name
    })

    // まず下書きを作成
    const success = await messageStore.createDraft({
      originalText: messageText.value,
      recipientEmail: recipientInfo.value.email
    })

    console.log('下書き作成結果:', {
      success,
      currentDraft: messageStore.currentDraft,
      error: messageStore.error
    })

    if (success && messageStore.currentDraft) {
      console.log('トーン変換ページに遷移中:', messageStore.currentDraft.id)
      // トーン変換ページに遷移（下書きIDを渡す）
      await router.push({
        name: 'tone-transform',
        params: { id: messageStore.currentDraft.id }
      })
    } else {
      throw new Error(messageStore.error || '下書きの作成に失敗しました')
    }
  } catch (error) {
    console.error('トーン変換エラー:', error)
    alert(`トーン変換の開始に失敗しました: ${error.message || error}`)
  } finally {
    isLoading.value = false
    currentAction.value = ''
  }
}
</script>

<style scoped>
.message-compose-view {
  padding: var(--spacing-2xl) var(--spacing-3xl);
  max-width: 1200px;
  margin: 0 auto;
  background: var(--background-primary);
  font-family: var(--font-family-main);
}

.page-title {
  font-size: var(--font-size-base);
  color: var(--text-primary);
  font-family: var(--font-family-main);
  font-weight: var(--font-weight-regular);
  margin: 0 0 var(--spacing-lg) 0;
}

/* 受信者情報表示 */
.recipient-info {
  background: var(--background-primary);
  border: 2px solid var(--primary-color);
  border-radius: 12px;
  padding: 20px;
  margin-bottom: 32px;
}

.recipient-label {
  font-size: 16px;
  font-weight: 600;
  color: var(--text-secondary);
  margin: 0 0 12px 0;
}

.recipient-display {
  display: flex;
  align-items: center;
  gap: 16px;
}

.recipient-avatar {
  width: 48px;
  height: 48px;
  border-radius: 50%;
  background: var(--primary-color);
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: 600;
  font-size: 18px;
  color: var(--text-primary);
  flex-shrink: 0;
}

.recipient-details {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.recipient-name {
  font-size: 16px;
  font-weight: 500;
  color: var(--text-primary);
}

.recipient-email {
  font-size: 14px;
  color: var(--text-secondary);
}

.change-recipient-btn {
  padding: 8px 16px;
  background: var(--primary-color-light);
  border: 1px solid var(--primary-color);
  border-radius: 6px;
  font-size: 14px;
  color: var(--text-primary);
  cursor: pointer;
  font-weight: 500;
  transition: all 0.2s ease;
}

.change-recipient-btn:hover {
  background: var(--primary-color);
  border-color: var(--primary-color-dark);
}

/* 新規作成セクション */
.compose-section {
  margin-bottom: var(--spacing-3xl);
}

.section-title {
  font-size: var(--font-size-base);
  color: var(--text-primary);
  font-family: var(--font-family-main);
  font-weight: var(--font-weight-regular);
  margin: 0 0 var(--spacing-lg) 0;
}

/* メッセージ入力エリア */
.message-input-container {
  width: 700px;
  height: 299px;
  margin-bottom: var(--spacing-2xl);
}

.message-textarea {
  width: 100%;
  height: 100%;
  padding: var(--spacing-xl);
  border: 3px solid var(--border-color);
  border-radius: 10px;
  background: var(--neutral-color);
  color: var(--text-primary);
  font-size: var(--font-size-base);
  font-family: var(--font-family-main);
  font-weight: var(--font-weight-regular);
  line-height: var(--line-height-normal);
  resize: none;
  outline: none;
  box-sizing: border-box;
}

.message-textarea::placeholder {
  color: var(--text-primary);
  font-size: var(--font-size-base);
  font-family: var(--font-family-main);
  line-height: var(--line-height-normal);
}

.message-textarea:focus {
  border-color: var(--border-color-focus);
}

/* アクションボタン */
.action-buttons {
  display: flex;
  gap: var(--spacing-lg);
  margin-bottom: var(--spacing-2xl);
}

.action-btn {
  width: 200px;
  height: 60px;
  border-radius: 30px;
  border: none;
  font-size: var(--font-size-base);
  font-family: var(--font-family-main);
  font-weight: var(--font-weight-regular);
  color: var(--text-primary);
  cursor: pointer;
  transition: all 0.3s ease;
  display: flex;
  align-items: center;
  justify-content: center;
}

.draft-btn,
.transform-btn {
  background: var(--primary-color);
}

.draft-btn:hover,
.transform-btn:hover {
  background: var(--primary-color-dark);
}

.action-btn:disabled {
  background: var(--gray-color-light);
  color: var(--text-muted);
  cursor: not-allowed;
}

/* 下書きセクション */
.drafts-section {
  margin-bottom: var(--spacing-3xl);
}

.drafts-container {
  width: 700px;
  min-height: 227px;
  border: 3px solid var(--border-color);
  border-radius: 10px;
  background: var(--neutral-color);
  padding: var(--spacing-xl);
}

.drafts-list {
  display: flex;
  flex-direction: column;
  gap: var(--spacing-md);
}

.draft-item {
  display: flex;
  align-items: center;
  padding: var(--spacing-lg);
  background: var(--background-primary);
  border: 2px solid var(--border-color);
  border-radius: 8px;
  cursor: pointer;
  transition: all 0.2s ease;
}

.draft-item:hover {
  border-color: var(--primary-color);
  background: var(--primary-color-light);
}

.draft-content {
  flex: 1;
  margin-right: var(--spacing-lg);
}

.draft-text {
  font-size: var(--font-size-base);
  color: var(--text-primary);
  margin-bottom: var(--spacing-sm);
  line-height: 1.4;
}

.draft-meta {
  display: flex;
  gap: var(--spacing-md);
  font-size: var(--font-size-sm);
  color: var(--text-secondary);
}

.draft-recipient {
  font-weight: 500;
}

.draft-date {
  color: var(--text-muted);
}

.draft-actions {
  display: flex;
  gap: var(--spacing-sm);
}

.draft-action-btn {
  width: 36px;
  height: 36px;
  border: none;
  border-radius: 50%;
  background: var(--neutral-color);
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 16px;
  transition: all 0.2s ease;
}

.draft-action-btn:hover {
  transform: scale(1.1);
}

.edit-btn:hover {
  background: var(--primary-color-light);
}

.delete-btn:hover {
  background: #ffebee;
}

.loading-state,
.empty-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: var(--spacing-3xl);
  text-align: center;
  color: var(--text-secondary);
}

.loading-spinner {
  width: 32px;
  height: 32px;
  border: 3px solid var(--border-color);
  border-top: 3px solid var(--primary-color);
  border-radius: 50%;
  animation: spin 1s linear infinite;
  margin-bottom: var(--spacing-md);
}

@keyframes spin {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}

.empty-icon {
  font-size: 48px;
  margin-bottom: var(--spacing-lg);
}

.empty-state p {
  font-size: var(--font-size-lg);
  margin-bottom: var(--spacing-sm);
}

.empty-state small {
  font-size: var(--font-size-sm);
  color: var(--text-muted);
  line-height: 1.4;
}

/* レスポンシブ対応 */
@media (max-width: 768px) {
  .message-compose-view {
    padding: var(--spacing-lg);
  }
  
  .message-input-container,
  .drafts-container {
    width: 100%;
    max-width: 700px;
  }
  
  .action-buttons {
    flex-direction: column;
    gap: var(--spacing-md);
  }
  
  .action-btn {
    width: 100%;
  }
  
  .draft-item {
    flex-direction: column;
    align-items: stretch;
    gap: var(--spacing-md);
  }
  
  .draft-content {
    margin-right: 0;
  }
  
  .draft-actions {
    align-self: flex-end;
  }
  
  .draft-meta {
    flex-direction: column;
    gap: var(--spacing-xs);
  }
}
</style>