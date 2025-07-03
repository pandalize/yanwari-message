<template>
  <div class="inbox-view">
    <InboxList />
  </div>
</template>

<script setup lang="ts">
import InboxList from '../components/inbox/InboxList.vue'
</script>

<style scoped>
.inbox-view {
  min-height: 100vh;
  background: #f8f9fa;
  padding-top: 2rem;
}
</style>