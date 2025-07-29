<template>
  <div class="recipient-select-view">
    <!-- ページタイトル -->
    <h1 class="page-title">送信先を選択</h1>

    <!-- 友達リスト -->
    <section class="friends-section">
      <h2 class="section-title">友達から選択</h2>
      
      <div v-if="isLoadingFriends" class="loading-state">
        <div class="spinner"></div>
        <p>友達一覧を読み込み中...</p>
      </div>
      
      <div v-else-if="friends.length === 0" class="empty-state">
        <div class="empty-icon">👥</div>
        <h3>友達がいません</h3>
        <p>友達を追加してメッセージを送信しましょう。</p>
        <router-link to="/friends" class="add-friends-btn">友達を追加</router-link>
      </div>
      
      <div v-else class="friends-grid">
        <div 
          v-for="friend in friends" 
          :key="friend.id" 
          class="friend-card"
          @click="selectRecipient(friend)"
          :class="{ selected: selectedRecipient?.id === friend.id }"
        >
          <div class="friend-avatar">
            {{ friend.name.charAt(0).toUpperCase() }}
          </div>
          <div class="friend-info">
            <h3 class="friend-name">{{ friend.name }}</h3>
            <p class="friend-email">{{ friend.email }}</p>
          </div>
          <div class="select-indicator" v-if="selectedRecipient?.id === friend.id">
            ✓
          </div>
        </div>
      </div>
    </section>

    <!-- 手動入力セクション -->
    <section class="manual-input-section">
      <h2 class="section-title">メールアドレスで指定</h2>
      
      <div class="email-input-container">
        <input
          v-model="manualEmail"
          type="email"
          placeholder="example@email.com"
          class="email-input"
          @input="onManualEmailInput"
        />
        <button 
          @click="selectManualRecipient"
          :disabled="!isValidEmail(manualEmail)"
          class="select-email-btn"
        >
          選択
        </button>
      </div>
      
      <div v-if="manualEmailSelected" class="selected-manual">
        <div class="manual-card selected">
          <div class="friend-avatar manual">
            @
          </div>
          <div class="friend-info">
            <h3 class="friend-name">{{ manualEmailSelected.name }}</h3>
            <p class="friend-email">{{ manualEmailSelected.email }}</p>
          </div>
          <div class="select-indicator">✓</div>
        </div>
      </div>
    </section>

    <!-- アクションボタン -->
    <div class="action-buttons">
      <button class="btn btn-secondary" @click="goBack">
        戻る
      </button>
      <button 
        class="btn btn-primary" 
        @click="proceedToCompose"
        :disabled="!hasSelectedRecipient"
      >
        メッセージ作成へ
      </button>
    </div>

    <!-- エラー表示 -->
    <div v-if="error" class="error-message">
      {{ error }}
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useFriendsStore } from '@/stores/friends'

const router = useRouter()
const friendsStore = useFriendsStore()

// 状態管理
const friends = ref<any[]>([])
const selectedRecipient = ref<any>(null)
const manualEmail = ref('')
const manualEmailSelected = ref<any>(null)
const isLoadingFriends = ref(false)
const error = ref('')

// 計算プロパティ
const hasSelectedRecipient = computed(() => {
  return selectedRecipient.value || manualEmailSelected.value
})

// メソッド
const isValidEmail = (email: string): boolean => {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
  return emailRegex.test(email)
}

const selectRecipient = (friend: any) => {
  selectedRecipient.value = friend
  manualEmailSelected.value = null
  manualEmail.value = ''
  error.value = ''
}

const onManualEmailInput = () => {
  if (manualEmailSelected.value) {
    manualEmailSelected.value = null
  }
  selectedRecipient.value = null
}

const selectManualRecipient = () => {
  if (!isValidEmail(manualEmail.value)) {
    error.value = '有効なメールアドレスを入力してください'
    return
  }
  
  manualEmailSelected.value = {
    id: `manual-${Date.now()}`,
    name: manualEmail.value.split('@')[0],
    email: manualEmail.value
  }
  selectedRecipient.value = null
  error.value = ''
}

const loadFriends = async () => {
  isLoadingFriends.value = true
  try {
    await friendsStore.loadFriends()
    friends.value = friendsStore.friends
  } catch (err) {
    console.error('友達一覧の取得に失敗:', err)
    error.value = '友達一覧の取得に失敗しました'
  } finally {
    isLoadingFriends.value = false
  }
}

const goBack = () => {
  router.go(-1)
}

const proceedToCompose = () => {
  const recipient = selectedRecipient.value || manualEmailSelected.value
  if (!recipient) {
    error.value = '送信先を選択してください'
    return
  }
  
  // メッセージ作成画面に遷移し、受信者情報を渡す
  router.push({
    name: 'message-compose',
    query: {
      recipientEmail: recipient.email,
      recipientName: recipient.name
    }
  })
}

// 初期化
onMounted(async () => {
  await loadFriends()
})
</script>

<style scoped>
.recipient-select-view {
  background: var(--background-primary);
  font-family: var(--font-family-main);
  min-height: 100vh;
  padding: 32px 80px;
  max-width: 1200px;
  margin: 0 auto;
}

