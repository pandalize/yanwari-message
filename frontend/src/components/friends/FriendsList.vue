<template>
  <div class="friends-list">
    <div class="header">
      <h3 class="title">友達リスト</h3>
      <span class="count">{{ friends.length }}人</span>
    </div>
    
    <div v-if="loading" class="loading">
      読み込み中...
    </div>
    
    <div v-else-if="friends.length === 0" class="empty">
      <div class="empty-icon">👥</div>
      <div class="empty-text">まだ友達がいません</div>
      <div class="empty-subtext">友達申請を送信して仲間を増やしましょう！</div>
    </div>
    
    <div v-else class="friends">
      <div
        v-for="friend in friends"
        :key="friend.friendship_id"
        class="friend-item"
      >
        <div class="friend-info">
          <div class="avatar">
            {{ getFriendDisplayName(friend).charAt(0).toUpperCase() }}
          </div>
          <div class="details">
            <div class="name">{{ getFriendDisplayName(friend) }}</div>
            <div class="email">{{ friend.friend.email }}</div>
            <div class="since">{{ formatFriendshipDate(friend.created_at) }}から友達</div>
          </div>
        </div>
        
        <div class="actions">
          <button
            @click="sendMessage(friend.friend.email)"
            class="btn btn-message"
            title="メッセージを送る"
          >
            💬 メッセージ
          </button>
          <button
            @click="confirmRemoveFriend(friend)"
            class="btn btn-remove"
            title="友達を削除"
            :disabled="actionLoading"
          >
            🗑️
          </button>
        </div>
      </div>
    </div>
    
    <!-- 友達削除確認モーダル -->
    <div v-if="showRemoveModal" class="modal-overlay" @click="closeRemoveModal">
      <div class="modal" @click.stop>
        <div class="modal-header">
          <h4>友達を削除しますか？</h4>
        </div>
        <div class="modal-body">
          <p>{{ friendToRemove?.friend.displayName || friendToRemove?.friend.email }} を友達リストから削除しますか？</p>
          <p class="warning">この操作は元に戻せません。再び友達になるには申請が必要です。</p>
        </div>
        <div class="modal-actions">
          <button
            @click="closeRemoveModal"
            class="btn btn-cancel"
            :disabled="actionLoading"
          >
            キャンセル
          </button>
          <button
            @click="removeFriend"
            class="btn btn-danger"
            :disabled="actionLoading"
          >
            <span v-if="actionLoading">削除中...</span>
            <span v-else>削除</span>
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed, ref } from 'vue'
import { useRouter } from 'vue-router'
import { useFriendsStore } from '@/stores/friends'
import type { FriendshipWithUser } from '@/services/friendService'

const friendsStore = useFriendsStore()
const router = useRouter()

const actionLoading = ref(false)
const showRemoveModal = ref(false)
const friendToRemove = ref<FriendshipWithUser | null>(null)

const friends = computed(() => friendsStore.friends)
const loading = computed(() => friendsStore.loading)

function getFriendDisplayName(friend: FriendshipWithUser): string {
  return friend.friend.displayName || friend.friend.email
}

function formatFriendshipDate(dateString: string): string {
  const date = new Date(dateString)
  const now = new Date()
  const diffMs = now.getTime() - date.getTime()
  const diffDays = Math.floor(diffMs / (1000 * 60 * 60 * 24))
  
  if (diffDays < 1) return '今日'
  if (diffDays < 7) return `${diffDays}日前`
  if (diffDays < 30) return `${Math.floor(diffDays / 7)}週間前`
  if (diffDays < 365) return `${Math.floor(diffDays / 30)}ヶ月前`
  
  return `${Math.floor(diffDays / 365)}年前`
}

function sendMessage(friendEmail: string) {
  // メッセージ作成画面に遷移（受信者を事前設定）
  router.push({
    name: 'message-compose',
    query: { recipient: friendEmail }
  })
}

function confirmRemoveFriend(friend: FriendshipWithUser) {
  friendToRemove.value = friend
  showRemoveModal.value = true
}

