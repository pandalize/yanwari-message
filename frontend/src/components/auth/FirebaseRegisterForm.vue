<template>
  <div class="firebase-register-form">
    <h2>🔥 Firebase ユーザー登録</h2>
    
    <form @submit.prevent="handleRegister" class="register-form">
      <div class="form-group">
        <label for="name">表示名</label>
        <input
          id="name"
          v-model="name"
          type="text"
          required
          placeholder="山田太郎"
          :disabled="isLoading"
        />
      </div>
      
      <div class="form-group">
        <label for="email">メールアドレス</label>
        <input
          id="email"
          v-model="email"
          type="email"
          required
          placeholder="example@yanwari.com"
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
          placeholder="8文字以上のパスワード"
          minlength="8"
          :disabled="isLoading"
        />
      </div>
      
      <div class="form-group">
        <label for="confirmPassword">パスワード確認</label>
        <input
          id="confirmPassword"
          v-model="confirmPassword"
          type="password"
          required
          placeholder="パスワードを再入力"
          :disabled="isLoading"
        />
      </div>
      
      <div v-if="error" class="error-message">
        ❌ {{ error }}
      </div>
      
      <div v-if="passwordError" class="error-message">
        ❌ {{ passwordError }}
      </div>
      
      <button 
        type="submit" 
        :disabled="isLoading || !canSubmit"
        class="register-button"
      >
        <span v-if="isLoading">🔄 登録中...</span>
        <span v-else>✨ ユーザー登録</span>
      </button>
    </form>
    
    <div class="login-link">
      <p>既にアカウントをお持ちですか？</p>
      <router-link to="/login" class="link-button">
        🚀 ログインはこちら
      </router-link>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import { useRouter } from 'vue-router'
import { useJWTAuthStore } from '@/stores/jwtAuth'

const router = useRouter()
const authStore = useJWTAuthStore()

const name = ref('')
const email = ref('')
const password = ref('')
const confirmPassword = ref('')

const { isLoading, error } = authStore

// パスワード確認エラー
const passwordError = computed(() => {
  if (!password.value || !confirmPassword.value) return ''
  return password.value !== confirmPassword.value ? 'パスワードが一致しません' : ''
})

// 送信可能かどうか
const canSubmit = computed(() => {
  return name.value && 
         email.value && 
         password.value && 
         confirmPassword.value &&
         !passwordError.value &&
         password.value.length >= 8
})

// ユーザー登録処理
const handleRegister = async () => {
  if (!canSubmit.value) return
  
  try {
    await authStore.register(email.value, password.value, name.value)
    router.push('/') // 登録成功後にホームページにリダイレクト
  } catch (err) {
    console.error('ユーザー登録失敗:', err)
  }
}
</script>

<style scoped>
.firebase-register-form {
  max-width: 400px;
  margin: 2rem auto;
  padding: 2rem;
  border: 1px solid #ddd;
  border-radius: 8px;
  background: white;
}

.register-form {
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

.register-button {
  width: 100%;
  padding: 0.75rem;
  background-color: #4caf50;
  color: white;
  border: none;
  border-radius: 4px;
  font-size: 1rem;
  cursor: pointer;
  transition: background-color 0.3s;
}

.register-button:hover:not(:disabled) {
  background-color: #45a049;
}

.register-button:disabled {
  background-color: #ccc;
  cursor: not-allowed;
}

.login-link {
  text-align: center;
  border-top: 1px solid #eee;
  padding-top: 1rem;
}

.link-button {
  display: inline-block;
  margin-top: 0.5rem;
  padding: 0.5rem 1rem;  
  background-color: #1976d2;
  color: white;
  text-decoration: none;
  border-radius: 4px;
  transition: background-color 0.3s;
}

.link-button:hover {
  background-color: #1565c0;
}
</style>