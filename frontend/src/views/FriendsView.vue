<template>
  <PageContainer>
    <div class="friends-view">
      <!-- ページタイトル -->
      <PageTitle>友達管理</PageTitle>
      
      <div class="tabs">
        <button
          v-for="tab in tabs"
          :key="tab.id"
          @click="activeTab = tab.id"
          class="tab-button"
          :class="{ active: activeTab === tab.id }"
        >
          {{ tab.label }}
          <span v-if="tab.count !== undefined" class="tab-count">{{ tab.count }}</span>
        </button>
      </div>
      
      <div class="tab-content">
        <!-- 友達申請送信 -->
        <div v-if="activeTab === 'send'" class="tab-panel">
          <SendFriendRequest @success="onRequestSent" />
        </div>
        
        <!-- 受信した申請 -->
        <div v-if="activeTab === 'received'" class="tab-panel">
          <FriendRequestList type="received" />
        </div>
        
        <!-- 送信した申請 -->
        <div v-if="activeTab === 'sent'" class="tab-panel">
          <FriendRequestList type="sent" />
        </div>
        
        <!-- 友達リスト -->
        <div v-if="activeTab === 'friends'" class="tab-panel">
          <FriendsList />
        </div>
      </div>
    </div>
  </PageContainer>
</template>

<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { useFriendsStore } from '@/stores/friends'
import PageContainer from '@/components/layout/PageContainer.vue'
import PageTitle from '@/components/layout/PageTitle.vue'
import SendFriendRequest from '@/components/friends/SendFriendRequest.vue'
import FriendRequestList from '@/components/friends/FriendRequestList.vue'
import FriendsList from '@/components/friends/FriendsList.vue'

const friendsStore = useFriendsStore()
const activeTab = ref('friends')

const tabs = computed(() => [
  {
    id: 'friends',
    label: '友達',
    count: friendsStore.friendCount
  },
  {
    id: 'received',
    label: '受信申請',
    count: friendsStore.pendingReceivedCount
  },
  {
    id: 'sent',
    label: '送信申請',
    count: friendsStore.pendingSentCount
  },
  {
    id: 'send',
    label: '申請送信'
  }
])

onMounted(async () => {
  // 全データを取得
  await Promise.all([
    friendsStore.fetchFriends(),
    friendsStore.fetchReceivedRequests(),
    friendsStore.fetchSentRequests()
  ])
})

function onRequestSent() {
  // 申請送信後は送信済み申請タブに切り替え
  activeTab.value = 'sent'
}
</script>

<style scoped>
.friends-view {
  /* page-containerで統一されたスタイルを使用 */
}

.tabs {
  display: flex;
  gap: 24px;
  margin-bottom: 32px;
  border-bottom: 1px solid var(--border-color);
  overflow-x: auto;
}

.tab-button {
  position: relative;
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 12px 0;
  border: none;
  background: none;
  font-size: var(--font-size-md);
  font-weight: 500;
  color: var(--text-secondary);
  cursor: pointer;
  transition: color 0.2s;
  white-space: nowrap;
}

.tab-button:hover {
  color: var(--text-primary);
}

.tab-button.active {
  color: var(--primary-color);
  font-weight: 600;
}

.tab-button.active::after {
  content: '';
  position: absolute;
  bottom: -1px;
  left: 0;
  right: 0;
  height: 2px;
  background: var(--primary-color);
}

.tab-count {
  background: var(--background-tertiary);
  color: var(--text-secondary);
  padding: 2px 8px;
  border-radius: var(--radius-lg);
  font-size: var(--font-size-sm);
  font-weight: 600;
  min-width: 20px;
  text-align: center;
}

.tab-button.active .tab-count {
  background: var(--primary-color);
  color: white;
}

.tab-content {
  animation: fadeIn 0.3s ease-in-out;
}

.tab-panel {
  min-height: 400px;
}

@keyframes fadeIn {
  from {
    opacity: 0;
    transform: translateY(10px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

/* レスポンシブ対応 */
@media (max-width: 768px) {
  .tabs {
    gap: 16px;
  }
  
  .tab-button {
    font-size: var(--font-size-sm);
    padding: 10px 0;
  }
}
</style>