<template>
  <div class="treemap-test-view">
    <div class="test-header">
      <h1>📊 ツリーマップビューテスト</h1>
      <div class="test-controls">
        <button @click="generateTestData" class="generate-btn">
          🎲 テストデータ生成
        </button>
        <button @click="clearData" class="clear-btn">
          🗑️ データクリア
        </button>
        <div class="data-info">
          {{ messages.length }} 件のメッセージ
        </div>
      </div>
    </div>

    <div class="test-content">
      <!-- ツリーマップビュー -->
      <div class="treemap-section">
        <TreemapView
          :messages="messages"
          @message-selected="handleMessageSelected"
        />
      </div>

      <!-- 統計情報 -->
      <div class="stats-section">
        <div class="stats-grid">
          <div class="stat-card">
            <h3>📈 評価分布</h3>
            <div class="rating-distribution">
              <div v-for="(count, rating) in ratingDistribution" :key="rating" class="rating-item">
                <span class="rating-label">
                  {{ rating === 'unrated' ? '未評価' : rating + '★' }}:
                </span>
                <span class="rating-count">{{ count }}件</span>
                <div class="rating-bar">
                  <div 
                    class="rating-fill" 
                    :style="{ 
                      width: (count / messages.length * 100) + '%',
                      backgroundColor: getRatingColor(rating)
                    }"
                  ></div>
                </div>
              </div>
            </div>
          </div>

          <div class="stat-card">
            <h3>👥 送信者統計</h3>
            <div class="sender-stats">
              <div 
                v-for="(stat, sender) in Object.entries(senderStats).slice(0, 5)" 
                :key="sender"
                class="sender-item"
              >
                <div class="sender-name">{{ stat[1].name }}</div>
                <div class="sender-details">
                  <span>{{ stat[1].messageCount }}件</span>
                  <span v-if="stat[1].ratedCount > 0">
                    (平均 {{ stat[1].avgRating.toFixed(1) }}★)
                  </span>
                </div>
              </div>
            </div>
          </div>

          <div class="stat-card">
            <h3>📅 期間別統計</h3>
            <div class="date-stats">
              <div v-for="(stat, period) in dateStats" :key="period" class="date-item">
                <span class="period-label">{{ getPeriodLabel(period) }}:</span>
                <span class="period-count">{{ stat.count }}件</span>
                <span v-if="stat.ratedCount > 0" class="period-rating">
                  (平均 {{ (stat.totalRating / stat.ratedCount).toFixed(1) }}★)
                </span>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- 選択されたメッセージの詳細 -->
      <div v-if="selectedMessage" class="selected-message">
        <div class="message-detail">
          <h3>選択されたメッセージ</h3>
          <div class="message-content">
            <div class="message-header">
              <strong>{{ selectedMessage.senderName }}</strong>
              <span class="message-date">{{ formatDate(selectedMessage.createdAt) }}</span>
            </div>
            <div class="message-text">{{ selectedMessage.finalText }}</div>
            <div v-if="selectedMessage.rating" class="message-rating">
              評価: {{ '★'.repeat(selectedMessage.rating) }} ({{ selectedMessage.rating }}/5)
            </div>
            <div v-else class="message-no-rating">
              未評価
            </div>
          </div>
          <button @click="selectedMessage = null" class="close-detail-btn">閉じる</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import TreemapView from '../components/visualization/TreemapView.vue'
import { generateMockMessages, generateRatingDistribution, generateSenderStats, generateDateStats } from '../utils/mockData'
import type { InboxMessageWithRating } from '../services/ratingService'

// State
const messages = ref<InboxMessageWithRating[]>([])
const selectedMessage = ref<InboxMessageWithRating | null>(null)

// Computed statistics
const ratingDistribution = computed(() => {
  return generateRatingDistribution(messages.value)
})

const senderStats = computed(() => {
  return generateSenderStats(messages.value)
})

const dateStats = computed(() => {
  return generateDateStats(messages.value)
})

// Methods
const generateTestData = () => {
  messages.value = generateMockMessages()
  selectedMessage.value = null
}

const clearData = () => {
  messages.value = []
  selectedMessage.value = null
}

const handleMessageSelected = (message: InboxMessageWithRating) => {
  selectedMessage.value = message
}

const getRatingColor = (rating: string | number) => {
  if (rating === 'unrated') return '#9ca3af'
  const r = Number(rating)
  if (r <= 2) return '#ef4444'
  if (r === 3) return '#f97316'
  if (r === 4) return '#eab308'
  return '#22c55e'
}

const getPeriodLabel = (period: string) => {
  const labels: { [key: string]: string } = {
    thisWeek: '今週',
    thisMonth: '今月',
    last3Months: '3ヶ月以内',
    older: 'それ以前'
  }
  return labels[period] || period
}

const formatDate = (dateString: string) => {
  const date = new Date(dateString)
  return date.toLocaleDateString('ja-JP', { 
    year: 'numeric', 
    month: 'short', 
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit'
  })
}

