<template>
  <div class="firebase-login-form">
    <h2>🔥 Firebase ログイン</h2>
    
    <form @submit.prevent="handleLogin" class="login-form">
      <div class="form-group">
        <label for="email">メールアドレス</label>
        <input
          id="email"
          v-model="email"
          type="email"
          required
          placeholder="alice@yanwari.com"
          :disabled="isLoading"
        />
      </div>
      
      <div class="form-group">
        <label for="password">パスワード</label>
        <input
          id="password"
          v-model="password"
          type="password"
          required
          placeholder="パスワードを入力"
          :disabled="isLoading"
        />
      </div>
      
      <div v-if="error" class="error-message">
        ❌ {{ error }}
      </div>
      
      <button 
        type="submit" 
        :disabled="isLoading || !email || !password"
        class="login-button"
      >
        <span v-if="isLoading">🔄 ログイン中...</span>
        <span v-else>🚀 ログイン</span>
      </button>
    </form>
    
    <div class="demo-accounts">
      <h3>🧪 デモアカウント</h3>
      <div class="demo-buttons">
        <button 
          @click="setDemoAccount('alice')"
          class="demo-button alice"
          :disabled="isLoading"
        >
          👩 Alice Demo
        </button>
        <button 
          @click="setDemoAccount('bob')"
          class="demo-button bob"
          :disabled="isLoading"
        >
          👨 Bob Demo
        </button>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'

const router = useRouter()
const authStore = useAuthStore()

const email = ref('')
const password = ref('')

const { isLoading, error } = authStore

// ログイン処理
const handleLogin = async () => {
  try {
    await authStore.login(email.value, password.value)
    router.push('/') // ログイン成功後にホームページにリダイレクト
  } catch (err) {
    console.error('ログイン失敗:', err)
  }
}

// デモアカウントを設定
const setDemoAccount = (account: 'alice' | 'bob') => {
  if (account === 'alice') {
    email.value = 'alice@yanwari.com'
    password.value = 'AliceDemo123!'
  } else {
    email.value = 'bob@yanwari.com'
    password.value = 'BobDemo123!'
  }
}
</script>

<style scoped>
.firebase-login-form {
  max-width: 400px;
  margin: 2rem auto;
  padding: 2rem;
  border: 1px solid #ddd;
  border-radius: 8px;
  background: white;
}

.login-form {
  margin-bottom: 2rem;
}

.form-group {
  margin-bottom: 1rem;
}

.form-group label {
  display: block;
  margin-bottom: 0.5rem;
  font-weight: bold;
}

.form-group input {
  width: 100%;
  padding: 0.75rem;
  border: 1px solid #ccc;
  border-radius: 4px;
  font-size: 1rem;
}

.form-group input:disabled {
  background-color: #f5f5f5;
  cursor: not-allowed;
}

.error-message {
  color: #d32f2f;
  background-color: #ffebee;
  padding: 0.75rem;
  border-radius: 4px;
  margin-bottom: 1rem;
}

.login-button {
  width: 100%;
  padding: 0.75rem;
  background-color: #1976d2;
  color: white;
  border: none;
  border-radius: 4px;
  font-size: 1rem;
  cursor: pointer;
  transition: background-color 0.3s;
}

.login-button:hover:not(:disabled) {
  background-color: #1565c0;
}

.login-button:disabled {
  background-color: #ccc;
  cursor: not-allowed;
}

.demo-accounts {
  border-top: 1px solid #eee;
  padding-top: 1rem;
}

.demo-accounts h3 {
  margin-bottom: 1rem;
  text-align: center;
}

.demo-buttons {
  display: flex;
  gap: 1rem;
}

.demo-button {
  flex: 1;
  padding: 0.75rem;
  border: 1px solid #ddd;
  border-radius: 4px;
  background-color: #f9f9f9;
  cursor: pointer;
  transition: background-color 0.3s;
}

.demo-button:hover:not(:disabled) {
  background-color: #e3f2fd;
}

.demo-button:disabled {
  background-color: #f5f5f5;
  cursor: not-allowed;
}

.demo-button.alice {
  border-color: #e91e63;
}

.demo-button.bob {
  border-color: #2196f3;
}
</style>