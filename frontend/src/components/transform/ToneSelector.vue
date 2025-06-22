<template>
  <div class="tone-selector">
    <!-- ローディング状態 -->
    <div v-if="transformStore.isTransforming" class="loading-state">
      <div class="loading-spinner"></div>
      <h3>🎭 AI がトーンを変換中...</h3>
      <p>優しめ・建設的・カジュアルの3つのトーンで変換しています</p>
    </div>

    <!-- エラー状態 -->
    <div v-else-if="transformStore.error" class="error-state">
      <h3>❌ 変換エラー</h3>
      <p>{{ transformStore.error }}</p>
      <button @click="retry" class="retry-btn">
        🔄 再試行
      </button>
    </div>

    <!-- トーン選択状態 -->
    <div v-else-if="transformStore.variations.length > 0" class="tone-selection">
      <h3>🎭 トーンを選択してください</h3>
      <p class="selection-guide">お相手に最適なトーンを選んでください</p>

      <div class="tone-options">
        <div
          v-for="variation in transformStore.variations"
          :key="variation.tone"
          class="tone-option"
          :class="{ selected: transformStore.selectedTone === variation.tone }"
          @click="selectTone(variation.tone)"
        >
          <div class="tone-header">
            <span class="tone-label">
              {{ transformStore.toneLabels[variation.tone] }}
            </span>
            <span v-if="transformStore.selectedTone === variation.tone" class="selected-icon">
              ✅
            </span>
          </div>
          <div class="tone-text">
            "{{ variation.text }}"
          </div>
        </div>
      </div>

      <!-- 選択したトーンの確認 -->
      <div v-if="transformStore.selectedTone" class="selected-confirmation">
        <div class="confirmation-header">
          <span class="confirmation-icon">👍</span>
          <span class="confirmation-text">
            {{ transformStore.toneLabels[transformStore.selectedTone] }} を選択しました
          </span>
        </div>
        <div class="final-text">
          "{{ transformStore.getSelectedText() }}"
        </div>
      </div>
    </div>

    <!-- 初期状態（変換前） -->
    <div v-else class="initial-state">
      <div class="transform-prompt">
        <h3>🎭 トーン変換</h3>
        <p>メッセージを3つのトーンで変換できます</p>
        <div class="tone-preview">
          <div class="tone-preview-item">
            <span class="preview-icon">💝</span>
            <span>優しめトーン</span>
          </div>
          <div class="tone-preview-item">
            <span class="preview-icon">🏗️</span>
            <span>建設的トーン</span>
          </div>
          <div class="tone-preview-item">
            <span class="preview-icon">🎯</span>
            <span>カジュアルトーン</span>
          </div>
        </div>
        <button 
          @click="startTransform" 
          class="transform-btn"
          :disabled="!canTransform"
        >
          🎭 トーン変換を開始
        </button>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { defineEmits, defineProps } from 'vue'
import { useTransformStore } from '@/stores/transform'

// Props
const props = defineProps<{
  messageId: string
  originalText: string
}>()

// Emits
const emit = defineEmits<{
  toneSelected: [tone: string, text: string]
}>()

// Store
const transformStore = useTransformStore()

// Computed
const canTransform = (): boolean => {
  return props.messageId !== '' && props.originalText.trim() !== ''
}

// Methods
const startTransform = async () => {
  if (!canTransform()) return
  
  await transformStore.transformMessage(props.messageId, props.originalText)
}

const selectTone = (tone: string) => {
  transformStore.selectTone(tone)
  const selectedText = transformStore.getSelectedText()
  emit('toneSelected', tone, selectedText)
}

const retry = () => {
  startTransform()
}
</script>

<style scoped>
.tone-selector {
  max-width: 800px;
  margin: 0 auto;
  padding: 20px;
}

/* ローディング状態 */
.loading-state {
  text-align: center;
  padding: 40px 20px;
}

.loading-spinner {
  width: 40px;
  height: 40px;
  border: 4px solid #f3f3f3;
  border-top: 4px solid #2563eb;
  border-radius: 50%;
  animation: spin 1s linear infinite;
  margin: 0 auto 20px;
}

@keyframes spin {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}

