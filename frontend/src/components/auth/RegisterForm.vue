<template>
  <div class="register-form">
    <h2>新規登録</h2>
    <form @submit.prevent="handleRegister">
      <div class="form-group">
        <label for="name">お名前</label>
        <input
          id="name"
          v-model="form.name"
          type="text"
          required
          placeholder="山田太郎"
        />
      </div>
      
      <div class="form-group">
        <label for="email">メールアドレス</label>
        <input
          id="email"
          v-model="form.email"
          type="email"
          required
          placeholder="example@email.com"
        />
      </div>
      
      <div class="form-group">
        <label for="password">パスワード</label>
        <input
          id="password"
          v-model="form.password"
          type="password"
          required
          placeholder="8文字以上のパスワード"
        />
        <small class="password-hint">パスワードは8文字以上である必要があります</small>
      </div>
      
      <div class="form-group">
        <label for="confirmPassword">パスワード確認</label>
        <input
          id="confirmPassword"
          v-model="form.confirmPassword"
          type="password"
          required
          placeholder="パスワードを再入力"
        />
      </div>
      
      <button type="submit" :disabled="isLoading || !isFormValid">
        {{ isLoading ? '登録中...' : '新規登録' }}
      </button>
      
      <div v-if="error" class="error-message">
        {{ error }}
      </div>
    </form>
    
    <p>
      既にアカウントをお持ちの方は
      <router-link to="/login">ログイン</router-link>
    </p>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, computed } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'

const router = useRouter()
const authStore = useAuthStore()

const form = reactive({
  name: '',
  email: '',
  password: '',
  confirmPassword: ''
})

const isLoading = ref(false)
const error = ref('')

const isFormValid = computed(() => {
  return form.name &&
         form.email && 
         form.password && 
         form.confirmPassword && 
         form.password === form.confirmPassword &&
         form.password.length >= 8
})

const handleRegister = async () => {
  isLoading.value = true
  error.value = ''
  
  if (form.password !== form.confirmPassword) {
    error.value = 'パスワードが一致しません'
    isLoading.value = false
    return
  }
  
  if (form.password.length < 8) {
    error.value = 'パスワードは8文字以上である必要があります'
    isLoading.value = false
    return
  }
  
  try {
    const success = await authStore.register({
      name: form.name,
      email: form.email,
      password: form.password
    })
    
    if (success) {
      router.push('/')
    } else {
      error.value = authStore.error || 'ユーザー登録に失敗しました'
    }
  } catch (err) {
    error.value = 'ユーザー登録に失敗しました'
  } finally {
    isLoading.value = false
  }
}
</script>

<style scoped>
.register-form {
  max-width: 400px;
  margin: 0 auto;
  padding: 2rem;
}

.form-group {
  margin-bottom: 1rem;
}

label {
  display: block;
  margin-bottom: 0.5rem;
  font-weight: bold;
}

input {
  width: 100%;
  padding: 0.75rem;
  border: 1px solid #ddd;
  border-radius: 4px;
  font-size: 1rem;
}

.password-hint {
  display: block;
  margin-top: 0.25rem;
  color: #666;
  font-size: 0.875rem;
}

button {
  width: 100%;
  padding: 0.75rem;
  background-color: #28a745;
  color: white;
  border: none;
  border-radius: 4px;
  font-size: 1rem;
  cursor: pointer;
}

button:disabled {
  background-color: #6c757d;
  cursor: not-allowed;
}

.error-message {
  color: #dc3545;
  margin-top: 1rem;
  text-align: center;
}

p {
  text-align: center;
  margin-top: 1.5rem;
}

a {
  color: #007bff;
  text-decoration: none;
}

a:hover {
  text-decoration: underline;
}
</style>