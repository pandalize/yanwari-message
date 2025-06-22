<script setup lang="ts">
import { RouterLink, RouterView } from 'vue-router'
import { useAuthStore } from '@/stores/auth'

const authStore = useAuthStore()

const handleLogout = async () => {
  await authStore.logout()
}
</script>

<template>
  <header>
    <div class="wrapper">
      <h1>やんわり伝言</h1>

      <nav>
        <RouterLink to="/">ホーム</RouterLink>
        <RouterLink to="/about">概要</RouterLink>
        
        <div v-if="authStore.isAuthenticated" class="auth-nav">
          <RouterLink to="/compose" class="compose-link">✏️ メッセージ作成</RouterLink>
          <RouterLink to="/schedules" class="schedule-link">📅 スケジュール一覧</RouterLink>
          <span class="user-info">{{ authStore.user?.name || authStore.user?.email }}</span>
          <button @click="handleLogout" class="logout-btn">ログアウト</button>
        </div>
        
        <div v-else class="auth-nav">
          <RouterLink to="/login">ログイン</RouterLink>
          <RouterLink to="/register">新規登録</RouterLink>
        </div>
      </nav>
    </div>
  </header>

  <RouterView />
</template>

<style scoped>
header {
  background-color: #fff;
  border-bottom: 1px solid #e0e0e0;
  padding: 1rem 0;
}

.wrapper {
  max-width: 1200px;
  margin: 0 auto;
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 0 1rem;
}

h1 {
  margin: 0;
  color: #333;
  font-size: 1.5rem;
}

nav {
  display: flex;
  align-items: center;
  gap: 1rem;
}

nav a {
  text-decoration: none;
  color: #007bff;
  padding: 0.5rem 1rem;
  border-radius: 4px;
  transition: background-color 0.2s;
}

nav a:hover {
  background-color: #f0f0f0;
}

nav a.router-link-exact-active {
  background-color: #007bff;
  color: white;
}

.auth-nav {
  display: flex;
  align-items: center;
  gap: 1rem;
}

.user-info {
  color: #666;
  font-size: 0.9rem;
}

.logout-btn {
  background-color: #dc3545;
  color: white;
  border: none;
  padding: 0.5rem 1rem;
  border-radius: 4px;
  cursor: pointer;
  font-size: 0.9rem;
  transition: background-color 0.2s;
}

.logout-btn:hover {
  background-color: #c82333;
}

.compose-link {
  background-color: #28a745 !important;
  color: white !important;
  font-weight: 600;
}

.compose-link:hover {
  background-color: #218838 !important;
}
</style>
