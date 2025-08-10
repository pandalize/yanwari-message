# やんわり伝言サービス API設計書

## 概要

やんわり伝言サービスのRESTful APIエンドポイント仕様書です。

**バージョン**: v1.0  
**ベースURL**: `http://localhost:8080/api/v1`  
**認証方式**: Firebase Authentication  
**データ形式**: JSON  
**文字エンコーディング**: UTF-8  

---

## 認証

全てのAPIエンドポイントは Firebase Authentication が必要です（一部のユーティリティエンドポイントを除く）。

**認証ヘッダー**:
```http
Authorization: Bearer <firebase_id_token>
```

**Firebase認証の流れ**:
1. フロントエンドでFirebase Auth SDK を使用してログイン
2. Firebase ID Token を取得
3. リクエストヘッダーに Bearer Token として設定
4. バックエンドで Firebase Admin SDK を使用してトークン検証
5. Firebase UID から MongoDB ユーザー情報を取得

---

## エラーレスポンス形式

```json
{
  "error": "エラーメッセージ",
  "details": "詳細情報（任意）"
}
```

**HTTPステータスコード**:
- `200` OK - 成功
- `201` Created - リソース作成成功
- `400` Bad Request - リクエスト不正
- `401` Unauthorized - 認証エラー  
- `403` Forbidden - 権限不足
- `404` Not Found - リソース未発見
- `500` Internal Server Error - サーバーエラー

---

## 1. 認証関連エンドポイント（廃止予定）

### POST /auth/register
**用途**: ユーザー登録（廃止予定 - Firebase認証に統合済み）  
**認証**: 不要  

### POST /auth/login  
**用途**: ユーザーログイン（廃止予定 - Firebase認証に統合済み）  
**認証**: 不要  

### POST /auth/refresh
**用途**: JWTトークンリフレッシュ（廃止予定）  
**認証**: リフレッシュトークン  

### POST /auth/logout
**用途**: ユーザーログアウト（廃止予定）  
**認証**: JWT  

---

## 2. Firebase認証関連エンドポイント

### GET /firebase/profile
**用途**: Firebase認証を使用してユーザープロフィールを取得  
**認証**: Firebase Required  
**リクエスト**: なし  
**レスポンス**:
```json
{
  "message": "ユーザープロフィールを取得しました",
  "data": {
    "user": {
      "id": "ObjectId",
      "name": "ユーザー名",
      "email": "user@example.com",
      "firebaseUID": "firebase_uid_string",
      "timezone": "Asia/Tokyo"
    }
  }
}
```

### POST /firebase/migrate
**用途**: 既存ユーザーのFirebase移行（管理者用）  
**認証**: Firebase Required  

---

## 3. ユーザー関連エンドポイント

### GET /users/search
**用途**: ユーザー検索（友達申請・メッセージ送信用）  
**認証**: Firebase Required  
**クエリパラメータ**:
- `q` (string, required) - 検索キーワード
- `limit` (int, optional) - 最大件数 (default: 10)

**レスポンス**:
```json
{
  "data": [
    {
      "id": "ObjectId",
      "name": "ユーザー名",
      "email": "user@example.com"
    }
  ]
}
```

### GET /users/by-email
**用途**: メールアドレスでユーザー検索  
**認証**: Firebase Required  
**クエリパラメータ**:
- `email` (string, required) - メールアドレス

### GET /users/:id
**用途**: ユーザーID指定でユーザー情報取得  
**認証**: Firebase Required  
**パラメータ**:
- `id` (string) - ユーザーのObjectID

### GET /users/me
**用途**: 現在のログインユーザー情報取得  
**認証**: Firebase Required  
**レスポンス**:
```json
{
  "message": "ユーザー情報を取得しました",
  "data": {
    "id": "ObjectId",
    "name": "ユーザー名", 
    "email": "user@example.com",
    "timezone": "Asia/Tokyo"
  }
}
```

---

## 4. メッセージ関連エンドポイント

### POST /messages/draft
**用途**: 下書きメッセージ作成  
**認証**: Firebase Required  
**リクエストボディ**:
```json
{
  "recipientEmail": "recipient@example.com",
  "originalText": "メッセージ本文",
  "reason": "送信理由（任意）"
}
```
**レスポンス**:
```json
{
  "data": {
    "id": "ObjectId",
    "senderId": "ObjectId",
    "recipientId": "ObjectId", 
    "recipientEmail": "recipient@example.com",
    "originalText": "メッセージ本文",
    "reason": "送信理由",
    "status": "draft",
    "createdAt": "2025-08-10T10:30:00Z"
  },
  "message": "下書きを作成しました"
}
```

