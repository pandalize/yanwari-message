<template>
  <PageContainer>
    <div class="recipient-select-view">
      <!-- ページタイトル -->
      <PageTitle>送信先を選択</PageTitle>

    <!-- 友達リスト -->
    <section class="friends-section">
      <h2 class="section-title">友達から選択</h2>
      
      <!-- 友達検索 -->
      <div class="search-section" v-if="friends.length > 0">
        <div class="search-input-container">
          <input
            v-model="searchQuery"
            type="text"
            placeholder="友達の名前、メールアドレスで検索..."
            class="search-input"
            @input="handleSearchInput"
          />
          <button 
            v-if="searchQuery"
            @click="clearSearch"
            class="clear-search-btn"
            title="検索をクリア"
          >
            ✕
          </button>
        </div>
        <div v-if="searchQuery && filteredFriends.length === 0" class="no-results">
          検索結果が見つかりません
        </div>
      </div>
      
      <div v-if="friendsStore.loading" class="loading-state">
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
          v-for="friendship in filteredFriends" 
          :key="friendship.friend.id" 
          class="friend-card"
          @click="selectRecipient(friendship.friend)"
          :class="{ selected: selectedRecipient?.id === friendship.friend.id }"
        >
          <div class="friend-avatar">
            {{ getFriendDisplayName(friendship.friend).charAt(0).toUpperCase() }}
          </div>
          <div class="friend-info">
            <h3 class="friend-name" v-html="highlightMatch(getFriendDisplayName(friendship.friend))"></h3>
            <p class="friend-email" v-html="highlightMatch(friendship.friend.email)"></p>
          </div>
          <div class="select-indicator" v-if="selectedRecipient?.id === friendship.friend.id">
            ✓
          </div>
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
  </PageContainer>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { useRouter } from 'vue-router'
import { useFriendsStore } from '@/stores/friends'
import PageContainer from '@/components/layout/PageContainer.vue'
import PageTitle from '@/components/layout/PageTitle.vue'

const router = useRouter()
const friendsStore = useFriendsStore()

// 状態管理
const friends = ref<any[]>([])
const selectedRecipient = ref<any>(null)
const error = ref('')
const searchQuery = ref('')

// 計算プロパティ
const hasSelectedRecipient = computed(() => {
  return selectedRecipient.value !== null
})

// 検索でフィルタリングされた友達リスト
const filteredFriends = computed(() => {
  if (!searchQuery.value.trim()) {
    return friends.value
  }
  
  const query = searchQuery.value.toLowerCase().trim()
  return friends.value.filter(friendship => {
    const friend = friendship.friend
    const displayName = getFriendDisplayName(friend).toLowerCase()
    const email = (friend.email || '').toLowerCase()
    
    return displayName.includes(query) || 
           email.includes(query)
  })
})

// メソッド
const selectRecipient = (friend: any) => {
  selectedRecipient.value = friend
  error.value = ''
}

// 検索入力時の処理
const handleSearchInput = () => {
  // デバウンス処理は不要（ローカル検索のため）
}

// 検索をクリア
const clearSearch = () => {
  searchQuery.value = ''
}

// 友達の表示名を取得（displayNameがない場合はメールアドレスから名前部分を抽出）
const getFriendDisplayName = (friend: any): string => {
  if (friend.displayName) {
    return friend.displayName
  }
  // メールアドレスから@より前の部分を名前として使用
  const emailName = friend.email.split('@')[0]
  return emailName
}

// 検索キーワードをハイライト
const highlightMatch = (text: string): string => {
  if (!searchQuery.value.trim() || !text) {
    return text
  }
  
  const query = searchQuery.value.trim()
  const regex = new RegExp(`(${query})`, 'gi')
  return text.replace(regex, '<mark>$1</mark>')
}

const loadFriends = async () => {
  try {
    await friendsStore.fetchFriends()
    friends.value = friendsStore.friends
  } catch (err) {
    console.error('友達一覧の取得に失敗:', err)
    error.value = '友達一覧の取得に失敗しました'
  }
}

const goBack = () => {
  router.go(-1)
}

const proceedToCompose = () => {
  const recipient = selectedRecipient.value
  if (!recipient) {
    error.value = '友達を選択してください'
    return
  }
  
  // メッセージ作成画面に遷移し、受信者情報を渡す
  router.push({
    name: 'message-compose',
    query: {
      recipientEmail: recipient.email,
      recipientName: getFriendDisplayName(recipient)
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
  /* page-containerで統一されたスタイルを使用 */
}

.friends-section {
  margin-bottom: 40px;
}

/* 検索セクション */
.search-section {
  margin-bottom: 24px;
}

.search-input-container {
  position: relative;
  max-width: 500px;
}

.search-input {
  width: 100%;
  height: 48px;
  padding: 0 50px 0 16px;
  border: 2px solid var(--border-color);
  border-radius: 8px;
  font-size: var(--font-size-md);
  font-family: var(--font-family-main);
  outline: none;
  transition: border-color 0.2s ease;
}

.search-input:focus {
  border-color: var(--primary-color);
}

.clear-search-btn {
  position: absolute;
  right: 8px;
  top: 50%;
  transform: translateY(-50%);
  width: 32px;
  height: 32px;
  border: none;
  background: var(--gray-color);
  color: var(--text-secondary);
  border-radius: 50%;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 14px;
  transition: all 0.2s ease;
}

.clear-search-btn:hover {
  background: var(--gray-color-dark);
  color: var(--text-primary);
}

.no-results {
  text-align: center;
  padding: 20px;
  color: var(--text-secondary);
  font-style: italic;
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

.friend-card {
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

.friend-card.selected {
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

.friend-id {
  font-size: var(--font-size-xs);
  color: var(--text-tertiary);
  margin: 4px 0 0 0;
  font-family: monospace;
}

/* 検索ハイライト */
:deep(mark) {
  background: var(--primary-color-light);
  color: var(--primary-color-dark);
  padding: 1px 2px;
  border-radius: 2px;
  font-weight: 500;
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
  
  .search-input-container {
    max-width: none;
  }
  
  .action-buttons {
    flex-direction: column;
  }
}
</style>