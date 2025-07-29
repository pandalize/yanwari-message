<template>
  <div class="friends-view">
    <div class="container">
      <div class="page-header">
        <h1 class="page-title">友達管理</h1>
        <p class="page-subtitle">友達申請の送信・管理、友達とのメッセージ交換ができます</p>
      </div>
      
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
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { useFriendsStore } from '@/stores/friends'
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
  min-height: 100vh;
  background: linear-gradient(135deg, #f0f9ff 0%, #e0f2fe 100%);
  padding: var(--spacing-2xl) 5%;
}

@media (min-width: 768px) {
  .friends-view {
    padding: var(--spacing-2xl) 10%;
  }
}

@media (min-width: 1200px) {
  .friends-view {
    padding: var(--spacing-2xl) 15%;
  }
}

@media (min-width: 1600px) {
  .friends-view {
    padding: var(--spacing-2xl) 20%;
  }
}

.container {
  width: 100%;
  margin: 0 auto;
}

.page-header {
  text-align: center;
  margin-bottom: 40px;
}

.page-title {
  font-size: 2.5rem;
  font-weight: 700;
  color: #1e293b;
  margin-bottom: 12px;
}

.page-subtitle {
  font-size: 1.1rem;
  color: #64748b;
  max-width: 600px;
  margin: 0 auto;
}

.tabs {
  display: flex;
  background: white;
  border-radius: 12px;
  padding: 8px;
  margin-bottom: 24px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.05);
  overflow-x: auto;
}

.tab-button {
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  padding: 12px 8px;
  border: none;
  background: none;
  border-radius: 8px;
  font-size: 0.85rem;
  font-weight: 500;
  color: #64748b;
  cursor: pointer;
  transition: all 0.2s;
  white-space: nowrap;
  min-width: 80px;
}

.tab-button:hover {
  background: #f8fafc;
  color: #475569;
}

.tab-button.active {
  background: linear-gradient(135deg, #81c784, #66bb6a);
  color: white;
  transform: translateY(-1px);
  box-shadow: 0 4px 12px rgba(129, 199, 132, 0.3);
}

.tab-count {
  background: rgba(255, 255, 255, 0.2);
  color: inherit;
  padding: 2px 8px;
  border-radius: 12px;
  font-size: 0.8rem;
  font-weight: 600;
  min-width: 20px;
  text-align: center;
}

.tab-button.active .tab-count {
  background: rgba(255, 255, 255, 0.3);
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

/* 大画面対応 */
@media (min-width: 1400px) {
  .container {
    padding: 0 40px;
  }
  
  .page-title {
    font-size: 3rem;
  }
  
  .page-subtitle {
    font-size: 1.25rem;
  }
  
  .tabs {
    padding: 12px;
    margin-bottom: 32px;
  }
  
  .tab-button {
    padding: 16px 24px;
    font-size: 1rem;
    min-width: 140px;
  }
}

@media (max-width: 768px) {
  .page-title {
    font-size: 2rem;
  }
  
  .page-subtitle {
    font-size: 1rem;
  }
  
  .tabs {
    gap: 4px;
    padding: 4px;
  }
  
  .tab-button {
    padding: 8px 4px;
    font-size: 0.75rem;
    min-width: 60px;
    gap: 4px;
  }
  
  .tab-count {
    padding: 1px 4px;
    font-size: 0.7rem;
  }
}

@media (max-width: 480px) {
  .page-title {
    font-size: 1.5rem;
  }
  
  .page-subtitle {
    font-size: 0.9rem;
    padding: 0 10px;
  }
  
  .tab-button {
    padding: 6px 2px;
    font-size: 0.7rem;
    min-width: 50px;
    gap: 2px;
  }
  
  .tab-count {
    padding: 1px 3px;
    font-size: 0.65rem;
    min-width: 14px;
  }
}
</style>