### PUT /messages/:id
**用途**: メッセージ更新  
**認証**: Firebase Required  
**パラメータ**: `id` - メッセージID  
**リクエストボディ**:
```json
{
  "originalText": "更新されたメッセージ本文",
  "reason": "更新された送信理由",
  "finalText": "最終送信テキスト（任意）",
  "selectedTone": "gentle|constructive|casual"
}
```

### GET /messages/:id
**用途**: メッセージ詳細取得  
**認証**: Firebase Required  
**パラメータ**: `id` - メッセージID  

### DELETE /messages/:id
**用途**: メッセージ削除  
**認証**: Firebase Required  
**パラメータ**: `id` - メッセージID  

### GET /messages/drafts
**用途**: 下書きメッセージ一覧取得  
**認証**: Firebase Required  
**クエリパラメータ**:
- `page` (int, optional) - ページ番号 (default: 1)
- `limit` (int, optional) - 1ページあたりの件数 (default: 20)

### GET /messages/received
**用途**: 受信メッセージ一覧取得  
**認証**: Firebase Required  
**クエリパラメータ**:
- `page` (int, optional) - ページ番号 (default: 1)
- `limit` (int, optional) - 1ページあたりの件数 (default: 20)

### GET /messages/sent
**用途**: 送信済みメッセージ一覧取得（送信者向け）  
**認証**: Firebase Required  
**クエリパラメータ**:
- `page` (int, optional) - ページ番号 (default: 1)  
- `limit` (int, optional) - 1ページあたりの件数 (default: 20)

**レスポンス**:
```json
{
  "message": "送信済みメッセージを取得しました",
  "data": {
    "messages": [
      {
        "id": "ObjectId",
        "recipientName": "受信者名",
        "recipientEmail": "recipient@example.com",
        "originalText": "元のメッセージ",
        "finalText": "最終送信テキスト",
        "reason": "送信理由",
        "status": "delivered|read",
        "sentAt": "2025-08-10T10:30:00Z",
        "deliveredAt": "2025-08-10T10:31:00Z",
        "readAt": "2025-08-10T11:00:00Z"
      }
    ],
    "pagination": {
      "page": 1,
      "limit": 20,
      "total": 100,
      "totalPages": 5
    }
  }
}
```

### POST /messages/:id/read
**用途**: メッセージを既読にする  
**認証**: Firebase Required  
**パラメータ**: `id` - メッセージID  

### POST /messages/deliver-scheduled
**用途**: スケジュール配信実行（システム内部用）  
**認証**: Firebase Required  

---

## 5. メッセージ評価関連エンドポイント

### POST /messages/:id/rate
**用途**: メッセージ評価作成・更新  
**認証**: Firebase Required  
**パラメータ**: `id` - メッセージID  
**リクエストボディ**:
```json
{
  "rating": 4
}
```
**バリデーション**: `rating` は 1-5 の整数  
**レスポンス**:
```json
{
  "message": "評価を保存しました",
  "data": {
    "id": "ObjectId",
    "messageId": "ObjectId", 
    "rating": 4,
    "createdAt": "2025-08-10T10:30:00Z",
    "updatedAt": "2025-08-10T10:30:00Z"
  }
}
```

### GET /messages/:id/rating
**用途**: メッセージ評価取得  
**認証**: Firebase Required  
**パラメータ**: `id` - メッセージID  
**レスポンス**:
```json
{
  "message": "評価を取得しました",
  "data": {
    "id": "ObjectId",
    "messageId": "ObjectId",
    "rating": 4,
    "createdAt": "2025-08-10T10:30:00Z",
    "updatedAt": "2025-08-10T10:30:00Z"
  }
}
```

### DELETE /messages/:id/rating
**用途**: メッセージ評価削除  
**認証**: Firebase Required  
**パラメータ**: `id` - メッセージID  

### GET /messages/inbox-with-ratings
**用途**: 評価付き受信トレイ取得  
**認証**: Firebase Required  
**クエリパラメータ**:
- `page` (int, optional) - ページ番号 (default: 1)
- `limit` (int, optional) - 1ページあたりの件数 (default: 20)

**レスポンス**:
```json
{
  "message": "評価付き受信トレイを取得しました",
  "data": {
    "messages": [
      {
        "id": "ObjectId",
        "senderId": "ObjectId",
        "senderName": "送信者名",
        "senderEmail": "sender@example.com",
        "originalText": "元のメッセージ",
        "finalText": "やんわり変換後テキスト",
        "status": "delivered",
        "rating": 4,
        "ratingId": "ObjectId",
        "createdAt": "2025-08-10T10:30:00Z",
        "sentAt": "2025-08-10T10:30:00Z",
        "deliveredAt": "2025-08-10T10:31:00Z",
        "readAt": "2025-08-10T11:00:00Z"
      }
    ],
    "pagination": {
      "page": 1,
      "limit": 20,
      "total": 100,
      "totalPages": 5
    }
  }
}
```

---

