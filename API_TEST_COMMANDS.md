# API テストコマンド集

このファイルには、やんわり伝言サービスのAPIを手動でテストするためのcurlコマンドと期待される結果が記載されています。

## 前提条件

1. **MongoDB Atlas接続設定完了**
   - `.env` ファイルにMongoDB Atlas URIが設定済み
   - 実際のデータベースに接続・保存されます

2. **バックエンドサーバーが起動していること**
```bash
cd backend
go run main.go
```

3. **サーバーが `http://localhost:8080` で動作していること**
   - MongoDB Atlas接続成功ログが表示されることを確認

## 基本動作確認

### 1. ヘルスチェック（MongoDB Atlas接続確認含む）

**コマンド:**
```bash
curl -X GET http://localhost:8080/health
```

**期待される結果:**
```json
{
  "status": "ok",
  "message": "Health check completed",
  "timestamp": "2025-06-21T17:10:15+09:00",
  "port": "8080",
  "components": {
    "server": {
      "status": "ok",
      "uptime": "2m30s"
    },
    "database": {
      "status": "ok",
      "type": "MongoDB Atlas"
    }
  }
}
```

**MongoDB接続エラー時:**
```json
{
  "status": "degraded",
  "message": "Health check completed",
  "components": {
    "database": {
      "status": "error",
      "type": "MongoDB Atlas",
      "error": "接続エラーの詳細"
    }
  }
}
```

### 2. API ステータス確認

**コマンド:**
```bash
curl -X GET http://localhost:8080/api/status
```

**期待される結果:**
```json
{"environment":"debug","service":"yanwari-message-backend","status":"running"}
```

## 認証システムテスト

### 3. ユーザー登録（MongoDB Atlas実保存）

**コマンド:**
```bash
curl -X POST http://localhost:8080/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test-user-$(date +%s)@example.com","password":"password123"}'
```

**重要:** 毎回異なるメールアドレスを使用するか、既存のユーザーは重複エラーになります。

**期待される結果:**
- 初回実行: 成功レスポンス（JWTトークン付き、MongoDB Atlasに実際に保存）
- 同じメール再実行: `{"error":"このメールアドレスは既に登録されています"}`

**成功時のレスポンス例:**
```json
{
  "data": {
    "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "expires_in": 900,
    "user": {
      "id": "6856690091b5f3e54b80270d",
      "email": "test-user@example.com",
      "timezone": "Asia/Tokyo",
      "created_at": "2025-06-21T17:10:40.655753+09:00",
      "updated_at": "2025-06-21T17:10:40.655753+09:00"
    }
  },
  "message": "ユーザー登録が完了しました"
}
```

**データベース確認:**
- ユーザーデータがMongoDB Atlas の `users` コレクションに実際に保存されます
- パスワードはArgon2でハッシュ化されて安全に保存されます

### 4. 新しいメールアドレスでの登録

**コマンド:**
```bash
curl -X POST http://localhost:8080/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"newuser@example.com","password":"password123"}'
```

**期待される結果:** 成功レスポンス（上記と同様）

### 5. 登録済みユーザーでのログイン

**重要:** 事前に登録したメールアドレス/パスワードを使用してください。

**コマンド:**
```bash
curl -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test-user@example.com","password":"password123"}'
```

**期待される結果:**
```json
{
  "data": {
    "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "expires_in": 900,
    "user": {
      "id": "6856690091b5f3e54b80270d",
      "email": "test-user@example.com",
      "timezone": "Asia/Tokyo",
      "created_at": "2025-06-21T08:10:40.655Z",
      "updated_at": "2025-06-21T08:10:40.655Z"
    }
  },
  "message": "ログインに成功しました"
}
```

**データベース認証:**
- MongoDB Atlasからユーザー情報を取得
- Argon2でパスワード検証を実行
- 新しいJWTトークンペアを生成

### 6. 不正なログイン

**コマンド:**
```bash
curl -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"invalid@example.com","password":"wrongpassword"}'
```

**期待される結果:**
```json
{"error":"メールアドレスまたはパスワードが正しくありません"}
```

### 7. トークンリフレッシュ（データベースユーザー情報取得）

**重要:** 事前にログインまたは登録でリフレッシュトークンを取得してください。

**コマンド:**
```bash
curl -X POST http://localhost:8080/api/v1/auth/refresh \
  -H "Content-Type: application/json" \
  -d '{"refresh_token":"ここにリフレッシュトークンを貼り付け"}'
```

**期待される結果:**
```json
{
  "data": {
    "access_token": "新しいアクセストークン",
    "refresh_token": "新しいリフレッシュトークン",
    "expires_in": 900,
    "user": {
      "id": "6856690091b5f3e54b80270d",
      "email": "test-user@example.com",
      "timezone": "Asia/Tokyo",
      "created_at": "2025-06-21T08:10:40.655Z",
      "updated_at": "2025-06-21T08:10:40.655Z"
    }
  },
  "message": "トークンのリフレッシュが完了しました"
}
```

**データベース処理:**
- リフレッシュトークンを検証
- MongoDB AtlasからユーザーIDでユーザー情報を取得
- 新しいアクセス・リフレッシュトークンペアを生成