// 初期化
onMounted(() => {
  generateTestData()
})
</script>

<style scoped>
.treemap-test-view {
  min-height: 100vh;
  background: #f8fafc;
  padding: 2rem;
}

.test-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 2rem;
  padding: 1.5rem;
  background: white;
  border-radius: 12px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
}

.test-header h1 {
  margin: 0;
  color: #374151;
  font-size: 1.75rem;
}

.test-controls {
  display: flex;
  align-items: center;
  gap: 1rem;
}

.generate-btn, .clear-btn {
  padding: 0.75rem 1.25rem;
  border: none;
  border-radius: 8px;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.2s ease;
}

.generate-btn {
  background: #10b981;
  color: white;
}

.generate-btn:hover {
  background: #059669;
  transform: translateY(-1px);
}

.clear-btn {
  background: #ef4444;
  color: white;
}

.clear-btn:hover {
  background: #dc2626;
  transform: translateY(-1px);
}

.data-info {
  padding: 0.5rem 1rem;
  background: #f3f4f6;
  border-radius: 6px;
  font-size: 0.875rem;
  color: #6b7280;
  font-weight: 500;
}

.test-content {
  display: grid;
  grid-template-columns: 2fr 1fr;
  gap: 2rem;
  align-items: start;
}

.treemap-section {
  background: white;
  border-radius: 12px;
  overflow: hidden;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
}

.stats-section {
  display: flex;
  flex-direction: column;
  gap: 1.5rem;
}

.stats-grid {
  display: flex;
  flex-direction: column;
  gap: 1.5rem;
}

.stat-card {
  background: white;
  border-radius: 12px;
  padding: 1.5rem;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
}

.stat-card h3 {
  margin: 0 0 1rem 0;
  color: #374151;
  font-size: 1.125rem;
  font-weight: 600;
}

.rating-distribution {
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
}

.rating-item {
  display: flex;
  align-items: center;
  gap: 0.75rem;
}

.rating-label {
  min-width: 60px;
  font-size: 0.875rem;
  color: #6b7280;
}

.rating-count {
  min-width: 40px;
  font-size: 0.875rem;
  font-weight: 500;
  color: #374151;
}

.rating-bar {
  flex: 1;
  height: 8px;
  background: #f3f4f6;
  border-radius: 4px;
  overflow: hidden;
}

.rating-fill {
  height: 100%;
  transition: width 0.3s ease;
}

.sender-stats {
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
}

.sender-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 0.75rem;
  background: #f8fafc;
  border-radius: 8px;
}

.sender-name {
  font-weight: 500;
  color: #374151;
}

.sender-details {
  font-size: 0.875rem;
  color: #6b7280;
}

.date-stats {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.date-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 0.5rem 0;
  border-bottom: 1px solid #f3f4f6;
}

.date-item:last-child {
  border-bottom: none;
}

.period-label {
  font-weight: 500;
  color: #374151;
}

.period-count {
  font-weight: 500;
  color: #6b7280;
}

.period-rating {
  font-size: 0.875rem;
  color: #f59e0b;
}

.selected-message {
  grid-column: 1 / -1;
  margin-top: 1rem;
}

.message-detail {
  background: white;
  border-radius: 12px;
  padding: 1.5rem;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
  border-left: 4px solid #3b82f6;
}

.message-detail h3 {
  margin: 0 0 1rem 0;
  color: #374151;
  font-size: 1.125rem;
}

.message-content {
  margin-bottom: 1rem;
}

.message-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 0.75rem;
  padding-bottom: 0.75rem;
  border-bottom: 1px solid #e5e7eb;
}

.message-date {
  font-size: 0.875rem;
  color: #6b7280;
}

.message-text {
  color: #374151;
  line-height: 1.6;
  margin-bottom: 0.75rem;
}

.message-rating {
  color: #f59e0b;
  font-weight: 500;
}

.message-no-rating {
  color: #9ca3af;
  font-style: italic;
}

.close-detail-btn {
  background: #6b7280;
  color: white;
  border: none;
  padding: 0.5rem 1rem;
  border-radius: 6px;
  cursor: pointer;
  font-size: 0.875rem;
  transition: background-color 0.2s ease;
}

.close-detail-btn:hover {
  background: #4b5563;
}

/* レスポンシブ対応 */
@media (max-width: 1200px) {
  .test-content {
    grid-template-columns: 1fr;
  }
  
  .selected-message {
    grid-column: 1;
  }
}

@media (max-width: 768px) {
  .treemap-test-view {
    padding: 1rem;
  }
  
  .test-header {
    flex-direction: column;
    gap: 1rem;
    align-items: stretch;
  }
  
  .test-controls {
    justify-content: space-between;
  }
  
  .stats-grid {
    gap: 1rem;
  }
  
  .stat-card {
    padding: 1rem;
  }
}
</style>