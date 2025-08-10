// メッセージ関連の型定義

export interface MessageVariations {
  gentle?: string
  constructive?: string
  casual?: string
}

export type MessageStatus = 'draft' | 'processing' | 'scheduled' | 'sent' | 'delivered' | 'read'

export interface Message {
  id: string
  senderId: string
  recipientId?: string
  originalText: string
  variations: MessageVariations
  selectedTone?: string
  finalText?: string
  scheduledAt?: string
  status: MessageStatus
  createdAt: string
  updatedAt: string
  sentAt?: string
  readAt?: string
}

export interface CreateMessageRequest {
  recipientEmail?: string
  originalText: string
}

export interface UpdateMessageRequest {
  recipientEmail?: string
  originalText?: string
  variations?: MessageVariations
  toneVariations?: Record<string, string>
  selectedTone?: string
  scheduledAt?: string
}

export interface MessageDraft extends Message {
  status: 'draft'
}

export interface TransformRequest {
  messageId: string
  originalText: string
}

export interface TransformResponse {
  gentle: string
  constructive: string
  casual: string
}