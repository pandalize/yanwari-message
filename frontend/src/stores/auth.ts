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
      const response = await apiService.get('/users/me')
      appUser.value = response.data.data
      
      console.log('✅ アプリユーザー情報取得成功:', appUser.value?.name)
    } catch (err) {
      console.error('❌ アプリユーザー情報取得エラー:', err)
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
      return token
    } catch (err) {
      console.error('❌ IDトークン更新エラー:', err)
      throw err
    }
  }

  // ユーザー情報の更新（設定画面用）
  const updateUserProfile = (updatedUserData: Partial<AppUser>) => {
    if (appUser.value) {
      const newUser = { ...appUser.value, ...updatedUserData }
      appUser.value = newUser
      console.log('✅ ユーザー情報を更新しました:', newUser.name)
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
    fetchAppUserInfo,
    updateUserProfile
  }
})