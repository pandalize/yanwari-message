import './assets/main.css'

import { createApp } from 'vue'
import { createPinia } from 'pinia'

import App from './App.vue'
import router from './router'
import { useAuthStore } from '@/stores/auth'

// アプリケーション初期化の非同期関数
async function initializeApp() {
  const app = createApp(App)
  const pinia = createPinia()

  app.use(pinia)
  app.use(router)

  // Firebase認証の初期化を待機
  console.log('🔥 Firebase認証初期化を開始...')
  const authStore = useAuthStore()
  await authStore.initializeAuth()
  console.log('🔥 Firebase認証初期化完了 - アプリをマウント')

  app.mount('#app')
}

// アプリケーション初期化実行
initializeApp().catch(console.error)
