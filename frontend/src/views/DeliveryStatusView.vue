<template>
  <PageContainer>
    <PageTitle>送信状況</PageTitle>
    
    <div class="delivery-status-container">
      <!-- 読み込み中 -->
      <div v-if="isLoading" class="loading-state">
        <div class="spinner"></div>
        <p>送信状況を読み込み中...</p>
      </div>

      <!-- エラー状態 -->
      <div v-else-if="error" class="error-state">
        <p>❌ {{ error }}</p>
        <button @click="loadDeliveryStatuses" class="retry-button">再試行</button>
      </div>

      <!-- データ表示 -->
      <div v-else class="delivery-content">
        <!-- 統計サマリー -->
        <div v-if="statusSummary" class="status-summary">
          <div class="summary-card">
            <span class="summary-number">{{ statusSummary.sent }}</span>
            <span class="summary-label">送信済み</span>
          </div>
          <div class="summary-card">
            <span class="summary-number">{{ statusSummary.delivered }}</span>
            <span class="summary-label">配信済み</span>
          </div>
          <div class="summary-card">
            <span class="summary-number">{{ statusSummary.read }}</span>
            <span class="summary-label">既読</span>
          </div>
          <div class="summary-card">
            <span class="summary-number">{{ statusSummary.scheduled }}</span>
            <span class="summary-label">予約中</span>
          </div>
        </div>

        <!-- フィルター -->
        <div class="filters">
          <select v-model="statusFilter" @change="applyFilter" class="filter-select">
            <option value="all">すべて</option>
            <option value="sent">送信済み</option>
            <option value="delivered">配信済み</option>
            <option value="read">既読</option>
            <option value="scheduled">予約中</option>
          </select>
          <button @click="loadDeliveryStatuses" class="refresh-button">🔄 更新</button>
        </div>

        <!-- メッセージ一覧 -->
        <div v-if="filteredStatuses.length === 0" class="empty-state">
          <p>📭 該当する送信メッセージがありません</p>
        </div>

        <div v-else class="status-list">
          <div 
            v-for="status in filteredStatuses" 
            :key="status.messageId"
            class="status-item"
          >
            <div class="status-header">
              <div class="status-info">
                <span class="recipient">{{ status.recipientName }}</span>
                <span class="status-badge" :class="getStatusClass(status.status)">
                  {{ getStatusText(status.status) }}
                </span>
              </div>
              <div class="status-time">
                {{ formatDateTime(status.sentAt) }}
              </div>
            </div>
            
            <div class="message-preview">
              {{ status.text.length > 100 ? status.text.substring(0, 100) + '...' : status.text }}
            </div>
            
            <div class="status-timeline">
              <div class="timeline-item" :class="{ active: status.sentAt }">
                <div class="timeline-dot"></div>
                <div class="timeline-content">
                  <span class="timeline-label">送信</span>
                  <span v-if="status.sentAt" class="timeline-time">
                    {{ formatDetailedTime(status.sentAt) }}
                  </span>
                </div>
              </div>
              
              <div class="timeline-item" :class="{ active: status.deliveredAt }">
                <div class="timeline-dot"></div>
                <div class="timeline-content">
                  <span class="timeline-label">配信</span>
                  <span v-if="status.deliveredAt" class="timeline-time">
                    {{ formatDetailedTime(status.deliveredAt) }}
                  </span>
                </div>
              </div>
              
              <div class="timeline-item" :class="{ active: status.readAt }">
                <div class="timeline-dot"></div>
                <div class="timeline-content">
                  <span class="timeline-label">既読</span>
                  <span v-if="status.readAt" class="timeline-time">
                    {{ formatDetailedTime(status.readAt) }}
                  </span>
                </div>
              </div>
            </div>
            
            <div v-if="status.errorMessage" class="error-message">
              ❌ {{ status.errorMessage }}
            </div>
          </div>
        </div>

        <!-- ページネーション -->
        <div v-if="deliveryData && deliveryData.totalPages > 1" class="pagination">
          <button 
            @click="goToPage(currentPage - 1)"
            :disabled="currentPage <= 1"
            class="pagination-button"
          >
            ← 前へ
          </button>
          
          <span class="page-info">
            {{ currentPage }} / {{ deliveryData.totalPages }}
          </span>
          
          <button 
            @click="goToPage(currentPage + 1)"
            :disabled="currentPage >= deliveryData.totalPages"
            class="pagination-button"
          >
            次へ →
          </button>
        </div>
      </div>
    </div>
  </PageContainer>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import PageContainer from '@/components/layout/PageContainer.vue'
import PageTitle from '@/components/layout/PageTitle.vue'
import dashboardService, { type DeliveryStatus, type DeliveryStatusResponse } from '@/services/dashboardService'

// データ状態管理
const deliveryData = ref<DeliveryStatusResponse | null>(null)
const isLoading = ref(false)
const error = ref<string | null>(null)
const currentPage = ref(1)
const statusFilter = ref('all')

