<template>
  <div class="settings-view">
    <div class="settings-container">
      <!-- ページヘッダー -->
      <div class="settings-header">
        <h1 class="page-title">⚙️ 設定</h1>
        <p class="page-subtitle">アカウントとアプリケーションの設定を管理</p>
      </div>

      <!-- 設定セクション -->
      <div class="settings-sections">
        
        <!-- プロフィール設定 -->
        <div class="settings-section">
          <h2 class="section-title">👤 プロフィール設定</h2>
          <div class="settings-card">
            <div class="form-group">
              <label for="displayName">表示名</label>
              <input 
                id="displayName"
                v-model="profileForm.displayName"
                type="text" 
                class="form-input"
                placeholder="表示名を入力"
              />
              <small class="form-hint">他のユーザーに表示される名前です</small>
            </div>

            <div class="form-group">
              <label for="email">メールアドレス</label>
              <input 
                id="email"
                v-model="profileForm.email"
                type="email" 
                class="form-input"
                readonly
              />
              <small class="form-hint">メールアドレスの変更はサポートまでご連絡ください</small>
            </div>

            <div class="form-actions">
              <button 
                @click="updateProfile"
                :disabled="isUpdatingProfile"
                class="btn btn-primary"
              >
                {{ isUpdatingProfile ? '更新中...' : '💾 プロフィール更新' }}
              </button>
            </div>
          </div>
        </div>

        <!-- パスワード変更 -->
        <div class="settings-section">
          <h2 class="section-title">🔒 パスワード変更</h2>
          <div class="settings-card">
            <div class="form-group">
              <label for="currentPassword">現在のパスワード</label>
              <input 
                id="currentPassword"
                v-model="passwordForm.currentPassword"
                type="password" 
                class="form-input"
                placeholder="現在のパスワード"
              />
            </div>

            <div class="form-group">
              <label for="newPassword">新しいパスワード</label>
              <input 
                id="newPassword"
                v-model="passwordForm.newPassword"
                type="password" 
                class="form-input"
                placeholder="新しいパスワード（8文字以上）"
              />
            </div>

            <div class="form-group">
              <label for="confirmPassword">新しいパスワード（確認）</label>
              <input 
                id="confirmPassword"
                v-model="passwordForm.confirmPassword"
                type="password" 
                class="form-input"
                placeholder="新しいパスワードを再入力"
              />
            </div>

            <div class="form-actions">
              <button 
                @click="changePassword"
                :disabled="!canChangePassword || isChangingPassword"
                class="btn btn-primary"
              >
                {{ isChangingPassword ? '変更中...' : '🔐 パスワード変更' }}
              </button>
            </div>
          </div>
        </div>

        <!-- 通知設定 -->
        <div class="settings-section">
          <h2 class="section-title">🔔 通知設定</h2>
          <div class="settings-card">
            <div class="setting-item">
              <div class="setting-info">
                <h3>メール通知</h3>
                <p>メッセージ受信時にメール通知を送信</p>
              </div>
              <div class="setting-control">
                <label class="toggle-switch">
                  <input 
                    type="checkbox" 
                    v-model="notificationSettings.emailNotifications"
                    @change="updateNotificationSettings"
                  />
                  <span class="toggle-slider"></span>
                </label>
              </div>
            </div>

            <div class="setting-item">
              <div class="setting-info">
                <h3>送信完了通知</h3>
                <p>メッセージ送信完了時に通知</p>
              </div>
              <div class="setting-control">
                <label class="toggle-switch">
                  <input 
                    type="checkbox" 
                    v-model="notificationSettings.sendNotifications"
                    @change="updateNotificationSettings"
                  />
                  <span class="toggle-slider"></span>
                </label>
              </div>
            </div>

            <div class="setting-item">
              <div class="setting-info">
                <h3>アプリ内通知</h3>
                <p>ブラウザ内での通知表示</p>
              </div>
              <div class="setting-control">
                <label class="toggle-switch">
                  <input 
                    type="checkbox" 
                    v-model="notificationSettings.browserNotifications"
                    @change="updateNotificationSettings"
                  />
                  <span class="toggle-slider"></span>
                </label>
              </div>
            </div>
          </div>
        </div>

        <!-- メッセージ設定 -->
        <div class="settings-section">
          <h2 class="section-title">💬 メッセージ設定</h2>
          <div class="settings-card">
            <div class="form-group">
              <label for="defaultTone">デフォルトトーン</label>
              <select 
                id="defaultTone"
                v-model="messageSettings.defaultTone"
                class="form-select"
                @change="updateMessageSettings"
              >
                <option value="gentle">💝 やんわり</option>
                <option value="constructive">🏗️ 建設的</option>
                <option value="casual">🎯 カジュアル</option>
              </select>
              <small class="form-hint">新しいメッセージ作成時の初期トーン</small>
            </div>

            <div class="form-group">
              <label for="timeRestriction">送信時間制限</label>
              <select 
                id="timeRestriction"
                v-model="messageSettings.timeRestriction"
                class="form-select"
                @change="updateMessageSettings"
              >
                <option value="none">制限なし</option>
                <option value="business_hours">営業時間のみ（9:00-18:00）</option>
                <option value="extended_hours">拡張時間（8:00-20:00）</option>
              </select>
              <small class="form-hint">メッセージ送信可能な時間帯</small>
            </div>
          </div>
        </div>

        <!-- アカウント管理 -->
        <div class="settings-section">
          <h2 class="section-title">🔧 アカウント管理</h2>
          <div class="settings-card">
            <div class="account-actions">
              <div class="account-action">
                <div class="action-info">
                  <h3>ログアウト</h3>
                  <p>現在のセッションからログアウトします</p>
                </div>
                <button @click="logout" class="btn btn-secondary">
                  🚪 ログアウト
                </button>
              </div>

              <div class="account-action danger">
                <div class="action-info">
                  <h3>アカウント削除</h3>
                  <p>アカウントと全てのデータが完全に削除されます</p>
                </div>
                <button @click="showDeleteConfirmation" class="btn btn-danger">
                  🗑️ アカウント削除
                </button>
              </div>
            </div>
          </div>
        </div>

      </div>
    </div>

    <!-- 削除確認モーダル -->
    <div v-if="showDeleteModal" class="modal-overlay" @click="hideDeleteConfirmation">
      <div class="modal-content" @click.stop>
        <h3>⚠️ アカウント削除の確認</h3>
        <p>この操作は取り消せません。本当にアカウントを削除しますか？</p>
        <div class="modal-actions">
          <button @click="hideDeleteConfirmation" class="btn btn-secondary">
            キャンセル
          </button>
          <button @click="deleteAccount" class="btn btn-danger">
            削除する
          </button>
        </div>
      </div>
    </div>

    <!-- 成功・エラーメッセージ -->
    <div v-if="message" class="message" :class="messageType">
      {{ message }}
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import settingsService, { 
  type UserSettings, 
  type NotificationSettings, 
  type MessageSettings 
} from '@/services/settingsService'

