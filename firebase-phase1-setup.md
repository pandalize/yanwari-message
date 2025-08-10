# Firebase Phase 1: Backend Integration セットアップガイド

## 実装完了状況

✅ **Firebase Admin SDK for Go インストール・設定完了**
✅ **Firebase サービス実装完了** (`backend/services/firebase_service.go`)
✅ **Firebase 認証ミドルウェア実装完了** (`backend/middleware/firebase_auth.go`)
✅ **User モデル Firebase UID 対応完了** (`backend/models/user.go`)
✅ **MongoDB ユーザー移行スクリプト完了** (`backend/migration/firebase_migration.go`)
✅ **Firebase 認証ハンドラー実装完了** (`backend/handlers/firebase_auth.go`)
✅ **main.go Firebase 統合完了**
✅ **環境変数設定テンプレート更新完了** (`.env.example`)

## 次に必要な作業

### 1. Firebase プロジェクト作成
```bash
# Firebase CLI のインストール
npm install -g firebase-tools

# Firebase ログイン
firebase login

# Firebase プロジェクト作成
firebase projects:create yanwari-message-prod

# Firebase プロジェクト初期化
firebase init auth
```

### 2. Firebase Admin SDK キー取得
1. [Firebase Console](https://console.firebase.google.com/) にアクセス
2. プロジェクト「yanwari-message-prod」を選択
3. 「プロジェクトの設定」→「サービス アカウント」
4. 「新しい秘密鍵の生成」をクリック
5. ダウンロードしたJSONファイルを `backend/config/firebase-admin-key.json` に配置

### 3. Web API キー取得
1. Firebase Console の「プロジェクトの設定」→「全般」
2. 「ウェブ API キー」をコピー

### 4. 実際の環境変数設定
```bash
cd backend
cp .env.example .env
```

`.env` ファイルを編集:
```env
# Firebase設定（Phase 1: Backend Integration）
FIREBASE_PROJECT_ID=yanwari-message-prod
FIREBASE_PRIVATE_KEY_PATH=./config/firebase-admin-key.json
FIREBASE_WEB_API_KEY=実際のWebAPIキー
FIREBASE_AUTH_DOMAIN=yanwari-message-prod.firebaseapp.com
```

### 5. Firebaseプロジェクト設定
Firebase Console で以下を設定:
- Authentication > Sign-in method > Email/Password を有効化
- Authentication > Settings > Authorized domains に `localhost:5173` を追加

### 6. 動作テスト
```bash
# サーバー起動
cd backend
go run main.go

# Firebase認証エンドポイント確認
curl -X GET http://localhost:8080/api/v1/firebase-auth/migration/status
```

## 実装済み API エンドポイント

### Firebase 認証（認証必要）
- `GET /api/v1/firebase-auth/profile` - プロフィール取得
- `POST /api/v1/firebase-auth/sync` - Firebase→MongoDB同期
- `POST /api/v1/firebase-auth/migration` - 移行実行（管理者用）
- `GET /api/v1/firebase-auth/migration/status` - 移行状況確認

### Firebase ユーティリティ（認証不要）
- `POST /api/v1/firebase-auth/utils/password-reset` - パスワードリセット
- `POST /api/v1/firebase-auth/utils/email-verification` - メール確認

## 技術実装詳細

### Dual Authentication System
- 既存のJWT認証システムと並行してFirebase認証を実装
- Firebase初期化エラー時はJWT認証のみで継続動作
- 段階的移行が可能な設計

### Firebase Service Features
- ID Token 検証
- ユーザー作成・取得・削除
- パスワードリセット・メール確認リンク生成
- エラーハンドリング・ログ出力

### Migration System
- MongoDB全ユーザーの一括Firebase移行
- API制限対策（10件毎に1秒待機）
- ロールバック機能（失敗時にFirebaseユーザー削除）
- 移行状況の検証・確認機能

### Security Features
- Firebase UID の一意性保証（MongoDB インデックス）
- スパースインデックス（Firebase UID 未設定ユーザー対応）
- 認証トークン検証・有効期限チェック

## Phase 2 予定
- フロントエンド Firebase SDK 統合
- Vue.js認証フロー Firebase 移行
- JWT → Firebase ID Token 切り替え

## Phase 3 予定
- Flutter モバイルアプリ Firebase 認証
- プッシュ通知・Cloud Messaging
- Firestore データベース移行検討