// フィルタリングされたステータス一覧
const filteredStatuses = computed(() => {
  if (!deliveryData.value) return []
  
  const statuses = deliveryData.value.statuses
  if (statusFilter.value === 'all') return statuses
  
  return statuses.filter(status => status.status === statusFilter.value)
})

// ステータス統計
const statusSummary = computed(() => {
  if (!deliveryData.value) return null
  
  const statuses = deliveryData.value.statuses
  return {
    sent: statuses.filter(s => s.status === 'sent').length,
    delivered: statuses.filter(s => s.status === 'delivered').length,
    read: statuses.filter(s => s.status === 'read').length,
    scheduled: statuses.filter(s => s.status === 'scheduled').length
  }
})

// 送信状況を読み込み
const loadDeliveryStatuses = async (page: number = 1) => {
  isLoading.value = true
  error.value = null
  
  try {
    deliveryData.value = await dashboardService.getDeliveryStatuses(page, 20)
    currentPage.value = page
  } catch (err) {
    console.error('送信状況読み込みエラー:', err)
    error.value = 'データの読み込みに失敗しました'
  } finally {
    isLoading.value = false
  }
}

// ページ移動
const goToPage = (page: number) => {
  if (page >= 1 && deliveryData.value && page <= deliveryData.value.totalPages) {
    loadDeliveryStatuses(page)
  }
}

// フィルター適用
const applyFilter = () => {
  // フィルターが変更された場合、現在のデータを再フィルタリング
  // 新しいデータの読み込みは不要
}

// ステータステキストの取得
const getStatusText = (status: string): string => {
  const statusMap: Record<string, string> = {
    draft: '下書き',
    processing: '処理中',
    scheduled: '予約中',
    sent: '送信済み',
    delivered: '配信済み',
    read: '既読',
    failed: '失敗'
  }
  return statusMap[status] || status
}

// ステータスのCSSクラス
const getStatusClass = (status: string): string => {
  const classMap: Record<string, string> = {
    draft: 'status-draft',
    processing: 'status-processing',
    scheduled: 'status-scheduled',
    sent: 'status-sent',
    delivered: 'status-delivered',
    read: 'status-read',
    failed: 'status-failed'
  }
  return classMap[status] || 'status-default'
}

// 時刻フォーマット（相対時間）
const formatDateTime = (dateStr: string | undefined): string => {
  if (!dateStr) return ''
  
  const date = new Date(dateStr)
  const now = new Date()
  const diffMs = now.getTime() - date.getTime()
  const diffMinutes = Math.floor(diffMs / (1000 * 60))
  const diffHours = Math.floor(diffMs / (1000 * 60 * 60))
  const diffDays = Math.floor(diffMs / (1000 * 60 * 60 * 24))
  
  if (diffMinutes < 60) {
    return `${diffMinutes}分前`
  } else if (diffHours < 24) {
    return `${diffHours}時間前`
  } else if (diffDays < 7) {
    return `${diffDays}日前`
  } else {
    return date.toLocaleDateString('ja-JP', {
      month: 'numeric',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    })
  }
}

// 詳細時刻フォーマット
const formatDetailedTime = (dateStr: string | undefined): string => {
  if (!dateStr) return ''
  
  const date = new Date(dateStr)
  return date.toLocaleDateString('ja-JP', {
    month: 'numeric',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit'
  })
}

// ページ読み込み時に送信状況を取得
onMounted(() => {
  loadDeliveryStatuses()
})
</script>

<style scoped>
.delivery-status-container {
  max-width: 1000px;
  margin: 0 auto;
}

.loading-state, .error-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 1rem;
  padding: 3rem;
  background: white;
  border-radius: 12px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.06);
}

.spinner {
  width: 40px;
  height: 40px;
  border: 4px solid #e2e8f0;
  border-left-color: #667eea;
  border-radius: 50%;
  animation: spin 1s linear infinite;
}

@keyframes spin {
  to {
    transform: rotate(360deg);
  }
}

.retry-button {
  padding: 0.75rem 1.5rem;
  background: #667eea;
  color: white;
  border: none;
  border-radius: 8px;
  cursor: pointer;
  font-weight: 500;
  transition: background 0.3s ease;
}

.retry-button:hover {
  background: #5a67d8;
}

.delivery-content {
  display: flex;
  flex-direction: column;
  gap: 2rem;
}

.status-summary {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
  gap: 1rem;
  margin-bottom: 1rem;
}

.summary-card {
  display: flex;
  flex-direction: column;
  align-items: center;
  background: white;
  border-radius: 12px;
  padding: 1.5rem;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.06);
  transition: transform 0.3s ease;
}

.summary-card:hover {
  transform: translateY(-2px);
}

.summary-number {
  font-size: 2rem;
  font-weight: bold;
  color: #667eea;
  margin-bottom: 0.5rem;
}

