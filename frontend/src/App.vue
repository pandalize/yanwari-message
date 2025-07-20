<script setup lang="ts">
import { RouterLink, RouterView } from 'vue-router'
import { useAuthStore } from '@/stores/auth'

const authStore = useAuthStore()

const handleLogout = async () => {
  await authStore.logout()
}
</script>

<template>
  <div class="app-layout">
    <!-- サイドバーナビゲーション -->
    <nav class="sidebar" v-if="authStore.isAuthenticated">
      <div class="nav-items">
        <RouterLink to="/" class="nav-item">
          <svg class="nav-icon" viewBox="0 0 24 24" fill="currentColor">
            <path d="M10 20v-6h4v6h5v-8h3L12 3 2 12h3v8z"/>
          </svg>
          <span class="nav-text">ホーム</span>
        </RouterLink>
        
        <RouterLink to="/compose" class="nav-item">
          <svg class="nav-icon" viewBox="0 0 24 24" fill="currentColor">
            <path d="M2.01 21L23 12 2.01 3 2 10l15 2-15 2z"/>
          </svg>
          <span class="nav-text">送信</span>
        </RouterLink>
        
        <RouterLink to="/inbox" class="nav-item">
          <svg class="nav-icon" viewBox="0 0 24 24" fill="currentColor">
            <path d="M20 4H4c-1.1 0-1.99.9-1.99 2L2 18c0 1.1.9 2 2 2h16c1.1 0 2-.9 2-2V6c0-1.1-.9-2-2-2zm0 4l-8 5-8-5V6l8 5 8-5v2z"/>
          </svg>
          <span class="nav-text">受信</span>
        </RouterLink>
        
        <RouterLink to="/schedules" class="nav-item">
          <svg class="nav-icon" viewBox="0 0 24 24" fill="currentColor">
            <path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/>
          </svg>
          <span class="nav-text">履歴</span>
        </RouterLink>
      </div>
      
      <!-- 設定・ログアウト -->
      <div class="nav-bottom">
        <button @click="handleLogout" class="nav-item logout-item">
          <svg class="nav-icon" viewBox="0 0 24 24" fill="currentColor">
            <path d="M12 2C13.1 2 14 2.9 14 4C14 5.1 13.1 6 12 6C10.9 6 10 5.1 10 4C10 2.9 10.9 2 12 2ZM21 9V7L19 5.73C18.18 5.26 17.24 5 16.24 5H7.76C6.76 5 5.82 5.26 5 5.73L3 7V9C3 9.55 3.45 10 4 10S5 9.55 5 9V8.41L6.12 7.59C6.68 7.21 7.34 7 8.03 7H15.97C16.66 7 17.32 7.21 17.88 7.59L19 8.41V9C19 9.55 19.45 10 20 10S21 9.55 21 9ZM12 17.5L6.5 12H9.5C10.33 12 11 12.67 11 13.5V16H13V13.5C13 12.67 13.67 12 14.5 12H17.5L12 17.5Z"/>
          </svg>
          <span class="nav-text">設定</span>
        </button>
      </div>
    </nav>

    <!-- 認証されていない場合の簡易ヘッダー -->
    <header v-else class="simple-header">
      <div class="header-content">
        <h1>やんわり伝言</h1>
        <div class="auth-buttons">
          <RouterLink to="/login" class="auth-btn">ログイン</RouterLink>
          <RouterLink to="/register" class="auth-btn primary">新規登録</RouterLink>
        </div>
      </div>
    </header>

    <!-- メインコンテンツ -->
    <main class="main-content" :class="{ 'with-sidebar': authStore.isAuthenticated }">
      <RouterView />
    </main>
  </div>
</template>

<style scoped>
.app-layout {
  display: flex;
  min-height: 100vh;
  background: var(--background-primary);
}

/* ===== サイドバーナビゲーション ===== */
.sidebar {
  width: 80px;
  background: linear-gradient(180deg, var(--primary-color) 0%, var(--secondary-color) 100%);
  display: flex;
  flex-direction: column;
  justify-content: space-between;
  padding: var(--spacing-lg) 0;
  box-shadow: var(--shadow-md);
  position: fixed;
  left: 0;
  top: 0;
  height: 100vh;
  z-index: 1000;
}

