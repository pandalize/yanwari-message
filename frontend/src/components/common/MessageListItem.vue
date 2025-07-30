<template>
  <div 
    class="message-list-item"
    :class="{ 'clickable': clickable }"
    :style="itemStyle"
    @click="handleClick"
  >
    <div v-if="$slots.left" class="item-left">
      <slot name="left" />
    </div>
    
    <div v-if="$slots.center" class="item-center">
      <slot name="center" />
    </div>
    
    <div v-if="$slots.content" class="item-content">
      <slot name="content" />
    </div>
    
    <div v-if="$slots.right || $slots.actions" class="item-right" @click.stop>
      <slot name="right" />
      <slot name="actions" />
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'

interface Props {
  clickable?: boolean
  width?: string
  height?: string
  minHeight?: string
  maxHeight?: string
  padding?: string
  paddingTop?: string
  paddingBottom?: string
  paddingLeft?: string
  paddingRight?: string
  margin?: string
  marginTop?: string
  marginBottom?: string
  marginLeft?: string
  marginRight?: string
  gap?: string
}

const props = withDefaults(defineProps<Props>(), {
  clickable: false,
  height: 'auto',
  minHeight: '60px',
  padding: 'var(--spacing-lg)'
})

const emit = defineEmits<{
  click: []
}>()

const itemStyle = computed(() => {
  const style: Record<string, string> = {}
  
  if (props.width) style.width = props.width
  if (props.height !== 'auto') style.height = props.height
  if (props.minHeight) style.minHeight = props.minHeight
  if (props.maxHeight) style.maxHeight = props.maxHeight
  if (props.padding) style.padding = props.padding
  if (props.paddingTop) style.paddingTop = props.paddingTop
  if (props.paddingBottom) style.paddingBottom = props.paddingBottom
  if (props.paddingLeft) style.paddingLeft = props.paddingLeft
  if (props.paddingRight) style.paddingRight = props.paddingRight
  if (props.margin) style.margin = props.margin
  if (props.marginTop) style.marginTop = props.marginTop
  if (props.marginBottom) style.marginBottom = props.marginBottom
  if (props.marginLeft) style.marginLeft = props.marginLeft
  if (props.marginRight) style.marginRight = props.marginRight
  if (props.gap) style.gap = props.gap
  
  return style
})

const handleClick = () => {
  if (props.clickable) {
    emit('click')
  }
}
</script>

<style scoped>
.message-list-item {
  display: flex;
  align-items: center;
  border-bottom: 1px solid var(--background-muted);
  transition: background-color 0.2s ease;
  border-radius: var(--radius-md);
}

.message-list-item:hover {
  background: var(--background-secondary);
}

.message-list-item.clickable {
  cursor: pointer;
}

.message-list-item:last-child {
  border-bottom: none;
}

.item-left {
  flex: 1;
  min-width: 200px;
}

.item-center {
  flex: 1;
  text-align: center;
}

.item-content {
  flex: 1;
  min-width: 200px;
  padding-right: var(--spacing-lg);
}

.item-right {
  display: flex;
  gap: var(--spacing-sm);
  flex-shrink: 0;
  position: relative;
  z-index: 1;
  cursor: default;
  pointer-events: auto;
}
</style>