<template>
  <div class="page-container">
    <slot />
  </div>
</template>

<script setup lang="ts">
// PageContainer: 全ページで統一されたレイアウトコンテナ
</script>

<style scoped>
.page-container {
  padding: 32px 20px;
  min-height: 100vh;
  background: var(--background-primary);
  box-sizing: border-box;
  width: 100%;
  font-family: var(--font-family-main);
}

@media (min-width: 768px) {
  .page-container {
    padding: 32px 40px;
  }
}

@media (min-width: 1200px) {
  .page-container {
    padding: 32px 80px;
    max-width: 1400px;
    margin: 0 auto;
  }
}
</style>