.nav-items {
  display: flex;
  flex-direction: column;
  gap: var(--spacing-md);
  padding: 0 var(--spacing-sm);
}

.nav-item {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: var(--spacing-xs);
  padding: var(--spacing-md) var(--spacing-sm);
  border-radius: var(--radius-lg);
  text-decoration: none;
  color: var(--text-primary);
  transition: all 0.3s ease;
  background: rgba(255, 255, 255, 0.1);
  backdrop-filter: blur(10px);
  border: 1px solid rgba(255, 255, 255, 0.2);
}

.nav-item:hover {
  background: rgba(255, 255, 255, 0.25);
  transform: translateY(-2px);
  box-shadow: var(--shadow-md);
}

.nav-item.router-link-exact-active {
  background: var(--neutral-color);
  color: var(--text-primary);
  box-shadow: var(--shadow-lg);
  font-weight: 600;
}

.nav-icon {
  width: 24px;
  height: 24px;
  flex-shrink: 0;
}

.nav-text {
  font-size: var(--font-size-xs);
  font-weight: 500;
  text-align: center;
  white-space: nowrap;
  font-family: var(--font-family-main);
}

.nav-bottom {
  padding: 0 var(--spacing-sm);
}

.logout-item {
  background: rgba(255, 155, 155, 0.3) !important;
  border: 1px solid rgba(255, 155, 155, 0.4) !important;
}

.logout-item:hover {
  background: rgba(255, 155, 155, 0.5) !important;
}

/* ===== 認証前ヘッダー ===== */
.simple-header {
  width: 100%;
  background: linear-gradient(135deg, var(--primary-color) 0%, var(--secondary-color) 100%);
  padding: var(--spacing-lg) 0;
  box-shadow: var(--shadow-sm);
}

.header-content {
  max-width: 1200px;
  margin: 0 auto;
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 0 var(--spacing-lg);
}

.simple-header h1 {
  margin: 0;
  color: var(--text-primary);
  font-size: var(--font-size-3xl);
  font-weight: 600;
  font-family: var(--font-family-main);
}

.auth-buttons {
  display: flex;
  gap: var(--spacing-md);
}

.auth-btn {
  text-decoration: none;
  color: var(--text-primary);
  padding: var(--spacing-sm) var(--spacing-lg);
  border-radius: var(--radius-lg);
  font-weight: 500;
  font-size: var(--font-size-md);
  transition: all 0.3s ease;
  background: rgba(255, 255, 255, 0.2);
  backdrop-filter: blur(10px);
  border: 1px solid rgba(255, 255, 255, 0.3);
}

.auth-btn:hover {
  background: rgba(255, 255, 255, 0.4);
  transform: translateY(-2px);
  box-shadow: var(--shadow-md);
}

.auth-btn.primary {
  background: var(--neutral-color);
  color: var(--text-primary);
  font-weight: 600;
}

.auth-btn.primary:hover {
  background: var(--gray-color-light);
}

/* ===== メインコンテンツ ===== */
.main-content {
  flex: 1;
  background: var(--background-primary);
  min-height: 100vh;
  transition: margin-left 0.3s ease;
}

.main-content.with-sidebar {
  margin-left: 80px;
}

/* ===== レスポンシブ対応 ===== */
@media (max-width: 768px) {
  .sidebar {
    width: 70px;
  }
  
  .main-content.with-sidebar {
    margin-left: 70px;
  }
  
  .nav-text {
    font-size: 10px;
  }
  
  .nav-icon {
    width: 20px;
    height: 20px;
  }
  
  .nav-item {
    padding: var(--spacing-sm) var(--spacing-xs);
  }
}

@media (max-width: 480px) {
  .sidebar {
    width: 60px;
  }
  
  .main-content.with-sidebar {
    margin-left: 60px;
  }
  
  .nav-text {
    display: none;
  }
  
  .nav-item {
    padding: var(--spacing-md);
  }
}
</style>
