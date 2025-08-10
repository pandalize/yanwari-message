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
      console.log('Creating draft with request:', request)
      const response = await messageService.createDraft(request)
      console.log('Draft creation response:', response)
      
      const newDraft: MessageDraft = {
        id: response.data.id,
        originalText: response.data.originalText,
        reason: response.data.reason,
        recipientEmail: request.recipientEmail,
        status: response.data.status as MessageDraft['status'],
        createdAt: response.data.createdAt,
        updatedAt: response.data.updatedAt
      }

      drafts.value.unshift(newDraft)
      currentDraft.value = newDraft
      console.log('Draft created successfully:', newDraft)
      
      return true
    } catch (err: any) {
      console.error('Draft creation failed:', err)
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
      console.log('Updating draft:', messageId, request)
      const response = await messageService.updateDraft(messageId, request)
      console.log('Update response:', response)
      
      const updatedDraft: MessageDraft = {
        id: response.data.id,
        originalText: response.data.originalText,
        reason: response.data.reason,
        recipientEmail: response.data.recipientId || currentDraft.value?.recipientEmail || request.recipientEmail,
        status: response.data.status as MessageDraft['status'],
        createdAt: response.data.createdAt,
        updatedAt: response.data.updatedAt
      }

      // 下書き一覧を更新（更新されたアイテムを削除して先頭に追加）
      const index = drafts.value.findIndex(d => d.id === messageId)
      if (index !== -1) {
        // 既存のアイテムを削除
        drafts.value.splice(index, 1)
      }
      // 更新されたアイテムを先頭に追加（最新順）
      drafts.value.unshift(updatedDraft)

      // 現在の下書きも更新
      if (currentDraft.value?.id === messageId) {
        currentDraft.value = updatedDraft
      }

      console.log('Draft updated successfully:', updatedDraft)
      return true
    } catch (err: any) {
      console.error('Draft update failed:', err)
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
      // 送信予定・送信済み以外の下書きのみ表示
      const filteredDrafts = response.data.messages.filter((draft: MessageDraft) => 
        draft.status === 'draft' || draft.status === 'processing'
      )
      
      // 更新日時順（最新が先頭）にソート
      drafts.value = filteredDrafts.sort((a, b) => {
        // updatedAt が優先、なければ createdAt を使用
        const dateA = new Date(a.updatedAt || a.createdAt || '1970-01-01')
        const dateB = new Date(b.updatedAt || b.createdAt || '1970-01-01')
        const result = dateB.getTime() - dateA.getTime()
        
        console.log('Sorting drafts:', {
          a: { id: a.id, updatedAt: a.updatedAt, createdAt: a.createdAt, dateA: dateA.toISOString() },
          b: { id: b.id, updatedAt: b.updatedAt, createdAt: b.createdAt, dateB: dateB.toISOString() },
          result
        })
        
        return result
      })
      
      console.log('Drafts sorted by date (newest first):', drafts.value.map(d => ({
        id: d.id,
        text: d.originalText.substring(0, 50),
        updatedAt: d.updatedAt,
        createdAt: d.createdAt
      })))
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
      console.log('Loading message:', messageId)
      const response = await messageService.getMessage(messageId)
      console.log('Message loaded:', response)
      
      currentDraft.value = {
        id: response.data.id,
        originalText: response.data.originalText,
        reason: response.data.reason,
        recipientEmail: response.data.recipientId, // Use recipientId as recipientEmail for now
        status: response.data.status as MessageDraft['status'],
        createdAt: response.data.createdAt,
        updatedAt: response.data.updatedAt
      }
      console.log('Current draft set:', currentDraft.value)
    } catch (err: any) {
      console.error('Failed to load message:', err)
      error.value = err.response?.data?.error || 'メッセージの取得に失敗しました'
    } finally {
      isLoading.value = false
    }
  }

  const deleteDraft = async (messageId: string): Promise<boolean> => {
    console.log('ストアのdeleteDraftが呼ばれました:', messageId)
    isLoading.value = true
    error.value = ''

    try {
      console.log('messageService.deleteDraftを実行中...')
      await messageService.deleteDraft(messageId)
      console.log('messageService.deleteDraft完了')
      
      // 下書き一覧から削除
      const beforeCount = drafts.value.length
      drafts.value = drafts.value.filter(d => d.id !== messageId)
      const afterCount = drafts.value.length
      console.log(`下書き一覧から削除: ${beforeCount} → ${afterCount}`)
      
      // 現在の下書きもクリア
      if (currentDraft.value?.id === messageId) {
        currentDraft.value = null
        console.log('現在の下書きもクリアしました')
      }

      console.log('削除処理完了')
      return true
    } catch (err: any) {
      console.error('削除処理でエラー:', err)
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

  const sortDraftsByDate = () => {
    drafts.value = drafts.value.sort((a, b) => {
      const dateA = new Date(a.updatedAt || a.createdAt || '1970-01-01')
      const dateB = new Date(b.updatedAt || b.createdAt || '1970-01-01')
      return dateB.getTime() - dateA.getTime()
    })
    
    console.log('Manual sort applied. Drafts order:', drafts.value.map(d => ({
      id: d.id,
      text: d.originalText.substring(0, 30),
      updatedAt: d.updatedAt,
      createdAt: d.createdAt
    })))
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
    sortDraftsByDate,
    clearError
  }
})