<template>
  <div style="padding: 20px;">
    <h1>Test History View</h1>
    <p>This is a simple test page to verify routing is working.</p>
    <p>Current route: {{ $route.path }}</p>
    <p>Route name: {{ $route.name }}</p>
    <button @click="goToActualHistory">Go to Actual History</button>
  </div>
</template>

<script setup lang="ts">
import { useRouter } from 'vue-router'

const router = useRouter()

const goToActualHistory = () => {
  console.log('Attempting to navigate to actual history view')
  router.push('/history').then(() => {
    console.log('Navigation successful')
  }).catch((error) => {
    console.error('Navigation failed:', error)
  })
}
</script>