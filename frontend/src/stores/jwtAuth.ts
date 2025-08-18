import { ref, computed } from 'vue'
import { defineStore } from 'pinia'
import { apiService } from '@/services/api'

export interface User {
  id: string
  name: string
  email: string
  profile?: {
    bio?: string
    avatar_url?: string
    timezone?: string
  }
  created_at: string
  updated_at: string
}

export interface LoginResponse {
  access_token: string
  refresh_token: string
  user: User
}

export const useJWTAuthStore = defineStore('jwtAuth', () => {
  const user = ref<User | null>(null)
  const accessToken = ref<string | null>(null)
  const refreshToken = ref<string | null>(null)
  const isLoading = ref(false)
  const error = ref<string>('')
  const isInitializing = ref(true)

  const isAuthenticated = computed(() => {
    if (isInitializing.value) return false
    return !!user.value && !!accessToken.value
  })

  // ローカルストレージからトークンを復元
  const initializeAuth = async () => {
    console.log('🔑 JWT認証を初期化中...')
    isLoading.value = true
    
    try {
      // ローカルストレージからトークンを取得
      const savedAccessToken = localStorage.getItem('access_token')
      const savedRefreshToken = localStorage.getItem('refresh_token')
      
      if (savedAccessToken && savedRefreshToken) {
        accessToken.value = savedAccessToken
        refreshToken.value = savedRefreshToken
        
        // APIサービスにトークンを設定
        apiService.setAuthToken(savedAccessToken)
        
        // ユーザー情報を取得して認証確認
        await fetchUserInfo()
        console.log('✅ JWT認証復元成功:', user.value?.name)
      } else {
        console.log('💡 保存されたトークンがありません')
      }
    } catch (err) {
      console.error('❌ JWT認証復元エラー:', err)
      // トークンが無効な場合はクリア
      await logout()
    } finally {
      isLoading.value = false
      isInitializing.value = false
    }
  }

  // ユーザー情報を取得
  const fetchUserInfo = async () => {
    if (!accessToken.value) throw new Error('アクセストークンが必要です')
    
    try {
      const response = await apiService.get('/users/me')
      user.value = response.data.data
      console.log('✅ ユーザー情報取得成功:', user.value?.name)
    } catch (err: any) {
      console.error('❌ ユーザー情報取得エラー:', err)
      throw err
    }
  }

  // ログイン
  const login = async (email: string, password: string) => {
    try {
      isLoading.value = true
      error.value = ''
      
      console.log('🔑 JWT ログイン開始:', email)
      const response = await apiService.post('/auth/login', { email, password })
      
      const loginData: LoginResponse = response.data.data
      
      // トークンとユーザー情報を保存
      accessToken.value = loginData.access_token
      refreshToken.value = loginData.refresh_token
      user.value = loginData.user
      
      // ローカルストレージに保存
      localStorage.setItem('access_token', loginData.access_token)
      localStorage.setItem('refresh_token', loginData.refresh_token)
      
      // APIサービスにトークンを設定
      apiService.setAuthToken(loginData.access_token)
      
      console.log('✅ JWT ログイン成功:', user.value?.name)
    } catch (err: any) {
      console.error('❌ JWT ログインエラー:', err)
      const errorMessage = err.response?.data?.error || err.message || 'ログインに失敗しました'
      error.value = errorMessage
      throw new Error(errorMessage)
    } finally {
      isLoading.value = false
    }
  }

  // ユーザー登録
  const register = async (email: string, password: string, name: string) => {
    try {
      isLoading.value = true
      error.value = ''
      
      console.log('🔑 JWT ユーザー登録開始:', email)
      const response = await apiService.post('/auth/register', { 
        email, 
        password, 
        name 
      })
      
      const registerData: LoginResponse = response.data.data
      
      // トークンとユーザー情報を保存
      accessToken.value = registerData.access_token
      refreshToken.value = registerData.refresh_token
      user.value = registerData.user
      
      // ローカルストレージに保存
      localStorage.setItem('access_token', registerData.access_token)
      localStorage.setItem('refresh_token', registerData.refresh_token)
      
      // APIサービスにトークンを設定
      apiService.setAuthToken(registerData.access_token)
      
      console.log('✅ JWT ユーザー登録成功:', user.value?.name)
    } catch (err: any) {
      console.error('❌ JWT ユーザー登録エラー:', err)
      const errorMessage = err.response?.data?.error || err.message || 'ユーザー登録に失敗しました'
      error.value = errorMessage
      throw new Error(errorMessage)
    } finally {
      isLoading.value = false
    }
  }

  // ログアウト
  const logout = async () => {
    try {
      console.log('🔑 JWT ログアウト開始')
      
      // サーバーにログアウト通知（ベストエフォート）
      if (accessToken.value) {
        try {
          await apiService.post('/auth/logout')
        } catch (err) {
          console.warn('⚠️ サーバーログアウト通知に失敗（継続）:', err)
        }
      }
      
      // 状態をクリア
      user.value = null
      accessToken.value = null
      refreshToken.value = null
      error.value = ''
      
      // ローカルストレージをクリア
      localStorage.removeItem('access_token')
      localStorage.removeItem('refresh_token')
      
      // API認証ヘッダーをクリア
      apiService.clearAuthToken()
      
      console.log('✅ JWT ログアウト完了')
    } catch (err) {
      console.error('❌ JWT ログアウトエラー:', err)
      error.value = err instanceof Error ? err.message : 'ログアウトに失敗しました'
    }
  }

  // アクセストークンの更新
  const refreshAccessToken = async () => {
    if (!refreshToken.value) {
      throw new Error('リフレッシュトークンがありません')
    }
    
    try {
      console.log('🔄 JWT トークン更新中...')
      const response = await apiService.post('/auth/refresh', {
        refresh_token: refreshToken.value
      })
      
      const refreshData = response.data.data
      
      // 新しいトークンを保存
      accessToken.value = refreshData.access_token
      
      // 新しいリフレッシュトークンがある場合は更新
      if (refreshData.refresh_token) {
        refreshToken.value = refreshData.refresh_token
        localStorage.setItem('refresh_token', refreshData.refresh_token)
      }
      
      localStorage.setItem('access_token', refreshData.access_token)
      apiService.setAuthToken(refreshData.access_token)
      
      console.log('✅ JWT トークン更新成功')
      return refreshData.access_token
    } catch (err) {
      console.error('❌ JWT トークン更新エラー:', err)
      // リフレッシュ失敗時は完全ログアウト
      await logout()
      throw err
    }
  }

  return {
    // 状態
    user,
    accessToken,
    refreshToken,
    isLoading,
    error,
    isInitializing,
    isAuthenticated,
    
    // アクション
    initializeAuth,
    login,
    register,
    logout,
    refreshAccessToken,
    fetchUserInfo
  }
})