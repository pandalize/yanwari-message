<template>
  <div class="firebase-register-view">
    <div class="container">
      <div class="header">
        <h1>✨ やんわり伝言 - 新規登録</h1>
        <p>Firebase認証でアカウントを作成してください</p>
      </div>
      
      <FirebaseRegisterForm />
    </div>
  </div>
</template>

<script setup lang="ts">
import FirebaseRegisterForm from '@/components/auth/FirebaseRegisterForm.vue'
</script>

<style scoped>
.firebase-register-view {
  min-height: 100vh;
  background: linear-gradient(135deg, #4facfe 0%, #00f2fe 100%);
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 1rem;
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