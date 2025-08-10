<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useAuthStore } from '@/stores/auth'
import { useRouter } from 'vue-router'
import PageContainer from '@/components/layout/PageContainer.vue'
import dashboardService, { type DashboardData, type RecentMessage } from '@/services/dashboardService'

const authStore = useAuthStore()
const router = useRouter()

// データ状態管理
const dashboardData = ref<DashboardData | null>(null)
const isLoading = ref(false)
const error = ref<string | null>(null)

const goToCompose = () => {
  router.push('/recipient-select')
}

const goToLogin = () => {
  router.push('/firebase-login')
}

const goToRegister = () => {
  router.push('/firebase-register')
}

const goToHistory = () => {
  router.push('/history')
}

const goToInbox = () => {
  router.push('/inbox')
}

const goToDeliveryStatus = () => {
  router.push('/delivery-status')
}

// ダッシュボードデータを読み込み
const loadDashboardData = async () => {
  if (!authStore.isAuthenticated) return
  
  isLoading.value = true
  error.value = null
  
  try {
    dashboardData.value = await dashboardService.getDashboard()
  } catch (err) {
    console.error('ダッシュボードデータ読み込みエラー:', err)
    error.value = 'データの読み込みに失敗しました'
  } finally {
    isLoading.value = false
  }
}

