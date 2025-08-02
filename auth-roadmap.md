# Firebase認証移行ロードマップ

## 概要

やんわり伝言アプリを現在の手動JWT認証システムからFirebase Authenticationに移行し、Web/Mobile統一認証基盤を構築するための詳細な計画書です。

### 移行の目的
- **開発効率向上**: 600行の認証コード → 200行に削減
- **セキュリティ強化**: Google レベルのセキュリティ対策
- **機能拡張**: MFA、ソーシャルログイン、パスワードリセット自動提供
- **統一体験**: Web(Vue.js)/Mobile(Flutter)で同一認証
- **保守性向上**: Firebase側での自動セキュリティ更新

### 現在の実装状況
- ✅ **完了済み**: 手動JWT認証システム（Argon2 + JWT）
- ✅ **完了済み**: MongoDB Atlas ユーザー管理
- ✅ **完了済み**: Vue.js 認証UI・状態管理
- 🎯 **移行対象**: 認証基盤をFirebaseに統一

## 段階的移行計画

### Stage 1: バックエンド統合（推定2-3週間）

#### 1.1 Firebase プロジェクト設定

**必要な作業:**
```bash
# Firebase CLI インストール・初期化
npm install -g firebase-tools
firebase login
firebase init

# Firebase プロジェクト作成
firebase projects:create yanwari-message-prod
firebase use yanwari-message-prod

# Firebase Admin SDK for Go
go get firebase.google.com/go/v4
```

**環境変数追加:**
```env
# backend/.env に追加
FIREBASE_PROJECT_ID=yanwari-message-prod
FIREBASE_PRIVATE_KEY_PATH=./config/firebase-admin-key.json
```

#### 1.2 Go バックエンドの変更

**Firebase Admin SDK統合:**
```go
// backend/services/firebase_service.go (新規作成)
package services

import (
    "context"
    "firebase.google.com/go/v4"
    "firebase.google.com/go/v4/auth"
    "google.golang.org/api/option"
)

type FirebaseService struct {
    Auth *auth.Client
}

func NewFirebaseService() (*FirebaseService, error) {
    opt := option.WithCredentialsFile("config/firebase-admin-key.json")
    app, err := firebase.NewApp(context.Background(), nil, opt)
    if err != nil {
        return nil, err
    }
    
    authClient, err := app.Auth(context.Background())
    if err != nil {
        return nil, err
    }
    
    return &FirebaseService{Auth: authClient}, nil
}

func (fs *FirebaseService) VerifyIDToken(idToken string) (*auth.Token, error) {
    return fs.Auth.VerifyIDToken(context.Background(), idToken)
}
```

**認証ミドルウェア更新:**
```go
// backend/middleware/auth.go (更新)
func FirebaseAuthMiddleware(firebaseService *services.FirebaseService) gin.HandlerFunc {
    return func(c *gin.Context) {
        authHeader := c.GetHeader("Authorization")
        if !strings.HasPrefix(authHeader, "Bearer ") {
            c.JSON(401, gin.H{"error": "Missing or invalid Authorization header"})
            c.Abort()
            return
        }
        
        idToken := strings.TrimPrefix(authHeader, "Bearer ")
        token, err := firebaseService.VerifyIDToken(idToken)
        if err != nil {
            c.JSON(401, gin.H{"error": "Invalid Firebase ID token"})
            c.Abort()
            return
        }
        
        // Firebase UIDをコンテキストに設定
        c.Set("firebase_uid", token.UID)
        c.Set("user_email", token.Claims["email"])
        c.Next()
    }
}
```

#### 1.3 MongoDB ユーザーデータ移行

**移行スクリプト作成:**
```go
// backend/migration/firebase_migration.go (新規作成)
package migration

import (
    "context"
    "log"
    "yanwari-message/models"
    "yanwari-message/services"
)

type UserMigration struct {
    userService     *models.UserService
    firebaseService *services.FirebaseService
}

func NewUserMigration(us *models.UserService, fs *services.FirebaseService) *UserMigration {
    return &UserMigration{
        userService:     us,
        firebaseService: fs,
    }
}

func (um *UserMigration) MigrateUsersToFirebase() error {
    // 1. MongoDB から全ユーザー取得
    users, err := um.userService.GetAllUsers()
    if err != nil {
        return err
    }
    
    for _, user := range users {
        // 2. Firebase にユーザー作成
        firebaseUser := &auth.UserToCreate{}
        firebaseUser.Email(user.Email)
        firebaseUser.EmailVerified(true)
        
        createdUser, err := um.firebaseService.Auth.CreateUser(context.Background(), firebaseUser)
        if err != nil {
            log.Printf("Firebase移行失敗 - Email: %s, Error: %v", user.Email, err)
            continue
        }
        
        // 3. MongoDB に Firebase UID を記録
        err = um.userService.UpdateFirebaseUID(user.ID, createdUser.UID)
        if err != nil {
            log.Printf("MongoDB更新失敗 - Email: %s, Error: %v", user.Email, err)
            continue
        }
        
        log.Printf("移行成功 - Email: %s, Firebase UID: %s", user.Email, createdUser.UID)
    }
    
    return nil
}
```

