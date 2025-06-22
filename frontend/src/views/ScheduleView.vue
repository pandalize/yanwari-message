<template>
  <div class="schedule-view">
    <ScheduleWizard />
  </div>
</template>

<script setup lang="ts">
import ScheduleWizard from '@/components/schedule/ScheduleWizard.vue'
</script>

<style scoped>
.schedule-view {
  min-height: 100vh;
  background-color: #f8f9fa;
}
</style>