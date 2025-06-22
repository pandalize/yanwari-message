import { apiService } from './api'

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
    const response = await apiService.api.post('/messages/draft', request)
    return response.data
  }

  async updateDraft(messageId: string, request: UpdateDraftRequest): Promise<MessageResponse> {
    const response = await apiService.api.put(`/messages/${messageId}`, request)
    return response.data
  }

  async getDrafts(page = 1, limit = 20): Promise<DraftsResponse> {
    const response = await apiService.api.get(`/messages/drafts?page=${page}&limit=${limit}`)
    return response.data
  }

  async getMessage(messageId: string): Promise<MessageResponse> {
    const response = await apiService.api.get(`/messages/${messageId}`)
    return response.data
  }

  async deleteDraft(messageId: string): Promise<{ message: string }> {
    const response = await apiService.api.delete(`/messages/${messageId}`)
    return response.data
  }
}

export const messageService = new MessageService()