**User モデル更新:**
```go
// backend/models/user.go (更新)
type User struct {
    ID          primitive.ObjectID `bson:"_id,omitempty" json:"id"`
    Email       string             `bson:"email" json:"email"`
    FirebaseUID string             `bson:"firebase_uid,omitempty" json:"firebase_uid"` // 追加
    // passwordHash, salt フィールドは削除予定
    Timezone    string             `bson:"timezone" json:"timezone"`
    CreatedAt   time.Time          `bson:"created_at" json:"created_at"`
}

// Firebase UID更新メソッド追加
func (us *UserService) UpdateFirebaseUID(userID primitive.ObjectID, firebaseUID string) error {
    filter := bson.M{"_id": userID}
    update := bson.M{"$set": bson.M{"firebase_uid": firebaseUID}}
    
    _, err := us.collection.UpdateOne(context.Background(), filter, update)
    return err
}

// Firebase UIDでユーザー取得メソッド追加
func (us *UserService) GetUserByFirebaseUID(firebaseUID string) (*User, error) {
    var user User
    filter := bson.M{"firebase_uid": firebaseUID}
    err := us.collection.FindOne(context.Background(), filter).Decode(&user)
    if err != nil {
        return nil, err
    }
    return &user, nil
}
```

#### 1.4 既存APIハンドラー更新

**認証ハンドラー簡素化:**
```go
// backend/handlers/auth.go (大幅簡素化)
type AuthHandler struct {
    userService     *models.UserService
    firebaseService *services.FirebaseService
}

// 登録・ログイン処理は Firebase Client SDK に移譲
// サーバーサイドでは Firebase UID でのユーザー情報管理のみ
func (h *AuthHandler) GetUserProfile(c *gin.Context) {
    firebaseUID := c.GetString("firebase_uid")
    
    user, err := h.userService.GetUserByFirebaseUID(firebaseUID)
    if err != nil {
        c.JSON(404, gin.H{"error": "User not found"})
        return
    }
    
    c.JSON(200, gin.H{"data": user})
}

// 従来の Login, Register, Refresh, Logout メソッドは削除
```

#### 1.5 main.go更新

**Firebase統合:**
```go
// backend/main.go (更新)
func main() {
    // Firebase サービス初期化
    firebaseService, err := services.NewFirebaseService()
    if err != nil {
        log.Fatal("Firebase初期化失敗:", err)
    }
    
    // 既存サービス初期化
    userService := models.NewUserService(db)
    
    // ハンドラー初期化
    authHandler := handlers.NewAuthHandler(userService, firebaseService)
    
    // ルーター設定
    router := gin.Default()
    
    // Firebase 認証ミドルウェア適用
    protected := router.Group("/api/v1")
    protected.Use(middleware.FirebaseAuthMiddleware(firebaseService))
    
    // 認証が必要なルート
    protected.GET("/profile", authHandler.GetUserProfile)
    protected.GET("/messages", messageHandler.GetMessages)
    // ... 他のAPIエンドポイント
}
```

### Stage 2: Web移行（推定1-2週間）

#### 2.1 Firebase SDK導入

**パッケージインストール:**
```bash
cd frontend
npm install firebase
```

**Firebase設定:**
```typescript
// frontend/src/firebase/config.ts (新規作成)
import { initializeApp } from 'firebase/app'
import { getAuth } from 'firebase/auth'

const firebaseConfig = {
  apiKey: "your-api-key",
  authDomain: "yanwari-message-prod.firebaseapp.com",
  projectId: "yanwari-message-prod",
  storageBucket: "yanwari-message-prod.appspot.com",
  messagingSenderId: "123456789",
  appId: "your-app-id"
}

const app = initializeApp(firebaseConfig)
export const auth = getAuth(app)
```

#### 2.2 認証ストア移行

