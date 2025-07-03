import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { inboxService, type ReceivedMessage } from '../services/inboxService'

export const useInboxStore = defineStore('inbox', () => {
  // 状態
  const messages = ref<ReceivedMessage[]>([])
  const currentPage = ref(1)
  const totalMessages = ref(0)
  const limit = ref(20)
  const isLoading = ref(false)
  const error = ref('')

  // 計算プロパティ
  const totalPages = computed(() => Math.ceil(totalMessages.value / limit.value))
  const hasNextPage = computed(() => currentPage.value < totalPages.value)
  const hasPrevPage = computed(() => currentPage.value > 1)
  
  // 未読メッセージ数
  const unreadCount = computed(() => 
    messages.value.filter(msg => msg.status === 'sent' || msg.status === 'delivered').length
  )

  // アクション
  const fetchMessages = async (page = 1) => {
    isLoading.value = true
    error.value = ''
    
    try {
      const response = await inboxService.getReceivedMessages(page, limit.value)
      messages.value = response.messages
      currentPage.value = page
      totalMessages.value = response.pagination.total
    } catch (err: any) {
      error.value = err.response?.data?.error || '受信メッセージの取得に失敗しました'
      console.error('受信メッセージ取得エラー:', err)
    } finally {
      isLoading.value = false
    }
  }

  const markAsRead = async (messageId: string) => {
    try {
      await inboxService.markAsRead(messageId)
      
      // ローカル状態を更新
      const message = messages.value.find(msg => msg.id === messageId)
      if (message) {
        message.status = 'read'
        message.readAt = new Date().toISOString()
      }
    } catch (err: any) {
      error.value = err.response?.data?.error || '既読更新に失敗しました'
      console.error('既読更新エラー:', err)
    }
  }

  const nextPage = async () => {
    if (hasNextPage.value) {
      await fetchMessages(currentPage.value + 1)
    }
  }

  const prevPage = async () => {
    if (hasPrevPage.value) {
      await fetchMessages(currentPage.value - 1)
    }
  }

  const refresh = async () => {
    await fetchMessages(currentPage.value)
  }

  // メッセージをIDで取得
  const getMessageById = (messageId: string) => {
    return messages.value.find(msg => msg.id === messageId)
  }

  return {
    // 状態
    messages,
    currentPage,
    totalMessages,
    limit,
    isLoading,
    error,
    
    // 計算プロパティ
    totalPages,
    hasNextPage,
    hasPrevPage,
    unreadCount,
    
    // アクション
    fetchMessages,
    markAsRead,
    nextPage,
    prevPage,
    refresh,
    getMessageById
  }
})