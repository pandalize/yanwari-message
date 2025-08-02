import { apiService } from './api'

// メッセージ評価データ型
export interface MessageRating {
  id: string
  messageId: string
  rating: number
  createdAt: string
  updatedAt: string
}

// 評価付きメッセージデータ型
export interface InboxMessageWithRating {
  id: string
  senderId: string
  senderName: string
  senderEmail: string
  originalText: string
  finalText: string
  status: string
  rating?: number
  ratingId?: string
  createdAt: string
  sentAt?: string
  deliveredAt?: string
  readAt?: string
}

// ページネーション情報
export interface PaginationInfo {
  page: number
  limit: number
  total: number
  totalPages: number
}

// 評価付き受信トレイレスポンス
export interface InboxWithRatingsResponse {
  messages: InboxMessageWithRating[]
  pagination: PaginationInfo
}

// 評価リクエスト
export interface RateMessageRequest {
  rating: number
}

// API応答フォーマット
interface ApiResponse<T> {
  message: string
  data: T
}

class RatingService {
  // メッセージを評価
  async rateMessage(messageId: string, rating: number): Promise<MessageRating> {
    const response = await apiService.post(`/messages/${messageId}/rate`, {
      rating
    })
    return response.data.data
  }

  // メッセージの評価を取得
  async getMessageRating(messageId: string): Promise<MessageRating | null> {
    try {
      const response = await apiService.get(`/messages/${messageId}/rating`)
      return response.data.data
    } catch (error: any) {
      if (error.response?.status === 404) {
        return null // 評価が存在しない場合
      }
      throw error
    }
  }

  // メッセージの評価を削除
  async deleteMessageRating(messageId: string): Promise<void> {
    await apiService.delete(`/messages/${messageId}/rating`)
  }

  // 評価付き受信トレイを取得
  async getInboxWithRatings(page: number = 1, limit: number = 20): Promise<InboxWithRatingsResponse> {
    const params = new URLSearchParams({
      page: page.toString(),
      limit: limit.toString()
    })
    
    const response = await apiService.get(`/messages/inbox-with-ratings?${params}`)
    return response.data.data
  }

  // 評価を更新（既存評価がある場合）
  async updateMessageRating(messageId: string, rating: number): Promise<MessageRating> {
    // rateMessage は内部的に作成または更新を行う
    return this.rateMessage(messageId, rating)
  }

  // メッセージを既読にする
  async markAsRead(messageId: string): Promise<void> {
    const response = await apiService.post(`/messages/${messageId}/read`)
    // バックエンドは200ステータスで{"message": "..."}を返すため、エラーチェックは不要
    // レスポンスが正常でない場合は apiService 側で例外が投げられる
  }
}

export const ratingService = new RatingService()