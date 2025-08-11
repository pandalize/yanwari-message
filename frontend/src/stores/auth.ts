import { ref, computed } from 'vue'
import { defineStore } from 'pinia'
import { firebaseAuthService } from '@/services/firebase'
import type { User as FirebaseUser } from 'firebase/auth'
import { apiService } from '@/services/api'

export interface AppUser {
  id: string
  name: string
  email: string
  firebase_uid: string
  timezone: string
  created_at: string
  updated_at: string
}

export const useAuthStore = defineStore('auth', () => {
  const firebaseUser = ref<FirebaseUser | null>(null)
  const appUser = ref<AppUser | null>(null)
  const idToken = ref<string | null>(null)
  const isLoading = ref(false)
  const error = ref<string>('')
  const isInitializing = ref(true) // 初期化中フラグ

  const isAuthenticated = computed(() => {
    // 初期化中は認証状態をチェックしない
    if (isInitializing.value) return false
    return !!firebaseUser.value && !!appUser.value && !!idToken.value
  })

  // Firebase認証状態の初期化
  const initializeAuth = async () => {
    console.log('🔥 Firebase認証を初期化中...')
    isLoading.value = true
    let isInitialized = false
    
    return new Promise<void>((resolve) => {
      // 認証状態の変更を継続的に監視
      firebaseAuthService.onAuthStateChanged(async (user) => {
        console.log('🔥 Firebase認証状態変更:', user?.email || 'ログアウト')
        firebaseUser.value = user
        
        if (user) {
          try {
            // IDトークンを取得
            const token = await user.getIdToken()
            idToken.value = token
            
            // バックエンドからアプリユーザー情報を取得
            await fetchAppUserInfo()
            
            console.log('✅ Firebase認証完了:', { 
              firebaseUser: user.email, 
              appUser: appUser.value?.name 
            })
          } catch (err) {
            console.error('❌ Firebase認証エラー:', err)
            error.value = err instanceof Error ? err.message : 'Firebase認証に失敗しました'
            await logout() // エラー時はログアウト
          }
        } else {
          // ログアウト状態
          appUser.value = null
          idToken.value = null
          error.value = ''
        }
        
        isLoading.value = false
        
        // 初回のみresolve
        if (!isInitialized) {
          isInitialized = true
          isInitializing.value = false // 初期化完了フラグ
          resolve()
        }
      })
    })
  }

  // バックエンドからアプリユーザー情報を取得
  const fetchAppUserInfo = async () => {
    if (!idToken.value) throw new Error('IDトークンが必要です')
    
    try {
      // APIサービスにFirebase IDトークンを設定
      apiService.setAuthToken(idToken.value)
      
      // バックエンドからユーザー情報を取得
      const response = await apiService.get('/firebase-auth/profile')
      
      // レスポンスがdata.userの形式の場合
      if (response.data?.data?.user) {
        appUser.value = response.data.data.user
      } else if (response.data?.data) {
        appUser.value = response.data.data
      } else {
        throw new Error('ユーザー情報の形式が不正です')
      }
      
      console.log('✅ アプリユーザー情報取得成功:', appUser.value?.name || appUser.value?.email)
    } catch (err: any) {
      console.error('❌ アプリユーザー情報取得エラー:', err)
      console.error('❌ エラー詳細:', err.response?.data)
      
      // 404の場合はユーザー同期を試みる
      if (err.response?.status === 404) {
        console.log('🔄 ユーザー同期を試みています...')
        try {
          const syncResponse = await apiService.post('/firebase-auth/sync')
          if (syncResponse.data?.data?.user) {
            appUser.value = syncResponse.data.data.user
            console.log('✅ ユーザー同期成功:', appUser.value?.name || appUser.value?.email)
            return
          }
        } catch (syncErr) {
          console.error('❌ ユーザー同期エラー:', syncErr)
        }
      }
      
      throw err
    }
  }

  // ログイン
  const login = async (email: string, password: string) => {
    try {
      isLoading.value = true
      error.value = ''
      
      console.log('🔥 Firebase ログイン開始:', email)
      const user = await firebaseAuthService.login(email, password)
      
      // IDトークンを取得
      const token = await user.getIdToken()
      idToken.value = token
      firebaseUser.value = user
      
      // バックエンドからアプリユーザー情報を取得
      await fetchAppUserInfo()
      
      console.log('✅ ログイン成功:', { 
        firebaseUser: user.email, 
        appUser: appUser.value?.name 
      })
      
      // 定期トークン更新を開始
      startTokenRefresh()
    } catch (err) {
      console.error('❌ ログインエラー:', err)
      error.value = err instanceof Error ? err.message : 'ログインに失敗しました'
      throw err
    } finally {
      isLoading.value = false
    }
  }

  // ユーザー登録
  const register = async (email: string, password: string, name: string) => {
    try {
      isLoading.value = true
      error.value = ''
      
      console.log('🔥 Firebase ユーザー登録開始:', email)
      const user = await firebaseAuthService.register(email, password)
      
      // バックエンドでアプリユーザーを作成
      const token = await user.getIdToken()
      idToken.value = token
      firebaseUser.value = user
      
      // バックエンドに同期（ユーザー作成）
      apiService.setAuthToken(token)
      await apiService.post('/firebase-auth/sync', { 
        name, 
        timezone: 'Asia/Tokyo' 
      })
      
      // アプリユーザー情報を取得
      await fetchAppUserInfo()
      
      console.log('✅ ユーザー登録成功:', { 
        firebaseUser: user.email, 
        appUser: appUser.value?.name 
      })
    } catch (err) {
      console.error('❌ ユーザー登録エラー:', err)
      error.value = err instanceof Error ? err.message : 'ユーザー登録に失敗しました'
      throw err
    } finally {
      isLoading.value = false
    }
  }

  // ログアウト
  const logout = async () => {
    try {
      console.log('🔥 Firebase ログアウト開始')
      await firebaseAuthService.logout()
      
      // 状態をクリア
      firebaseUser.value = null
      appUser.value = null
      idToken.value = null
      error.value = ''
      
      // API認証ヘッダーをクリア
      apiService.clearAuthToken()
      
      console.log('✅ ログアウト完了')
      
      // 定期トークン更新を停止
      stopTokenRefresh()
    } catch (err) {
      console.error('❌ ログアウトエラー:', err)
      error.value = err instanceof Error ? err.message : 'ログアウトに失敗しました'
    }
  }

  // IDトークンの更新
  const refreshIdToken = async () => {
    if (!firebaseUser.value) return null
    
    try {
      const token = await firebaseUser.value.getIdToken(true) // 強制更新
      idToken.value = token
      apiService.setAuthToken(token)
      console.log('🎫 IDトークン更新完了')
      return token
    } catch (err) {
      console.error('❌ IDトークン更新エラー:', err)
      throw err
    }
  }

  // 定期的なトークン更新（50分ごと）
  let tokenRefreshInterval: number | null = null
  
  const startTokenRefresh = () => {
    stopTokenRefresh() // 既存のタイマーをクリア
    tokenRefreshInterval = window.setInterval(async () => {
      if (firebaseUser.value && isAuthenticated.value) {
        console.log('🔄 定期トークン更新を実行')
        try {
          await refreshIdToken()
        } catch (err) {
          console.error('❌ 定期トークン更新失敗:', err)
        }
      }
    }, 50 * 60 * 1000) // 50分
  }
  
  const stopTokenRefresh = () => {
    if (tokenRefreshInterval) {
      clearInterval(tokenRefreshInterval)
      tokenRefreshInterval = null
    }
  }

  return {
    // 状態
    firebaseUser,
    appUser,
    idToken,
    isLoading,
    error,
    isInitializing,
    isAuthenticated,
    
    // アクション
    initializeAuth,
    login,
    register,
    logout,
    refreshIdToken,
    fetchAppUserInfo
  }
})