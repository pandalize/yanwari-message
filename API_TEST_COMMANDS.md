# API テストコマンド集

このファイルには、やんわり伝言サービスのAPIを手動でテストするためのcurlコマンドと期待される結果が記載されています。

## 前提条件

1. バックエンドサーバーが起動していること
```bash
cd backend
go run main.go
```

2. サーバーが `http://localhost:8080` で動作していること

## 基本動作確認

### 1. ヘルスチェック

**コマンド:**
```bash
curl -X GET http://localhost:8080/health
```

**期待される結果:**
```json
{"message":"Server is running","port":"","status":"ok"}
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

### 3. ユーザー登録

**コマンド:**
```bash
curl -X POST http://localhost:8080/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123"}'
```

**期待される結果:**
- 初回実行: 成功レスポンス（JWTトークン付き）
- 2回目以降: `{"error":"このメールアドレスは既に登録されています"}`

**成功時のレスポンス例:**
```json
{
  "data": {
    "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "expires_in": 900,
    "user": {
      "id": "uuid-string",
      "email": "test@example.com",
      "created_at": "2025-06-21T13:00:00+09:00",
      "updated_at": "2025-06-21T13:00:00+09:00"
    }
  },
  "message": "ユーザー登録が完了しました"
}
```

### 4. 新しいメールアドレスでの登録

**コマンド:**
```bash
curl -X POST http://localhost:8080/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"newuser@example.com","password":"password123"}'
```

**期待される結果:** 成功レスポンス（上記と同様）

### 5. デモアカウントログイン

**コマンド:**
```bash
curl -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"demo@example.com","password":"password123"}'
```

**期待される結果:**
```json
{
  "data": {
    "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "expires_in": 900,
    "user": {
      "id": "uuid-string",
      "email": "demo@example.com",
      "created_at": "2025-06-20T13:22:08+09:00",
      "updated_at": "2025-06-21T13:22:08+09:00"
    }
  },
  "message": "ログインに成功しました"
}
```

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

### 7. トークンリフレッシュ

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
      "id": "uuid-string",
      "email": "user@example.com",
      "created_at": "2025-06-21T13:00:00+09:00",
      "updated_at": "2025-06-21T13:00:00+09:00"
    }
  },
  "message": "トークンのリフレッシュが完了しました"
}
```

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
    "user_id": "uuid-string"
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

## 完全テストシーケンス

以下のシーケンスで全機能を順次テストできます：

```bash
# 1. サーバー動作確認
curl -X GET http://localhost:8080/health
curl -X GET http://localhost:8080/api/status

# 2. ユーザー登録
curl -X POST http://localhost:8080/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"testuser@example.com","password":"password123"}'

# 3. 重複登録確認
curl -X POST http://localhost:8080/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"testuser@example.com","password":"password123"}'

# 4. デモアカウントログイン
curl -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"demo@example.com","password":"password123"}'

# 5. ここで上記のレスポンスからトークンをコピーして、以下で使用
# リフレッシュトークンでトークンリフレッシュ
# アクセストークンでログアウト
```

## トラブルシューティング

### サーバーが起動していない場合
```bash
# ポート確認
lsof -i :8080

# サーバー起動
cd backend
go run main.go
```

### レスポンスが見やすくない場合
```bash
# jqを使って整形（jqがインストールされている場合）
curl -X GET http://localhost:8080/health | jq

# 改行付きで表示
curl -s -X GET http://localhost:8080/health && echo
```

### サーバーログの確認
サーバーを起動したターミナルでリクエストのログを確認できます。

---

**最終更新:** 2025年6月21日  
**対応バージョン:** F-01認証システム完全実装版