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


export interface UserSettings {
  user: UserProfile
  notifications: NotificationSettings
  messages: MessageSettings
}

export interface UpdateProfileRequest {
  name?: string
  email?: string
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



}

// シングルトンインスタンスをエクスポート
const settingsService = new SettingsService()
export default settingsService