import { apiService } from './api'

// 設定関連の型定義
export interface UserProfile {
  id: string
  name: string
  email: string
}

export interface NotificationSettings {
  emailNotifications: boolean
  sendNotifications: boolean
  browserNotifications: boolean
}

export interface MessageSettings {
  defaultTone: 'gentle' | 'constructive' | 'casual'
  timeRestriction: 'none' | 'business_hours' | 'extended_hours'
  userPreferences?: string
}

export interface UserSettings {
  user: UserProfile
  notifications: NotificationSettings
  messages: MessageSettings
}

export interface UpdateProfileRequest {
  name: string
}

export interface ChangePasswordRequest {
  currentPassword: string
  newPassword: string
}

class SettingsService {
  private readonly baseUrl = '/settings'

  /**
   * ユーザー設定を取得
   */
  async getSettings(): Promise<UserSettings> {
    const response = await apiService.get<{
      success: boolean
      data: UserSettings
    }>(this.baseUrl)
    
    if (!response.data.success) {
      throw new Error('設定の取得に失敗しました')
    }
    
    return response.data.data
  }

  /**
   * プロフィールを更新
   */
  async updateProfile(data: UpdateProfileRequest): Promise<void> {
    const response = await apiService.put<{
      success: boolean
      message: string
    }>(`${this.baseUrl}/profile`, data)
    
    if (!response.data.success) {
      throw new Error('プロフィールの更新に失敗しました')
    }
  }

  /**
   * パスワードを変更
   */
  async changePassword(data: ChangePasswordRequest): Promise<void> {
    const response = await apiService.put<{
      success: boolean
      message: string
    }>(`${this.baseUrl}/password`, data)
    
    if (!response.data.success) {
      throw new Error('パスワードの変更に失敗しました')
    }
  }

  /**
   * 通知設定を更新
   */
  async updateNotificationSettings(settings: NotificationSettings): Promise<void> {
    const response = await apiService.put<{
      success: boolean
      message: string
    }>(`${this.baseUrl}/notifications`, settings)
    
    if (!response.data.success) {
      throw new Error('通知設定の更新に失敗しました')
    }
  }

  /**
   * メッセージ設定を更新
   */
  async updateMessageSettings(settings: MessageSettings): Promise<void> {
    const response = await apiService.put<{
      success: boolean
      message: string
    }>(`${this.baseUrl}/messages`, settings)
    
    if (!response.data.success) {
      throw new Error('メッセージ設定の更新に失敗しました')
    }
  }

  /**
   * アカウントを削除
   */
  async deleteAccount(): Promise<void> {
    const response = await apiService.delete<{
      success: boolean
      message: string
    }>(`${this.baseUrl}/account`)
    
    if (!response.data.success) {
      throw new Error('アカウントの削除に失敗しました')
    }
  }

  /**
   * トーンのラベル取得
   */
  getToneLabel(tone: string): string {
    const labels: Record<string, string> = {
      gentle: '💝 やんわり',
      constructive: '🏗️ 建設的',
      casual: '🎯 カジュアル'
    }
    return labels[tone] || tone
  }

  /**
   * 時間制限のラベル取得
   */
  getTimeRestrictionLabel(restriction: string): string {
    const labels: Record<string, string> = {
      none: '制限なし',
      business_hours: '営業時間のみ（9:00-18:00）',
      extended_hours: '拡張時間（8:00-20:00）'
    }
    return labels[restriction] || restriction
  }
}

// シングルトンインスタンスをエクスポート
const settingsService = new SettingsService()
export default settingsService