**新しい認証ストア:**
```typescript
// frontend/src/stores/auth.ts (大幅簡素化)
import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { 
  signInWithEmailAndPassword,
  createUserWithEmailAndPassword,
  signOut,
  onAuthStateChanged,
  User
} from 'firebase/auth'
import { auth } from '@/firebase/config'

export const useAuthStore = defineStore('auth', () => {
  const user = ref<User | null>(null)
  const loading = ref(false)
  
  // 認証状態の監視（自動リフレッシュ）
  onAuthStateChanged(auth, (firebaseUser) => {
    user.value = firebaseUser
  })
  
  // ログイン
  const login = async (email: string, password: string) => {
    loading.value = true
    try {
      const userCredential = await signInWithEmailAndPassword(auth, email, password)
      return userCredential.user
    } finally {
      loading.value = false
    }
  }
  
  // 新規登録
  const register = async (email: string, password: string) => {
    loading.value = true
    try {
      const userCredential = await createUserWithEmailAndPassword(auth, email, password)
      return userCredential.user
    } finally {
      loading.value = false
    }
  }
  
  // ログアウト
  const logout = async () => {
    await signOut(auth)
  }
  
  // ID Token取得
  const getIdToken = async (): Promise<string | null> => {
    if (!user.value) return null
    return await user.value.getIdToken()
  }
  
  const isAuthenticated = computed(() => !!user.value)
  
  return {
    user,
    loading,
    isAuthenticated,
    login,
    register,
    logout,
    getIdToken
  }
})
```

#### 2.3 API サービス更新

**Firebase ID Token連携:**
```typescript
// frontend/src/services/api.ts (更新)
import { useAuthStore } from '@/stores/auth'

class ApiService {
  private baseURL = 'http://localhost:8080/api/v1'
  
  async getAuthToken(): Promise<string | null> {
    const authStore = useAuthStore()
    return await authStore.getIdToken()
  }
  
  async request(endpoint: string, options: RequestInit = {}) {
    const token = await this.getAuthToken()
    
    const headers: Record<string, string> = {
      'Content-Type': 'application/json',
      ...options.headers as Record<string, string>
    }
    
    if (token) {
      headers['Authorization'] = `Bearer ${token}`
    }
    
    const response = await fetch(`${this.baseURL}${endpoint}`, {
      ...options,
      headers
    })
    
    if (!response.ok) {
      throw new Error(`API Error: ${response.status}`)
    }
    
    return response.json()
  }
}

export const apiService = new ApiService()
```

#### 2.4 認証コンポーネント更新

**ログインフォーム更新:**
```vue
<!-- frontend/src/components/auth/LoginForm.vue (更新) -->
<template>
  <form @submit.prevent="handleLogin">
    <div class="form-group">
      <label for="email">メールアドレス</label>
      <input
        id="email"
        v-model="email"
        type="email"
        required
        :disabled="loading"
      />
    </div>
    
    <div class="form-group">
      <label for="password">パスワード</label>
      <input
        id="password"
        v-model="password"
        type="password"
        required
        :disabled="loading"
      />
    </div>
    
    <button type="submit" :disabled="loading">
      {{ loading ? 'ログイン中...' : 'ログイン' }}
    </button>
    
    <!-- Firebase提供のパスワードリセット機能 -->
    <p>
      <router-link to="/password-reset">
        パスワードを忘れた方はこちら
      </router-link>
    </p>
  </form>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'

const router = useRouter()
const authStore = useAuthStore()

const email = ref('')
const password = ref('')
const loading = ref(false)

const handleLogin = async () => {
  loading.value = true
  try {
    await authStore.login(email.value, password.value)
    router.push('/dashboard')
  } catch (error) {
    console.error('ログインエラー:', error)
    // エラーハンドリング
  } finally {
    loading.value = false
  }
}
</script>
```

### Stage 3: Flutter開発（推定3-4週間）

#### 3.1 Flutter プロジェクト作成

**プロジェクト初期化:**
```bash
# Flutter プロジェクト作成
flutter create yanwari_message_mobile
cd yanwari_message_mobile

# Firebase dependencies 追加
flutter pub add firebase_core firebase_auth dio
flutter pub add --dev flutter_lints

# Firebase設定（Android/iOS）
flutterfire configure
```

#### 3.2 Firebase設定

**メイン関数設定:**
```dart
// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:yanwari_message_mobile/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const YanwariApp());
}
```

#### 3.3 認証サービス実装

