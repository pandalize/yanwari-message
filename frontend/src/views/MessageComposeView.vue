<template>
  <div class="message-compose-view">
    <MessageComposer />
  </div>
</template>

<script setup lang="ts">
import MessageComposer from '@/components/messages/MessageComposer.vue'
</script>

<style scoped>
.message-compose-view {
  min-height: 100vh;
  background-color: #f5f5f5;
  padding: 1rem;
}
</style>