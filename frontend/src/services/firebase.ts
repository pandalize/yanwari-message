import { initializeApp } from 'firebase/app'
import { getAuth, signInWithEmailAndPassword, createUserWithEmailAndPassword, signOut, onAuthStateChanged, type User, connectAuthEmulator } from 'firebase/auth'

// Firebase設定
const firebaseConfig = {
  apiKey: "AIzaSyDMN2wUjE6NicanP0KP8ybnPgJZloMNOoI",
  authDomain: "yanwari-message.firebaseapp.com",
  projectId: "yanwari-message"
}

// Firebase初期化
const app = initializeApp(firebaseConfig)
export const auth = getAuth(app)

// Firebase Emulator接続（開発環境）
if (import.meta.env.DEV) {
  console.log('🔥 Firebase Emulator に接続中...')
  try {
    // Emulator接続は一度のみ実行
    if (!auth.config.emulator) {
      connectAuthEmulator(auth, 'http://127.0.0.1:9099', { disableWarnings: true })
      console.log('✅ Firebase Authentication Emulator に接続しました (127.0.0.1:9099)')
    } else {
      console.log('✅ Firebase Authentication Emulator は既に接続済みです')
    }
  } catch (error) {
    console.log('⚠️ Firebase Emulator接続エラー:', error)
    console.log('Firebase Emulatorが起動していることを確認してください')
  }
}

// Firebase認証サービス
export class FirebaseAuthService {
  private auth = auth

  // ユーザー登録
  async register(email: string, password: string): Promise<User> {
    const userCredential = await createUserWithEmailAndPassword(this.auth, email, password)
    return userCredential.user
  }

  // ログイン
  async login(email: string, password: string): Promise<User> {
    const userCredential = await signInWithEmailAndPassword(this.auth, email, password)
    return userCredential.user
  }

  // ログアウト
  async logout(): Promise<void> {
    await signOut(this.auth)
  }

  // 現在のユーザーを取得
  getCurrentUser(): User | null {
    return this.auth.currentUser
  }

  // IDトークンを取得
  async getIdToken(): Promise<string | null> {
    const user = this.getCurrentUser()
    if (!user) return null
    return await user.getIdToken()
  }

  // 認証状態の変更を監視
  onAuthStateChanged(callback: (user: User | null) => void) {
    return onAuthStateChanged(this.auth, callback)
  }
}

export const firebaseAuthService = new FirebaseAuthService()