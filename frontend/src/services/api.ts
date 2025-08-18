import axios, { type AxiosInstance, type AxiosResponse } from 'axios'


export interface ApiError {
  error: string
  details?: string
}

class ApiService {
  private api: AxiosInstance

  constructor() {
    // Capacitorモバイル環境用のAPI URL設定
    const getApiBaseUrl = () => {
      // Capacitorネイティブアプリの場合
      if (window.location.protocol === 'capacitor:') {
        // 実機テスト用：MacのローカルIPアドレスを使用
        return 'http://192.168.0.7:8080/api/v1'
      }
      // Web版の場合
      return 'http://localhost:8080/api/v1'
    }

    this.api = axios.create({
      baseURL: getApiBaseUrl(),
      timeout: 15000, // AI処理のため15秒に延長
      headers: {
        'Content-Type': 'application/json'
      }
    })

    // Firebase IDトークンは認証ストアで管理されるため、
    // ここではリクエスト・レスポンスインターセプターは最小限
  }



  async healthCheck(): Promise<any> {
    const url = window.location.protocol === 'capacitor:' 
      ? 'http://192.168.0.7:8080/health' 
      : 'http://localhost:8080/health'
    const response = await axios.get(url)
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