**Flutter認証サービス:**
```dart
// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // 現在のユーザー
  User? get currentUser => _auth.currentUser;
  
  // 認証状態の変更を監視
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  
  // ログイン
  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }
  
  // 新規登録
  Future<User?> createUserWithEmailAndPassword(String email, String password) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }
  
  // ログアウト
  Future<void> signOut() async {
    await _auth.signOut();
  }
  
  // ID Token取得
  Future<String?> getIdToken() async {
    final user = _auth.currentUser;
    if (user != null) {
      return await user.getIdToken();
    }
    return null;
  }
  
  // Firebase認証エラーのハンドリング
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'メールアドレスが見つかりません';
      case 'wrong-password':
        return 'パスワードが間違っています';
      case 'email-already-in-use':
        return 'このメールアドレスは既に使用されています';
      case 'weak-password':
        return 'パスワードが弱すぎます';
      case 'invalid-email':
        return 'メールアドレスの形式が正しくありません';
      default:
        return '認証エラーが発生しました: ${e.message}';
    }
  }
}
```

#### 3.4 API連携サービス

**Go API連携:**
```dart
// lib/services/api_service.dart
import 'package:dio/dio.dart';
import 'package:yanwari_message_mobile/services/auth_service.dart';

class ApiService {
  static const String baseUrl = 'https://your-api-domain.com/api/v1';
  late final Dio _dio;
  final AuthService _authService = AuthService();
  
  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));
    
    // リクエストインターセプター（認証トークン自動追加）
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _authService.getIdToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
    ));
  }
  
  // メッセージ作成
  Future<Map<String, dynamic>> createMessage({
    required String originalText,
    required String recipientEmail,
  }) async {
    final response = await _dio.post('/messages/draft', data: {
      'originalText': originalText,
      'recipientEmail': recipientEmail,
    });
    return response.data;
  }
  
  // トーン変換
  Future<Map<String, dynamic>> transformTones({
    required String messageId,
    required String originalText,
  }) async {
    final response = await _dio.post('/transform/tones', data: {
      'messageId': messageId,
      'originalText': originalText,
    });
    return response.data;
  }
  
  // AI時間提案
  Future<Map<String, dynamic>> suggestSchedule({
    required String messageId,
    required String messageText,
    required String selectedTone,
  }) async {
    final response = await _dio.post('/schedule/suggest', data: {
      'messageId': messageId,
      'messageText': messageText,
      'selectedTone': selectedTone,
    });
    return response.data;
  }
  
  // スケジュール作成
  Future<Map<String, dynamic>> createSchedule({
    required String messageId,
    required DateTime scheduledAt,
    required String timezone,
  }) async {
    final response = await _dio.post('/schedules/', data: {
      'messageId': messageId,
      'scheduledAt': scheduledAt.toIso8601String(),
      'timezone': timezone,
    });
    return response.data;
  }
}
```

#### 3.5 やんわり伝言UI実装

**メッセージ作成画面:**
```dart
// lib/screens/message_compose_screen.dart
import 'package:flutter/material.dart';
import 'package:yanwari_message_mobile/services/api_service.dart';
import 'package:yanwari_message_mobile/screens/tone_selection_screen.dart';

class MessageComposeScreen extends StatefulWidget {
  const MessageComposeScreen({Key? key}) : super(key: key);
  
  @override
  State<MessageComposeScreen> createState() => _MessageComposeScreenState();
}

class _MessageComposeScreenState extends State<MessageComposeScreen> {
  final _messageController = TextEditingController();
  final _recipientController = TextEditingController();
  final _apiService = ApiService();
  bool _isLoading = false;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('やんわり伝言'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 受信者入力
            TextField(
              controller: _recipientController,
              decoration: const InputDecoration(
                labelText: '送信先メールアドレス',
                hintText: 'user@example.com',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            
            // メッセージ入力
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: const InputDecoration(
                  labelText: '伝えたいこと',
                  hintText: '明日の会議、準備できてないから延期してほしい',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
              ),
            ),
            const SizedBox(height: 16),
            
            // 文字数表示
            Text(
              '${_messageController.text.length} / 500文字',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.right,
            ),
            const SizedBox(height: 16),
            
            // トーン変換ボタン
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _transformTone,
              icon: const Icon(Icons.transform),
              label: _isLoading 
                  ? const Text('変換中...')
                  : const Text('🎭 トーン変換'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _transformTone() async {
    if (_messageController.text.isEmpty || _recipientController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('メッセージと送信先を入力してください')),
      );
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      // 1. メッセージ作成
      final messageResponse = await _apiService.createMessage(
        originalText: _messageController.text,
        recipientEmail: _recipientController.text,
      );
      
      final messageId = messageResponse['data']['id'];
      
      // 2. トーン変換
      final toneResponse = await _apiService.transformTones(
        messageId: messageId,
        originalText: _messageController.text,
      );
      
      // 3. トーン選択画面に遷移
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ToneSelectionScreen(
            messageId: messageId,
            originalText: _messageController.text,
            toneVariations: toneResponse['data']['variations'],
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('エラーが発生しました: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  @override
  void dispose() {
    _messageController.dispose();
    _recipientController.dispose();
    super.dispose();
  }
}
```

