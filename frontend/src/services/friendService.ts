import { apiService } from './api'

// 友達申請の型定義
export interface FriendRequest {
  id: string
  from_user_id: string
  to_user_id: string
  status: 'pending' | 'accepted' | 'rejected' | 'canceled'
  message?: string
  created_at: string
  updated_at: string
}

// ユーザー情報を含む友達申請
export interface FriendRequestWithUsers {
  id: string
  from_user_id: string
  to_user_id: string
  status: 'pending' | 'accepted' | 'rejected' | 'canceled'
  message?: string
  created_at: string
  updated_at: string
  from_user?: {
    id: string
    email: string
    displayName?: string
  }
  to_user?: {
    id: string
    email: string
    displayName?: string
  }
}

// 友達情報
export interface FriendshipWithUser {
  friendship_id: string
  friend: {
    id: string
    email: string
    displayName?: string
  }
  created_at: string
}

// 友達申請送信のリクエスト
export interface SendFriendRequestInput {
  to_user_email: string
  message?: string
}

// 友達削除のリクエスト
export interface RemoveFriendInput {
  friend_email: string
}

class FriendService {
  // 友達申請を送信
  async sendFriendRequest(input: SendFriendRequestInput): Promise<FriendRequest> {
    const response = await apiService.post('/friend-requests/send', input)
    return response.data.data
  }

  // 受信した友達申請一覧を取得
  async getReceivedRequests(): Promise<FriendRequestWithUsers[]> {
    const response = await apiService.get('/friend-requests/received')
    return response.data.data || []
  }

  // 送信した友達申請一覧を取得
  async getSentRequests(): Promise<FriendRequestWithUsers[]> {
    const response = await apiService.get('/friend-requests/sent')
    return response.data.data || []
  }

  // 友達申請を承諾
  async acceptRequest(requestId: string): Promise<void> {
    await apiService.post(`/friend-requests/${requestId}/accept`)
  }

  // 友達申請を拒否
  async rejectRequest(requestId: string): Promise<void> {
    await apiService.post(`/friend-requests/${requestId}/reject`)
  }

  // 送信した友達申請をキャンセル
  async cancelRequest(requestId: string): Promise<void> {
    await apiService.post(`/friend-requests/${requestId}/cancel`)
  }

  // 友達一覧を取得
  async getFriends(): Promise<FriendshipWithUser[]> {
    const response = await apiService.get('/friends/')
    return response.data.data || []
  }

  // 友達を削除
  async removeFriend(friendEmail: string): Promise<void> {
    await apiService.delete('/friends/remove', {
      data: { friend_email: friendEmail }
    })
  }

  // ユーザーが既に友達かどうかをチェック
  async isFriend(userId: string): Promise<boolean> {
    try {
      const friends = await this.getFriends()
      return friends.some(f => f.friend.id === userId)
    } catch (error) {
      console.error('友達チェックエラー:', error)
      return false
    }
  }

  // 友達申請が既に送信されているかチェック
  async hasPendingRequest(userEmail: string): Promise<boolean> {
    try {
      const sentRequests = await this.getSentRequests()
      return sentRequests.some(
        r => r.to_user?.email === userEmail && r.status === 'pending'
      )
    } catch (error) {
      console.error('友達申請チェックエラー:', error)
      return false
    }
  }
}

export const friendService = new FriendService()