const router = useRouter()
const authStore = useAuthStore()

// フォームデータ
const profileForm = reactive({
  displayName: '',
  email: ''
})

const passwordForm = reactive({
  currentPassword: '',
  newPassword: '',
  confirmPassword: ''
})

const notificationSettings = reactive({
  emailNotifications: true,
  sendNotifications: true,
  browserNotifications: false
})

const messageSettings = reactive({
  defaultTone: 'gentle',
  timeRestriction: 'none'
})

// 状態管理
const isLoading = ref(true)
const isUpdatingProfile = ref(false)
const isChangingPassword = ref(false)
const showDeleteModal = ref(false)
const message = ref('')
const messageType = ref('')

// 計算プロパティ
const canChangePassword = computed(() => {
  return passwordForm.currentPassword.length >= 8 &&
         passwordForm.newPassword.length >= 8 &&
         passwordForm.newPassword === passwordForm.confirmPassword
})

// 設定データの読み込み
const loadSettings = async () => {
  try {
    console.log('設定データ読み込み開始')
    isLoading.value = true
    const settings = await settingsService.getSettings()
    console.log('設定データ取得成功:', settings)
    
    // フォームデータに反映
    profileForm.displayName = settings.user.name
    profileForm.email = settings.user.email
    
    // 通知設定に反映
    Object.assign(notificationSettings, settings.notifications)
    
    // メッセージ設定に反映
    Object.assign(messageSettings, settings.messages)
    
    console.log('設定データ反映完了')
    
  } catch (error: any) {
    console.error('設定の読み込みエラー:', error)
    console.error('エラー詳細:', error.response?.data)
    const errorMessage = error.response?.data?.error || '設定の読み込みに失敗しました'
    showMessage(errorMessage, 'error')
  } finally {
    isLoading.value = false
  }
}

