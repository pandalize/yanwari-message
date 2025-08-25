<template>
  <PageContainer>
      <form @submit.prevent="handleLogin" class="login-form">
          <h2 class="form-title">ログイン</h2>
      
      <!-- エラーメッセージ -->
      <div v-if="authStore.error" class="error-message">
        {{ authStore.error }}
      </div>
      
      <!-- メールアドレス -->
      <div class="form-group">
        <label for="email" class="form-label">メールアドレス</label>
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
        <label for="password" class="form-label">パスワード</label>
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
      <div class="button-wrapper">
        <UnifiedButton
          type="submit"
          :disabled="authStore.isLoading"
          variant="primary"
        >
          <span v-if="authStore.isLoading">ログイン中...</span>
          <span v-else>ログイン</span>
        </UnifiedButton>
      </div>
      
      <!-- 登録リンク -->
      <div class="register-link">
        <p>
          アカウントをお持ちでない方は<br>
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
  </PageContainer>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { useJWTAuthStore } from '@/stores/jwtAuth'
import PageContainer from '@/components/layout/PageContainer.vue'
import UnifiedButton from '@/components/ui/UnifiedButton.vue'

const router = useRouter()
const authStore = useJWTAuthStore()

const email = ref('')
const password = ref('')

const handleLogin = async () => {
  try {
    await authStore.login(email.value, password.value)
    console.log('✅ ログイン成功、ホームページにリダイレクト')
    router.push('/home')
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
.login-form {
  max-width: 400px;
  margin: 0 auto;
  background: white;
  padding: 2.5rem;
  padding-top: 2.5rem;
  padding-bottom: 2.5rem;
}

.form-title {
  text-align: center;
  margin-bottom: var(--spacing-xl);
  color: var(--text-primary);
  font-size: var(--font-size-2xl);
  line-height: 1.2;
  font-weight: 600;
}

.error-message {
  background: var(--error-color);
  color: var(--text-primary);
  padding: var(--spacing-md);
  border-radius: var(--radius-sm);
  margin-bottom: var(--spacing-md);
  font-size: var(--font-size-sm);
}

.form-group {
  margin-bottom: var(--spacing-lg);
}

.form-label {
  display: block;
  margin-bottom: var(--spacing-sm);
  font-weight: 500;
  color: var(--text-secondary);
}

.form-input {
  width: 100%;
  padding: var(--spacing-md);
  border: none;
  border-radius: var(--radius-sm);
  font-size: var(--font-size-md);
  background: var(--gray-color-light);
}

.form-input:focus {
  outline: none;
  background: var(--neutral-color);
  box-shadow: 0 0 0 2px var(--secondary-color);
}

.form-input:disabled {
  background: var(--background-muted);
  cursor: not-allowed;
  opacity: 0.7;
}

.form-input::placeholder {
  color: var(--text-tertiary);
}

.button-wrapper {
  display: flex;
  justify-content: center;
  margin-top: var(--spacing-lg);
}


.register-link {
  text-align: center;
  margin-top: var(--spacing-lg);
  padding-top: var(--spacing-lg);
}

.link {
  color: var(--secondary-color);
  text-decoration: none;
}

.link:hover {
  color: var(--secondary-color-dark);
  text-decoration: underline;
}

.test-accounts {
  margin-top: var(--spacing-xl);
  padding-top: var(--spacing-xl);
}

.test-accounts h3 {
  text-align: center;
  color: var(--text-secondary);
  margin-bottom: var(--spacing-md);
  font-size: var(--font-size-md);
}

.test-account-list {
  display: grid;
  gap: var(--spacing-sm);
  margin-bottom: var(--spacing-md);
}

.test-account {
  padding: var(--spacing-md);
  background: var(--gray-color-light);
  border-radius: var(--radius-sm);
  cursor: pointer;
  transition: background-color 0.3s;
  text-align: center;
}

.test-account:hover {
  background: var(--gray-color);
}

.test-account strong {
  color: var(--text-primary);
}

.test-account small {
  color: var(--text-secondary);
}

.test-note {
  text-align: center;
  color: var(--text-secondary);
  margin: 0;
}

@media (max-width: 440px) {
  .login-form {
    max-width: 100%;
    margin: 0;
    padding: 1rem;
  }
  
  .form-title {
    font-size: var(--font-size-xl);
  }
  
  .form-group {
    margin-bottom: var(--spacing-md);
  }
  
  .form-input {
    padding: var(--spacing-sm);
    font-size: 16px;
    min-height: 44px;
  }
  
  
  .register-link {
    margin-top: var(--spacing-lg);
    padding-top: var(--spacing-md);
  }
  
  .register-link p {
    font-size: var(--font-size-sm);
  }
  
  .test-accounts {
    margin-top: var(--spacing-md);
    padding-top: var(--spacing-md);
  }
  
  .test-accounts h3 {
    font-size: var(--font-size-sm);
    margin-bottom: var(--spacing-sm);
  }
  
  .test-account-list {
    gap: var(--spacing-xs);
  }
  
  .test-account {
    padding: var(--spacing-sm);
    font-size: var(--font-size-sm);
    min-height: 44px;
    display: flex;
    flex-direction: column;
    justify-content: center;
  }
  
  .test-account strong {
    font-size: var(--font-size-sm);
  }
  
  .test-account small {
    font-size: var(--font-size-xs);
  }
  
  .test-note {
    font-size: var(--font-size-xs);
  }
}

</style>