.loading-state h3 {
  color: #2563eb;
  margin-bottom: 10px;
}

.loading-state p {
  color: #6b7280;
}

/* エラー状態 */
.error-state {
  text-align: center;
  padding: 40px 20px;
  background-color: #fef2f2;
  border: 1px solid #fecaca;
  border-radius: 8px;
}

.error-state h3 {
  color: #dc2626;
  margin-bottom: 10px;
}

.error-state p {
  color: #7f1d1d;
  margin-bottom: 20px;
}

.retry-btn {
  background-color: #dc2626;
  color: white;
  border: none;
  padding: 10px 20px;
  border-radius: 6px;
  cursor: pointer;
  font-size: 14px;
}

.retry-btn:hover {
  background-color: #b91c1c;
}

/* トーン選択状態 */
.tone-selection h3 {
  text-align: center;
  color: #1f2937;
  margin-bottom: 10px;
}

.selection-guide {
  text-align: center;
  color: #6b7280;
  margin-bottom: 30px;
}

.tone-options {
  display: flex;
  flex-direction: column;
  gap: 20px;
  margin-bottom: 30px;
}

.tone-option {
  border: 2px solid #e5e7eb;
  border-radius: 12px;
  padding: 20px;
  cursor: pointer;
  transition: all 0.2s ease;
  background-color: #fff;
}

.tone-option:hover {
  border-color: #2563eb;
  box-shadow: 0 4px 12px rgba(37, 99, 235, 0.1);
}

.tone-option.selected {
  border-color: #2563eb;
  background-color: #eff6ff;
  box-shadow: 0 4px 12px rgba(37, 99, 235, 0.2);
}

.tone-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 12px;
}

.tone-label {
  font-size: 16px;
  font-weight: 600;
  color: #1f2937;
}

.selected-icon {
  font-size: 18px;
}

.tone-text {
  font-size: 14px;
  line-height: 1.6;
  color: #374151;
  background-color: #f9fafb;
  padding: 12px;
  border-radius: 8px;
  border-left: 4px solid #e5e7eb;
}

.tone-option.selected .tone-text {
  background-color: #dbeafe;
  border-left-color: #2563eb;
}

/* 選択確認 */
.selected-confirmation {
  background-color: #f0fdf4;
  border: 1px solid #bbf7d0;
  border-radius: 8px;
  padding: 20px;
}

.confirmation-header {
  display: flex;
  align-items: center;
  gap: 10px;
  margin-bottom: 12px;
}

.confirmation-icon {
  font-size: 20px;
}

.confirmation-text {
  font-weight: 600;
  color: #15803d;
}

.final-text {
  font-size: 14px;
  line-height: 1.6;
  color: #166534;
  background-color: #dcfce7;
  padding: 12px;
  border-radius: 8px;
  border-left: 4px solid #22c55e;
}

/* 初期状態 */
.initial-state {
  text-align: center;
  padding: 40px 20px;
}

.transform-prompt h3 {
  color: #1f2937;
  margin-bottom: 10px;
}

.transform-prompt p {
  color: #6b7280;
  margin-bottom: 30px;
}

.tone-preview {
  display: flex;
  justify-content: center;
  gap: 20px;
  margin-bottom: 30px;
  flex-wrap: wrap;
}

.tone-preview-item {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 10px 16px;
  background-color: #f9fafb;
  border-radius: 8px;
  font-size: 14px;
  color: #374151;
}

.preview-icon {
  font-size: 16px;
}

.transform-btn {
  background-color: #2563eb;
  color: white;
  border: none;
  padding: 12px 24px;
  border-radius: 8px;
  font-size: 16px;
  font-weight: 600;
  cursor: pointer;
  transition: background-color 0.2s ease;
}

.transform-btn:hover:not(:disabled) {
  background-color: #1d4ed8;
}

.transform-btn:disabled {
  background-color: #9ca3af;
  cursor: not-allowed;
}

/* レスポンシブ対応 */
@media (max-width: 768px) {
  .tone-selector {
    padding: 15px;
  }
  
  .tone-preview {
    flex-direction: column;
    align-items: center;
  }
  
  .tone-options {
    gap: 15px;
  }
  
  .tone-option {
    padding: 15px;
  }
}
</style>