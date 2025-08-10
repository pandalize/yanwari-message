import { defineStore } from 'pinia'
import { ref } from 'vue'
import { transformService, type ToneVariation, type ToneTransformRequest } from '@/services/transformService'

export interface TransformState {
  isTransforming: boolean
  variations: ToneVariation[]
  selectedTone: string
  error: string | null
}

export const useTransformStore = defineStore('transform', () => {
  // State
  const isTransforming = ref(false)
  const variations = ref<ToneVariation[]>([])
  const selectedTone = ref('')
  const error = ref<string | null>(null)

  // トーン表示名マッピング
  const toneLabels = {
    gentle: '💝 優しめトーン',
    constructive: '🏗️ 建設的トーン', 
    casual: '🎯 カジュアルトーン'
  }

  // Actions
  /**
   * メッセージを3つのトーンに変換
   */
  const transformMessage = async (messageId: string, originalText: string) => {
    isTransforming.value = true
    error.value = null
    variations.value = []
    selectedTone.value = ''

    try {
      const request: ToneTransformRequest = {
        messageId,
        originalText
      }

      const response = await transformService.transformToTones(request)
      variations.value = response.variations
      
      console.log('トーン変換完了:', response.variations)
    } catch (err: any) {
      error.value = err.response?.data?.error || 'トーン変換に失敗しました'
      console.error('トーン変換エラー:', err)
    } finally {
      isTransforming.value = false
    }
  }

  /**
   * トーンを選択
   */
  const selectTone = (tone: string) => {
    selectedTone.value = tone
  }

  /**
   * 選択されたトーンのテキストを取得
   */
  const getSelectedText = (): string => {
    if (!selectedTone.value) return ''
    const variation = variations.value.find(v => v.tone === selectedTone.value)
    return variation?.text || ''
  }

  /**
   * 状態をリセット
   */
  const reset = () => {
    isTransforming.value = false
    variations.value = []
    selectedTone.value = ''
    error.value = null
  }

  return {
    // State
    isTransforming,
    variations,
    selectedTone,
    error,
    toneLabels,
    
    // Actions
    transformMessage,
    selectTone,
    getSelectedText,
    reset,
  }
})