// メソッド
const updateProfile = async () => {
  isUpdatingProfile.value = true
  try {
    await settingsService.updateProfile({
      name: profileForm.displayName
    })
    showMessage('プロフィールを更新しました', 'success')
  } catch (error) {
    console.error('プロフィール更新エラー:', error)
    showMessage('プロフィールの更新に失敗しました', 'error')
  } finally {
    isUpdatingProfile.value = false
  }
}

const changePassword = async () => {
  isChangingPassword.value = true
  try {
    await settingsService.changePassword({
      currentPassword: passwordForm.currentPassword,
      newPassword: passwordForm.newPassword
    })
    passwordForm.currentPassword = ''
    passwordForm.newPassword = ''
    passwordForm.confirmPassword = ''
    showMessage('パスワードを変更しました', 'success')
  } catch (error: any) {
    console.error('パスワード変更エラー:', error)
    const errorMessage = error.response?.data?.error || 'パスワードの変更に失敗しました'
    showMessage(errorMessage, 'error')
  } finally {
    isChangingPassword.value = false
  }
}

const updateNotificationSettings = async () => {
  try {
    await settingsService.updateNotificationSettings(notificationSettings)
    showMessage('通知設定を更新しました', 'success')
  } catch (error: any) {
    console.error('通知設定更新エラー:', error)
    const errorMessage = error.response?.data?.error || '通知設定の更新に失敗しました'
    showMessage(errorMessage, 'error')
  }
}

const updateMessageSettings = async () => {
  try {
    await settingsService.updateMessageSettings(messageSettings)
    showMessage('メッセージ設定を更新しました', 'success')
  } catch (error: any) {
    console.error('メッセージ設定更新エラー:', error)
    const errorMessage = error.response?.data?.error || 'メッセージ設定の更新に失敗しました'
    showMessage(errorMessage, 'error')
  }
}

const logout = async () => {
  await authStore.logout()
  router.push('/login')
}

const showDeleteConfirmation = () => {
  showDeleteModal.value = true
}

const hideDeleteConfirmation = () => {
  showDeleteModal.value = false
}

const deleteAccount = async () => {
  try {
    await settingsService.deleteAccount()
    showMessage('アカウントを削除しました', 'success')
    await authStore.logout()
    router.push('/login')
  } catch (error: any) {
    console.error('アカウント削除エラー:', error)
    const errorMessage = error.response?.data?.error || 'アカウントの削除に失敗しました'
    showMessage(errorMessage, 'error')
  } finally {
    hideDeleteConfirmation()
  }
}

const showMessage = (text: string, type: string) => {
  message.value = text
  messageType.value = type
  setTimeout(() => {
    message.value = ''
    messageType.value = ''
  }, 3000)
}

// 初期化
onMounted(async () => {
  console.log('SettingsView: マウント開始')
  console.log('認証状態:', authStore.isAuthenticated)
  console.log('ユーザー情報:', authStore.user)
  
  try {
    // 設定データの読み込み
    await loadSettings()
  } catch (error) {
    console.error('設定読み込みエラー:', error)
  }
  
  // 認証ストアからの情報でフォールバック
  if (authStore.user) {
    if (!profileForm.displayName) {
      profileForm.displayName = authStore.user.name || ''
    }
    if (!profileForm.email) {
      profileForm.email = authStore.user.email || ''
    }
  }
  
  console.log('SettingsView: マウント完了')
})
</script>

<style scoped>
.settings-view {
  min-height: 100vh;
  background: #f8f9fa;
  padding: 2rem 0;
}

.settings-container {
  max-width: 800px;
  margin: 0 auto;
  padding: 0 1rem;
}

.settings-header {
  text-align: center;
  margin-bottom: 3rem;
}

.page-title {
  font-size: 2.5rem;
  color: #333;
  margin: 0 0 0.5rem 0;
  font-weight: 600;
}

.page-subtitle {
  color: #666;
  font-size: 1.1rem;
  margin: 0;
}

.settings-sections {
  display: flex;
  flex-direction: column;
  gap: 2rem;
}

.settings-section {
  background: white;
  border-radius: 12px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.06);
  overflow: hidden;
}

.section-title {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  margin: 0;
  padding: 1.5rem;
  font-size: 1.25rem;
  font-weight: 600;
}

.settings-card {
  padding: 2rem;
}

.form-group {
  margin-bottom: 1.5rem;
}

.form-group label {
  display: block;
  margin-bottom: 0.5rem;
  font-weight: 600;
  color: #333;
}