## 6. AIトーン変換関連エンドポイント

### POST /transform/tones
**用途**: メッセージを3つのトーンに変換（gentle/constructive/casual）  
**認証**: Firebase Required  
**リクエストボディ**:
```json
{
  "messageId": "ObjectId",
  "originalText": "変換したいメッセージ"
}
```
**レスポンス**:
```json
{
  "message": "トーン変換が完了しました",
  "data": {
    "messageId": "ObjectId",
    "originalText": "元のメッセージ", 
    "transformations": {
      "gentle": "とても丁寧で優しい表現に変換されたテキスト",
      "constructive": "建設的で解決志向な表現に変換されたテキスト", 
      "casual": "親しみやすくカジュアルな表現に変換されたテキスト"
    },
    "processingTime": "2.5s",
    "completedAt": "2025-08-10T10:30:00Z"
  }
}
```

### POST /transform/reload-config
**用途**: AI設定ファイル再読み込み（開発・チューニング用）  
**認証**: Firebase Required  
**リクエスト**: なし  
**レスポンス**:
```json
{
  "message": "設定ファイルを再読み込みしました",
  "data": {
    "configPath": "/path/to/config.yaml",
    "reloadedAt": "2025-08-10T10:30:00Z"
  }
}
```

---

## 7. スケジュール関連エンドポイント

### POST /schedules
**用途**: 送信スケジュール作成  
**認証**: Firebase Required  
**リクエストボディ**:
```json
{
  "messageId": "ObjectId",
  "scheduledAt": "2025-08-11T09:00:00Z",
  "timezone": "Asia/Tokyo",
  "notes": "スケジュールメモ（任意）"
}
```

### GET /schedules
**用途**: スケジュール一覧取得  
**認証**: Firebase Required  
**クエリパラメータ**:
- `page` (int, optional) - ページ番号 (default: 1)
- `limit` (int, optional) - 1ページあたりの件数 (default: 20)
- `status` (string, optional) - ステータスフィルタ (pending|processed|failed)

### PUT /schedules/:id
**用途**: スケジュール更新  
**認証**: Firebase Required  
**パラメータ**: `id` - スケジュールID  

### DELETE /schedules/:id
**用途**: スケジュール削除  
**認証**: Firebase Required  
**パラメータ**: `id` - スケジュールID  

### POST /schedule/suggest
**用途**: AI時間提案（メッセージ内容を分析して最適な送信時間を提案）  
**認証**: Firebase Required  
**リクエストボディ**:
```json
{
  "messageId": "ObjectId",
  "messageText": "分析対象のメッセージテキスト",
  "selectedTone": "gentle"
}
```
**レスポンス**:
```json
{
  "message": "AI時間提案が完了しました",
  "data": {
    "suggestions": [
      {
        "time": "今すぐ",
        "delay_minutes": 0,
        "reason": "緊急性の高い内容のため即座の送信を推奨"
      },
      {
        "time": "明日の朝9時",
        "delay_minutes": "next_business_day_9:00am", 
        "reason": "ビジネス関連の内容のため営業時間開始時の送信を推奨"
      },
      {
        "time": "1時間後",
        "delay_minutes": 60,
        "reason": "相手に考える時間を与えつつ適度なタイミングでの送信"
      }
    ],
    "analysis": {
      "urgency": "medium",
      "category": "business",
      "tone": "gentle"
    },
    "processingTime": "6.5s"
  }
}
```

### POST /schedules/sync-status
**用途**: スケジュールとメッセージのステータス同期  
**認証**: Firebase Required  

---

## 8. 友達申請関連エンドポイント

### POST /friend-requests/send
**用途**: 友達申請送信  
**認証**: Firebase Required  
**リクエストボディ**:
```json
{
  "to_email": "friend@example.com",
  "message": "申請メッセージ（任意）"
}
```

### GET /friend-requests/received
**用途**: 受信した友達申請一覧  
**認証**: Firebase Required  

### GET /friend-requests/sent  
**用途**: 送信した友達申請一覧  
**認証**: Firebase Required  

### POST /friend-requests/:id/accept
**用途**: 友達申請承諾  
**認証**: Firebase Required  
**パラメータ**: `id` - 申請ID  

### POST /friend-requests/:id/reject
**用途**: 友達申請拒否  
**認証**: Firebase Required  
**パラメータ**: `id` - 申請ID  

### POST /friend-requests/:id/cancel
**用途**: 友達申請キャンセル（送信者が自分の申請をキャンセル）  
**認証**: Firebase Required  
**パラメータ**: `id` - 申請ID  

### GET /friends
**用途**: 友達一覧取得  
**認証**: Firebase Required  

### DELETE /friends/remove
**用途**: 友達削除  
**認証**: Firebase Required  
**リクエストボディ**:
```json
{
  "friend_email": "friend@example.com"
}
```

