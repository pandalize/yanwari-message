<template>
  <div class="schedule-list-view">
    <ScheduleList />
  </div>
</template>

<script setup lang="ts">
import ScheduleList from '@/components/schedule/ScheduleList.vue'
</script>

<style scoped>
.schedule-list-view {
  min-height: 100vh;
  background-color: #f8f9fa;
}
</style>