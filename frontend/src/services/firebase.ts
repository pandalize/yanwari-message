import { initializeApp } from 'firebase/app'
import { getAuth, signInWithEmailAndPassword, createUserWithEmailAndPassword, signOut, onAuthStateChanged, type User } from 'firebase/auth'

// Firebase設定
const firebaseConfig = {
  apiKey: "AIzaSyDMN2wUjE6NicanP0KP8ybnPgJZloMNOoI",
  authDomain: "yanwari-message.firebaseapp.com",
  projectId: "yanwari-message"
}

// Firebase初期化
const app = initializeApp(firebaseConfig)
export const auth = getAuth(app)

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