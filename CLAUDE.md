# CLAUDE.md

このファイルは、Claude Code (claude.ai/code) がこのリポジトリで作業する際のガイダンスを提供します。

## プロジェクト概要

やんわり伝言サービス - AIを使って気まずい用件を優しく伝えるサービス

### 基本フロー
1. ユーザーがメッセージ入力
2. AI が3つのトーン（優しめ、建設的、カジュアル）に変換
3. 最適なトーンを選択
4. AI がメッセージを分析して最適な送信時間を提案
5. 配信時間を決定して送信予約
6. 受信者に指定時間に配信

## 技術スタック

- **バックエンド**: Go 1.23+ + Gin + JWT認証 + MongoDB Local/Atlas
- **フロントエンド**: Vue 3 + TypeScript + Vite + Pinia
- **モバイル**: Flutter (iOS/Android)
- **AI**: Anthropic Claude API
- **認証**: JWT (Firebase認証から移行完了 - 2025年8月18日)
- **データベース**: MongoDB (ローカル開発はDocker、本番はAtlas)

## 開発コマンド

### 🚀 基本コマンド
```bash
# 初回セットアップ
npm run install:all      # 依存関係インストール
npm run setup:env        # 環境変数テンプレート作成

# 開発サーバー起動
npm run dev:local        # MongoDB + Backend同時起動（推奨）
npm run dev              # Frontend + Backend同時起動

# 個別起動
npm run dev:backend      # Go サーバー :8080
npm run dev:frontend     # Vue 開発サーバー :5173
npm run mongodb:start    # MongoDB Docker起動
npm run mongodb:admin    # MongoDB + Mongo Express起動
```

### 🔧 開発ツール
```bash
# API・テスト
npm run test            # テスト実行
npm run lint            # コード品質チェック
npm run build           # プロダクションビルド

# MongoDB管理
npm run mongodb:start   # MongoDB起動
npm run mongodb:stop    # MongoDB停止
npm run mongodb:admin   # Mongo Express管理画面付きで起動
```

### 📍 開発環境アクセスURL

- **Frontend**: http://localhost:5173
- **Backend API**: http://localhost:8080  
- **Health Check**: http://localhost:8080/health
- **MongoDB管理**: http://localhost:8081 (Mongo Express)

## JWT認証システム

### 🔐 認証エンドポイント
- `POST /api/v1/auth/register` - ユーザー登録
- `POST /api/v1/auth/login` - ログイン
- `POST /api/v1/auth/refresh` - トークン更新
- `POST /api/v1/auth/logout` - ログアウト

### 環境変数設定（.env）
```bash
# JWT認証（必須）
JWT_SECRET_KEY=your-super-secret-jwt-key-change-this-in-production-minimum-32-characters
JWT_REFRESH_SECRET_KEY=your-super-secret-refresh-key-change-this-in-production-minimum-32-characters

# MongoDB
MONGODB_URI=mongodb://localhost:27017/
MONGODB_DATABASE=yanwari-message

# AI API
ANTHROPIC_API_KEY=sk-ant-api03-...

# CORS
ALLOWED_ORIGINS=http://localhost:5173,http://localhost:3000
```

### JWT認証テスト
```bash
# cURL例：ユーザー登録
curl -X POST http://localhost:8080/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"name":"テストユーザー","email":"test@example.com","password":"password123"}'

# ブラウザテスト
open jwt-auth-test.html  # JWT認証テスト用HTMLページ
```

## ブランチ戦略

### メインブランチ
- **main** - 本番環境（プロダクション）
- **develop** - 統合開発ブランチ（Web・Mobile・API全て）

### 機能開発ブランチ
- **feature/shared-[機能名]** - 共通機能（バックエンドAPI・DB・認証等）
- **feature/web-[機能名]** - Web版専用機能（Vue.js）
- **feature/mobile-[機能名]** - モバイル版専用機能（Flutter）

### 開発フロー
```bash
# 機能開発例
git checkout develop
git pull origin develop
git checkout -b feature/shared-new-api    # 共通機能
git checkout -b feature/web-new-ui        # Web版機能
git checkout -b feature/mobile-new-screen # Mobile版機能

# 開発完了後
git push origin feature/xxx
# PR作成: feature/xxx → develop
# develop → main（リリース時）
```

## 運用ルール

1. **日本語コメント必須**
2. **JWT認証**: 全APIで認証必須
3. **品質チェック**: 実装後は `npm run lint` と `npm run test` を実行
4. **⚠️ 開発サーバー起動の重要ルール**:
   - **Claude Code は自動で開発サーバーを起動してはいけません**
   - 開発サーバー起動(`npm run dev`、`npm run dev:local`等)は必ずユーザーが手動で実行する
   - Claude と ユーザーが同時に起動するとポート競合やプロセス重複が発生する
   - Claude Code は起動方法の説明やデバッグのみ行い、実際の起動コマンド実行は避ける

## 完了済み機能

- ✅ JWT認証システム（Firebase認証から移行完了）
- ✅ メッセージ作成・AIトーン変換  
- ✅ スケジュール・時間提案機能
- ✅ 友達申請システム
- ✅ メッセージ評価システム
- ✅ Flutter iOSアプリ
- ✅ ローカル開発環境（Docker MongoDB）

## 重要なファイル構成

- `backend/main.go` - メインサーバーエントリーポイント
- `backend/handlers/auth.go` - JWT認証ハンドラー
- `backend/middleware/jwt_auth.go` - JWT認証ミドルウェア
- `backend/utils/jwt.go` - JWT生成・検証ユーティリティ
- `backend/.env.example` - 環境変数テンプレート
- `jwt-auth-test.html` - JWT認証テスト用HTMLページ

## トラブルシューティング

### よくある問題
1. **MongoDB接続エラー**
   ```bash
   npm run mongodb:start  # MongoDB起動確認
   docker ps | grep mongo  # コンテナ状況確認
   ```

2. **JWT認証エラー**
   - `.env`ファイルの`JWT_SECRET_KEY`設定確認
   - トークンの有効期限確認（15分）
   - ヘッダー形式確認: `Authorization: Bearer <token>`

3. **ポート競合**
   ```bash
   lsof -i :8080   # バックエンドポート確認
   lsof -i :5173   # フロントエンドポート確認
   lsof -i :27017  # MongoDBポート確認
   ```