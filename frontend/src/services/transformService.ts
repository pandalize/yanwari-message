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
  const response = await apiService.post('/transform/tones', request)
  return response.data.data
}

/**
 * トーン変換サービス
 */
export const transformService = {
  transformToTones,
}