# データベースアーキテクチャ分析

## Firebase認証 + MongoDB データベースの兼ね合い

### アーキテクチャ概要
**やんわり伝言サービス**では、認証とデータ保存を以下のように分離している：

- **Firebase**: ユーザー認証のみ（ID Token検証・ログイン・パスワード管理）
- **MongoDB**: すべてのアプリケーションデータ（メッセージ・友達関係・評価等）

### 認証フロー
1. **フロントエンド**: Firebase Web SDK でログイン → ID Token取得
2. **バックエンド**: Firebase Admin SDK でID Token検証 → Firebase UID抽出
3. **データ連携**: Firebase UID → MongoDB内ユーザーレコード検索

### データ構造

#### MongoDB内Userモデル
```go
type User struct {
    ID           primitive.ObjectID `bson:"_id,omitempty" json:"id"`
    Name         string             `bson:"name" json:"name"`
    Email        string             `bson:"email" json:"email"`
    FirebaseUID  string             `bson:"firebase_uid,omitempty" json:"firebase_uid,omitempty"`  // 重要：Firebase連携キー
    PasswordHash string             `bson:"password_hash" json:"-"`     // 古いJWT用（現在未使用）
    Salt         string             `bson:"salt" json:"-"`              // 古いJWT用（現在未使用）
    Timezone     string             `bson:"timezone" json:"timezone"`
    CreatedAt    time.Time          `bson:"created_at" json:"created_at"`
    UpdatedAt    time.Time          `bson:"updated_at" json:"updated_at"`
}
```

#### Firebase-MongoDB連携の仕組み
1. **認証**: Firebase ID Tokenで認証
2. **ユーザー特定**: `firebase_uid`フィールドでMongoDB内ユーザーを検索
3. **データ操作**: MongoDB ObjectIDでアプリケーションデータを管理

### 認証ミドルウェア実装

#### Firebase認証ミドルウェア (`middleware/firebase_auth.go`)
```go
func FirebaseAuthMiddleware(firebaseService *services.FirebaseService) gin.HandlerFunc {
    return func(c *gin.Context) {
        // Authorization ヘッダーからBearer tokenを抽出
        authHeader := c.GetHeader("Authorization")
        idToken := strings.TrimPrefix(authHeader, "Bearer ")
        
        // Firebase ID Tokenを検証
        token, err := firebaseService.VerifyIDToken(idToken)
        if err != nil {
            c.JSON(401, gin.H{"error": "認証が必要です"})
            c.Abort()
            return
        }
        
        // Firebase UIDとEmailをコンテキストに保存
        c.Set("firebase_uid", token.UID)
        c.Set("user_email", token.Claims["email"])
        c.Next()
    }
}
```

#### API ハンドラーでのユーザー取得パターン
```go
func (h *MessageHandler) CreateMessage(c *gin.Context) {
    // 1. Firebase認証からUID取得
    firebaseUID, exists := c.Get("firebase_uid")
    if !exists {
        c.JSON(401, gin.H{"error": "認証が必要です"})
        return
    }
    
    // 2. Firebase UID → MongoDB ユーザーレコード検索
    user, err := h.userService.GetUserByFirebaseUID(c.Request.Context(), firebaseUID.(string))
    if err != nil {
        c.JSON(404, gin.H{"error": "ユーザーが見つかりません"})
        return
    }
    
    // 3. MongoDB ObjectIDでメッセージ作成
    message := &Message{
        SenderID: user.ID,  // MongoDB ObjectID
        // ...
    }
}
```

### ユーザー同期システム

#### Firebase → MongoDB同期 (`handlers/firebase_auth.go`)
```go
func (h *FirebaseAuthHandler) SyncUserFromFirebase(c *gin.Context) {
    firebaseUID, _ := middleware.GetFirebaseUID(c)
    
    // 既存ユーザーをチェック
    existingUser, err := h.userService.GetUserByFirebaseUID(c.Request.Context(), firebaseUID)
    if err == nil {
        // 既存ユーザーが見つかった場合
        return existingUser
    }
    
    // Firebase上でのユーザー情報を取得
    firebaseUser, err := h.firebaseService.GetUserByUID(firebaseUID)
    if err != nil {
        return err
    }
    
    // 新しいユーザーをMongoDBに作成
    newUser := &models.User{
        Email:       firebaseUser.Email,
        FirebaseUID: firebaseUID,        // 重要：連携キー
        Name:        firebaseUser.DisplayName,
        Timezone:    "Asia/Tokyo",
    }
    
    err = h.userService.CreateUserWithFirebaseUID(c.Request.Context(), newUser)
    return newUser
}
```

## テストデータ初期化への影響

### データベース初期化で考慮すべき点

#### 1. Firebase認証データ
- **問題**: Firebaseはクラウドサービスのため、ローカルで完全制御できない
- **解決案**: テスト用Firebase UIDを使用したモックデータ

#### 2. MongoDB アプリケーションデータ
- **対象**: users, messages, friendships, ratings等のコレクション
- **制御**: 完全にローカルで制御可能

### テストデータ初期化戦略

#### Option 1: Firebase Emulator + MongoDB（推奨）
```bash
# Firebase Emulator起動
firebase emulators:start --only auth

# MongoDB初期化
npm run db:reset
```

#### Option 2: 固定テスト用Firebase UID（実装予定）
```json
// test-data/users.json
[
  {
    "_id": "test_user_001",
    "email": "alice@yanwari.com",
    "name": "Alice テスター", 
    "firebase_uid": "test_firebase_uid_001",  // 固定テスト用UID
    "timezone": "Asia/Tokyo"
  }
]
```

#### Option 3: Firebase実アカウント + MongoDB初期化（現在の方法）
- テスト用Firebaseアカウントを事前作成
- MongoDBのみ初期化スクリプトで管理

## 実装における重要な考慮事項

### セキュリティ
- Firebase ID Tokenは短期間有効（1時間）
- MongoDB接続は適切に認証・暗号化
- テスト環境と本番環境の分離

### パフォーマンス
- Firebase UID → MongoDB検索のインデックス最適化
- 認証ミドルウェアでの効率的なトークン検証

### 開発・テスト体験
- 簡単なデータベース初期化コマンド
- 一貫したテストデータセット
- エラー時のわかりやすいメッセージ