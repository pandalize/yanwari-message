<template>
  <h1 class="page-title">
    <slot />
  </h1>
</template>

<script setup lang="ts">
// PageTitle: 全ページで統一されたページタイトル
</script>

<style scoped>
.page-title {
  color: var(--text-primary);
  font-size: 24px;
  font-weight: 600;
  font-family: var(--font-family-main);
  line-height: var(--line-height-base);
  margin: 0 0 32px 0;
}
</style>