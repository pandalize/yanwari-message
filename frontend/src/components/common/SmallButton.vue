<template>
  <button 
    @click="handleClick"
    class="small-btn"
    :title="title"
  >
    {{ text }}
  </button>
</template>

<script setup lang="ts">
interface Props {
  text?: string
  title?: string
}

withDefaults(defineProps<Props>(), {
  text: 'ボタン',
  title: 'ボタン'
})

const emit = defineEmits<{
  click: []
}>()

const handleClick = (event: Event) => {
  event.stopPropagation()
  emit('click')
}
</script>

<style scoped>
.small-btn {
  padding: var(--spacing-sm) var(--spacing-md);
  border: none;
  border-radius: var(--radius-sm);
  background: var(--primary-color);
  color: var(--text-primary);
  cursor: pointer;
  font-size: var(--font-size-sm);
  font-family: var(--font-family-main);
  font-weight: var(--font-weight-regular);
}
</style>