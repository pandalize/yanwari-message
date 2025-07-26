<template>
  <div class="message-compose-view">
    <!-- ページタイトル -->
    <h1 class="page-title">送信</h1>

    <!-- 新規作成セクション -->
    <section class="compose-section">
      <h2 class="section-title">新規作成</h2>
      
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
      <div class="drafts-container">
        <div class="drafts-list">
          <!-- 下書き一覧がここに表示される -->
        </div>
      </div>
    </section>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { useMessageStore } from '@/stores/messages'

const router = useRouter()
const messageStore = useMessageStore()
const messageText = ref('')
const isLoading = ref(false)
const currentAction = ref('')

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
      recipientEmail: '' // 後で受信者選択機能で設定
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

  isLoading.value = true
  currentAction.value = 'transform'

  try {
    // まず下書きを作成
    const success = await messageStore.createDraft({
      originalText: messageText.value,
      recipientEmail: ''
    })

    if (success && messageStore.currentDraft) {
      // トーン変換ページに遷移（下書きIDを渡す）
      await router.push({
        name: 'tone-transform',
        params: { id: messageStore.currentDraft.id }
      })
    } else {
      throw new Error('下書きの作成に失敗しました')
    }
  } catch (error) {
    console.error('トーン変換エラー:', error)
    alert('トーン変換の開始に失敗しました')
  } finally {
    isLoading.value = false
    currentAction.value = ''
  }
}
</script>

<style scoped>
.message-compose-view {
  padding: var(--spacing-2xl) 5%;
  background: var(--background-primary);
  font-family: var(--font-family-main);
  min-height: 100vh;
}

@media (min-width: 768px) {
  .message-compose-view {
    padding: var(--spacing-2xl) 10%;
  }
}

@media (min-width: 1200px) {
  .message-compose-view {
    padding: var(--spacing-2xl) 15%;
  }
}

@media (min-width: 1600px) {
  .message-compose-view {
    padding: var(--spacing-2xl) 20%;
  }
}

.page-title {
  font-size: var(--font-size-base);
  color: var(--text-primary);
  font-family: var(--font-family-main);
  font-weight: var(--font-weight-regular);
  margin: 0 0 var(--spacing-lg) 0;
}

/* 新規作成セクション */
.compose-section {
  margin-bottom: var(--spacing-2xl);
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
  width: 100%;
  height: 200px;
  margin-bottom: var(--spacing-xl);
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
  margin-bottom: var(--spacing-xl);
}

.action-btn {
  width: 200px;
  height: 50px;
  border-radius: 25px;
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
  margin-bottom: var(--spacing-2xl);
}

.drafts-container {
  width: 100%;
  min-height: 150px;
  max-height: 250px;
  overflow-y: auto;
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
  .action-buttons {
    flex-direction: column;
    gap: var(--spacing-md);
  }
  
  .action-btn {
    width: 100%;
  }
}
</style>