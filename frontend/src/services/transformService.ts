import { apiService } from './api'

// トーン変換リクエスト
export interface ToneTransformRequest {
  messageId: string
  originalText: string
}

// トーン変換結果
export interface ToneVariation {
  tone: string
  text: string
}

// トーン変換レスポンス
export interface ToneTransformResponse {
  messageId: string
  variations: ToneVariation[]
}

/**
 * メッセージを3つのトーンに変換
 */
export const transformToTones = async (request: ToneTransformRequest): Promise<ToneTransformResponse> => {
  console.log('[TransformService] API呼び出し開始:', request)
  
  try {
    const response = await apiService.post('/transform/tones', request)
    console.log('[TransformService] API生レスポンス:', response)
    console.log('[TransformService] レスポンスデータ:', response.data)
    console.log('[TransformService] 変換結果:', response.data.data)
    
    if (!response.data || !response.data.data) {
      throw new Error('APIレスポンスの形式が正しくありません')
    }
    
    const result = response.data.data
    console.log('[TransformService] 返却データ:', result)
    
    return result
  } catch (error: any) {
    console.error('[TransformService] APIエラー:', error)
    console.error('[TransformService] エラー詳細:', {
      message: error.message,
      status: error.response?.status,
      statusText: error.response?.statusText,
      data: error.response?.data,
      code: error.code
    })
    throw error
  }
}

/**
 * トーン変換サービス
 */
export const transformService = {
  transformToTones,
}