.summary-label {
  font-size: 0.9rem;
  color: #666;
  font-weight: 500;
}

.filters {
  display: flex;
  gap: 1rem;
  align-items: center;
  background: white;
  padding: 1rem;
  border-radius: 12px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.06);
}

.filter-select {
  padding: 0.5rem 1rem;
  border: 2px solid #e2e8f0;
  border-radius: 8px;
  background: white;
  font-size: 1rem;
  cursor: pointer;
}

.filter-select:focus {
  outline: none;
  border-color: #667eea;
}

.refresh-button {
  padding: 0.5rem 1rem;
  background: #f7fafc;
  border: 2px solid #e2e8f0;
  border-radius: 8px;
  cursor: pointer;
  font-size: 1rem;
  transition: all 0.3s ease;
}

.refresh-button:hover {
  background: #edf2f7;
  border-color: #cbd5e0;
}

.empty-state {
  text-align: center;
  padding: 3rem;
  background: white;
  border-radius: 12px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.06);
  color: #666;
}

.status-list {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.status-item {
  background: white;
  border-radius: 12px;
  padding: 1.5rem;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.06);
  transition: transform 0.3s ease, box-shadow 0.3s ease;
}

.status-item:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 16px rgba(0, 0, 0, 0.1);
}

.status-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 1rem;
}

.status-info {
  display: flex;
  align-items: center;
  gap: 1rem;
}

.recipient {
  font-weight: 600;
  font-size: 1.1rem;
  color: #333;
}

.status-badge {
  padding: 0.25rem 0.75rem;
  border-radius: 20px;
  font-size: 0.8rem;
  font-weight: 500;
  text-transform: uppercase;
  letter-spacing: 0.5px;
}

.status-sent { background: #e6fffa; color: #38a169; }
.status-delivered { background: #e6f3ff; color: #3182ce; }
.status-read { background: #f0fff4; color: #22c35e; }
.status-scheduled { background: #fef5e7; color: #d69e2e; }
.status-failed { background: #fed7d7; color: #e53e3e; }
.status-default { background: #f7fafc; color: #4a5568; }

.status-time {
  color: #666;
  font-size: 0.9rem;
}

.message-preview {
  color: #555;
  line-height: 1.5;
  margin-bottom: 1.5rem;
  padding: 1rem;
  background: #f8f9fa;
  border-radius: 8px;
  border-left: 4px solid #667eea;
}

.status-timeline {
  display: flex;
  justify-content: space-between;
  position: relative;
  margin: 1rem 0;
}

.status-timeline::before {
  content: '';
  position: absolute;
  top: 12px;
  left: 12px;
  right: 12px;
  height: 2px;
  background: #e2e8f0;
  z-index: 1;
}

.timeline-item {
  display: flex;
  flex-direction: column;
  align-items: center;
  position: relative;
  z-index: 2;
}

.timeline-dot {
  width: 24px;
  height: 24px;
  border-radius: 50%;
  background: #e2e8f0;
  border: 3px solid white;
  transition: background 0.3s ease;
}

.timeline-item.active .timeline-dot {
  background: #667eea;
}

.timeline-content {
  display: flex;
  flex-direction: column;
  align-items: center;
  margin-top: 0.5rem;
}

.timeline-label {
  font-size: 0.8rem;
  font-weight: 500;
  color: #666;
}

.timeline-time {
  font-size: 0.7rem;
  color: #999;
  margin-top: 0.25rem;
}

.error-message {
  margin-top: 1rem;
  padding: 0.75rem;
  background: #fed7d7;
  color: #9b2c2c;
  border-radius: 8px;
  font-size: 0.9rem;
}

.pagination {
  display: flex;
  justify-content: center;
  align-items: center;
  gap: 1rem;
  background: white;
  padding: 1rem;
  border-radius: 12px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.06);
}

.pagination-button {
  padding: 0.5rem 1rem;
  background: #667eea;
  color: white;
  border: none;
  border-radius: 8px;
  cursor: pointer;
  font-weight: 500;
  transition: background 0.3s ease;
}

.pagination-button:hover:not(:disabled) {
  background: #5a67d8;
}

.pagination-button:disabled {
  background: #cbd5e0;
  cursor: not-allowed;
}

.page-info {
  font-weight: 500;
  color: #4a5568;
}

@media (max-width: 768px) {
  .status-summary {
    grid-template-columns: repeat(2, 1fr);
  }
  
  .filters {
    flex-direction: column;
    align-items: stretch;
  }
  
  .status-header {
    flex-direction: column;
    align-items: flex-start;
    gap: 0.5rem;
  }
  
  .status-timeline {
    flex-direction: column;
    gap: 1rem;
  }
  
  .status-timeline::before {
    display: none;
  }
  
  .timeline-item {
    flex-direction: row;
    justify-content: flex-start;
    align-items: center;
    gap: 1rem;
  }
  
  .timeline-content {
    align-items: flex-start;
    margin-top: 0;
  }
}
</style>