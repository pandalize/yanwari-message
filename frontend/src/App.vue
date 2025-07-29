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
        
        <RouterLink to="/recipient-select" class="nav-item">
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
        
        <RouterLink to="/friends" class="nav-item">
          <svg class="nav-icon" viewBox="0 0 24 24" fill="currentColor">
            <path d="M16 4c0-1.11.89-2 2-2s2 .89 2 2-.89 2-2 2-2-.89-2-2zM4 18v-4h3v4h2v-4h3l-2.5-7.5c-.28-.86-1.08-1.5-2-1.5s-1.72.64-2 1.5L1 14h3v4h0z"/>
          </svg>
          <span class="nav-text">友達</span>
        </RouterLink>
      </div>
      
      <!-- 設定・ログアウト -->
      <div class="nav-bottom">
        <RouterLink to="/settings" class="nav-item settings-item">
          <svg class="nav-icon" viewBox="0 0 24 24" fill="currentColor">
            <path d="M19.14,12.94c0.04-0.3,0.06-0.61,0.06-0.94c0-0.32-0.02-0.64-0.07-0.94l2.03-1.58c0.18-0.14,0.23-0.41,0.12-0.61 l-1.92-3.32c-0.12-0.22-0.37-0.29-0.59-0.22l-2.39,0.96c-0.5-0.38-1.03-0.7-1.62-0.94L14.4,2.81c-0.04-0.24-0.24-0.41-0.48-0.41 h-3.84c-0.24,0-0.43,0.17-0.47,0.41L9.25,5.35C8.66,5.59,8.12,5.92,7.63,6.29L5.24,5.33c-0.22-0.08-0.47,0-0.59,0.22L2.74,8.87 C2.62,9.08,2.66,9.34,2.86,9.48l2.03,1.58C4.84,11.36,4.8,11.69,4.8,12s0.02,0.64,0.07,0.94l-2.03,1.58 c-0.18,0.14-0.23,0.41-0.12,0.61l1.92,3.32c0.12,0.22,0.37,0.29,0.59,0.22l2.39-0.96c0.5,0.38,1.03,0.7,1.62,0.94l0.36,2.54 c0.05,0.24,0.24,0.41,0.48,0.41h3.84c0.24,0,0.44-0.17,0.47-0.41l0.36-2.54c0.59-0.24,1.13-0.56,1.62-0.94l2.39,0.96 c0.22,0.08,0.47,0,0.59-0.22l1.92-3.32c0.12-0.22,0.07-0.47-0.12-0.61L19.14,12.94z M12,15.6c-1.98,0-3.6-1.62-3.6-3.6 s1.62-3.6,3.6-3.6s3.6,1.62,3.6,3.6S13.98,15.6,12,15.6z"/>
          </svg>
          <span class="nav-text">設定</span>
        </RouterLink>
        
        <button @click="handleLogout" class="nav-item logout-item">
          <svg class="nav-icon" viewBox="0 0 24 24" fill="currentColor">
            <path d="M17 7l-1.41 1.41L18.17 11H8v2h10.17l-2.58 2.59L17 17l5-5zM4 5h8V3H4c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h8v-2H4V5z"/>
          </svg>
          <span class="nav-text">ログアウト</span>
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
  max-width: var(--max-width-content);
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
/* ===== 大画面対応 ===== */
@media (min-width: 1400px) {
  .sidebar {
    width: 90px;
  }
  
  .main-content.with-sidebar {
    margin-left: 90px;
  }
  
  .nav-item {
    padding: var(--spacing-lg) var(--spacing-md);
  }
  
  .nav-icon {
    width: 28px;
    height: 28px;
  }
  
  .nav-text {
    font-size: var(--font-size-sm);
  }
  
  .header-content {
    max-width: 1400px;
    padding: 0 var(--spacing-2xl);
  }
  
  .simple-header h1 {
    font-size: var(--font-size-4xl);
  }
  
  .auth-btn {
    padding: var(--spacing-md) var(--spacing-xl);
    font-size: var(--font-size-lg);
  }
}

/* タブレット表示 */
@media (max-width: 1199px) {
  .sidebar {
    width: 75px;
  }
  
  .main-content.with-sidebar {
    margin-left: 75px;
  }
  
  .nav-text {
    font-size: 11px;
  }
}

/* モバイル表示 */
@media (max-width: 767px) {
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
  
  .simple-header {
    padding: var(--spacing-lg) var(--spacing-md);
  }
  
  .header-content h1 {
    font-size: var(--font-size-2xl);
  }
}

/* 小さいモバイル表示 */
@media (max-width: 479px) {
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
  
  .simple-header {
    padding: var(--spacing-md);
  }
  
  .header-content {
    flex-direction: column;
    gap: var(--spacing-md);
    align-items: center;
  }
  
  .auth-buttons {
    gap: var(--spacing-sm);
  }
  
  .auth-btn {
    padding: var(--spacing-sm) var(--spacing-md);
    font-size: var(--font-size-sm);
  }
}

.settings-item {
  background: rgba(144, 238, 144, 0.3) !important;
  border: 1px solid rgba(144, 238, 144, 0.4) !important;
}

.settings-item:hover {
  background: rgba(144, 238, 144, 0.5) !important;
}
</style>
