<template>
  <div 
    class="message-container"
    :style="containerStyle"
  >
    <slot />
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'

interface Props {
  width?: string
  height?: string
  minHeight?: string
  maxHeight?: string
  padding?: string
  margin?: string
  marginTop?: string
  marginBottom?: string
  marginLeft?: string
  marginRight?: string
  gap?: string
}

const props = withDefaults(defineProps<Props>(), {
  width: '700px',
  minHeight: '100px'
})

const containerStyle = computed(() => {
  const style: Record<string, string> = {}
  
  if (props.width) style.width = props.width
  if (props.height) style.height = props.height
  if (props.minHeight) style.minHeight = props.minHeight
  if (props.maxHeight) style.maxHeight = props.maxHeight
  if (props.padding) style.padding = props.padding
  if (props.margin) style.margin = props.margin
  if (props.marginTop) style.marginTop = props.marginTop
  if (props.marginBottom) style.marginBottom = props.marginBottom
  if (props.marginLeft) style.marginLeft = props.marginLeft
  if (props.marginRight) style.marginRight = props.marginRight
  if (props.gap) style.gap = props.gap
  
  return style
})
</script>

<style scoped>
.message-container {
  background: var(--background-primary);
  border: 1px solid var(--border-color);
  border-radius: var(--radius-lg);
  overflow: hidden;
}

/* モバイル対応 - インラインスタイルより優先させるために!important使用 */
@media (max-width: 440px) {
  .message-container {
    width: 100% !important;
    max-width: none !important;
    margin-left: 0 !important;
    margin-right: 0 !important;
    box-sizing: border-box;
  }
}
</style>