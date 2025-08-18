<template>
  <div class="jwt-login-form">
    <form @submit.prevent="handleLogin" class="login-form">
      <h2 class="form-title">ログイン</h2>
      
      <!-- エラーメッセージ -->
      <div v-if="authStore.error" class="error-message">
        {{ authStore.error }}
      </div>
      
      <!-- メールアドレス -->
      <div class="form-group">
        <label for="email">メールアドレス</label>
        <input
          id="email"
          v-model="email"
          type="email"
          required
          :disabled="authStore.isLoading"
          placeholder="例: alice@yanwari-message.com"
          class="form-input"
        />
      </div>
      
      <!-- パスワード -->
      <div class="form-group">
        <label for="password">パスワード</label>
        <input
          id="password"
          v-model="password"
          type="password"
          required
          :disabled="authStore.isLoading"
          placeholder="パスワードを入力"
          class="form-input"
        />
      </div>
      
      <!-- ログインボタン -->
      <button
        type="submit"
        :disabled="authStore.isLoading"
        class="login-button"
      >
        <span v-if="authStore.isLoading">ログイン中...</span>
        <span v-else>ログイン</span>
      </button>
      
      <!-- 登録リンク -->
      <div class="register-link">
        <p>
          アカウントをお持ちでない方は
          <router-link to="/register" class="link">新規登録</router-link>
        </p>
      </div>
      
      <!-- テストアカウント情報 -->
      <div class="test-accounts">
        <h3>🧪 テストアカウント</h3>
        <div class="test-account-list">
          <div class="test-account" @click="fillTestAccount('alice@yanwari-message.com')">
            <strong>👩 田中 あかり</strong><br>
            <small>alice@yanwari-message.com</small>
          </div>
          <div class="test-account" @click="fillTestAccount('bob@yanwari-message.com')">
            <strong>👨 佐藤 ひろし</strong><br>
            <small>bob@yanwari-message.com</small>
          </div>
          <div class="test-account" @click="fillTestAccount('charlie@yanwari-message.com')">
            <strong>👩 鈴木 みゆき</strong><br>
            <small>charlie@yanwari-message.com</small>
          </div>
        </div>
        <p class="test-note">
          <small>パスワード: password123（クリックで自動入力）</small>
        </p>
      </div>
    </form>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { useJWTAuthStore } from '@/stores/jwtAuth'

const router = useRouter()
const authStore = useJWTAuthStore()

const email = ref('')
const password = ref('')

const handleLogin = async () => {
  try {
    await authStore.login(email.value, password.value)
    console.log('✅ ログイン成功、ホームページにリダイレクト')
    router.push('/')
  } catch (err) {
    console.error('❌ ログイン失敗:', err)
    // エラーはストアで管理されるため、ここでは何もしない
  }
}

const fillTestAccount = (testEmail: string) => {
  email.value = testEmail
  password.value = 'password123'
}
</script>

<style scoped>
.jwt-login-form {
  max-width: 400px;
  margin: 0 auto;
  padding: 2rem;
}

.login-form {
  background: white;
  padding: 2rem;
  border-radius: 8px;
  box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
}

.form-title {
  text-align: center;
  margin-bottom: 2rem;
  color: #333;
  font-size: 1.5rem;
}

.error-message {
  background: #fee;
  color: #c33;
  padding: 0.75rem;
  border-radius: 4px;
  margin-bottom: 1rem;
  border: 1px solid #fcc;
  font-size: 0.9rem;
}

.form-group {
  margin-bottom: 1.5rem;
}

.form-group label {
  display: block;
  margin-bottom: 0.5rem;
  font-weight: 500;
  color: #555;
}

.form-input {
  width: 100%;
  padding: 0.75rem;
  border: 1px solid #ddd;
  border-radius: 4px;
  font-size: 1rem;
  transition: border-color 0.3s;
}

.form-input:focus {
  outline: none;
  border-color: #007bff;
  box-shadow: 0 0 0 2px rgba(0, 123, 255, 0.25);
}

.form-input:disabled {
  background: #f5f5f5;
  cursor: not-allowed;
}

.login-button {
  width: 100%;
  padding: 0.75rem;
  background: #007bff;
  color: white;
  border: none;
  border-radius: 4px;
  font-size: 1rem;
  font-weight: 500;
  cursor: pointer;
  transition: background-color 0.3s;
}

.login-button:hover:not(:disabled) {
  background: #0056b3;
}

.login-button:disabled {
  background: #ccc;
  cursor: not-allowed;
}

.register-link {
  text-align: center;
  margin-top: 1.5rem;
  padding-top: 1.5rem;
  border-top: 1px solid #eee;
}

.link {
  color: #007bff;
  text-decoration: none;
}

.link:hover {
  text-decoration: underline;
}

.test-accounts {
  margin-top: 2rem;
  padding-top: 2rem;
  border-top: 1px solid #eee;
}

.test-accounts h3 {
  text-align: center;
  color: #666;
  margin-bottom: 1rem;
  font-size: 1rem;
}

.test-account-list {
  display: grid;
  gap: 0.5rem;
  margin-bottom: 1rem;
}

.test-account {
  padding: 0.75rem;
  background: #f8f9fa;
  border-radius: 4px;
  cursor: pointer;
  transition: background-color 0.3s;
  text-align: center;
}

.test-account:hover {
  background: #e9ecef;
}

.test-account strong {
  color: #333;
}

.test-account small {
  color: #666;
}

.test-note {
  text-align: center;
  color: #666;
  margin: 0;
}
</style>