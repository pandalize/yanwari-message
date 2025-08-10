<template>
  <PageContainer>
    <div class="firebase-login-view">
      <div class="header">
        <PageTitle>🔥 やんわり伝言 - Firebase認証</PageTitle>
        <p>Firebase認証でログインしてください</p>
      </div>
      
      <FirebaseLoginForm />
      
      <div class="register-link">
        <p>アカウントをお持ちでない方は</p>
        <router-link to="/firebase-register" class="link-button">
          ✨ ユーザー登録
        </router-link>
      </div>
    </div>
  </PageContainer>
</template>

<script setup lang="ts">
import PageContainer from '@/components/layout/PageContainer.vue'
import PageTitle from '@/components/layout/PageTitle.vue'
import FirebaseLoginForm from '@/components/auth/FirebaseLoginForm.vue'
</script>

<style scoped>
.firebase-login-view {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  display: flex;
  align-items: center;
  justify-content: center;
}

.container {
  width: 100%;
  max-width: 500px;
}

.header {
  text-align: center;
  margin-bottom: 2rem;
  color: white;
}

.header h1 {
  font-size: 2rem;
  margin-bottom: 0.5rem;
}

.register-link {
  text-align: center;
  margin-top: 2rem;
  color: white;
}

.link-button {
  display: inline-block;
  margin-top: 0.5rem;
  padding: 0.75rem 1.5rem;
  background-color: rgba(255, 255, 255, 0.2);
  color: white;
  text-decoration: none;
  border-radius: 4px;
  border: 1px solid rgba(255, 255, 255, 0.3);
  transition: background-color 0.3s;
}

.link-button:hover {
  background-color: rgba(255, 255, 255, 0.3);
}
</style>