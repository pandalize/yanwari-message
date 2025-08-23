import './assets/main.css'

import { createApp } from 'vue'
import { createPinia } from 'pinia'

import App from './App.vue'
import router from './router'
import { useJWTAuthStore } from '@/stores/jwtAuth'

// viewport スケールリセット機能
function resetViewportScale() {
  const viewport = document.querySelector('meta[name="viewport"]')
  if (viewport) {
    viewport.setAttribute('content', 'width=device-width, initial-scale=1.0, user-scalable=yes, minimum-scale=0.1, maximum-scale=10.0')
  }
}

// アプリケーション初期化の非同期関数
async function initializeApp() {
  const app = createApp(App)
  const pinia = createPinia()

  app.use(pinia)
  app.use(router)

  // viewport スケールリセット
  resetViewportScale()

  // ルーター変更時のviewportリセット
  router.beforeEach((to, from, next) => {
    resetViewportScale()
    next()
  })

  // JWT認証の初期化を待機
  console.log('🔑 JWT認証初期化を開始...')
  const authStore = useJWTAuthStore()
  await authStore.initializeAuth()
  console.log('🔑 JWT認証初期化完了 - アプリをマウント')

  app.mount('#app')
}

// アプリケーション初期化実行
initializeApp().catch(console.error)
