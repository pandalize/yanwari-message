<template>
  <PageContainer>
    <PageTitle>設定</PageTitle>
    
    <div class="settings-container">
      <!-- 設定メインコンテンツ -->
      <div class="settings-main">
        <!-- 設定サイドバー -->
        <div class="settings-sidebar">
          <nav class="settings-nav">
            <button 
              v-for="section in settingsSections" 
              :key="section.id"
              @click="activeSection = section.id"
              :class="['nav-item', { active: activeSection === section.id }]"
            >
              <span class="nav-label">{{ section.label }}</span>
            </button>
          </nav>
        </div>

        <!-- 設定コンテンツエリア -->
        <div class="settings-content">
          <!-- アカウント設定 -->
          <div v-if="activeSection === 'account'" class="section-content">
            <div class="form-container">
              <div class="form-group">
                <label for="displayName">ユーザー名</label>
                <input 
                  id="displayName"
                  v-model="profileForm.displayName"
                  type="text" 
                  class="form-input"
                  placeholder="今のユーザーネーム"
                />
              </div>

              <div class="form-group">
                <label for="userId">ID</label>
                <input 
                  id="userId"
                  :value="profileForm.email"
                  type="text" 
                  class="form-input"
                  placeholder="今のID"
                  readonly
                />
              </div>

              <div class="form-group">
                <label for="email">メールアドレス</label>
                <input 
                  id="email"
                  v-model="profileForm.email"
                  type="email" 
                  class="form-input"
                  placeholder="今のメールアドレス"
                />
              </div>

              <div class="form-group">
                <label for="currentPassword">パスワード</label>
                <label class="password-label">今のパスワード</label>
                <input 
                  id="currentPassword"
                  v-model="passwordForm.currentPassword"
                  type="password" 
                  class="form-input"
                  placeholder=""
                />

                <label class="password-label">変更後のパスワード</label>
                <input 
                  id="newPassword"
                  v-model="passwordForm.newPassword"
                  type="password" 
                  class="form-input"
                  placeholder=""
                />

                <label class="password-label">再入力</label>
                <input 
                  id="confirmPassword"
                  v-model="passwordForm.confirmPassword"
                  type="password" 
                  class="form-input"
                  placeholder=""
                />
              </div>
              
              <!-- 更新ボタン -->
              <div class="update-button-container">
                <button 
                  @click="updateAllSettings"
                  :disabled="isUpdating"
                  class="update-button"
                >
                  {{ isUpdating ? '更新中...' : '更新する' }}
                </button>
              </div>
            </div>
          </div>

          <!-- 通知設定 -->
          <div v-if="activeSection === 'notifications'" class="section-content">
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

          <!-- 言語・地域設定 -->
          <div v-if="activeSection === 'language'" class="section-content">
            <h2 class="section-title">🌍 言語・地域設定</h2>
            <div class="settings-card">
              <div class="form-group">
                <label for="language">言語</label>
                <select 
                  id="language"
                  v-model="languageSettings.language"
                  class="form-select"
                  @change="updateLanguageSettings"
                >
                  <option value="ja">日本語</option>
                  <option value="en">English</option>
                  <option value="ko">한국어</option>
                  <option value="zh">中文</option>
                </select>
                <small class="form-hint">アプリケーションの表示言語を選択</small>
              </div>

              <div class="form-group">
                <label for="timezone">タイムゾーン</label>
                <select 
                  id="timezone"
                  v-model="languageSettings.timezone"
                  class="form-select"
                  @change="updateLanguageSettings"
                >
                  <option value="Asia/Tokyo">日本標準時 (JST)</option>
                  <option value="America/New_York">東部標準時 (EST)</option>
                  <option value="America/Los_Angeles">太平洋標準時 (PST)</option>
                  <option value="Europe/London">グリニッジ標準時 (GMT)</option>
                  <option value="Asia/Seoul">韓国標準時 (KST)</option>
                  <option value="Asia/Shanghai">中国標準時 (CST)</option>
                </select>
                <small class="form-hint">メッセージの送信時間などに使用されます</small>
              </div>

              <div class="form-group">
                <label for="dateFormat">日付形式</label>
                <select 
                  id="dateFormat"
                  v-model="languageSettings.dateFormat"
                  class="form-select"
                  @change="updateLanguageSettings"
                >
                  <option value="YYYY/MM/DD">2024/01/15</option>
                  <option value="MM/DD/YYYY">01/15/2024</option>
                  <option value="DD/MM/YYYY">15/01/2024</option>
                  <option value="YYYY-MM-DD">2024-01-15</option>
                </select>
                <small class="form-hint">日付の表示形式を選択</small>
              </div>
            </div>
          </div>

          <!-- メッセージ設定 -->
          <div v-if="activeSection === 'messages'" class="section-content">
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

              <div class="form-group">
                <label for="autoSave">自動保存</label>
                <div class="setting-item">
                  <div class="setting-info">
                    <h3>下書きの自動保存</h3>
                    <p>メッセージ入力中に自動的に下書きを保存</p>
                  </div>
                  <div class="setting-control">
                    <label class="toggle-switch">
                      <input 
                        type="checkbox" 
                        v-model="messageSettings.autoSave"
                        @change="updateMessageSettings"
                      />
                      <span class="toggle-slider"></span>
                    </label>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <!-- ログアウト -->
          <div v-if="activeSection === 'logout'" class="section-content">
            <h2 class="section-title">🚪 ログアウト</h2>
            <div class="settings-card">
              <div class="logout-container">
                <p class="logout-description">
                  現在のアカウントからログアウトします。<br>
                  再度ログインするにはメールアドレスとパスワードが必要です。
                </p>
                <button 
                  @click="logout"
                  class="btn btn-logout"
                >
                  ログアウトする
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
  </PageContainer>