// 時刻を日本語形式でフォーマット
const formatDateTime = (dateStr: string): string => {
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

// メッセージタイプのアイコンとラベル
const getMessageTypeInfo = (message: RecentMessage) => {
  if (message.type === 'sent') {
    return {
      icon: '📤',
      label: message.recipientName || message.recipientEmail || '送信先不明',
      prefix: 'から'
    }
  } else {
    return {
      icon: '📥',
      label: message.senderName || message.senderEmail || '送信者不明',
      prefix: 'へ'
    }
  }
}

// ページ読み込み時にダッシュボードデータを取得
onMounted(() => {
  loadDashboardData()
})

// 認証状態変更時にデータを再読み込み
authStore.$subscribe(() => {
  if (authStore.isAuthenticated && !dashboardData.value) {
    loadDashboardData()
  }
})
</script>

<template>
  <PageContainer>
    <main class="home">
    <section class="hero">
      <div class="hero-content">
        <h1>✨ やんわり伝言</h1>
        <p class="hero-description">
          気持ちを優しく伝えるメッセージサービス
        </p>
        
        <div v-if="authStore.isAuthenticated" class="authenticated-home">
          <p class="welcome-message">
            お帰りなさい、{{ authStore.user?.displayName || authStore.user?.email }}さん
          </p>
          
          <!-- 主要アクション -->
          <div class="main-actions">
            <button @click="goToCompose" class="btn btn-primary">
              📝 メッセージを作成する
            </button>
            <button @click="goToInbox" class="btn btn-secondary">
              📫 受信トレイを見る
            </button>
            <button @click="goToDeliveryStatus" class="btn btn-secondary">
              📊 送信状況を確認
            </button>
          </div>
          
          <!-- 統計情報 -->
          <div v-if="isLoading" class="loading-state">
            <div class="spinner"></div>
            <p>データを読み込み中...</p>
          </div>
          
          <div v-else-if="error" class="error-state">
            <p>{{ error }}</p>
            <button @click="loadDashboardData" class="btn btn-secondary">再試行</button>
          </div>
          
          <div v-else-if="dashboardData" class="dashboard-stats">
            <!-- 今日の活動 -->
            <div class="stats-section">
              <h3>📈 今日の活動</h3>
              <div class="stats-grid">
                <div class="stat-item">
                  <span class="stat-number">{{ dashboardData.activityStats.today.messagesSent }}</span>
                  <span class="stat-label">送信</span>
                </div>
                <div class="stat-item">
                  <span class="stat-number">{{ dashboardData.activityStats.today.messagesReceived }}</span>
                  <span class="stat-label">受信</span>
                </div>
                <div class="stat-item">
                  <span class="stat-number">{{ dashboardData.activityStats.today.messagesRead }}</span>
                  <span class="stat-label">既読</span>
                </div>
                <div class="stat-item">
                  <span class="stat-number">{{ dashboardData.pendingMessages }}</span>
                  <span class="stat-label">未読</span>
                </div>
              </div>
            </div>
            
            <!-- 今月の統計 -->
            <div class="stats-section">
              <h3>📊 今月の統計</h3>
              <div class="stats-grid">
                <div class="stat-item">
                  <span class="stat-number">{{ dashboardData.activityStats.thisMonth.messagesSent }}</span>
                  <span class="stat-label">送信</span>
                </div>
                <div class="stat-item">
                  <span class="stat-number">{{ dashboardData.activityStats.thisMonth.messagesReceived }}</span>
                  <span class="stat-label">受信</span>
                </div>
                <div class="stat-item">
                  <span class="stat-number">{{ dashboardData.activityStats.total.friends }}</span>
                  <span class="stat-label">友達</span>
                </div>
                <div class="stat-item">
                  <span class="stat-number">{{ dashboardData.scheduledMessages }}</span>
                  <span class="stat-label">予約</span>
                </div>
              </div>
            </div>
            
            <!-- 最近のメッセージ -->
            <div v-if="dashboardData.recentMessages.length > 0" class="recent-messages">
              <h3>📝 最近のメッセージ</h3>
              <div class="message-list">
                <div 
                  v-for="message in dashboardData.recentMessages.slice(0, 5)" 
                  :key="message.id"
                  class="message-item"
                >
                  <div class="message-type">
                    {{ getMessageTypeInfo(message).icon }}
                  </div>
                  <div class="message-content">
                    <div class="message-meta">
                      <span class="message-target">
                        {{ getMessageTypeInfo(message).label }}{{ getMessageTypeInfo(message).prefix }}
                      </span>
                      <span class="message-time">{{ formatDateTime(message.sentAt) }}</span>
                    </div>
                    <div class="message-text">{{ message.text.length > 50 ? message.text.substring(0, 50) + '...' : message.text }}</div>
                    <div class="message-status">
                      <span v-if="message.isRead" class="status-read">✓ 既読</span>
                      <span v-else class="status-unread">○ 未読</span>
                    </div>
                  </div>
                </div>
              </div>
              <button @click="goToHistory" class="btn btn-link">すべてのメッセージを見る →</button>
            </div>
          </div>
        </div>
        
        <div v-else class="unauthenticated-home">
          <p class="hero-subtitle">
            AIが様々なトーンでメッセージを変換し、<br>
            相手に配慮した伝え方をサポートします
          </p>
          <div class="hero-actions">
            <button @click="goToRegister" class="btn btn-primary">
              🚀 今すぐ始める
            </button>
            <button @click="goToLogin" class="btn btn-secondary">
              📱 ログイン
            </button>
          </div>
        </div>
      </div>
    </section>

    <section class="features">
      <div class="container">
        <h2>📋 主な機能</h2>
        <div class="features-grid">
          <div class="feature-card">
            <div class="feature-icon">🎭</div>
            <h3>AIトーン変換</h3>
            <p>やさしい・建設的・カジュアルなど、様々なトーンでメッセージを変換</p>
          </div>
          
          <div class="feature-card">
            <div class="feature-icon">⏰</div>
            <h3>配信時間設定</h3>
            <p>適切なタイミングでメッセージを配信</p>
          </div>
          
          <div class="feature-card">
            <div class="feature-icon">🔍</div>
            <h3>ユーザー検索</h3>
            <p>簡単に送信先を見つけて選択</p>
          </div>
          
          <div class="feature-card">
            <div class="feature-icon">💾</div>
            <h3>下書き保存</h3>
            <p>メッセージを下書きとして保存・管理</p>
          </div>
        </div>
      </div>
    </section>
    </main>
  </PageContainer>
</template>

<style scoped>
.home {
  min-height: 100vh;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
}

.hero {
  padding: 4rem 2rem;
  text-align: center;
  color: white;
}

.hero-content {
  max-width: 800px;
  margin: 0 auto;
}

.hero h1 {
  font-size: 3rem;
  margin-bottom: 1rem;
  text-shadow: 2px 2px 4px rgba(0, 0, 0, 0.3);
}

.hero-description {
  font-size: 1.5rem;
  margin-bottom: 1rem;
  opacity: 0.9;
}

.hero-subtitle {
  font-size: 1.1rem;
  margin-bottom: 2rem;
  opacity: 0.8;
  line-height: 1.6;
}

.hero-actions {
  display: flex;
  gap: 1rem;
  justify-content: center;
  align-items: center;
  flex-wrap: wrap;
}

.btn {
  padding: 1rem 2rem;
  border: none;
  border-radius: 8px;
  font-size: 1.1rem;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.3s ease;
  text-decoration: none;
  display: inline-block;
}

.btn-primary {
  background-color: #28a745;
  color: white;
}

.btn-primary:hover {
  background-color: #218838;
  transform: translateY(-2px);
  box-shadow: 0 4px 8px rgba(0, 0, 0, 0.2);
}

.btn-secondary {
  background-color: rgba(255, 255, 255, 0.2);
  color: white;
  border: 2px solid white;
}

.btn-secondary:hover {
  background-color: white;
  color: #667eea;
  transform: translateY(-2px);
}

.welcome-message {
  margin-bottom: 2rem;
  font-size: 1.2rem;
  opacity: 0.9;
  font-weight: 500;
}

.authenticated-home {
  width: 100%;
  max-width: 1000px;
}

.main-actions {
  display: flex;
  gap: 1rem;
  justify-content: center;
  margin-bottom: 3rem;
  flex-wrap: wrap;
}

.dashboard-stats {
  display: flex;
  flex-direction: column;
  gap: 2rem;
  margin-top: 2rem;
}

.stats-section {
  background: rgba(255, 255, 255, 0.1);
  backdrop-filter: blur(10px);
  border-radius: 12px;
  padding: 1.5rem;
}

.stats-section h3 {
  margin: 0 0 1rem 0;
  font-size: 1.2rem;
  font-weight: 600;
}

.stats-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(120px, 1fr));
  gap: 1rem;
}