.form-input,
.form-select {
  width: 100%;
  padding: 0.75rem;
  border: 2px solid #e1e5e9;
  border-radius: 8px;
  font-size: 1rem;
  transition: border-color 0.3s ease;
}

.form-input:focus,
.form-select:focus {
  outline: none;
  border-color: #667eea;
  box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.1);
}

.form-input[readonly] {
  background-color: #f8f9fa;
  color: #6c757d;
}

.form-hint {
  display: block;
  margin-top: 0.25rem;
  color: #6c757d;
  font-size: 0.875rem;
}

.form-actions {
  margin-top: 2rem;
}

.setting-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 1.5rem 0;
  border-bottom: 1px solid #e9ecef;
}

.setting-item:last-child {
  border-bottom: none;
}

.setting-info h3 {
  margin: 0 0 0.25rem 0;
  color: #333;
  font-size: 1rem;
  font-weight: 600;
}

.setting-info p {
  margin: 0;
  color: #6c757d;
  font-size: 0.875rem;
}

.toggle-switch {
  position: relative;
  display: inline-block;
  width: 50px;
  height: 28px;
}

.toggle-switch input {
  opacity: 0;
  width: 0;
  height: 0;
}

.toggle-slider {
  position: absolute;
  cursor: pointer;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background-color: #ccc;
  transition: 0.3s;
  border-radius: 28px;
}

.toggle-slider:before {
  position: absolute;
  content: "";
  height: 20px;
  width: 20px;
  left: 4px;
  bottom: 4px;
  background-color: white;
  transition: 0.3s;
  border-radius: 50%;
}

input:checked + .toggle-slider {
  background-color: #667eea;
}

input:checked + .toggle-slider:before {
  transform: translateX(22px);
}

.account-actions {
  display: flex;
  flex-direction: column;
  gap: 1.5rem;
}

.account-action {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 1.5rem;
  border: 2px solid #e9ecef;
  border-radius: 8px;
}

.account-action.danger {
  border-color: #dc3545;
  background-color: #fff5f5;
}

.action-info h3 {
  margin: 0 0 0.25rem 0;
  color: #333;
  font-size: 1rem;
  font-weight: 600;
}

.action-info p {
  margin: 0;
  color: #6c757d;
  font-size: 0.875rem;
}

.btn {
  padding: 0.75rem 1.5rem;
  border: none;
  border-radius: 8px;
  font-size: 1rem;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.3s ease;
  text-decoration: none;
  display: inline-block;
}

.btn:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.btn-primary {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
}

.btn-primary:hover:not(:disabled) {
  transform: translateY(-1px);
  box-shadow: 0 4px 12px rgba(102, 126, 234, 0.3);
}

.btn-secondary {
  background: #6c757d;
  color: white;
}

.btn-secondary:hover:not(:disabled) {
  background: #545b62;
}

.btn-danger {
  background: #dc3545;
  color: white;
}

.btn-danger:hover:not(:disabled) {
  background: #c82333;
}

.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.5);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
}

.modal-content {
  background: white;
  padding: 2rem;
  border-radius: 12px;
  max-width: 400px;
  width: 90%;
}

.modal-content h3 {
  margin: 0 0 1rem 0;
  color: #333;
}

.modal-content p {
  margin: 0 0 2rem 0;
  color: #666;
  line-height: 1.5;
}

.modal-actions {
  display: flex;
  gap: 1rem;
  justify-content: flex-end;
}

.message {
  position: fixed;
  top: 2rem;
  right: 2rem;
  padding: 1rem 1.5rem;
  border-radius: 8px;
  font-weight: 500;
  z-index: 1001;
}

.message.success {
  background: #d4edda;
  color: #155724;
  border: 1px solid #c3e6cb;
}

.message.error {
  background: #f8d7da;
  color: #721c24;
  border: 1px solid #f5c6cb;
}

@media (max-width: 768px) {
  .settings-view {
    padding: 1rem 0;
  }
  
  .settings-container {
    padding: 0 0.5rem;
  }
  
  .page-title {
    font-size: 2rem;
  }
  
  .settings-card {
    padding: 1.5rem;
  }
  
  .section-title {
    padding: 1rem;
    font-size: 1.1rem;
  }
  
  .setting-item,
  .account-action {
    flex-direction: column;
    align-items: stretch;
    gap: 1rem;
  }
  
  .modal-content {
    margin: 1rem;
  }
  
  .message {
    top: 1rem;
    right: 1rem;
    left: 1rem;
  }
}
</style>