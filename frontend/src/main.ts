import './assets/main.css'

import { createApp } from 'vue'
import { createPinia } from 'pinia'

import App from './App.vue'
import router from './router'
import { useJWTAuthStore } from '@/stores/jwtAuth'

// アプリケーション初期化の非同期関数
async function initializeApp() {
  const app = createApp(App)
  const pinia = createPinia()

  app.use(pinia)
  app.use(router)

  // JWT認証の初期化を待機
  console.log('🔑 JWT認証初期化を開始...')
  const authStore = useJWTAuthStore()
  await authStore.initializeAuth()
  console.log('🔑 JWT認証初期化完了 - アプリをマウント')

  app.mount('#app')
}

// アプリケーション初期化実行
initializeApp().catch(console.error)
