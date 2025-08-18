# やんわり伝言プロジェクト - JWT認証移行後の概要

## プロジェクト目的
AI を使って気まずい用件を優しく伝えるサービス。ユーザーが直接的なメッセージを入力すると、Anthropic Claude APIを使って3種類のトーン（優しめ、建設的、カジュアル）に変換し、送信者が最適なトーンを選択できる。

## 主要フロー
1. 送信者がメッセージを入力
2. AIが3つのトーン（優しめ、建設的、カジュアル）に並行変換
3. 送信者がベストなトーンを選択
4. 配信時間を設定（今すぐ/1時間後/明日朝/カスタム）
5. 受信者に指定時間に配信

## 技術スタック（2025年8月現在）
- **バックエンド**: Go 1.23+ + Gin + JWT認証 + MongoDB Local/Atlas
- **フロントエンド**: Vue 3 + TypeScript + Vite + Pinia
- **モバイル**: Flutter (iOS/Android対応)
- **AI連携**: Anthropic Claude API
- **認証**: JWT (Firebase認証から移行完了)
- **データベース**: MongoDB (ローカル開発はDocker、本番はAtlas)

## 認証システム移行
- **🔄 Firebase → JWT移行完了**: 2025年8月18日
- **新認証エンドポイント**:
  - `POST /api/v1/auth/register` - ユーザー登録
  - `POST /api/v1/auth/login` - ログイン
  - `POST /api/v1/auth/refresh` - トークン更新
  - `POST /api/v1/auth/logout` - ログアウト
- **セキュリティ**: Argon2パスワードハッシュ + HMAC-SHA256 JWT署名

## 開発環境セットアップ
### 基本起動方法
```bash
# MongoDB起動（Docker）
npm run mongodb:start

# バックエンドサーバー起動
npm run dev:backend

# フロントエンド起動
npm run dev:frontend

# 全環境同時起動
npm run dev
```

### 環境変数設定（.env）
```bash
# MongoDB
MONGODB_URI=mongodb://localhost:27017/
MONGODB_DATABASE=yanwari-message

# JWT認証
JWT_SECRET_KEY=your-super-secret-jwt-key-change-this-in-production-minimum-32-characters
JWT_REFRESH_SECRET_KEY=your-super-secret-refresh-key-change-this-in-production-minimum-32-characters

# AI API
ANTHROPIC_API_KEY=sk-ant-api03-...

# CORS
ALLOWED_ORIGINS=http://localhost:5173,http://localhost:3000
```

## ブランチ戦略
- **main** - 本番環境（プロダクション）
- **develop** - 統合開発ブランチ（Web・Mobile・API全て）
- **feature/shared-[機能名]** - 共通機能（バックエンドAPI・DB・認証等）
- **feature/web-[機能名]** - Web版専用機能（Vue.js）
- **feature/mobile-[機能名]** - モバイル版専用機能（Flutter）

## 完了済み機能
- ✅ JWT認証システム（Firebase認証から移行完了）
- ✅ メッセージ作成・下書き機能
- ✅ AIトーン変換機能（3種並行変換）
- ✅ スケジュール機能（AI時間提案含む）
- ✅ 設定画面機能
- ✅ 友達申請システム
- ✅ メッセージ評価システム
- ✅ Flutter iOSアプリ受信トレイ機能
- ✅ ローカル開発環境（Docker MongoDB）

## アクセスURL（開発環境）
- **Frontend**: http://localhost:5173
- **Backend API**: http://localhost:8080
- **Swagger/Health**: http://localhost:8080/health
- **MongoDB管理**: http://localhost:8081 (Mongo Express)

## 重要なファイル構成
- `backend/main.go` - メインサーバーエントリーポイント
- `backend/handlers/auth.go` - JWT認証ハンドラー
- `backend/middleware/jwt_auth.go` - JWT認証ミドルウェア
- `backend/utils/jwt.go` - JWT生成・検証ユーティリティ
- `backend/.env.example` - 環境変数テンプレート
- `jwt-auth-test.html` - JWT認証テスト用HTMLページ