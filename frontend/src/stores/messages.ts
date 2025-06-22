import { ref, computed } from 'vue'
import { defineStore } from 'pinia'
import { messageService, type MessageDraft, type CreateDraftRequest, type UpdateDraftRequest } from '@/services/messageService'

export const useMessageStore = defineStore('messages', () => {
  const drafts = ref<MessageDraft[]>([])
  const currentDraft = ref<MessageDraft | null>(null)
  const isLoading = ref(false)
  const error = ref<string>('')

  const hasDrafts = computed(() => drafts.value.length > 0)

  const createDraft = async (request: CreateDraftRequest): Promise<boolean> => {
    isLoading.value = true
    error.value = ''

    try {
      const response = await messageService.createDraft(request)
      
      const newDraft: MessageDraft = {
        id: response.data.id,
        originalText: response.data.originalText,
        recipientEmail: request.recipientEmail,
        status: response.data.status as MessageDraft['status'],
        createdAt: response.data.createdAt,
        updatedAt: response.data.updatedAt
      }

      drafts.value.unshift(newDraft)
      currentDraft.value = newDraft
      
      return true
    } catch (err: any) {
      error.value = err.response?.data?.error || 'メッセージの作成に失敗しました'
      return false
    } finally {
      isLoading.value = false
    }
  }

  const updateDraft = async (messageId: string, request: UpdateDraftRequest): Promise<boolean> => {
    isLoading.value = true
    error.value = ''

    try {
      const response = await messageService.updateDraft(messageId, request)
      
      const updatedDraft: MessageDraft = {
        id: response.data.id,
        originalText: response.data.originalText,
        status: response.data.status as MessageDraft['status'],
        createdAt: response.data.createdAt,
        updatedAt: response.data.updatedAt
      }

      // 下書き一覧を更新
      const index = drafts.value.findIndex(d => d.id === messageId)
      if (index !== -1) {
        drafts.value[index] = updatedDraft
      }

      // 現在の下書きも更新
      if (currentDraft.value?.id === messageId) {
        currentDraft.value = updatedDraft
      }

      return true
    } catch (err: any) {
      error.value = err.response?.data?.error || 'メッセージの更新に失敗しました'
      return false
    } finally {
      isLoading.value = false
    }
  }

  const loadDrafts = async (page = 1, limit = 20): Promise<void> => {
    isLoading.value = true
    error.value = ''

    try {
      const response = await messageService.getDrafts(page, limit)
      drafts.value = response.data.messages
    } catch (err: any) {
      error.value = err.response?.data?.error || '下書きの取得に失敗しました'
    } finally {
      isLoading.value = false
    }
  }

  const loadMessage = async (messageId: string): Promise<void> => {
    isLoading.value = true
    error.value = ''

    try {
      const response = await messageService.getMessage(messageId)
      
      currentDraft.value = {
        id: response.data.id,
        originalText: response.data.originalText,
        status: response.data.status as MessageDraft['status'],
        createdAt: response.data.createdAt,
        updatedAt: response.data.updatedAt
      }
    } catch (err: any) {
      error.value = err.response?.data?.error || 'メッセージの取得に失敗しました'
    } finally {
      isLoading.value = false
    }
  }

  const deleteDraft = async (messageId: string): Promise<boolean> => {
    isLoading.value = true
    error.value = ''

    try {
      await messageService.deleteDraft(messageId)
      
      // 下書き一覧から削除
      drafts.value = drafts.value.filter(d => d.id !== messageId)
      
      // 現在の下書きもクリア
      if (currentDraft.value?.id === messageId) {
        currentDraft.value = null
      }

      return true
    } catch (err: any) {
      error.value = err.response?.data?.error || 'メッセージの削除に失敗しました'
      return false
    } finally {
      isLoading.value = false
    }
  }

  const setCurrentDraft = (draft: MessageDraft) => {
    currentDraft.value = draft
  }

  const clearCurrentDraft = () => {
    currentDraft.value = null
  }

  const clearError = () => {
    error.value = ''
  }

  return {
    // State
    drafts: computed(() => drafts.value),
    currentDraft: computed(() => currentDraft.value),
    isLoading: computed(() => isLoading.value),
    error: computed(() => error.value),
    hasDrafts,

    // Actions
    createDraft,
    updateMessage: updateDraft,
    updateDraft,
    loadDrafts,
    loadMessage,
    fetchMessage: loadMessage,
    deleteDraft,
    setCurrentDraft,
    clearCurrentDraft,
    clearError
  }
})