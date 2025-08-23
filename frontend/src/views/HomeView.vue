<script setup lang="ts">
import { useJWTAuthStore } from '@/stores/jwtAuth'
import { useRouter } from 'vue-router'
import PageContainer from '@/components/layout/PageContainer.vue'

const authStore = useJWTAuthStore()
const router = useRouter()

const goToCompose = () => {
  router.push('/compose')
}

const goToLogin = () => {
  router.push('/login')
}

const goToRegister = () => {
  router.push('/register')
}

const goToHistory = () => {
  console.log('HomeView: Attempting to navigate to /history')
  router.push('/history').then(() => {
    console.log('HomeView: Navigation to /history successful')
  }).catch((error) => {
    console.error('HomeView: Navigation to /history failed:', error)
  })
}
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
        <p class="hero-subtitle">
          AIが様々なトーンでメッセージを変換し、<br>
          相手に配慮した伝え方をサポートします
        </p>
        
        <div v-if="authStore.isAuthenticated" class="hero-actions">
          <button @click="goToCompose" class="btn btn-primary">
            📝 メッセージを作成する
          </button>
          <button @click="goToHistory" class="btn btn-secondary">
            📋 履歴を見る
          </button>
          <p class="welcome-message">
            お帰りなさい、{{ authStore.user?.name || authStore.user?.email }}さん
          </p>
        </div>
        
        <div v-else class="hero-actions">
          <button @click="goToRegister" class="btn btn-primary">
            🚀 今すぐ始める
          </button>
          <button @click="goToLogin" class="btn btn-secondary">
            📱 ログイン
          </button>
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
  border-radius: var(--radius-md);
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
  margin-top: 1rem;
  font-size: 1rem;
  opacity: 0.9;
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
  border-radius: var(--radius-lg);
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
