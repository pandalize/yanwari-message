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
      component: () => import('../views/LoginView.vue'),
      meta: { requiresAuth: false }
    },
    {
      path: '/register',
      name: 'register',
      component: () => import('../views/RegisterView.vue'),
      meta: { requiresAuth: false }
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
      component: () => import('../views/ScheduleView.vue'),
      meta: { requiresAuth: true }
    },
    {
      path: '/schedules',
      name: 'schedule-list',
      component: () => import('../views/ScheduleListView.vue'),
      meta: { requiresAuth: true }
    },
    {
      path: '/schedules/:id/edit',
      name: 'schedule-edit',
      component: () => import('../views/ScheduleEditView.vue'),
      meta: { requiresAuth: true }
    },
    {
      path: '/about',
      name: 'about',
      component: () => import('../views/AboutView.vue'),
      meta: { requiresAuth: false }
    },
  ],
})

router.beforeEach((to, from, next) => {
  const authStore = useAuthStore()
  
  console.log('Router navigation:', {
    to: to.path,
    authenticated: authStore.isAuthenticated,
    requiresAuth: to.meta.requiresAuth,
    user: authStore.user
  })
  
  if (to.meta.requiresAuth && !authStore.isAuthenticated) {
    console.log('Redirecting to login - authentication required')
    next('/login')
  } else if ((to.name === 'login' || to.name === 'register') && authStore.isAuthenticated) {
    console.log('Redirecting to home - already authenticated')
    next('/')
  } else {
    console.log('Navigation allowed')
    next()
  }
})

export default router
