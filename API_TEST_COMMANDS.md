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

**注意:** バリデーションエラーメッセージが日本語で統一されています。

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

## 6. トーン変換機能テスト（F-02 実装完了）

### 前提条件
- ログイン済みでJWTトークンを保持していること
- Anthropic Claude APIキーが設定済みであること

### 6.1. メッセージ下書き作成

**コマンド:**
```bash
export JWT_TOKEN="[ログインで取得したJWTトークン]"

curl -X POST http://localhost:8080/api/v1/messages/draft \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $JWT_TOKEN" \
  -d '{"originalText":"明日の会議、準備が間に合わないので延期してもらえませんか？","recipientEmail":"hnn-a@gmail.com"}'
```

**期待される結果:**
```json
{
  "data": {
    "id": "6857982dd1f7d86254217933",
    "senderId": "6856690091b5f3e54b80270d",
    "recipientId": "685750682b7f67bacc835277",
    "originalText": "明日の会議、準備が間に合わないので延期してもらえませんか？",
    "variations": {},
    "status": "draft",
    "createdAt": "2025-06-22T14:44:13.920895+09:00",
    "updatedAt": "2025-06-22T14:44:13.920895+09:00"
  },
  "message": "下書きを作成しました"
}
```

### 6.2. AIトーン変換実行

**コマンド:**
```bash
curl -X POST http://localhost:8080/api/v1/transform/tones \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $JWT_TOKEN" \
  -d '{"messageId":"6857982dd1f7d86254217933","originalText":"明日の会議、準備が間に合わないので延期してもらえませんか？"}'
```

**期待される結果:**
```json
{
  "data": {
    "messageId": "6857982dd1f7d86254217933",
    "variations": [
      {
        "tone": "gentle",
        "text": "大変申し訳ございません🙇‍♀️\n明日の会議についてお願いがございます。\n\n資料の準備に想定以上の時間がかかっており、より良い内容にするためにもう少しお時間をいただけますと大変ありがたく存じます。皆様のご予定を調整いただくことになり、大変恐縮ではございますが、会議の延期をご検討いただけませんでしょうか？😊\n\nご多忙の中、突然のお願いで誠に申し訳ございません。ご理解いただけますと幸いです。\n\n何卒よろしくお願い申し上げます。🙏"
      },
      {
        "tone": "constructive", 
        "text": "お世話になっております。明日の会議に関しまして、より充実した内容をご提供させていただくため、開催日程の調整をご相談させていただきたく存じます。\n\n具体的には、\n・より詳細な資料作成\n・関係者との事前すり合わせ\nを確実に行いたいと考えております。\n\nつきましては、来週前半でお時間を頂戴できますと幸いです。その際には、\n・現在の進捗状況の共有\n・追加で必要な準備事項の確認\nなどもさせていただければと存じます。\n\nご多用の中、大変恐縮ではございますが、ご検討いただけますと幸いです。"
      },
      {
        "tone": "casual",
        "text": "すみません😅 明日の会議なんですけど、ちょっと準備がまだ追いついてなくて...💦\nよければ、日程ずらしていただけたら助かるんですけど、どうでしょ？🙏"
      }
    ]
  },
  "message": "トーン変換が完了しました"
}
```

### トーン変換の特徴

**💝 優しめトーン**: 丁寧語・敬語、感謝・謝罪表現、絵文字使用  
**🏗️ 建設的トーン**: 具体的提案、代替案含む、プロフェッショナルな表現  
**🎯 カジュアルトーン**: フレンドリー、話し言葉、親近感のある表現  

### 実測パフォーマンス
- メッセージ作成: 約200ms
- AIトーン変換: 約7秒（3トーン並行処理）
- データベース保存: 約50ms
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

## メッセージ作成機能テスト

### 前提条件
1. 事前にユーザー登録とログインを完了し、アクセストークンを取得してください
2. 複数ユーザーが登録されていると検索テストがより効果的です

### 13. ユーザー検索テスト

**ユーザー検索（名前で検索）:**
```bash
curl -X GET "http://localhost:8080/api/v1/users/search?q=Demo" \
  -H "Authorization: Bearer <アクセストークン>"
```

**ユーザー検索（メールで検索）:**
```bash
curl -X GET "http://localhost:8080/api/v1/users/search?q=example.com" \
  -H "Authorization: Bearer <アクセストークン>"
```

