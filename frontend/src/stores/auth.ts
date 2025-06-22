import { ref, computed } from 'vue'
import { defineStore } from 'pinia'
import { apiService, type LoginRequest, type RegisterRequest, type AuthResponse } from '@/services/api'

export interface User {
  id: string
  name: string
  email: string
  timezone: string
  created_at: string
  updated_at: string
}

export const useAuthStore = defineStore('auth', () => {
  const user = ref<User | null>(null)
  const accessToken = ref<string | null>(null)
  const refreshToken = ref<string | null>(null)
  const isLoading = ref(false)
  const error = ref<string>('')

  const isAuthenticated = computed(() => !!accessToken.value && !!user.value)

  const isTokenExpired = (token: string): boolean => {
    try {
      const payload = JSON.parse(atob(token.split('.')[1]))
      const currentTime = Math.floor(Date.now() / 1000)
      return payload.exp < currentTime
    } catch (err) {
      return true
    }
  }

  const initializeAuth = async () => {
    console.log('Initializing auth...')
    const storedAccessToken = localStorage.getItem('access_token')
    const storedRefreshToken = localStorage.getItem('refresh_token')
    const storedUser = localStorage.getItem('user')

    console.log('Stored tokens:', {
      hasAccessToken: !!storedAccessToken,
      hasRefreshToken: !!storedRefreshToken,
      hasUser: !!storedUser
    })

    if (storedAccessToken && storedRefreshToken && storedUser) {
      accessToken.value = storedAccessToken
      refreshToken.value = storedRefreshToken
      try {
        user.value = JSON.parse(storedUser)
        console.log('Auth restored:', { user: user.value, isAuthenticated: isAuthenticated.value })
        
        // トークンの有効性をチェック（JWTの期限切れを確認）
        if (isTokenExpired(storedAccessToken)) {
          console.log('Token expired, attempting refresh...')
          // トークンが期限切れの場合、リフレッシュを試行
          const refreshSuccess = await refreshAuthToken()
          if (!refreshSuccess) {
            console.log('Token refresh failed, clearing auth')
            clearAuth()
          }
        }
      } catch (err) {
        console.error('認証情報の復元に失敗:', err)
        clearAuth()
      }
    } else {
      console.log('No stored auth found')
    }
  }

  const saveAuthData = (authResponse: AuthResponse) => {
    const { access_token, refresh_token, user: userData } = authResponse.data
    
    accessToken.value = access_token
    refreshToken.value = refresh_token
    user.value = userData

    localStorage.setItem('access_token', access_token)
    localStorage.setItem('refresh_token', refresh_token)
    localStorage.setItem('user', JSON.stringify(userData))
  }

  const clearAuth = () => {
    user.value = null
    accessToken.value = null
    refreshToken.value = null

    localStorage.removeItem('access_token')
    localStorage.removeItem('refresh_token')
    localStorage.removeItem('user')
  }

  const login = async (credentials: LoginRequest): Promise<boolean> => {
    isLoading.value = true
    error.value = ''

    try {
      const response = await apiService.login(credentials)
      saveAuthData(response)
      return true
    } catch (err: any) {
      error.value = err.response?.data?.error || 'ログインに失敗しました'
      return false
    } finally {
      isLoading.value = false
    }
  }

  const register = async (userData: RegisterRequest): Promise<boolean> => {
    isLoading.value = true
    error.value = ''

    try {
      const response = await apiService.register(userData)
      saveAuthData(response)
      return true
    } catch (err: any) {
      error.value = err.response?.data?.error || 'ユーザー登録に失敗しました'
      return false
    } finally {
      isLoading.value = false
    }
  }

  const logout = async (): Promise<void> => {
    isLoading.value = true

    try {
      if (accessToken.value) {
        await apiService.logout()
      }
    } catch (err) {
      console.warn('ログアウト処理でエラーが発生しましたが、ローカル認証情報をクリアします')
    } finally {
      clearAuth()
      isLoading.value = false
    }
  }

  const refreshAuthToken = async (): Promise<boolean> => {
    if (!refreshToken.value) {
      clearAuth()
      return false
    }

    try {
      const response = await apiService.refreshToken({
        refresh_token: refreshToken.value
      })
      saveAuthData(response)
      return true
    } catch (err) {
      clearAuth()
      return false
    }
  }

  return {
    user: computed(() => user.value),
    isAuthenticated,
    isLoading: computed(() => isLoading.value),
    error: computed(() => error.value),
    initializeAuth,
    login,
    register,
    logout,
    refreshAuthToken,
    clearAuth
  }
})