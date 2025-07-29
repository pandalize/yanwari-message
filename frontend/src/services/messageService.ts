import { apiService } from './api'

// User lookup cache to avoid repeated API calls
const userCache = new Map<string, { name: string, email: string }>()

// Add cache clearing function
export const clearUserCache = () => {
  userCache.clear()
  console.log('User cache cleared')
}

// Helper function to get user info by ID or email
export const getUserInfo = async (userIdOrEmail: string): Promise<{ name: string, email: string }> => {
  if (userCache.has(userIdOrEmail)) {
    return userCache.get(userIdOrEmail)!
  }
  
  try {
    console.log('getUserInfo called with:', userIdOrEmail)
    
    // 🚨 無効なIDの場合は早期リターン
    if (!userIdOrEmail || userIdOrEmail === '000000000000000000000000' || userIdOrEmail.trim() === '') {
      console.log('⚠️ Invalid userIdOrEmail detected:', userIdOrEmail)
      const fallbackInfo = { name: '不明なユーザー', email: 'unknown@example.com' }
      userCache.set(userIdOrEmail, fallbackInfo)
      return fallbackInfo
    }
    

    // Try to search user by ID first (MongoDB ObjectID format)
    if (userIdOrEmail.length === 24 && /^[0-9a-fA-F]{24}$/.test(userIdOrEmail)) {
      console.log('Searching by ObjectID:', userIdOrEmail)
      try {
        const response = await apiService.get(`/users/${userIdOrEmail}`)
        if (response.data.data) {
          const user = response.data.data
          console.log('Raw user data from ID API:', user)
          const userInfo = { 
            name: user.name && user.name.trim() !== '' ? user.name : 'Unknown User', 
            email: user.email 
          }
          userCache.set(userIdOrEmail, userInfo)
          console.log('Processed user info from ID:', userInfo)
          return userInfo
        }
      } catch (idError) {
        console.warn('Failed to fetch user by ID:', idError)
        // Continue to try other methods
      }
    }
    
    // Try to search user by email if it looks like an email
    if (userIdOrEmail.includes('@')) {
      console.log('Searching by email:', userIdOrEmail)
      try {
        const response = await apiService.get(`/users/by-email?email=${userIdOrEmail}`)
        if (response.data.data) {
          const user = response.data.data
          console.log('Raw user data from email API:', user)
          const userInfo = { 
            name: user.name && user.name.trim() !== '' ? user.name : 'Unknown User', 
            email: user.email 
          }
          userCache.set(userIdOrEmail, userInfo)
          console.log('Processed user info from email:', userInfo)
          return userInfo
        }
      } catch (emailError) {
        console.warn('Failed to fetch user by email:', emailError)
        // Continue to try other methods
      }
    }
    
    // For ObjectID that wasn't found directly, try a general search as fallback
    if (userIdOrEmail.length === 24 && /^[0-9a-fA-F]{24}$/.test(userIdOrEmail)) {
      try {
        console.log('Fallback: Searching all users for ObjectID:', userIdOrEmail)
        const searchResponse = await apiService.get('/users/search?q=@')  // Search for users with @
        if (searchResponse.data.data && searchResponse.data.data.users && searchResponse.data.data.users.length > 0) {
          // Look for a user that might match this ID
          const allUsers = searchResponse.data.data.users
          const matchingUser = allUsers.find((user: any) => 
            user.id === userIdOrEmail || user._id === userIdOrEmail
          )
          
          if (matchingUser) {
            const userInfo = { 
              name: matchingUser.name && matchingUser.name.trim() !== '' ? matchingUser.name : 'Unknown User', 
              email: matchingUser.email 
            }
            userCache.set(userIdOrEmail, userInfo)
            console.log('Found user by fallback search:', userInfo)
            return userInfo
          }
        }
      } catch (searchError) {
        console.warn('Failed to search for user:', searchError)
      }
    }
    
    // Final fallback: always use Unknown User
    let fallbackEmail = 'unknown@example.com'
    
    if (userIdOrEmail.includes('@')) {
      fallbackEmail = userIdOrEmail
    } else {
      // For ObjectID format, create a generic email
      fallbackEmail = `user-${userIdOrEmail.slice(-6)}@example.com`
    }
    
    const userInfo = { name: 'Unknown User', email: fallbackEmail }
    userCache.set(userIdOrEmail, userInfo)
    console.log('Using improved fallback user info:', userInfo)
    return userInfo
  } catch (error) {
    console.error('Failed to fetch user info:', error)
    
    // Error fallback: always use Unknown User
    let errorFallbackEmail = 'unknown@example.com'
    
    if (userIdOrEmail && userIdOrEmail.includes('@')) {
      errorFallbackEmail = userIdOrEmail
    }
    
    const userInfo = { name: 'Unknown User', email: errorFallbackEmail }
    userCache.set(userIdOrEmail, userInfo)
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
        let recipientName = 'Unknown User'
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