import './assets/main.css'

import { createApp } from 'vue'
import { createPinia } from 'pinia'

import App from './App.vue'
import router from './router'
import { useAuthStore } from '@/stores/auth'

// デバッグ用のシンプルな初期化
async function initializeApp() {
  console.log('🚀 アプリケーション初期化開始...')
  
  try {
    const app = createApp(App)
    const pinia = createPinia()

    app.use(pinia)
    app.use(router)

    console.log('🔄 Firebase認証初期化開始...')
    
    // Firebase認証初期化にタイムアウトを設定
    const authStore = useAuthStore()
    
    const initPromise = authStore.initializeAuth()
    const timeoutPromise = new Promise((_, reject) => 
      setTimeout(() => reject(new Error('Firebase初期化タイムアウト')), 10000)
    )
    
    try {
      await Promise.race([initPromise, timeoutPromise])
      console.log('✅ Firebase認証初期化完了')
    } catch (error) {
      console.warn('⚠️ Firebase認証初期化失敗:', error)
      // Firebase初期化失敗でもアプリは起動
    }

    console.log('🎯 アプリをマウント中...')
    app.mount('#app')
    console.log('✅ アプリケーション起動完了')
    
  } catch (error) {
    console.error('❌ アプリケーション初期化エラー:', error)
    // 最低限のアプリを起動
    const app = createApp(App)
    const pinia = createPinia()
    app.use(pinia)
    app.use(router)
    app.mount('#app')
  }
}

// エラーハンドリング付きで初期化実行
initializeApp().catch(error => {
  console.error('❌ 致命的エラー:', error)
  // 最終手段: 基本的なVueアプリを起動
  const app = createApp(App)
  app.mount('#app')
})