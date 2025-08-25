<template>
  <PageContainer>
    <form @submit.prevent="handleRegister" class="register-form">
      <h2 class="form-title">新規登録</h2>
      
      <!-- エラーメッセージ -->
      <div v-if="authStore.error" class="error-message">
        {{ authStore.error }}
      </div>
      
      <!-- 名前 -->
      <div class="form-group">
        <label for="name" class="form-label">お名前</label>
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
        <label for="email" class="form-label">メールアドレス</label>
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
        <label for="password" class="form-label">パスワード</label>
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
        <label for="confirmPassword" class="form-label">パスワード（確認）</label>
        <input
          id="confirmPassword"
          v-model="confirmPassword"
          type="password"
          required
          :disabled="authStore.isLoading"
          placeholder="パスワードを再入力"
          class="form-input"
          :class="{ 
            'input-error': confirmPassword && password !== confirmPassword
          }"
        />
        <div v-if="password && confirmPassword && password !== confirmPassword" class="field-error">
          パスワードが一致しません
        </div>
      </div>
      
      <!-- 登録ボタン -->
      <div class="button-wrapper">
        <UnifiedButton
          type="submit"
          :disabled="authStore.isLoading || !isFormValid"
          variant="primary"
        >
          <span v-if="authStore.isLoading">登録中...</span>
          <span v-else>新規登録</span>
        </UnifiedButton>
      </div>
      
      <!-- ログインリンク -->
      <div class="register-link">
        <p>
          既にアカウントをお持ちの方は<br>
          <router-link to="/login" class="link">ログイン</router-link>
        </p>
      </div>
    </form>
  </PageContainer>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import { useRouter } from 'vue-router'
import { useJWTAuthStore } from '@/stores/jwtAuth'
import PageContainer from '@/components/layout/PageContainer.vue'
import UnifiedButton from '@/components/ui/UnifiedButton.vue'

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
    router.push('/home')
  } catch (err) {
    console.error('❌ 登録失敗:', err)
    // エラーはストアで管理されるため、ここでは何もしない
  }
}
</script>

<style scoped>
.register-form {
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

.field-error {
  color: var(--text-primary);
  font-size: var(--font-size-sm);
  margin-top: var(--spacing-sm);
  background: var(--error-color);
  padding: var(--spacing-xs);
  border-radius: var(--radius-xs);
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

@media (max-width: 440px) {
  .register-form {
    max-width: 100%;
    margin: 0;
    padding: 1rem;
  }
  
  .form-title {
    font-size: var(--font-size-xl);
  }
  
  .form-input {
    padding: var(--spacing-sm);
    font-size: 16px;
    min-height: 44px;
  }
  
  
  .form-group {
    margin-bottom: var(--spacing-md);
  }
  
  .register-link {
    margin-top: var(--spacing-lg);
    padding-top: var(--spacing-md);
  }
  
  .register-link p {
    font-size: var(--font-size-sm);
  }
  
}

</style>