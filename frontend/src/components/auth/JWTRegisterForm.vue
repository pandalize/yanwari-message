<template>
  <div class="jwt-register-form">
    <form @submit.prevent="handleRegister" class="register-form">
      <h2 class="form-title">新規登録</h2>
      
      <!-- エラーメッセージ -->
      <div v-if="authStore.error" class="error-message">
        {{ authStore.error }}
      </div>
      
      <!-- 名前 -->
      <div class="form-group">
        <label for="name">お名前</label>
        <input
          id="name"
          v-model="name"
          type="text"
          required
          :disabled="authStore.isLoading"
          placeholder="例: 田中 あかり"
          class="form-input"
        />
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
          placeholder="例: example@yanwari-message.com"
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
          placeholder="8文字以上のパスワード"
          class="form-input"
          minlength="8"
        />
      </div>
      
      <!-- パスワード確認 -->
      <div class="form-group">
        <label for="confirmPassword">パスワード（確認）</label>
        <input
          id="confirmPassword"
          v-model="confirmPassword"
          type="password"
          required
          :disabled="authStore.isLoading"
          placeholder="パスワードを再入力"
          class="form-input"
        />
        <div v-if="password && confirmPassword && password !== confirmPassword" class="field-error">
          パスワードが一致しません
        </div>
      </div>
      
      <!-- 登録ボタン -->
      <button
        type="submit"
        :disabled="authStore.isLoading || !isFormValid"
        class="register-button"
      >
        <span v-if="authStore.isLoading">登録中...</span>
        <span v-else>新規登録</span>
      </button>
      
      <!-- ログインリンク -->
      <div class="login-link">
        <p>
          既にアカウントをお持ちの方は
          <router-link to="/login" class="link">ログイン</router-link>
        </p>
      </div>
    </form>
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

const isFormValid = computed(() => {
  return name.value.trim() && 
         email.value.trim() && 
         password.value.length >= 8 && 
         password.value === confirmPassword.value
})

const handleRegister = async () => {
  if (!isFormValid.value) {
    authStore.error = 'すべての項目を正しく入力してください'
    return
  }
  
  try {
    await authStore.register(email.value, password.value, name.value)
    console.log('✅ 登録成功、ホームページにリダイレクト')
    router.push('/')
  } catch (err) {
    console.error('❌ 登録失敗:', err)
    // エラーはストアで管理されるため、ここでは何もしない
  }
}
</script>

<style scoped>
.jwt-register-form {
  max-width: 400px;
  margin: 0 auto;
  padding: 2rem;
}

.register-form {
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

.field-error {
  color: #c33;
  font-size: 0.875rem;
  margin-top: 0.25rem;
}

.register-button {
  width: 100%;
  padding: 0.75rem;
  background: #28a745;
  color: white;
  border: none;
  border-radius: 4px;
  font-size: 1rem;
  font-weight: 500;
  cursor: pointer;
  transition: background-color 0.3s;
}

.register-button:hover:not(:disabled) {
  background: #218838;
}

.register-button:disabled {
  background: #ccc;
  cursor: not-allowed;
}

.login-link {
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
</style>