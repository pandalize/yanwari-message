<template>
  <div class="schedule-wizard-view">
    <ScheduleWizard />
  </div>
</template>

<script setup lang="ts">
import ScheduleWizard from '@/components/schedule/ScheduleWizard.vue'
</script>

<style scoped>
.schedule-wizard-view {
  height: 100vh;
  background-color: #f8f9fa;
  overflow: hidden;
}
</style>