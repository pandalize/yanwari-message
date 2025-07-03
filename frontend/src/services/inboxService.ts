import { apiService } from './api'

// 受信メッセージの型定義
export interface ReceivedMessage {
  id: string
  senderId: string
  recipientId: string
  originalText: string
  variations: {
    gentle?: string
    constructive?: string
    casual?: string
  }
  selectedTone?: string
  finalText?: string
  status: 'sent' | 'delivered' | 'read'
  createdAt: string
  updatedAt: string
  sentAt?: string
  readAt?: string
}

// 受信メッセージ一覧のレスポンス
export interface ReceivedMessagesResponse {
  messages: ReceivedMessage[]
  pagination: {
    page: number
    limit: number
    total: number
  }
}

// 受信メッセージサービス
class InboxService {
  // 受信メッセージ一覧を取得
  async getReceivedMessages(page = 1, limit = 20): Promise<ReceivedMessagesResponse> {
    const response = await apiService.get(`/messages/received?page=${page}&limit=${limit}`)
    return response.data.data
  }

  // メッセージを既読にする
  async markAsRead(messageId: string): Promise<void> {
    await apiService.post(`/messages/${messageId}/read`)
  }

  // 受信メッセージの詳細を取得
  async getReceivedMessage(messageId: string): Promise<ReceivedMessage> {
    const response = await apiService.get(`/messages/${messageId}`)
    return response.data.data
  }

  // メッセージの送信日時をフォーマット
  formatSentTime(sentAt: string): string {
    const date = new Date(sentAt)
    const now = new Date()
    
    const isToday = date.toDateString() === now.toDateString()
    const isYesterday = date.toDateString() === new Date(now.getTime() - 24 * 60 * 60000).toDateString()
    
    const timeStr = date.toLocaleTimeString('ja-JP', { 
      hour: '2-digit', 
      minute: '2-digit' 
    })
    
    if (isToday) {
      return `今日 ${timeStr}`
    } else if (isYesterday) {
      return `昨日 ${timeStr}`
    } else {
      return `${date.toLocaleDateString('ja-JP')} ${timeStr}`
    }
  }

  // メッセージの状態に応じたバッジテキスト
  getStatusBadge(status: string): { text: string, color: string } {
    switch (status) {
      case 'sent':
        return { text: '配信済み', color: 'blue' }
      case 'delivered':
        return { text: '受信済み', color: 'green' }
      case 'read':
        return { text: '既読', color: 'gray' }
      default:
        return { text: status, color: 'gray' }
    }
  }

  // トーンの日本語表示
  getToneLabel(tone: string): string {
    const labels: Record<string, string> = {
      gentle: 'やんわり',
      constructive: '建設的',
      casual: 'カジュアル'
    }
    return labels[tone] || tone
  }
}

export const inboxService = new InboxService()
export default inboxService