## リスク管理と対策

### Stage 1 リスク

**リスク**: Firebase Admin SDK統合時の認証エラー
**対策**: 
- ローカル環境での段階的テスト
- Firebase Emulator Suiteでの事前検証
- ロールバック可能な段階的デプロイ

**リスク**: MongoDB ユーザーデータ移行時の データロス
**対策**:
- 移行前の完全バックアップ作成
- 段階的移行（少数ユーザーでのテスト）
- 移行確認後の古いデータ保持

### Stage 2 リスク

**リスク**: Vue.js認証フロー変更時のUI不具合
**対策**:
- 既存UIをできるだけ維持
- A/Bテストでの段階的展開
- ユーザー受け入れテストの実施

### Stage 3 リスク

**リスク**: Flutter開発の学習コスト
**対策**:
- Flutter公式ドキュメント・チュートリアル活用
- 小規模プロトタイプでの事前検証
- 段階的機能実装（MVP → 機能拡張）

## 実装チェックリスト

### Stage 1: バックエンド統合
- [ ] Firebase プロジェクト作成・設定
- [ ] Firebase Admin SDK導入
- [ ] 認証ミドルウェア更新
- [ ] MongoDB ユーザーデータ移行スクリプト作成
- [ ] 移行テスト実行
- [ ] API エンドポイントテスト
- [ ] パフォーマンステスト

### Stage 2: Web移行
- [ ] Firebase Client SDK導入
- [ ] 認証ストア移行
- [ ] APIサービス更新
- [ ] 認証フローテスト
- [ ] UI/UX動作確認
- [ ] ブラウザ互換性テスト

### Stage 3: Flutter開発
- [ ] Flutter プロジェクト作成
- [ ] FlutterFire設定
- [ ] 認証サービス実装
- [ ] API連携サービス実装
- [ ] 基本UI実装（ログイン・メッセージ作成）
- [ ] トーン変換・スケジュール機能実装
- [ ] iOS/Android実機テスト
- [ ] ストア申請準備

## 完了基準

### Stage 1 完了基準
- ✅ Firebase Admin SDKでの認証が正常動作
- ✅ 全てのAPIエンドポイントでFirebase ID Token認証が機能
- ✅ MongoDB ユーザーデータ移行が完了
- ✅ 既存のWeb UIから正常にAPIアクセス可能

### Stage 2 完了基準
- ✅ Firebase Client SDKでのログイン・登録が正常動作
- ✅ 自動トークンリフレッシュが機能
- ✅ 全ての既存機能がFirebase認証で動作
- ✅ パスワードリセット等の追加機能が利用可能

### Stage 3 完了基準
- ✅ Flutter アプリでFirebase認証が正常動作
- ✅ やんわり伝言の全機能がモバイルで利用可能
- ✅ iOS/Android両プラットフォームで動作確認
- ✅ プッシュ通知等のモバイル特化機能が実装
- ✅ ストア申請・リリース準備完了

## 期待される成果

### 開発効率向上
- **コード削減**: 認証関連600行 → 200行
- **保守工数削減**: セキュリティ更新がFirebase側で自動実施
- **新機能追加**: MFA、ソーシャルログイン等がSDKで提供

### セキュリティ強化
- **エンタープライズレベル**: Google標準のセキュリティ対策
- **自動更新**: 最新の脆弱性対策が自動適用
- **監査ログ**: Firebase Consoleでの詳細なアクセスログ

### ユーザー体験向上
- **統一認証**: Web/Mobile同一アカウント
- **高度な機能**: パスワードリセット、MFA等
- **高速認証**: Firebase最適化された認証フロー

この移行により、やんわり伝言アプリは現代的で拡張性の高い認証基盤を獲得し、Web/Mobile統一プラットフォームとしての基盤が完成します。