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
  min-height: 100vh;
  background-color: #f8f9fa;
  overflow-y: auto;
}

/* モバイル対応 */
@media (max-width: 440px) {
  .schedule-wizard-view {
    padding: 20px;
    height: auto;
    overflow: visible;
  }
}
</style>