function closeRemoveModal() {
  showRemoveModal.value = false
  friendToRemove.value = null
}

async function removeFriend() {
  if (!friendToRemove.value) return
  
  actionLoading.value = true
  try {
    await friendsStore.removeFriend(friendToRemove.value.friend.email)
    closeRemoveModal()
  } finally {
    actionLoading.value = false
  }
}
</script>

<style scoped>
.friends-list {
  background: white;
  border-radius: 12px;
  padding: 24px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
}

.header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
}

.title {
  font-size: 1.2rem;
  font-weight: 600;
  color: #2d3748;
}

.count {
  font-size: 0.9rem;
  color: #718096;
  background: #f7fafc;
  padding: 4px 12px;
  border-radius: 16px;
}

.loading {
  text-align: center;
  color: #718096;
  padding: 40px 20px;
}

.empty {
  text-align: center;
  color: #718096;
  padding: 60px 20px;
}

.empty-icon {
  font-size: 3rem;
  margin-bottom: 16px;
}

.empty-text {
  font-size: 1.1rem;
  font-weight: 500;
  margin-bottom: 8px;
}

.empty-subtext {
  font-size: 0.9rem;
}

.friends {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.friend-item {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 16px;
  border: 2px solid #e2e8f0;
  border-radius: 12px;
  transition: border-color 0.2s;
}

.friend-item:hover {
  border-color: #cbd5e0;
}

.friend-info {
  display: flex;
  align-items: center;
  gap: 12px;
  flex: 1;
}

.avatar {
  width: 48px;
  height: 48px;
  border-radius: 50%;
  background: linear-gradient(135deg, #81c784, #66bb6a);
  display: flex;
  align-items: center;
  justify-content: center;
  color: white;
  font-weight: 600;
  font-size: 1.2rem;
}

.details {
  flex: 1;
}

.name {
  font-weight: 600;
  color: #2d3748;
  margin-bottom: 4px;
}

.email {
  font-size: 0.85rem;
  color: #718096;
  margin-bottom: 4px;
}

.since {
  font-size: 0.8rem;
  color: #a0aec0;
}

.actions {
  display: flex;
  gap: 8px;
}

.btn {
  padding: 8px 12px;
  border: none;
  border-radius: 6px;
  font-size: 0.85rem;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.2s;
}

.btn:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.btn-message {
  background-color: #4299e1;
  color: white;
}

.btn-message:hover:not(:disabled) {
  background-color: #3182ce;
}

.btn-remove {
  background-color: #e2e8f0;
  color: #718096;
  padding: 8px;
}

.btn-remove:hover:not(:disabled) {
  background-color: #fed7d7;
  color: #e53e3e;
}

/* モーダル */
.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.5);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
}

.modal {
  background: white;
  border-radius: 12px;
  padding: 24px;
  max-width: 400px;
  width: 90%;
  box-shadow: 0 10px 25px rgba(0, 0, 0, 0.2);
}

.modal-header {
  margin-bottom: 16px;
}

.modal-header h4 {
  color: #2d3748;
  font-weight: 600;
  margin: 0;
}

.modal-body {
  margin-bottom: 24px;
}

.modal-body p {
  color: #4a5568;
  margin-bottom: 12px;
}

.warning {
  color: #e53e3e !important;
  font-size: 0.9rem;
}

.modal-actions {
  display: flex;
  gap: 12px;
  justify-content: flex-end;
}

.btn-cancel {
  background-color: #e2e8f0;
  color: #4a5568;
}

.btn-cancel:hover:not(:disabled) {
  background-color: #cbd5e0;
}

.btn-danger {
  background-color: #e53e3e;
  color: white;
}

.btn-danger:hover:not(:disabled) {
  background-color: #c53030;
}

@media (max-width: 768px) {
  .friend-item {
    flex-direction: column;
    align-items: stretch;
    gap: 12px;
  }
  
  .friend-info {
    justify-content: center;
    text-align: center;
  }
  
  .actions {
    justify-content: center;
  }
  
  .modal {
    margin: 20px;
  }
}
</style>