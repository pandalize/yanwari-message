<template>
  <div class="login-view">
    <PageContainer>
      <PageTitle title="やんわり伝言 - ログイン" />
      <JWTLoginForm />
    </PageContainer>
  </div>
</template>

<script setup lang="ts">
import PageContainer from '@/components/layout/PageContainer.vue'
import PageTitle from '@/components/layout/PageTitle.vue'
import JWTLoginForm from '@/components/auth/JWTLoginForm.vue'
</script>

<style scoped>
.login-view {
  min-height: 100vh;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 1rem;
}
</style>