import { createRouter, createWebHistory } from 'vue-router'
import HomeView from '../views/HomeView.vue'
import { useAuthStore } from '@/stores/auth'

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    {
      path: '/',
      name: 'home',
      component: HomeView,
      meta: { requiresAuth: false }
    },
    {
      path: '/login',
      name: 'login',
      component: () => import('../views/FirebaseLoginView.vue'),
      meta: { requiresAuth: false }
    },
    {
      path: '/register',
      name: 'register',
      component: () => import('../views/FirebaseRegisterView.vue'),
      meta: { requiresAuth: false }
    },
    {
      path: '/recipient-select',
      name: 'recipient-select',
      component: () => import('../views/RecipientSelectView.vue'),
      meta: { requiresAuth: true }
    },
    {
      path: '/compose',
      name: 'message-compose',
      component: () => import('../views/MessageComposeView.vue'),
      meta: { requiresAuth: true }
    },
    {
      path: '/messages/:id/transform',
      name: 'tone-transform',
      component: () => import('../views/ToneTransformView.vue'),
      meta: { requiresAuth: true }
    },
    {
      path: '/schedule',
      name: 'schedule-wizard',
      component: () => import('../views/ScheduleWizardView.vue'),
      meta: { requiresAuth: true }
    },
    {
      path: '/schedules',
      name: 'schedule-list',
      component: () => import('../views/ScheduleListView.vue'),
      meta: { requiresAuth: true }
    },
    {
      path: '/history',
      name: 'message-history',
      component: () => import('../views/HistoryView.vue'),
      meta: { requiresAuth: true }
    },
    {
      path: '/history-simple',
      name: 'message-history-simple',
      component: () => import('../views/SimpleHistoryView.vue'),
      meta: { requiresAuth: true }
    },
    {
      path: '/history-original',
      name: 'message-history-original',
      component: () => import('../views/HistoryView.vue'),
      meta: { requiresAuth: true }
    },
    {
      path: '/inbox',
      name: 'inbox',
      component: () => import('../views/InboxView.vue'),
      meta: { requiresAuth: true }
    },
    {
      path: '/delivery-status',
      name: 'delivery-status',
      component: () => import('../views/DeliveryStatusView.vue'),
      meta: { requiresAuth: true }
    },
    {
      path: '/settings',
      name: 'settings',
      component: () => import('../views/SettingsView.vue'),
      meta: { requiresAuth: true }
    },
    {
      path: '/friends',
      name: 'friends',
      component: () => import('../views/FriendsView.vue'),
      meta: { requiresAuth: true }
    },
    {
      path: '/about',
      name: 'about',
      component: () => import('../views/AboutView.vue'),
      meta: { requiresAuth: false }
    },
    {
      path: '/test-history',
      name: 'test-history',
      component: () => import('../views/TestHistoryView.vue'),
      meta: { requiresAuth: true }
    },
    {
      path: '/test-treemap',
      name: 'test-treemap',
      component: () => import('../views/TreemapTestView.vue'),
      meta: { requiresAuth: false }
    },
  ],
})

router.beforeEach(async (to, from, next) => {
  const authStore = useAuthStore()
  
  console.log('🔥 Router navigation:', {
    from: from.path,
    to: to.path,
    authenticated: authStore.isAuthenticated,
    initializing: authStore.isInitializing,
    requiresAuth: to.meta.requiresAuth,
    routeName: to.name
  })
  
  // 初期化中は待機
  if (authStore.isInitializing) {
    console.log('🔥 Firebase認証初期化中 - 待機...')
    await authStore.initializeAuth()
    console.log('🔥 Firebase認証初期化完了 - ナビゲーション続行')
  }
  
  // Firebase認証ルートガード
  if (to.meta.requiresAuth && !authStore.isAuthenticated) {
    console.log('🔥 Redirecting to login - authentication required')
    next('/login')
  } else if ((to.name === 'login' || to.name === 'register') && authStore.isAuthenticated) {
    console.log('🔥 Redirecting to home - already authenticated')
    next('/')
  } else {
    console.log('🔥 Navigation allowed - proceeding to:', to.path)
    next()
  }
})

export default router