.stat-item {
  display: flex;
  flex-direction: column;
  align-items: center;
  background: rgba(255, 255, 255, 0.2);
  border-radius: 8px;
  padding: 1rem;
  transition: transform 0.3s ease;
}

.stat-item:hover {
  transform: translateY(-2px);
}

.stat-number {
  font-size: 2rem;
  font-weight: bold;
  color: white;
  margin-bottom: 0.5rem;
}

.stat-label {
  font-size: 0.9rem;
  opacity: 0.8;
  font-weight: 500;
}

.recent-messages {
  background: rgba(255, 255, 255, 0.1);
  backdrop-filter: blur(10px);
  border-radius: 12px;
  padding: 1.5rem;
}

.recent-messages h3 {
  margin: 0 0 1rem 0;
  font-size: 1.2rem;
  font-weight: 600;
}

.message-list {
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
  margin-bottom: 1rem;
}

.message-item {
  display: flex;
  gap: 0.75rem;
  background: rgba(255, 255, 255, 0.15);
  border-radius: 8px;
  padding: 1rem;
  transition: background 0.3s ease;
}

.message-item:hover {
  background: rgba(255, 255, 255, 0.25);
}

.message-type {
  font-size: 1.5rem;
  flex-shrink: 0;
}

.message-content {
  flex: 1;
  min-width: 0;
}

.message-meta {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 0.5rem;
  gap: 1rem;
}

.message-target {
  font-weight: 500;
  font-size: 0.9rem;
}

.message-time {
  font-size: 0.8rem;
  opacity: 0.7;
  flex-shrink: 0;
}

.message-text {
  font-size: 0.9rem;
  line-height: 1.4;
  margin-bottom: 0.5rem;
  opacity: 0.9;
}

.message-status {
  display: flex;
  align-items: center;
}

.status-read {
  color: #4ade80;
  font-size: 0.8rem;
  font-weight: 500;
}

.status-unread {
  color: #fbbf24;
  font-size: 0.8rem;
  font-weight: 500;
}

.btn-link {
  background: none;
  border: none;
  color: white;
  text-decoration: underline;
  font-size: 0.9rem;
  cursor: pointer;
  opacity: 0.8;
  transition: opacity 0.3s ease;
}

.btn-link:hover {
  opacity: 1;
}

.loading-state, .error-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 1rem;
  padding: 2rem;
  background: rgba(255, 255, 255, 0.1);
  backdrop-filter: blur(10px);
  border-radius: 12px;
  margin-top: 2rem;
}

.spinner {
  width: 40px;
  height: 40px;
  border: 4px solid rgba(255, 255, 255, 0.3);
  border-left-color: white;
  border-radius: 50%;
  animation: spin 1s linear infinite;
}

@keyframes spin {
  to {
    transform: rotate(360deg);
  }
}

.unauthenticated-home {
  text-align: center;
}

.features {
  background-color: white;
  padding: 4rem 2rem;
}

.container {
  max-width: 1200px;
  margin: 0 auto;
}

.features h2 {
  text-align: center;
  font-size: 2.5rem;
  margin-bottom: 3rem;
  color: #333;
}

.features-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
  gap: 2rem;
}

.feature-card {
  background-color: #f8f9fa;
  padding: 2rem;
  border-radius: 12px;
  text-align: center;
  transition: transform 0.3s ease, box-shadow 0.3s ease;
}

.feature-card:hover {
  transform: translateY(-5px);
  box-shadow: 0 8px 25px rgba(0, 0, 0, 0.1);
}

.feature-icon {
  font-size: 3rem;
  margin-bottom: 1rem;
}

.feature-card h3 {
  font-size: 1.3rem;
  margin-bottom: 1rem;
  color: #333;
}

.feature-card p {
  color: #666;
  line-height: 1.6;
}

@media (max-width: 768px) {
  .hero h1 {
    font-size: 2rem;
  }
  
  .hero-description {
    font-size: 1.2rem;
  }
  
  .hero-actions {
    flex-direction: column;
  }
  
  .btn {
    width: 100%;
    max-width: 300px;
  }
}
</style>