**期待される結果:**
```json
{
  "data": {
    "users": [
      {
        "id": "68574d282b7f67bacc835270",
        "name": "Demo User",
        "email": "demo@example.com",
        "timezone": "Asia/Tokyo",
        "created_at": "2025-06-22T00:24:08.529Z",
        "updated_at": "2025-06-22T00:24:08.529Z"
      }
    ],
    "pagination": {
      "page": 1,
      "limit": 10,
      "total": 1
    }
  }
}
```

### 14. メッセージ下書き作成テスト

**下書き作成（受信者なし）:**
```bash
curl -X POST http://localhost:8080/api/v1/messages/draft \
  -H "Authorization: Bearer <アクセストークン>" \
  -H "Content-Type: application/json" \
  -d '{
    "originalText": "明日の会議の件でご相談があります。お時間のある時にお話しできればと思います。"
  }'
```

**下書き作成（受信者指定）:**
```bash
curl -X POST http://localhost:8080/api/v1/messages/draft \
  -H "Authorization: Bearer <アクセストークン>" \
  -H "Content-Type: application/json" \
  -d '{
    "originalText": "プロジェクトの進捗について報告いたします。",
    "recipientEmail": "demo@example.com"
  }'
```

**期待される結果:**
```json
{
  "data": {
    "id": "68574d3e2b7f67bacc835271",
    "senderId": "68574d282b7f67bacc835270",
    "recipientId": "68574d282b7f67bacc835270",
    "originalText": "明日の会議の件でご相談があります。お時間のある時にお話しできればと思います。",
    "variations": {},
    "status": "draft",
    "createdAt": "2025-06-22T09:24:30.375578+09:00",
    "updatedAt": "2025-06-22T09:24:30.375578+09:00"
  },
  "message": "下書きを作成しました"
}
```

### 15. 下書き一覧取得テスト

**下書き一覧取得:**
```bash
curl -X GET http://localhost:8080/api/v1/messages/drafts \
  -H "Authorization: Bearer <アクセストークン>"
```

**ページネーション付き取得:**
```bash
curl -X GET "http://localhost:8080/api/v1/messages/drafts?page=1&limit=5" \
  -H "Authorization: Bearer <アクセストークン>"
```

**期待される結果:**
```json
{
  "data": {
    "messages": [
      {
        "id": "68574d3e2b7f67bacc835271",
        "senderId": "68574d282b7f67bacc835270",
        "recipientId": "000000000000000000000000",
        "originalText": "明日の会議の件でご相談があります。",
        "variations": {},
        "status": "draft",
        "createdAt": "2025-06-22T00:24:30.375Z",
        "updatedAt": "2025-06-22T00:24:30.375Z"
      }
    ],
    "pagination": {
      "page": 1,
      "limit": 20,
      "total": 1
    }
  }
}
```

### 16. 特定メッセージ取得テスト

**メッセージID指定で取得:**
```bash
curl -X GET http://localhost:8080/api/v1/messages/<メッセージID> \
  -H "Authorization: Bearer <アクセストークン>"
```

### 17. メッセージ更新テスト

**下書き内容更新:**
```bash
curl -X PUT http://localhost:8080/api/v1/messages/<メッセージID> \
  -H "Authorization: Bearer <アクセストークン>" \
  -H "Content-Type: application/json" \
  -d '{
    "originalText": "更新されたメッセージ内容です。やんわりと伝えたいことがあります。",
    "recipientEmail": "updated-recipient@example.com"
  }'
```

### 18. メッセージ削除テスト

**下書き削除:**
```bash
curl -X DELETE http://localhost:8080/api/v1/messages/<メッセージID> \
  -H "Authorization: Bearer <アクセストークン>"
```

**期待される結果:**
```json
{
  "message": "メッセージを削除しました"
}
```

### 19. 現在のユーザー情報取得テスト

**自分のユーザー情報取得:**
```bash
curl -X GET http://localhost:8080/api/v1/users/me \
  -H "Authorization: Bearer <アクセストークン>"
```

**期待される結果:**
```json
{
  "data": {
    "id": "68574d282b7f67bacc835270",
    "name": "Demo User",
    "email": "demo@example.com",
    "timezone": "Asia/Tokyo",
    "created_at": "2025-06-22T00:24:08.529Z",
    "updated_at": "2025-06-22T00:24:08.529Z"
  }
}
```

