import axios, { type AxiosInstance, type AxiosResponse } from 'axios'


export interface ApiError {
  error: string
  details?: string
}

class ApiService {
  private api: AxiosInstance

  constructor() {
    this.api = axios.create({
      baseURL: 'http://localhost:8080/api/v1',
      timeout: 15000, // AI処理のため15秒に延長
      headers: {
        'Content-Type': 'application/json'
      }
    })

    // レスポンスインターセプター（自動トークン更新 + エラー処理）
    this.api.interceptors.response.use(
      (response) => response,
      async (error) => {
        console.error('API Error:', error.response?.data || error.message)
        
        // 401エラーの場合、トークンリフレッシュを試みる
        if (error.response?.status === 401) {
          console.log('🔄 401エラー - トークンリフレッシュを試行')
          try {
            // authStoreをdynamic importで取得
            const { useAuthStore } = await import('@/stores/auth')
            const authStore = useAuthStore()
            
            // トークンリフレッシュ
            const newToken = await authStore.refreshIdToken()
            if (newToken) {
              console.log('✅ トークンリフレッシュ成功 - リクエスト再試行')
              // 元のリクエストを新しいトークンで再試行
              error.config.headers['Authorization'] = `Bearer ${newToken}`
              return this.api.request(error.config)
            }
          } catch (refreshError) {
            console.error('❌ トークンリフレッシュ失敗:', refreshError)
            // リフレッシュ失敗時はログアウト処理
            const { useAuthStore } = await import('@/stores/auth')
            const authStore = useAuthStore()
            await authStore.logout()
          }
        }
        
        return Promise.reject(error)
      }
    )
  }



  async healthCheck(): Promise<any> {
    const response = await axios.get('http://localhost:8080/health')
    return response.data
  }

  // 汎用的なHTTPメソッド（他のサービスで使用）
  async get(url: string): Promise<AxiosResponse> {
    return this.api.get(url)
  }

  async post(url: string, data?: any): Promise<AxiosResponse> {
    return this.api.post(url, data)
  }

  async put(url: string, data?: any): Promise<AxiosResponse> {
    return this.api.put(url, data)
  }

  async delete(url: string): Promise<AxiosResponse> {
    return this.api.delete(url)
  }

  // Firebase IDトークンを設定
  setAuthToken(token: string) {
    this.api.defaults.headers.common['Authorization'] = `Bearer ${token}`
  }

  // 認証ヘッダーをクリア
  clearAuthToken() {
    delete this.api.defaults.headers.common['Authorization']
  }

}

export const apiService = new ApiService()