<template>
  <PageContainer>
    <div class="firebase-register-view">
      <div class="header">
        <PageTitle>✨ やんわり伝言 - 新規登録</PageTitle>
        <p>Firebase認証でアカウントを作成してください</p>
      </div>
      
      <FirebaseRegisterForm />
    </div>
  </PageContainer>
</template>

<script setup lang="ts">
import PageContainer from '@/components/layout/PageContainer.vue'
import PageTitle from '@/components/layout/PageTitle.vue'
import FirebaseRegisterForm from '@/components/auth/FirebaseRegisterForm.vue'
</script>

<style scoped>
.firebase-register-view {
  background: linear-gradient(135deg, #4facfe 0%, #00f2fe 100%);
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
</style>