### 20. メールアドレスでユーザー取得テスト

**メールアドレス指定でユーザー検索:**
```bash
curl -X GET "http://localhost:8080/api/v1/users/by-email?email=demo@example.com" \
  -H "Authorization: Bearer <アクセストークン>"
```

## メッセージ作成機能 完全テストシーケンス

以下の順序で全機能をテストできます：

```bash
# 1. 事前準備：ユーザー登録とログイン
curl -X POST http://localhost:8080/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"name":"テストユーザー","email":"test-message-'$(date +%s)'@example.com","password":"testpass123"}'

# 上記のレスポンスからアクセストークンをコピーして以下で使用

# 2. ユーザー検索テスト
curl -X GET "http://localhost:8080/api/v1/users/search?q=テスト" \
  -H "Authorization: Bearer <アクセストークン>"

# 3. 下書き作成テスト
curl -X POST http://localhost:8080/api/v1/messages/draft \
  -H "Authorization: Bearer <アクセストークン>" \
  -H "Content-Type: application/json" \
  -d '{"originalText":"やんわりテストメッセージです。お疲れ様でした。"}'

# 4. 下書き一覧確認
curl -X GET http://localhost:8080/api/v1/messages/drafts \
  -H "Authorization: Bearer <アクセストークン>"

# 5. 特定メッセージ取得（上記レスポンスのIDを使用）
curl -X GET http://localhost:8080/api/v1/messages/<メッセージID> \
  -H "Authorization: Bearer <アクセストークン>"

# 6. メッセージ更新
curl -X PUT http://localhost:8080/api/v1/messages/<メッセージID> \
  -H "Authorization: Bearer <アクセストークン>" \
  -H "Content-Type: application/json" \
  -d '{"originalText":"更新されたやんわりメッセージです。"}'

# 7. メッセージ削除
curl -X DELETE http://localhost:8080/api/v1/messages/<メッセージID> \
  -H "Authorization: Bearer <アクセストークン>"
```

## エラーハンドリングテスト（メッセージ機能）

### 21. 認証なしでアクセス

**コマンド:**
```bash
curl -X GET http://localhost:8080/api/v1/messages/drafts
```

**期待される結果:**
```json
{"error":"認証ヘッダーが必要です"}
```

### 22. 無効なトークンでアクセス

**コマンド:**
```bash
curl -X GET http://localhost:8080/api/v1/messages/drafts \
  -H "Authorization: Bearer invalid-token"
```

**期待される結果:**
```json
{"error":"無効なトークンです"}
```

### 23. 存在しないメッセージID

**コマンド:**
```bash
curl -X GET http://localhost:8080/api/v1/messages/000000000000000000000000 \
  -H "Authorization: Bearer <アクセストークン>"
```

**期待される結果:**
```json
{"error":"メッセージが見つかりません"}
```

### 24. 他人のメッセージへのアクセス

異なるユーザーが作成したメッセージIDでアクセスした場合、適切にアクセス制御されることを確認できます。

### 25. 無効な受信者メールアドレス

**コマンド:**
```bash
curl -X POST http://localhost:8080/api/v1/messages/draft \
  -H "Authorization: Bearer <アクセストークン>" \
  -H "Content-Type: application/json" \
  -d '{"originalText":"テストメッセージ","recipientEmail":"nonexistent@example.com"}'
```

**期待される結果:**
```json
{"error":"指定された受信者が見つかりません"}
```

## フロントエンド連携テスト

フロントエンドが起動している場合（http://localhost:5173）、以下でブラウザテストが可能：

1. **ユーザー登録**: http://localhost:5173/register
2. **ログイン**: http://localhost:5173/login  
3. **メッセージ作成**: http://localhost:5173/compose

**フロントエンドテスト項目:**
- ユーザー検索（リアルタイム検索）
- 受信者選択と表示
- メッセージ入力と文字数カウント
- 下書き保存と一覧表示
- エラーハンドリング表示

---

**最終更新:** 2025年6月22日  
**対応バージョン:** メッセージ作成機能統合完了版（F-01認証システム + message-compose機能）  
**動作確認済み:** ユーザー検索、メッセージCRUD、リアルタイム検索、フロントエンド連携