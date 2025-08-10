<template>
  <PageContainer>
    <div class="message-compose-view">
      <!-- ページタイトル -->
      <PageTitle>送信</PageTitle>

    <!-- 受信者情報表示 -->
    <MessageContainer 
      v-if="recipientInfo" 
      width="700px" 
      min-height="auto" 
      padding="20px"
      margin-bottom="32px"
      class="recipient-info"
    >
      <h3 class="recipient-label">送信先:</h3>
      <div class="recipient-display">
        <div class="recipient-avatar">
          {{ recipientInfo.name.charAt(0).toUpperCase() }}
        </div>
        <div class="recipient-details">
          <span class="recipient-name">{{ recipientInfo.name }}</span>
          <span class="recipient-email">{{ recipientInfo.email }}</span>
        </div>
        <SmallButton @click="changeRecipient" text="変更" title="送信先を変更" />
      </div>
    </MessageContainer>

    <!-- 新規作成セクション -->
    <section class="compose-section">
      <h2 class="section-title">メッセージ作成</h2>
      
      <!-- メッセージ入力エリア -->
      <div class="input-sections">
        <!-- メッセージ内容 -->
        <div class="input-section">
          <h3 class="input-label">メッセージ内容</h3>
          <MessageContainer 
            width="700px" 
            height="200px"
            margin-bottom="var(--spacing-lg)"
            class="message-input-container"
          >
            <textarea
              v-model="messageText"
              placeholder="送りたいメッセージを入力してください"
              class="message-textarea"
              maxlength="500"
            ></textarea>
          </MessageContainer>
        </div>

        <!-- 送信理由 -->
        <div class="input-section">
          <h3 class="input-label">送信理由・背景</h3>
          <MessageContainer 
            width="700px" 
            height="150px"
            margin-bottom="var(--spacing-2xl)"
            class="reason-input-container"
          >
            <textarea
              v-model="reasonText"
              placeholder="このメッセージを送る理由や背景を教えてください（任意）"
              class="reason-textarea"
              maxlength="500"
            ></textarea>
          </MessageContainer>
        </div>
      </div>

      <!-- アクションボタン -->
      <div class="action-buttons">
        <button 
          class="action-btn draft-btn" 
          @click="saveDraft"
          :disabled="isLoading || !messageText.trim()"
        >
          <span v-if="isLoading && currentAction === 'draft'">保存中...</span>
          <span v-else-if="messageStore.currentDraft?.id">下書きを更新</span>
          <span v-else>下書きに追加</span>
        </button>
        <button 
          class="action-btn transform-btn" 
          @click="transformTone"
          :disabled="isLoading || !messageText.trim()"
        >
          <span v-if="isLoading && currentAction === 'transform'">処理中...</span>
          <span v-else>トーン変換を行う</span>
        </button>
      </div>
    </section>

    <!-- 下書きセクション -->
    <section class="drafts-section">
      <h2 class="section-title">下書き</h2>
      <MessageContainer 
        width="700px" 
        min-height="100px"
        class="drafts-container"
      >
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
          <MessageListItem 
            v-for="draft in messageStore.drafts" 
            :key="draft.id"
            :clickable="true"
            height="100px"
            padding="var(--spacing-xl)"
            @click="loadDraft(draft)"
          >
            <template #content>
              <div class="draft-text">
                {{ draft.originalText.length > 100 ? draft.originalText.substring(0, 100) + '...' : draft.originalText }}
              </div>
              <div class="draft-meta">
                <span class="draft-date">
                  {{ formatDate(draft.updatedAt || draft.createdAt || '') }}
                </span>
              </div>
            </template>
            <template #actions>
              <button 
                @click.stop="deleteDraftConfirm(draft)"
                class="delete-button"
                title="削除"
              >
                削除
              </button>
            </template>
          </MessageListItem>
        </div>
      </MessageContainer>
    </section>
    </div>
  </PageContainer>
</template>

<script setup lang="ts">
import { ref, onMounted, onActivated } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { useMessageStore } from '@/stores/messages'
import type { MessageDraft } from '@/services/messageService'
import PageContainer from '@/components/layout/PageContainer.vue'
import PageTitle from '@/components/layout/PageTitle.vue'
import SmallButton from '@/components/common/SmallButton.vue'
import MessageContainer from '@/components/common/MessageContainer.vue'
import MessageListItem from '@/components/common/MessageListItem.vue'

const router = useRouter()
const route = useRoute()
const messageStore = useMessageStore()
const messageText = ref('')
const reasonText = ref('')
const isLoading = ref(false)
const currentAction = ref('')
const recipientInfo = ref<any>(null)

