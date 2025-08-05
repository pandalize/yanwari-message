<template>
  <PageContainer>
    <PageTitle>受信トレイ</PageTitle>
    <InboxList />
  </PageContainer>
</template>

<script setup lang="ts">
import PageContainer from '@/components/layout/PageContainer.vue'
import PageTitle from '@/components/layout/PageTitle.vue'
import InboxList from '../components/inbox/InboxList.vue'
</script>

<style scoped>
/* PageContainerで統一されたスタイルを使用 */
</style>