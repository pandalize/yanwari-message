import { apiService } from './api'

// User lookup cache to avoid repeated API calls
const userCache = new Map<string, { name: string, email: string }>()

// Helper function to get user info by ID
export const getUserInfo = async (userId: string): Promise<{ name: string, email: string }> => {
  if (userCache.has(userId)) {
    return userCache.get(userId)!
  }
  
  try {
    // Try to search user by email if it looks like an email
    if (userId.includes('@')) {
      const response = await apiService.get(`/users/search?email=${userId}`)
      if (response.data.data && response.data.data.length > 0) {
        const user = response.data.data[0]
        const userInfo = { 
          name: user.displayName || user.email.split('@')[0] || 'Unknown User', 
          email: user.email 
        }
        userCache.set(userId, userInfo)
        return userInfo
      }
    }
    
    // If it's an ObjectID, we'll use a placeholder for now
    // In a real application, you'd have a "get user by ID" endpoint
    const userInfo = { name: `User-${userId.slice(-6)}`, email: `${userId}@example.com` }
    userCache.set(userId, userInfo)
    return userInfo
  } catch (error) {
    console.error('Failed to fetch user info:', error)
    const userInfo = { name: 'Unknown User', email: 'unknown@example.com' }
    userCache.set(userId, userInfo)
    return userInfo
  }
}

export interface MessageDraft {
  id?: string
  originalText: string
  recipientEmail?: string
  status: 'draft' | 'processing' | 'scheduled' | 'sent' | 'delivered' | 'read'
  createdAt?: string
  updatedAt?: string
}

export interface MessageVariations {
  gentle?: string
  constructive?: string
  casual?: string
}

export interface CreateDraftRequest {
  originalText: string
  recipientEmail?: string
}

export interface UpdateDraftRequest {
  originalText?: string
  recipientEmail?: string
  variations?: MessageVariations
  selectedTone?: string
  scheduledAt?: string
}

export interface MessageResponse {
  data: {
    id: string
    senderId: string
    recipientId?: string
    originalText: string
    variations: MessageVariations
    selectedTone?: string
    finalText?: string
    scheduledAt?: string
    status: string
    createdAt: string
    updatedAt: string
    sentAt?: string
    readAt?: string
  }
  message: string
}

export interface DraftsResponse {
  data: {
    messages: MessageDraft[]
    pagination: {
      page: number
      limit: number
      total: number
    }
  }
}

class MessageService {
  async createDraft(request: CreateDraftRequest): Promise<MessageResponse> {
    const response = await apiService.post('/messages/draft', request)
    return response.data
  }

  async updateDraft(messageId: string, request: UpdateDraftRequest): Promise<MessageResponse> {
    const response = await apiService.put(`/messages/${messageId}`, request)
    return response.data
  }

  async getDrafts(page = 1, limit = 20): Promise<DraftsResponse> {
    const response = await apiService.get(`/messages/drafts?page=${page}&limit=${limit}`)
    return response.data
  }

  async getMessage(messageId: string): Promise<MessageResponse> {
    const response = await apiService.get(`/messages/${messageId}`)
    return response.data
  }

  async deleteDraft(messageId: string): Promise<{ message: string }> {
    const response = await apiService.delete(`/messages/${messageId}`)
    return response.data
  }

  async getSentMessages(page = 1, limit = 20): Promise<{ 
    messages: (MessageDraft & { recipientEmail?: string, recipientName?: string, sentAt?: string, readAt?: string })[] 
  }> {
    // 既存のdrafts APIを使用して送信済みステータスのメッセージを取得
    // 実際には全ての下書きを取得してフィルタリング
    const response = await apiService.get(`/messages/drafts?page=${page}&limit=${limit}`)
    
    // 送信済みステータス（sent, delivered, read）のもののみフィルタ
    const allMessages = response.data.data?.messages || []
    const sentMessages = allMessages.filter((msg: any) => 
      ['sent', 'delivered', 'read'].includes(msg.status)
    )
    
    // 受信者情報を並行して取得
    const messagesWithRecipientInfo = await Promise.all(
      sentMessages.map(async (msg: any) => {
        let recipientName = '受信者'
        let recipientEmail = 'unknown@example.com'
        
        if (msg.recipientId) {
          try {
            const userInfo = await getUserInfo(msg.recipientId)
            recipientName = userInfo.name
            recipientEmail = userInfo.email
          } catch (error) {
            console.warn('Failed to get recipient info for:', msg.recipientId)
          }
        }
        
        return {
          ...msg,
          id: msg.id || msg._id,
          recipientEmail,
          recipientName,
          sentAt: msg.sentAt || msg.updatedAt || msg.createdAt,
          readAt: msg.readAt || (msg.status === 'read' ? msg.updatedAt : undefined)
        }
      })
    )
    
    return { messages: messagesWithRecipientInfo }
  }
}

export const messageService = new MessageService()