</template>

<script setup lang="ts">
import { ref, reactive, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useJWTAuthStore } from '@/stores/jwtAuth'
import settingsService, { 
  type UserSettings, 
  type NotificationSettings, 
  type MessageSettings 
} from '@/services/settingsService'
import PageContainer from '@/components/layout/PageContainer.vue'
import PageTitle from '@/components/layout/PageTitle.vue'

const router = useRouter()
const authStore = useJWTAuthStore()

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
  timeRestriction: 'none',
  autoSave: true
})

const languageSettings = reactive({
  language: 'ja',
  timezone: 'Asia/Tokyo',
  dateFormat: 'YYYY/MM/DD'
})

// サイドバーナビゲーション
const activeSection = ref('account')
const settingsSections = [
  { id: 'account', label: 'アカウント' },
  { id: 'notifications', label: '通知' },
  { id: 'language', label: '言語・地域' },
  { id: 'messages', label: 'メッセージ' },
  { id: 'logout', label: 'ログアウト' }
]

// 状態管理
const isLoading = ref(true)
const isUpdatingProfile = ref(false)
const isChangingPassword = ref(false)
const isUpdating = ref(false)
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
      name: profileForm.displayName,
      email: profileForm.email
    })
    showMessage('プロフィールを更新しました', 'success')
    
    // 認証ストアのユーザー情報も更新
    if (authStore.user) {
      const updatedUser = {
        ...authStore.user,
        name: profileForm.displayName,
        email: profileForm.email
      }
      localStorage.setItem('user', JSON.stringify(updatedUser))
    }
  } catch (error: any) {
    console.error('プロフィール更新エラー:', error)
    const errorMessage = error.response?.data?.error || 'プロフィールの更新に失敗しました'
    showMessage(errorMessage, 'error')
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

const updateLanguageSettings = async () => {
  try {
    // TODO: バックエンドに言語設定APIを追加する必要があります
    // await settingsService.updateLanguageSettings(languageSettings)
    showMessage('言語・地域設定を更新しました', 'success')
  } catch (error: any) {
    console.error('言語設定更新エラー:', error)
    const errorMessage = error.response?.data?.error || '言語設定の更新に失敗しました'
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

const updateAllSettings = async () => {
  isUpdating.value = true
  try {
    // プロフィールの更新
    await settingsService.updateProfile({
      name: profileForm.displayName,
      email: profileForm.email
    })
    
    // パスワードの変更（入力されている場合のみ）
    if (canChangePassword.value) {
      await settingsService.changePassword({
        currentPassword: passwordForm.currentPassword,
        newPassword: passwordForm.newPassword
      })
      
      // パスワードフィールドをクリア
      passwordForm.currentPassword = ''
      passwordForm.newPassword = ''
      passwordForm.confirmPassword = ''
    }
    
    showMessage('設定を更新しました', 'success')
    
    // 認証ストアのユーザー情報も更新
    if (authStore.user) {
      const updatedUser = {
        ...authStore.user,
        name: profileForm.displayName,
        email: profileForm.email
      }
      localStorage.setItem('user', JSON.stringify(updatedUser))
    }
  } catch (error: any) {
    console.error('設定更新エラー:', error)
    const errorMessage = error.response?.data?.error || '設定の更新に失敗しました'
    showMessage(errorMessage, 'error')
  } finally {
    isUpdating.value = false
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
.settings-container {
  max-width: 1200px;
  margin: 0 auto;
}

.settings-main {
  display: flex;
  gap: 2rem;
  align-items: flex-start;
}

.settings-sidebar {
  width: 200px;
  background: white;
  border-radius: 8px;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
  overflow: hidden;
  flex-shrink: 0;
}

.settings-nav {
  display: flex;
  flex-direction: column;
}

.nav-item {
  display: block;
  padding: 1rem 1.5rem;
  border: none;
  background: white;
  color: #333;
  cursor: pointer;
  transition: all 0.2s ease;
  font-size: 1rem;
  font-weight: 400;
  text-align: left;
  border-bottom: 1px solid #e9ecef;
}

.nav-item:last-child {
  border-bottom: none;
}

.nav-item:hover {
  background: #f8f9fa;
}

.nav-item.active {
  background: #e9ecef;
  font-weight: 500;
}

.nav-label {
  display: block;
}

.settings-content {
  flex: 1;
  min-width: 0;
}

.section-content {
  background: white;
  border-radius: 8px;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
  padding: 2rem;
}

.form-container {
  max-width: 600px;
}

/* 削除された古いスタイル */

.form-group {
  margin-bottom: 2rem;
}

.form-group label {
  display: block;
  margin-bottom: 0.5rem;
  font-weight: 500;
  color: #333;
  font-size: 1rem;
}

.password-label {
  display: block;
  margin-top: 1rem;
  margin-bottom: 0.5rem;
  font-weight: 400;
  color: #666;
  font-size: 0.9rem;
}

.form-input {
  width: 100%;
  padding: 12px 16px;
  border: 1.5px solid #e0e0e0;
  border-radius: 8px;
  font-size: 1rem;
  transition: border-color 0.2s ease;
  background: white;
}

.form-input:focus {
  outline: none;
  border-color: #007bff;
}

.form-input[readonly] {
  background-color: #f8f9fa;
  color: #6c757d;
}

.form-input::placeholder {
  color: #adb5bd;
}

.form-hint {
  display: block;
  margin-top: 0.25rem;
  color: var(--text-muted);
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
  border-bottom: 1px solid var(--border-color);
}

.setting-item:last-child {
  border-bottom: none;
}

.setting-info h3 {
  margin: 0 0 0.25rem 0;
  color: var(--text-primary);
  font-size: 1rem;
  font-weight: 600;
}

.setting-info p {
  margin: 0;
  color: var(--text-muted);
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
  background-color: var(--gray-color);
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
  background-color: var(--neutral-color);
  transition: 0.3s;
  border-radius: 50%;
}

input:checked + .toggle-slider {
  background-color: var(--secondary-color);
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
  border: 2px solid var(--border-color);
  border-radius: var(--radius-md);
}

.account-action.danger {
  border-color: var(--error-color);
  background-color: var(--background-secondary);
}

.action-info h3 {
  margin: 0 0 0.25rem 0;
  color: var(--text-primary);
  font-size: 1rem;
  font-weight: 600;
}

.action-info p {
  margin: 0;
  color: var(--text-muted);
  font-size: 0.875rem;
}

.btn {
  padding: 0.75rem 1.5rem;
  border: none;
  border-radius: var(--radius-md);
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
  background: var(--secondary-color);
  color: var(--text-inverse);
}

.btn-primary:hover:not(:disabled) {
  background: var(--secondary-color-dark);
  transform: translateY(-1px);
  box-shadow: var(--shadow-md);
}

.btn-secondary {
  background: var(--gray-color);
  color: var(--text-inverse);
}

.btn-secondary:hover:not(:disabled) {
  background: var(--gray-color-dark);
}

.btn-danger {
  background: var(--error-color);
  color: var(--text-inverse);
}

.btn-danger:hover:not(:disabled) {
  background: var(--error-color);
  opacity: 0.9;
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
  background: var(--background-primary);
  padding: 2rem;
  border-radius: var(--radius-lg);
  max-width: 400px;
  width: 90%;
}

.modal-content h3 {
  margin: 0 0 1rem 0;
  color: var(--text-primary);
}

.modal-content p {
  margin: 0 0 2rem 0;
  color: var(--text-secondary);
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
  border-radius: var(--radius-md);
  font-weight: 500;
  z-index: 1001;
}

.message.success {
  background: var(--success-color);
  color: var(--text-primary);
  border: 1px solid var(--success-color);
}

.message.error {
  background: var(--error-color);
  color: var(--text-primary);
  border: 1px solid var(--error-color);
}

/* メッセージ表示 */
.message {
  position: fixed;
  top: 2rem;
  right: 2rem;
  padding: 1rem 1.5rem;
  border-radius: 8px;
  font-weight: 500;
  z-index: 1001;
  box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
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

/* モーダル */
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
  border-radius: 8px;
  max-width: 400px;
  width: 90%;
  box-shadow: 0 10px 25px rgba(0, 0, 0, 0.2);
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

/* 更新ボタンのスタイル（下書きボタンと同じ） */
.update-button {
  display: flex;
  gap: var(--spacing-lg);
  margin-bottom: var(--spacing-2xl);
  justify-content: center;
  width: 700px;
}

.update-button {
  width: 200px;
  height: 60px;
  border-radius: 30px;
  border: none;
  font-size: var(--font-size-base);
  font-family: var(--font-family-main);
  font-weight: var(--font-weight-regular);
  color: var(--text-primary);
  cursor: pointer;
  transition: all 0.3s ease;
  display: flex;
  align-items: center;
  justify-content: center;
}

.update-button-container {
  display: flex;
  justify-content: center;
  margin-top: 2rem;
  padding-top: 1.5rem;
  border-top: 1px solid #e9ecef;
}

/* ボタン */
.btn {
  padding: 0.75rem 1.5rem;
  border: none;
  border-radius: 6px;
  font-size: 1rem;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.2s ease;
  text-decoration: none;
  display: inline-block;
}

.btn:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.btn-primary {
  background: #007bff;
  color: white;
}

.btn-primary:hover:not(:disabled) {
  background: #0056b3;
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

/* ログアウトセクション専用スタイル */
.logout-container {
  text-align: center;
  padding: 2rem 0;
}

.logout-description {
  color: #666;
  line-height: 1.6;
  margin-bottom: 2rem;
  font-size: 1rem;
}

.btn-logout {
  background: #dc3545;
  color: white;
  padding: 0.75rem 2rem;
  font-size: 1rem;
  font-weight: 500;
  border: none;
  border-radius: 6px;
  cursor: pointer;
  transition: all 0.2s ease;
}

.btn-logout:hover {
  background: #c82333;
  transform: translateY(-1px);
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.2);
}

/* レスポンシブデザイン */
@media (max-width: 1024px) {
  .settings-main {
    gap: 1.5rem;
  }
  
  .settings-sidebar {
    width: 180px;
  }
  
  .nav-item {
    padding: 0.8rem 1rem;
    font-size: 0.9rem;
  }
}

@media (max-width: 768px) {
  .settings-view {
    padding: 1rem;
  }
  
  .settings-main {
    flex-direction: column;
    gap: 1rem;
  }
  
  .settings-sidebar {
    width: 100%;
    order: 2;
  }
  
  .settings-nav {
    flex-direction: row;
    overflow-x: auto;
  }
  
  .nav-item {
    flex-shrink: 0;
    min-width: 100px;
    text-align: center;
    border-bottom: none;
    border-right: 1px solid #e9ecef;
  }
  
  .nav-item:last-child {
    border-right: none;
  }
  
  .settings-content {
    order: 1;
  }
  
  .section-content {
    padding: 1.5rem;
  }
  
  .form-container {
    max-width: none;
  }
}
</style>