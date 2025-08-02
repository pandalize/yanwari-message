import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { friendService, type FriendRequestWithUsers, type FriendshipWithUser } from '@/services/friendService'

export const useFriendsStore = defineStore('friends', () => {
  // 状態
  const friends = ref<FriendshipWithUser[]>([])
  const receivedRequests = ref<FriendRequestWithUsers[]>([])
  const sentRequests = ref<FriendRequestWithUsers[]>([])
  const loading = ref(false)
  const error = ref<string | null>(null)

  // 計算プロパティ
  const friendCount = computed(() => friends.value.length)
  const pendingReceivedCount = computed(() => 
    receivedRequests.value.filter(r => r.status === 'pending').length
  )
  const pendingSentCount = computed(() => 
    sentRequests.value.filter(r => r.status === 'pending').length
  )

  // 友達IDのセット（高速検索用）
  const friendIds = computed(() => 
    new Set(friends.value.map(f => f.friend.id))
  )

  // アクション
  // 友達一覧を取得
  async function fetchFriends() {
    loading.value = true
    error.value = null
    try {
      friends.value = await friendService.getFriends()
    } catch (err: any) {
      error.value = err.response?.data?.error || '友達一覧の取得に失敗しました'
      console.error('友達一覧の取得エラー:', error.value)
    } finally {
      loading.value = false
    }
  }

  // 受信した友達申請を取得
  async function fetchReceivedRequests() {
    loading.value = true
    error.value = null
    try {
      receivedRequests.value = await friendService.getReceivedRequests()
    } catch (err: any) {
      error.value = err.response?.data?.error || '受信申請の取得に失敗しました'
      console.error('受信申請の取得エラー:', error.value)
    } finally {
      loading.value = false
    }
  }

  // 送信した友達申請を取得
  async function fetchSentRequests() {
    loading.value = true
    error.value = null
    try {
      sentRequests.value = await friendService.getSentRequests()
    } catch (err: any) {
      error.value = err.response?.data?.error || '送信申請の取得に失敗しました'
      console.error('送信申請の取得エラー:', error.value)
    } finally {
      loading.value = false
    }
  }

  // 友達申請を送信
  async function sendFriendRequest(toUserEmail: string, message?: string) {
    loading.value = true
    error.value = null
    try {
      await friendService.sendFriendRequest({ to_email: toUserEmail, message })
      console.log('友達申請を送信しました')
      // 送信済み申請リストを更新
      await fetchSentRequests()
    } catch (err: any) {
      error.value = err.response?.data?.error || '友達申請の送信に失敗しました'
      console.error('友達申請の送信エラー:', error.value)
      throw err
    } finally {
      loading.value = false
    }
  }

  // 友達申請を承諾
  async function acceptRequest(requestId: string) {
    loading.value = true
    error.value = null
    try {
      await friendService.acceptRequest(requestId)
      console.log('友達申請を承諾しました')
      // リストを更新
      await Promise.all([
        fetchReceivedRequests(),
        fetchFriends()
      ])
    } catch (err: any) {
      error.value = err.response?.data?.error || '友達申請の承諾に失敗しました'
      console.error('友達申請の承諾エラー:', error.value)
    } finally {
      loading.value = false
    }
  }

  // 友達申請を拒否
  async function rejectRequest(requestId: string) {
    loading.value = true
    error.value = null
    try {
      await friendService.rejectRequest(requestId)
      console.log('友達申請を拒否しました')
      // 受信申請リストを更新
      await fetchReceivedRequests()
    } catch (err: any) {
      error.value = err.response?.data?.error || '友達申請の拒否に失敗しました'
      console.error('友達申請の拒否エラー:', error.value)
    } finally {
      loading.value = false
    }
  }

  // 送信した友達申請をキャンセル
  async function cancelRequest(requestId: string) {
    loading.value = true
    error.value = null
    try {
      await friendService.cancelRequest(requestId)
      console.log('友達申請をキャンセルしました')
      // 送信申請リストを更新
      await fetchSentRequests()
    } catch (err: any) {
      error.value = err.response?.data?.error || '友達申請のキャンセルに失敗しました'
      console.error('友達申請のキャンセルエラー:', error.value)
    } finally {
      loading.value = false
    }
  }

  // 友達を削除
  async function removeFriend(friendEmail: string) {
    loading.value = true
    error.value = null
    try {
      await friendService.removeFriend(friendEmail)
      console.log('友達を削除しました')
      // 友達リストを更新
      await fetchFriends()
    } catch (err: any) {
      error.value = err.response?.data?.error || '友達の削除に失敗しました'
      console.error('友達の削除エラー:', error.value)
    } finally {
      loading.value = false
    }
  }

  // ユーザーが友達かどうかをチェック
  function isFriend(userId: string): boolean {
    return friendIds.value.has(userId)
  }

  // メールアドレスで友達をチェック
  function isFriendByEmail(email: string): boolean {
    return friends.value.some(f => f.friend.email === email)
  }

  // 全データを初期化
  function clearAll() {
    friends.value = []
    receivedRequests.value = []
    sentRequests.value = []
    error.value = null
  }

  return {
    // 状態
    friends,
    receivedRequests,
    sentRequests,
    loading,
    error,
    
    // 計算プロパティ
    friendCount,
    pendingReceivedCount,
    pendingSentCount,
    
    // アクション
    fetchFriends,
    fetchReceivedRequests,
    fetchSentRequests,
    sendFriendRequest,
    acceptRequest,
    rejectRequest,
    cancelRequest,
    removeFriend,
    isFriend,
    isFriendByEmail,
    clearAll
  }
})