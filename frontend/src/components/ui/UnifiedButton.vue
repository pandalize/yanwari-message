<template>
  <button 
    :class="buttonClasses" 
    :disabled="disabled"
    @click="$emit('click', $event)"
  >
    <slot>{{ text }}</slot>
  </button>
</template>

<script setup lang="ts">
import { computed } from 'vue'

interface Props {
  variant?: 'primary' | 'secondary'
  size?: 'standard'
  disabled?: boolean
  text?: string
  fullWidth?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  variant: 'primary',
  size: 'standard',
  disabled: false,
  text: '',
  fullWidth: false
})

defineEmits<{
  click: [event: MouseEvent]
}>()

const buttonClasses = computed(() => [
  'unified-btn',
  `btn-${props.variant}`,
  `btn-${props.size}`,
  { 'btn-full-width': props.fullWidth }
])
</script>

<style scoped>
.unified-btn {
  border: none;
  font-family: var(--font-family-main);
  font-weight: 500;
  cursor: pointer;
  transition: all 0.2s ease;
  display: flex;
  align-items: center;
  justify-content: center;
  box-sizing: border-box;
}

/* 統一サイズ */
.btn-standard {
  height: 48px;
  padding: 0 24px;
  font-size: var(--font-size-md);
  width: 200px;
  border-radius: 100px;
}

/* バリアント */
.btn-primary {
  background: var(--primary-color);
  color: var(--text-primary);
}

.btn-primary:hover:not(:disabled) {
  background: var(--primary-color-dark);
}

.btn-secondary {
  background: var(--border-color);
  color: var(--text-primary);
}

.btn-secondary:hover:not(:disabled) {
  background: var(--gray-color-dark);
}

/* フル幅 */
.btn-full-width {
  width: 100%;
}

/* 無効状態 */
.unified-btn:disabled {
  background: var(--gray-color-light);
  color: var(--text-muted);
  cursor: not-allowed;
}

/* モバイル版のみ中央配置 */
@media (max-width: 440px) {
  .unified-btn {
    margin: 0 auto;
    display: block;
  }
}
</style>