---

## 9. 設定関連エンドポイント

### GET /settings
**用途**: ユーザー設定取得  
**認証**: Firebase Required  
**レスポンス**:
```json
{
  "success": true,
  "data": {
    "user": {
      "id": "ObjectId",
      "name": "ユーザー名",
      "email": "user@example.com"
    },
    "notifications": {
      "emailNotifications": true,
      "sendNotifications": true,
      "browserNotifications": false
    },
    "messages": {
      "defaultTone": "gentle",
      "timeRestriction": "business_hours"
    }
  }
}
```

### PUT /settings/profile
**用途**: プロフィール更新  
**認証**: Firebase Required  
**リクエストボディ**:
```json
{
  "name": "新しいユーザー名"
}
```

### PUT /settings/password
**用途**: パスワード変更（廃止予定 - Firebase認証に統合済み）  
**認証**: Firebase Required  

### PUT /settings/notifications
**用途**: 通知設定更新  
**認証**: Firebase Required  
**リクエストボディ**:
```json
{
  "emailNotifications": true,
  "sendNotifications": false,
  "browserNotifications": true
}
```

### PUT /settings/messages  
**用途**: メッセージ設定更新  
**認証**: Firebase Required  
**リクエストボディ**:
```json
{
  "defaultTone": "constructive",
  "timeRestriction": "anytime"
}
```

### DELETE /settings/account
**用途**: アカウント削除  
**認証**: Firebase Required  

---

## 10. 旧下書きエンドポイント（廃止予定）

以下のエンドポイントは `/messages/*` に統合されており、廃止予定です:

- `POST /drafts`
- `GET /drafts/:id`  
- `PUT /drafts/:id`
- `DELETE /drafts/:id`
- `POST /drafts/:id/transform`

---

## システム用エンドポイント

### GET /health
**用途**: システムヘルスチェック  
**認証**: 不要  
**レスポンス**:
```json
{
  "status": "ok",
  "message": "Health check completed", 
  "timestamp": "2025-08-10T10:30:00Z",
  "port": "8080",
  "components": {
    "server": {
      "status": "ok",
      "uptime": "2h30m15s"
    },
    "database": {
      "status": "ok", 
      "type": "MongoDB Atlas"
    }
  }
}
```

### GET /api/status  
**用途**: API動作状況確認  
**認証**: 不要  
**レスポンス**:
```json
{
  "status": "running",
  "service": "yanwari-message-backend",
  "environment": "debug"
}
```

---

## データモデル

### Message（メッセージ）
```typescript
interface Message {
  id: string;
  senderId: string;
  recipientId: string;
  recipientEmail: string;
  originalText: string;      // 元のメッセージ
  finalText?: string;        // 最終送信テキスト（トーン変換後）
  reason?: string;          // 送信理由
  selectedTone?: string;    // 選択されたトーン
  status: 'draft' | 'scheduled' | 'sent' | 'delivered' | 'read';
  createdAt: string;
  sentAt?: string;
  deliveredAt?: string;
  readAt?: string;
}
```

### MessageRating（メッセージ評価）
```typescript  
interface MessageRating {
  id: string;
  messageId: string;
  recipientId: string;      // 評価者（受信者）
  rating: number;          // 1-5の評価
  createdAt: string;
  updatedAt: string;
}
```

### Schedule（スケジュール）
```typescript
interface Schedule {
  id: string;
  messageId: string;
  userId: string;
  scheduledAt: string;
  timezone: string;
  status: 'pending' | 'processed' | 'failed';
  notes?: string;
  createdAt: string;
  updatedAt: string;
}
```

### FriendRequest（友達申請）  
```typescript
interface FriendRequest {
  id: string;
  fromUserId: string;
  toUserId: string;
  status: 'pending' | 'accepted' | 'rejected' | 'canceled';
  message?: string;
  createdAt: string;
  updatedAt: string;
}
```

### Friendship（友達関係）
```typescript
interface Friendship {
  id: string;
  user1Id: string;         // 小さいID
  user2Id: string;         // 大きいID（正規化）
  createdAt: string;
}
```

---

## 開発・デバッグ情報

### 環境設定
- **開発環境**: `http://localhost:8080`
- **データベース**: MongoDB Atlas
- **認証**: Firebase Authentication
- **CORS**: 開発時は `*` 許可、本番では適切なオリジン制限

### ログ出力
開発モードでは詳細なログが出力されます:
- API リクエスト/レスポンス
- データベース操作
- Firebase認証
- エラー詳細

### パフォーマンス目安
- 通常のCRUD操作: 50-100ms
- AI トーン変換: 2-3秒
- AI 時間提案: 5-7秒
- データベース接続: 10-20ms

---

**最終更新**: 2025年8月10日  
**作成者**: Claude Code Assistant  
**バージョン**: v1.0