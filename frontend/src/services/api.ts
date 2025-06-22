import axios, { type AxiosInstance, type AxiosResponse } from 'axios'

export interface LoginRequest {
  email: string
  password: string
}

export interface RegisterRequest {
  name: string
  email: string
  password: string
}

export interface AuthResponse {
  data: {
    access_token: string
    refresh_token: string
    expires_in: number
    user: {
      id: string
      name: string
      email: string
      timezone: string
      created_at: string
      updated_at: string
    }
  }
  message: string
}

export interface RefreshRequest {
  refresh_token: string
}

export interface ApiError {
  error: string
  details?: string
}

class ApiService {
  private api: AxiosInstance

  constructor() {
    this.api = axios.create({
      baseURL: 'http://localhost:8080/api/v1',
      timeout: 10000,
      headers: {
        'Content-Type': 'application/json'
      }
    })

    this.api.interceptors.request.use(
      (config) => {
        const token = localStorage.getItem('access_token')
        if (token) {
          config.headers.Authorization = `Bearer ${token}`
        }
        return config
      },
      (error) => Promise.reject(error)
    )

    this.api.interceptors.response.use(
      (response) => response,
      async (error) => {
        if (error.response?.status === 401) {
          await this.handleTokenRefresh()
        }
        return Promise.reject(error)
      }
    )
  }

  private async handleTokenRefresh(): Promise<void> {
    const refreshToken = localStorage.getItem('refresh_token')
    if (!refreshToken) {
      this.clearTokens()
      return
    }

    try {
      const response = await axios.post<AuthResponse>(
        'http://localhost:8080/api/v1/auth/refresh',
        { refresh_token: refreshToken }
      )
      
      const { access_token, refresh_token } = response.data.data
      localStorage.setItem('access_token', access_token)
      localStorage.setItem('refresh_token', refresh_token)
    } catch (error) {
      this.clearTokens()
      window.location.href = '/login'
    }
  }

  private clearTokens(): void {
    localStorage.removeItem('access_token')
    localStorage.removeItem('refresh_token')
  }

  async login(credentials: LoginRequest): Promise<AuthResponse> {
    const response: AxiosResponse<AuthResponse> = await this.api.post('/auth/login', credentials)
    return response.data
  }

  async register(userData: RegisterRequest): Promise<AuthResponse> {
    const response: AxiosResponse<AuthResponse> = await this.api.post('/auth/register', userData)
    return response.data
  }

  async refreshToken(refreshData: RefreshRequest): Promise<AuthResponse> {
    const response: AxiosResponse<AuthResponse> = await this.api.post('/auth/refresh', refreshData)
    return response.data
  }

  async logout(): Promise<void> {
    await this.api.post('/auth/logout')
    this.clearTokens()
  }

  async healthCheck(): Promise<any> {
    const response = await axios.get('http://localhost:8080/health')
    return response.data
  }
}

export const apiService = new ApiService()