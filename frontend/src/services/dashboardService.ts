import apiService from './api'

// 活動統計
export interface ActivityStats {
  today: {
    messagesSent: number
    messagesReceived: number
    messagesRead: number
  }
  thisMonth: {
    messagesSent: number
    messagesReceived: number
    messagesRead: number
  }
  total: {
    messagesSent: number
    messagesReceived: number
    friends: number
  }
}

// 最近のメッセージ
export interface RecentMessage {
  id: string
  type: 'sent' | 'received'
  senderName?: string
  senderEmail?: string
  recipientName?: string
  recipientEmail?: string
  text: string
  sentAt: string
  readAt?: string
  isRead: boolean
}

// ダッシュボード情報
export interface DashboardData {
  activityStats: ActivityStats
  recentMessages: RecentMessage[]
  pendingMessages: number
  scheduledMessages: number
}

// 送信状況
export interface DeliveryStatus {
  messageId: string
  status: string
  sentAt?: string
  deliveredAt?: string
  readAt?: string
  recipientName: string
  text: string
  errorMessage?: string
}

// 送信状況一覧
export interface DeliveryStatusResponse {
  statuses: DeliveryStatus[]
  total: number
  page: number
  limit: number
  totalPages: number
}

class DashboardService {
  /**
   * ダッシュボード情報を取得
   */
  async getDashboard(): Promise<DashboardData> {
    try {
      const response = await apiService.get<{ data: DashboardData }>('/dashboard')
      return response.data.data
    } catch (error) {
      console.error('ダッシュボード情報取得エラー:', error)
      throw new Error('ダッシュボード情報の取得に失敗しました')
    }
  }

  /**
   * 送信状況一覧を取得
   */
  async getDeliveryStatuses(page: number = 1, limit: number = 20): Promise<DeliveryStatusResponse> {
    try {
      const response = await apiService.get<{ data: DeliveryStatusResponse }>('/delivery-status', {
        params: { page, limit }
      })
      return response.data.data
    } catch (error) {
      console.error('送信状況取得エラー:', error)
      throw new Error('送信状況の取得に失敗しました')
    }
  }
}

export default new DashboardService()