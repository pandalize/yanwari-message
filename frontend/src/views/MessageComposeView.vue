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
        <div class="drafts-list">
          <!-- 下書き一覧がここに表示される -->
        </div>
      </div>
    </section>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { useMessageStore } from '@/stores/messages'

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

// クエリパラメータから編集対象のメッセージと受信者情報を読み込み
onMounted(() => {
  const { originalText, recipientEmail, recipientName, editScheduleId } = route.query
  
  console.log('MessageCompose mounted with query:', { originalText, recipientEmail, recipientName, editScheduleId })
  
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
    routeQuery: route.query
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
    await messageStore.createDraft({
      originalText: messageText.value,
      recipientEmail: recipientInfo.value?.email || ''
    })
    
    alert('下書きを保存しました')
    messageText.value = '' // 入力欄をクリア
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
  /* 下書き一覧のスタイル */
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
}
</style>