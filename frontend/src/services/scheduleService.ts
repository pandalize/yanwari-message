import { apiService } from './api'
import type { Message } from '../types/message'

// AI時間提案リクエスト
export interface ScheduleSuggestionRequest {
  messageId: string
  messageText: string
  selectedTone: string
}

// AI時間提案レスポンス
export interface ScheduleSuggestionResponse {
  message_type: string
  urgency_level: string
  recommended_timing: string
  reasoning: string
  suggested_options: Array<{
    option: string
    priority: string
    reason: string
    delay_minutes: number | string // 数値または文字列（特殊な時間指定）を許可
  }>
}

// スケジュール作成リクエスト
export interface CreateScheduleRequest {
  messageId: string
  scheduledAt: string // ISO8601形式
}

// スケジュール
export interface Schedule {
  id: string
  messageId: string
  userId: string
  scheduledAt: string
  status: string
  createdAt: string
  updatedAt: string
  retryCount: number
  timezone: string
  // 受信者詳細情報（サーバーから追加される）
  recipientName?: string
  recipientEmail?: string
  originalText?: string
  finalText?: string
  selectedTone?: string
}

// スケジュール更新リクエスト
export interface UpdateScheduleRequest {
  scheduledAt?: string
  status?: string
}

class ScheduleService {
  // AI時間提案を取得
  async getSuggestion(request: ScheduleSuggestionRequest): Promise<ScheduleSuggestionResponse> {
    const response = await apiService.post('/schedule/suggest', request)
    return response.data.data
  }

  // スケジュールを作成
  async createSchedule(request: CreateScheduleRequest): Promise<Schedule> {
    const response = await apiService.post('/schedules/', request)
    return response.data.data
  }

  // スケジュール一覧を取得
  async getSchedules(page = 1, limit = 20, status?: string): Promise<{
    schedules: Schedule[]
    pagination: {
      page: number
      limit: number
      total: number
    }
  }> {
    const params: any = { page, limit }
    if (status) params.status = status
    
    const response = await apiService.get('/schedules/' + (status ? `?status=${status}&page=${page}&limit=${limit}` : `?page=${page}&limit=${limit}`))
    return response.data.data
  }

  // スケジュールを更新
  async updateSchedule(id: string, request: UpdateScheduleRequest): Promise<Schedule> {
    const response = await apiService.put(`/schedules/${id}`, request)
    return response.data.data
  }

  // スケジュールを削除
  async deleteSchedule(id: string): Promise<void> {
    await apiService.delete(`/schedules/${id}`)
  }

  // スケジュール詳細を取得
  async getScheduleDetail(id: string): Promise<{
    schedule: Schedule & {
      recipientName?: string
      recipientEmail?: string
      originalText?: string
      finalText?: string
      selectedTone?: string
    }
  }> {
    const response = await apiService.get(`/schedules/${id}`)
    return response.data
  }

  // 相対時間を絶対時間に変換（delay_minutesから）
  calculateScheduleTime(delayMinutes: number): string {
    const now = new Date()
    const scheduledTime = new Date(now.getTime() + delayMinutes * 60000)
    return scheduledTime.toISOString()
  }

  // 日本語の時間表記を解析してISO8601に変換
  parseJapaneseTime(timeText: string): string | null {
    const now = new Date()
    
    // "今すぐ" の場合
    if (timeText.includes('今すぐ')) {
      return now.toISOString()
    }
    
    // "X時間後" の場合
    const hoursMatch = timeText.match(/(\d+)時間後/)
    if (hoursMatch) {
      const hours = parseInt(hoursMatch[1])
      const futureTime = new Date(now.getTime() + hours * 60 * 60000)
      return futureTime.toISOString()
    }
    
    // "X時" の場合（今日または明日）
    const hourMatch = timeText.match(/(\d+)時/)
    if (hourMatch) {
      const targetHour = parseInt(hourMatch[1])
      const targetTime = new Date(now)
      targetTime.setHours(targetHour, 0, 0, 0)
      
      // 指定時刻が過去の場合は明日に設定
      if (targetTime <= now) {
        targetTime.setDate(targetTime.getDate() + 1)
      }
      
      return targetTime.toISOString()
    }
    
    return null
  }

  // 時間をユーザーフレンドリーな形式で表示
  formatScheduleTime(isoString: string): string {
    const date = new Date(isoString)
    const now = new Date()
    
    const isToday = date.toDateString() === now.toDateString()
    const isTomorrow = date.toDateString() === new Date(now.getTime() + 24 * 60 * 60000).toDateString()
    
    const timeStr = date.toLocaleTimeString('ja-JP', { 
      hour: '2-digit', 
      minute: '2-digit' 
    })
    
    if (isToday) {
      return `今日 ${timeStr}`
    } else if (isTomorrow) {
      return `明日 ${timeStr}`
    } else {
      return `${date.toLocaleDateString('ja-JP')} ${timeStr}`
    }
  }
}

export const scheduleService = new ScheduleService()
export default scheduleService