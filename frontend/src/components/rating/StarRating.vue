<template>
  <div class="star-rating">
    <div class="stars-container">
      <button
        v-for="star in 5"
        :key="star"
        class="star-button"
        :class="{
          'star-filled': star <= (hoveredRating || currentRating),
          'star-empty': star > (hoveredRating || currentRating),
          'star-interactive': !readonly
        }"
        :disabled="readonly || loading"
        @click="handleStarClick(star)"
        @mouseenter="handleStarHover(star)"
        @mouseleave="handleStarLeave"
        :title="getStarTitle(star)"
      >
        <svg
          class="star-icon"
          viewBox="0 0 24 24"
          :fill="star <= (hoveredRating || currentRating) ? '#fbbf24' : 'none'"
          :stroke="star <= (hoveredRating || currentRating) ? '#fbbf24' : '#d1d5db'"
          stroke-width="2"
        >
          <polygon points="12,2 15,8 22,8.5 17,13 18.5,20 12,16.5 5.5,20 7,13 2,8.5 9,8" />
        </svg>
      </button>
    </div>
    
    <div v-if="showLabel" class="rating-label">
      <span v-if="currentRating > 0" class="rating-text">
        {{ getRatingText(hoveredRating || currentRating) }}
      </span>
      <span v-else class="no-rating-text">
        評価なし
      </span>
    </div>

    <div v-if="loading" class="loading-indicator">
      <span class="loading-text">保存中...</span>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, watch } from 'vue'

// Props
interface Props {
  modelValue?: number // v-model対応
  readonly?: boolean
  showLabel?: boolean
  size?: 'small' | 'medium' | 'large'
  loading?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  modelValue: 0,
  readonly: false,
  showLabel: true,
  size: 'medium',
  loading: false
})

// Events
const emit = defineEmits<{
  'update:modelValue': [value: number]
  'rate': [rating: number]
}>()

// State
const hoveredRating = ref<number>(0)
const currentRating = ref<number>(props.modelValue)

// Watch for external changes
watch(() => props.modelValue, (newValue) => {
  currentRating.value = newValue
})

// Methods
const handleStarClick = (rating: number) => {
  if (props.readonly || props.loading) return
  
  // 同じ星をクリックした場合は評価をリセット
  const newRating = currentRating.value === rating ? 0 : rating
  
  currentRating.value = newRating
  emit('update:modelValue', newRating)
  emit('rate', newRating)
}

const handleStarHover = (rating: number) => {
  if (props.readonly || props.loading) return
  hoveredRating.value = rating
}

const handleStarLeave = () => {
  if (props.readonly || props.loading) return
  hoveredRating.value = 0
}

const getRatingText = (rating: number): string => {
  const texts = {
    1: '不満',
    2: 'やや不満',
    3: '普通',
    4: '良い',
    5: 'とても良い'
  }
  return texts[rating as keyof typeof texts] || ''
}

const getStarTitle = (star: number): string => {
  if (props.readonly) {
    return `評価: ${currentRating.value}/5`
  }
  return `${star}つ星で評価`
}

// Computed
const starSize = computed(() => {
  const sizes = {
    small: '16px',
    medium: '20px',
    large: '24px'
  }
  return sizes[props.size]
})
</script>

<style scoped>
.star-rating {
  display: flex;
  flex-direction: column;
  align-items: flex-start;
  gap: 8px;
}

.stars-container {
  display: flex;
  gap: 4px;
}

.star-button {
  background: none;
  border: none;
  padding: 2px;
  cursor: pointer;
  transition: transform 0.15s ease;
  border-radius: 4px;
}

.star-button:disabled {
  cursor: default;
}

.star-button.star-interactive:hover {
  transform: scale(1.1);
}

.star-button:focus {
  outline: 2px solid #3b82f6;
  outline-offset: 2px;
}

.star-icon {
  width: v-bind(starSize);
  height: v-bind(starSize);
  transition: all 0.15s ease;
}

.star-filled .star-icon {
  filter: drop-shadow(0 1px 2px rgba(0, 0, 0, 0.1));
}

.rating-label {
  font-size: 14px;
  min-height: 20px;
  display: flex;
  align-items: center;
}

.rating-text {
  color: #374151;
  font-weight: 500;
}

.no-rating-text {
  color: #9ca3af;
}

.loading-indicator {
  display: flex;
  align-items: center;
  gap: 8px;
}

.loading-text {
  font-size: 12px;
  color: #6b7280;
}

/* レスポンシブ対応 */
@media (max-width: 768px) {
  .star-rating {
    align-items: center;
  }
  
  .rating-label {
    text-align: center;
    font-size: 12px;
  }
}

/* ダークモード対応（必要に応じて） */
@media (prefers-color-scheme: dark) {
  .rating-text {
    color: #f3f4f6;
  }
  
  .no-rating-text {
    color: #6b7280;
  }
  
  .loading-text {
    color: #9ca3af;
  }
}
</style>