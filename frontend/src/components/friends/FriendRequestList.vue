<template>
  <div class="friend-request-list">
    <div class="header">
      <h3 class="title">{{ type === 'received' ? '受信した申請' : '送信した申請' }}</h3>
      <span class="count">{{ requests.length }}件</span>
    </div>
    
    <div v-if="loading" class="loading">
      読み込み中...
    </div>
    
    <div v-else-if="requests.length === 0" class="empty">
      {{ type === 'received' ? '受信した申請はありません' : '送信した申請はありません' }}
    </div>
    
    <div v-else class="requests">
      <div
        v-for="request in requests"
        :key="request.id"
        class="request-item"
      >
        <div class="user-info">
          <div class="avatar">
            {{ getUserDisplayName(request).charAt(0).toUpperCase() }}
          </div>
          <div class="details">
            <div class="name">{{ getUserDisplayName(request) }}</div>
            <div class="email">{{ getUserEmail(request) }}</div>
            <div v-if="request.message" class="message">
              「{{ request.message }}」
            </div>
          </div>
        </div>
        
        <div class="meta">
          <div class="date">{{ formatDate(request.created_at) }}</div>
          <div class="status" :class="`status-${request.status}`">
            {{ getStatusText(request.status) }}
          </div>
        </div>
        
        <div v-if="request.status === 'pending'" class="actions">
          <template v-if="type === 'received'">
            <button
              @click="acceptRequest(request.id)"
              class="btn btn-accept"
              :disabled="actionLoading"
            >
              承諾
            </button>
            <button
              @click="rejectRequest(request.id)"
              class="btn btn-reject"
              :disabled="actionLoading"
            >
              拒否
            </button>
          </template>
          <template v-else-if="type === 'sent'">
            <button
              @click="cancelRequest(request.id)"
              class="btn btn-cancel"
              :disabled="actionLoading"
            >
              キャンセル
            </button>
          </template>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed, ref } from 'vue'
import { useFriendsStore } from '@/stores/friends'
import type { FriendRequestWithUsers } from '@/services/friendService'

interface Props {
  type: 'received' | 'sent'
}

const props = defineProps<Props>()
const friendsStore = useFriendsStore()
const actionLoading = ref(false)

const requests = computed(() => {
  return props.type === 'received' 
    ? friendsStore.receivedRequests 
    : friendsStore.sentRequests
})

const loading = computed(() => friendsStore.loading)

function getUserDisplayName(request: FriendRequestWithUsers): string {
  const user = props.type === 'received' ? request.from_user : request.to_user
  return user?.displayName || user?.email || '不明なユーザー'
}

function getUserEmail(request: FriendRequestWithUsers): string {
  const user = props.type === 'received' ? request.from_user : request.to_user
  return user?.email || ''
}

function getStatusText(status: string): string {
  const statusMap = {
    pending: '待機中',
    accepted: '承諾済み',
    rejected: '拒否済み',
    canceled: 'キャンセル済み'
  }
  return statusMap[status as keyof typeof statusMap] || status
}

function formatDate(dateString: string): string {
  const date = new Date(dateString)
  const now = new Date()
  const diffMs = now.getTime() - date.getTime()
  const diffMinutes = Math.floor(diffMs / (1000 * 60))
  const diffHours = Math.floor(diffMinutes / 60)
  const diffDays = Math.floor(diffHours / 24)
  
  if (diffMinutes < 1) return 'たった今'
  if (diffMinutes < 60) return `${diffMinutes}分前`
  if (diffHours < 24) return `${diffHours}時間前`
  if (diffDays < 7) return `${diffDays}日前`
  
  return date.toLocaleDateString('ja-JP')
}

async function acceptRequest(requestId: string) {
  actionLoading.value = true
  try {
    await friendsStore.acceptRequest(requestId)
  } finally {
    actionLoading.value = false
  }
}

async function rejectRequest(requestId: string) {
  actionLoading.value = true
  try {
    await friendsStore.rejectRequest(requestId)
  } finally {
    actionLoading.value = false
  }
}

async function cancelRequest(requestId: string) {
  actionLoading.value = true
  try {
    await friendsStore.cancelRequest(requestId)
  } finally {
    actionLoading.value = false
  }
}
</script>

<style scoped>
.friend-request-list {
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

.loading, .empty {
  text-align: center;
  color: #718096;
  padding: 40px 20px;
}

.requests {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.request-item {
  display: flex;
  align-items: center;
  gap: 16px;
  padding: 16px;
  border: 2px solid #e2e8f0;
  border-radius: 12px;
  transition: border-color 0.2s;
}

.request-item:hover {
  border-color: #cbd5e0;
}

.user-info {
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

.message {
  font-size: 0.9rem;
  color: #4a5568;
  font-style: italic;
}

.meta {
  display: flex;
  flex-direction: column;
  align-items: flex-end;
  gap: 8px;
}

.date {
  font-size: 0.8rem;
  color: #a0aec0;
}

.status {
  padding: 4px 8px;
  border-radius: 8px;
  font-size: 0.8rem;
  font-weight: 500;
}

.status-pending {
  background: #fef5e7;
  color: #d69e2e;
}

.status-accepted {
  background: #f0fff4;
  color: #38a169;
}

.status-rejected {
  background: #fed7d7;
  color: #e53e3e;
}

.status-canceled {
  background: #edf2f7;
  color: #718096;
}

.actions {
  display: flex;
  gap: 8px;
}

.btn {
  padding: 8px 16px;
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

.btn-accept {
  background-color: #48bb78;
  color: white;
}

.btn-accept:hover:not(:disabled) {
  background-color: #38a169;
}

.btn-reject {
  background-color: #f56565;
  color: white;
}

.btn-reject:hover:not(:disabled) {
  background-color: #e53e3e;
}

.btn-cancel {
  background-color: #a0aec0;
  color: white;
}

.btn-cancel:hover:not(:disabled) {
  background-color: #718096;
}

@media (max-width: 768px) {
  .request-item {
    flex-direction: column;
    align-items: stretch;
    gap: 12px;
  }
  
  .user-info {
    flex-direction: column;
    align-items: center;
    text-align: center;
  }
  
  .meta {
    flex-direction: row;
    justify-content: space-between;
    align-items: center;
  }
  
  .actions {
    justify-content: center;
  }
}
</style>