// 受信者を変更
const changeRecipient = () => {
  router.push('/recipient-select')
}

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
  // 組み合わせられたテキストを分離
  const text = draft.originalText
  const reasonSeparator = '\n\n【送信理由・背景】\n'
  
  if (text.includes(reasonSeparator)) {
    const parts = text.split(reasonSeparator)
    messageText.value = parts[0]
    reasonText.value = parts[1] || ''
  } else {
    // 古い形式の下書きの場合は全てメッセージテキストに入れる
    messageText.value = text
    reasonText.value = ''
  }
  
  // 受信者情報を復元
  if (draft.recipientEmail) {
    recipientInfo.value = {
      email: draft.recipientEmail,
      name: draft.recipientEmail.split('@')[0] // デフォルト名
    }
    console.log('下書きから受信者情報を復元:', recipientInfo.value)
  }
  
  // 現在の下書きとして設定
  messageStore.setCurrentDraft(draft)
  
  // 画面を一番上にスクロール
  window.scrollTo({
    top: 0,
    behavior: 'smooth'
  })
}


// 下書き削除の確認
const deleteDraftConfirm = (draft: MessageDraft) => {
  console.log('削除ボタンがクリックされました:', draft)
  console.log('draft.id:', draft.id)
  console.log('draft.originalText:', draft.originalText.substring(0, 30))
  
  if (!draft.id) {
    console.error('draft.idが存在しません！')
    alert('削除対象のIDが見つかりません')
    return
  }
  
  if (confirm(`「${draft.originalText.substring(0, 50)}...」を削除しますか？`)) {
    console.log('削除が確認されました、deleteDraftを実行します')
    deleteDraft(draft)
  } else {
    console.log('削除がキャンセルされました')
  }
}