.page-title {
  color: var(--text-primary);
  font-size: 24px;
  font-weight: 600;
  font-family: var(--font-family-main);
  line-height: var(--line-height-base);
  margin: 0 0 32px 0;
}

.section-title {
  font-size: var(--font-size-lg);
  font-weight: 600;
  color: var(--text-primary);
  margin: 0 0 16px 0;
  font-family: var(--font-family-main);
}

.friends-section, .manual-input-section {
  margin-bottom: 40px;
}

/* ローディング・空状態 */
.loading-state, .empty-state {
  text-align: center;
  padding: 40px 20px;
  color: var(--text-secondary);
}

.spinner {
  width: 32px;
  height: 32px;
  border: 3px solid var(--border-color);
  border-top: 3px solid var(--primary-color);
  border-radius: 50%;
  animation: spin 1s linear infinite;
  margin: 0 auto 16px;
}

@keyframes spin {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}

.empty-icon {
  font-size: 48px;
  margin-bottom: 16px;
}

.add-friends-btn {
  display: inline-block;
  padding: 12px 24px;
  background: var(--primary-color);
  color: var(--text-primary);
  text-decoration: none;
  border-radius: 8px;
  font-weight: 500;
  margin-top: 16px;
  transition: all 0.2s ease;
}

.add-friends-btn:hover {
  background: var(--primary-color-dark);
}

/* 友達グリッド */
.friends-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
  gap: 16px;
  margin-bottom: 24px;
}

.friend-card, .manual-card {
  display: flex;
  align-items: center;
  padding: 16px;
  background: var(--background-primary);
  border: 2px solid var(--border-color);
  border-radius: 12px;
  cursor: pointer;
  transition: all 0.2s ease;
  position: relative;
}

.friend-card:hover {
  border-color: var(--primary-color);
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
}

.friend-card.selected, .manual-card.selected {
  border-color: var(--primary-color);
  background: var(--primary-color-light);
}

.friend-avatar {
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
  margin-right: 16px;
  flex-shrink: 0;
}

.friend-avatar.manual {
  background: var(--secondary-color);
}

.friend-info {
  flex: 1;
}

.friend-name {
  font-size: var(--font-size-md);
  font-weight: 500;
  color: var(--text-primary);
  margin: 0 0 4px 0;
}

.friend-email {
  font-size: var(--font-size-sm);
  color: var(--text-secondary);
  margin: 0;
}

.select-indicator {
  position: absolute;
  top: 8px;
  right: 8px;
  width: 24px;
  height: 24px;
  background: var(--success-color);
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: 600;
  color: var(--text-primary);
  font-size: 14px;
}

/* 手動入力 */
.email-input-container {
  display: flex;
  gap: 12px;
  align-items: center;
  margin-bottom: 16px;
}

.email-input {
  flex: 1;
  max-width: 400px;
  height: 48px;
  padding: 0 16px;
  border: 2px solid var(--border-color);
  border-radius: 8px;
  font-size: var(--font-size-md);
  font-family: var(--font-family-main);
  outline: none;
  transition: border-color 0.2s ease;
}

.email-input:focus {
  border-color: var(--primary-color);
}

.select-email-btn {
  height: 48px;
  padding: 0 24px;
  background: var(--primary-color);
  color: var(--text-primary);
  border: none;
  border-radius: 8px;
  font-size: var(--font-size-md);
  font-weight: 500;
  cursor: pointer;
  transition: all 0.2s ease;
}

.select-email-btn:disabled {
  background: var(--border-color);
  cursor: not-allowed;
}

.select-email-btn:not(:disabled):hover {
  background: var(--primary-color-dark);
}

.selected-manual {
  margin-top: 16px;
}

/* アクションボタン */
.action-buttons {
  display: flex;
  gap: 16px;
  justify-content: center;
  margin-top: 40px;
}

.btn {
  height: 48px;
  padding: 0 32px;
  border: none;
  border-radius: 8px;
  font-size: var(--font-size-md);
  font-weight: 500;
  font-family: var(--font-family-main);
  cursor: pointer;
  transition: all 0.2s ease;
}

.btn-secondary {
  background: var(--border-color);
  color: var(--text-primary);
}

.btn-secondary:hover {
  background: var(--gray-color-dark);
}

.btn-primary {
  background: var(--primary-color);
  color: var(--text-primary);
}

.btn-primary:disabled {
  background: var(--border-color);
  cursor: not-allowed;
}

.btn-primary:not(:disabled):hover {
  background: var(--primary-color-dark);
}

/* エラーメッセージ */
.error-message {
  background: var(--error-color);
  color: var(--text-primary);
  padding: 12px 16px;
  border-radius: 8px;
  margin-top: 16px;
  text-align: center;
  font-size: var(--font-size-sm);
}

/* レスポンシブ */
@media (max-width: 768px) {
  .recipient-select-view {
    padding: 20px;
  }
  
  .friends-grid {
    grid-template-columns: 1fr;
  }
  
  .email-input-container {
    flex-direction: column;
    align-items: stretch;
  }
  
  .action-buttons {
    flex-direction: column;
  }
}
</style>