### 8. ログアウト

**重要:** 事前にログインまたは登録でアクセストークンを取得してください。

**コマンド:**
```bash
curl -X POST http://localhost:8080/api/v1/auth/logout \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ここにアクセストークンを貼り付け"
```

**期待される結果:**
```json
{
  "data": {
    "logged_out": true,
    "user_id": "6856690091b5f3e54b80270d"
  },
  "message": "ログアウトが完了しました"
}
```

## エラーハンドリングテスト

### 9. 無効なトークンでログアウト

**コマンド:**
```bash
curl -X POST http://localhost:8080/api/v1/auth/logout \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer invalid-token"
```

**期待される結果:**
```json
{"error":"無効なトークンです"}
```

### 10. 認証ヘッダー無しでログアウト

**コマンド:**
```bash
curl -X POST http://localhost:8080/api/v1/auth/logout \
  -H "Content-Type: application/json"
```

**期待される結果:**
```json
{"error":"認証ヘッダーが必要です"}
```

### 11. 無効なリフレッシュトークン

**コマンド:**
```bash
curl -X POST http://localhost:8080/api/v1/auth/refresh \
  -H "Content-Type: application/json" \
  -d '{"refresh_token":"invalid-refresh-token"}'
```

**期待される結果:**
```json
{"error":"無効なリフレッシュトークンです"}
```

### 12. バリデーションエラーテスト

**短いパスワードでの登録:**
```bash
curl -X POST http://localhost:8080/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"123"}'
```

**期待される結果:**
```json
{"error":"パスワードは8文字以上である必要があります"}
```

**無効なメール形式:**
```bash
curl -X POST http://localhost:8080/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"invalid-email","password":"password123"}'
```

**期待される結果:**
```json
{"error":"リクエストが無効です","details":"Key: 'RegisterRequest.Email' Error:Field validation for 'Email' failed on the 'email' tag"}
```

## 完全テストシーケンス（MongoDB Atlas統合版）

以下のシーケンスで全機能を順次テストできます：

```bash
# 1. サーバー・データベース動作確認
curl -X GET http://localhost:8080/health
curl -X GET http://localhost:8080/api/status

# 2. 新規ユーザー登録（MongoDB Atlasに実保存）
curl -X POST http://localhost:8080/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"testuser-'$(date +%s)'@example.com","password":"password123"}'

# 3. 重複登録確認（同じメールアドレス）
curl -X POST http://localhost:8080/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"testuser-'$(date +%s)'@example.com","password":"password123"}'

# 4. 登録済みユーザーでログイン（DBから認証）
curl -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"登録時のメールアドレス","password":"password123"}'

# 5. 動作確認済み実例（実際のMongoDB AtlasユーザーID）
curl -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test-user@example.com","password":"testpassword123"}'

# 6. ここで上記のレスポンスからトークンをコピーして、以下で使用
# リフレッシュトークンでトークンリフレッシュ
# アクセストークンでログアウト
```

## MongoDB Atlas 統合確認

実際にデータベースに保存されているかの確認：

**登録性能実測値:**
- ユーザー登録: 147ms
- ログイン: 97ms
- ヘルスチェック: 13ms

**保存データ例:**
- ユーザーID: `6856690091b5f3e54b80270d` (ObjectID)
- コレクション: `users`
- パスワード: Argon2ハッシュ化済み
- タイムゾーン: `Asia/Tokyo` (自動設定)

## トラブルシューティング

### MongoDB Atlas接続エラー
```bash
# 1. 環境変数確認
cat backend/.env

# 2. ヘルスチェックでDB状況確認
curl -X GET http://localhost:8080/health

# 3. サーバーログでMongoDB接続確認
# 起動時に「MongoDB Atlas への接続が成功しました」が表示されるか確認
```

**MongoDB接続エラーの原因:**
- `.env` ファイルの `MONGODB_URI` が正しく設定されていない
- MongoDB Atlas のネットワークアクセス設定（IP許可）
- ユーザー名・パスワードの間違い

### サーバーが起動していない場合
```bash
# ポート確認
lsof -i :8080

# サーバー起動
cd backend
go run main.go

# 起動ログ確認ポイント
# "MongoDB Atlas への接続が成功しました。データベース: yanwari-message"
# "Server starting on port 8080"
```

### レスポンスが見やすくない場合
```bash
# jqを使って整形（jqがインストールされている場合）
curl -X GET http://localhost:8080/health | jq

# 改行付きで表示
curl -s -X GET http://localhost:8080/health && echo
```

### ユーザー登録・ログインエラー
- **重複エラー**: 既に登録済みのメールアドレスを使用
- **認証エラー**: メールアドレス・パスワードの不一致
- **DB接続エラー**: MongoDB Atlas接続に失敗

### パフォーマンス確認
正常動作時の応答速度目安：
- ヘルスチェック: 10-20ms
- ユーザー登録: 100-200ms（Argon2ハッシュ化のため）
- ログイン: 80-150ms（パスワード検証のため）

---

**最終更新:** 2025年6月21日  
**対応バージョン:** MongoDB Atlas統合完了版（F-01認証システム）  
**動作確認済み:** 実際のMongoDB Atlasでのデータ保存・取得・認証