// 下書きを削除
const deleteDraft = async (draft: MessageDraft) => {
  console.log('deleteDraft関数が呼ばれました:', draft.id)
  
  try {
    console.log('messageStore.deleteDraftを実行中...')
    const success = await messageStore.deleteDraft(draft.id!)
    console.log('messageStore.deleteDraft実行結果:', success)
    
    if (success) {
      // 削除した下書きが現在編集中の場合、テキストエリアをクリア
      if (messageStore.currentDraft?.id === draft.id) {
        messageText.value = ''
        reasonText.value = ''
        recipientInfo.value = null
        // currentDraftをクリアして新規作成状態に戻す
        messageStore.clearCurrentDraft()
        
        console.log('削除した下書きが現在編集中だったため、編集状態をリセットしました')
      }
      
      // 下書きが全て削除された場合の処理
      if (messageStore.drafts.length === 0) {
        console.log('全ての下書きが削除されました')
      }
      
      console.log('下書き削除完了:', draft.id)
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
    // 確実に日付順でソートする
    messageStore.sortDraftsByDate()
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

// 画面がアクティブになった時（他の画面から戻ってきた時）に下書きをリロード
onActivated(async () => {
  console.log('MessageCompose activated - reloading drafts')
  try {
    await messageStore.loadDrafts()
    // 確実に日付順でソートする
    messageStore.sortDraftsByDate()
    console.log('下書き再読み込み完了:', messageStore.drafts.length, '件')
  } catch (error) {
    console.error('下書き再読み込みに失敗:', error)
  }
})

const saveDraft = async () => {
  if (!messageText.value.trim()) {
    alert('メッセージ内容を入力してください')
    return
  }

  isLoading.value = true
  currentAction.value = 'draft'

  try {
    let success = false
    
    // 既存の下書きがある場合は更新、ない場合は新規作成
    if (messageStore.currentDraft?.id) {
      // 既存の下書きを更新
      console.log('既存の下書きを更新:', messageStore.currentDraft.id)
      const combinedText = reasonText.value.trim() 
        ? `${messageText.value}\n\n【送信理由・背景】\n${reasonText.value}`
        : messageText.value
      success = await messageStore.updateDraft(messageStore.currentDraft.id, {
        originalText: combinedText
      })
      
      if (success) {
        alert('下書きを更新しました')
      }
    } else {
      // 新しい下書きを作成
      console.log('新しい下書きを作成')
      const combinedText = reasonText.value.trim() 
        ? `${messageText.value}\n\n【送信理由・背景】\n${reasonText.value}`
        : messageText.value
      success = await messageStore.createDraft({
        originalText: combinedText
      })
      
      if (success) {
        alert('下書きを保存しました')
      }
    }
    
    if (success) {
      messageText.value = '' // 入力欄をクリア
      reasonText.value = '' // 理由欄もクリア
      // currentDraftをクリアして新規作成状態に戻す
      messageStore.clearCurrentDraft()
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
    alert('メッセージ内容を入力してください')
    return
  }

  if (!recipientInfo.value?.email) {
    // 受信者情報がない場合は受信者選択画面に移動
    if (confirm('送信先が選択されていません。受信者選択画面に移動しますか？')) {
      // 現在の内容を一時保存してから受信者選択画面に移動
      const combinedText = reasonText.value.trim() 
        ? `${messageText.value}\n\n【送信理由・背景】\n${reasonText.value}`
        : messageText.value
      
      // クエリパラメータで現在の内容を渡す
      router.push({
        path: '/recipient-select',
        query: {
          returnText: combinedText,
          currentDraftId: messageStore.currentDraft?.id || ''
        }
      })
    }
    return
  }

  if (!recipientInfo.value?.name) {
    recipientInfo.value.name = recipientInfo.value.email.split('@')[0]
  }

  isLoading.value = true
  currentAction.value = 'transform'

  try {
    const combinedText = reasonText.value.trim() 
      ? `${messageText.value}\n\n【送信理由・背景】\n${reasonText.value}`
      : messageText.value
    
    console.log('トーン変換開始:', {
      messageText: messageText.value,
      reasonText: reasonText.value,
      combinedText: combinedText,
      recipientEmail: recipientInfo.value.email,
      recipientName: recipientInfo.value.name
    })

    let success = false
    let targetDraftId = ''

    // 既存の下書きがあるかチェック
    if (messageStore.currentDraft?.id) {
      // 既存の下書きを更新（recipientEmailは更新しない）
      console.log('既存の下書きを更新:', messageStore.currentDraft.id)
      success = await messageStore.updateDraft(messageStore.currentDraft.id, {
        originalText: combinedText
      })
      targetDraftId = messageStore.currentDraft.id
    } else {
      // 新しい下書きを作成
      console.log('新しい下書きを作成')
      success = await messageStore.createDraft({
        originalText: combinedText,
        recipientEmail: recipientInfo.value.email
      })
      targetDraftId = messageStore.currentDraft?.id || ''
    }

    console.log('下書き処理結果:', {
      success,
      targetDraftId,
      currentDraft: messageStore.currentDraft,
      error: messageStore.error
    })

    if (success && targetDraftId) {
      console.log('トーン変換ページに遷移中:', targetDraftId)
      // トーン変換ページに遷移（下書きIDと受信者情報を渡す）
      await router.push({
        name: 'tone-transform',
        params: { id: targetDraftId },
        query: {
          recipientEmail: recipientInfo.value.email,
          recipientName: recipientInfo.value.name
        }
      })
    } else {
      throw new Error(messageStore.error || '下書きの処理に失敗しました')
    }
  } catch (error) {
    console.error('トーン変換エラー詳細:', {
      error,
      errorMessage: (error as any)?.message,
      errorResponse: (error as any)?.response,
      currentDraft: messageStore.currentDraft,
      messageText: messageText.value,
      recipientInfo: recipientInfo.value
    })
    alert(`トーン変換の開始に失敗しました: ${(error as any)?.message || String(error)}`)
  } finally {
    isLoading.value = false
    currentAction.value = ''
  }
}
</script>

<style scoped>
.message-compose-view {
  display: flex;
  flex-direction: column;
  align-items: center;
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


/* 入力セクション */
.input-sections {
  display: flex;
  flex-direction: column;
  gap: var(--spacing-lg);
}

.input-section {
  display: flex;
  flex-direction: column;
}

.input-label {
  font-size: var(--font-size-md);
  color: var(--text-primary);
  font-family: var(--font-family-main);
  font-weight: 600;
  margin: 0 0 var(--spacing-sm) 0;
}

.message-textarea,
.reason-textarea {
  width: 100%;
  height: 100%;
  padding: var(--spacing-xl);
  border: none;
  border-radius: 0;
  background: transparent;
  color: var(--text-primary);
  font-size: var(--font-size-base);
  font-family: var(--font-family-main);
  font-weight: var(--font-weight-regular);
  line-height: var(--line-height-normal);
  resize: none;
  outline: none;
  box-sizing: border-box;
}

.message-textarea::placeholder,
.reason-textarea::placeholder {
  color: var(--text-primary);
  font-size: var(--font-size-base);
  font-family: var(--font-family-main);
  line-height: var(--line-height-normal);
}

.message-textarea:focus,
.reason-textarea:focus {
  border-color: var(--border-color-focus);
}

/* アクションボタン */
.action-buttons {
  display: flex;
  gap: var(--spacing-lg);
  margin-bottom: var(--spacing-2xl);
  justify-content: center;
  width: 700px;
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


.drafts-list {
  display: flex;
  flex-direction: column;
}


.draft-text {
  font-size: var(--font-size-base);
  color: var(--text-primary);
  margin-bottom: var(--spacing-sm);
  line-height: 1.4;
  overflow: hidden;
  text-overflow: ellipsis;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  line-clamp: 2;
  -webkit-box-orient: vertical;
}

.draft-meta {
  font-size: var(--font-size-sm);
  color: var(--text-secondary);
}

.draft-date {
  color: var(--text-muted);
}



.loading-state,
.empty-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: var(--spacing-3xl) var(--spacing-xl);
  text-align: center;
  color: var(--text-secondary);
  margin: var(--spacing-lg) 0;
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
    align-items: flex-start;
    gap: var(--spacing-sm);
    padding: var(--spacing-md);
  }
  
  .draft-content,
  .draft-actions {
    flex: none;
    width: 100%;
  }
  
  .draft-actions {
    justify-content: flex-end;
  }
}

.delete-button {
  padding: var(--spacing-sm) var(--spacing-md);
  border: none;
  border-radius: var(--radius-sm);
  background: var(--primary-color);
  color: var(--text-primary);
  cursor: pointer;
  font-size: var(--font-size-sm);
  font-family: var(--font-family-main);
  font-weight: var(--font-weight-regular);
}
</style>