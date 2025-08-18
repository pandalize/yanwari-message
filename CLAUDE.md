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

- **バックエンド**: Go 1.23+ + Gin + JWT認証 + MongoDB
- **フロントエンド**: Vue 3 + TypeScript + Vite + Pinia + Nginx + JWT認証
- **モバイル**: Flutter (iOS/Android)
- **AI**: Anthropic Claude API
- **インフラ**: Docker + Docker Compose（完全コンテナ化）

## 🚀 開発環境セットアップ

### 必要な環境
- Docker & Docker Compose
- Git
- エディタ（VS Code推奨）

### 初回セットアップ
```bash
# 1. リポジトリをクローン
git clone <repository-url>
cd yanwari-message

# 2. 環境変数を設定
cp .env.example .env
# .env ファイルを編集してANTHROPIC_API_KEYを設定

# 3. 全サービスを起動（初回は自動ビルド）
npm run dev

# または
docker-compose up --build
```

### 🎯 基本コマンド

#### 🔥 開発コマンド（推奨）
```bash
# 全サービス起動（フォアグラウンド）
npm run dev

# 全サービス起動（バックグラウンド）
npm run dev:detached

# サービス停止
npm run stop

# ログ確認
npm run logs                # 全サービス
npm run logs:backend        # バックエンドのみ
npm run logs:frontend       # フロントエンドのみ
npm run logs:db            # データベースのみ

# サービス再起動
npm run restart
```

#### 🔧 ビルド・テスト
```bash
# イメージビルド
npm run build

# キャッシュなしビルド
npm run build:no-cache

# テスト実行
npm run test                # 全テスト
npm run test:backend        # バックエンドテスト
npm run test:frontend       # フロントエンドテスト

# コード品質チェック
npm run lint                # 全体
npm run lint:backend        # バックエンド
npm run lint:frontend       # フロントエンド
```

#### 🗄️ データベース管理
```bash
# MongoDB管理UI起動
npm run db:admin
# → http://localhost:8081 でアクセス（admin/admin123）

# MongoDBのみ起動
npm run db:start

# データベースバックアップ
npm run db:backup

# データベースリストア
npm run db:restore
```

#### 🗃️ サンプルデータ管理
```bash
# 開発用テストデータの管理
npm run db:seed         # 全サンプルデータを投入
npm run db:clean        # 全データをクリア
npm run db:reset        # クリア後、再投入
npm run db:status       # データベースの状況確認

# 個別データ操作
npm run db:seed:users   # ユーザーデータのみ投入
```

**📋 テストユーザー情報**（パスワード: `password123`）:
- 👩 田中 あかり（デザイナー） - `alice@yanwari-message.com`
- 👨 佐藤 ひろし（エンジニア） - `bob@yanwari-message.com`  
- 👩 鈴木 みゆき（PM） - `charlie@yanwari-message.com`

> 詳細なテストアカウント情報: [docs/TEST_ACCOUNTS.md](docs/TEST_ACCOUNTS.md)

### 📍 開発環境アクセスURL

| サービス | URL | 説明 |
|---------|-----|------|
| **フロントエンド** | http://localhost | メインアプリケーション |
| **バックエンドAPI** | http://localhost:8080 | REST API |
| **MongoDB管理** | http://localhost:8081 | mongo-express (admin/admin123) |

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

## 🛠️ 開発ガイドライン

1. **日本語コメント必須** - コードとコミットメッセージ
2. **JWT認証**: 全APIで認証必須（/auth エンドポイント除く）
3. **品質チェック**: 実装後は `npm run lint` と `npm run test` を実行
4. **Dockerファースト**: 開発は必ずコンテナ環境を使用
5. **⚠️ Claude Codeの制限**:
   - **開発サーバー起動は禁止**: ユーザーが手動で `npm run dev` を実行
   - 起動方法の説明とデバッグのみ対応

## 📊 完了済み機能

- ✅ JWT認証システム（バックエンド・フロントエンド完全移行、Firebase廃止済み）
- ✅ メッセージ作成・AIトーン変換  
- ✅ スケジュール・時間提案機能
- ✅ 友達申請システム
- ✅ メッセージ評価システム
- ✅ Flutter iOSアプリ
- ✅ 完全コンテナ化（Docker Compose）
- ✅ サンプルデータ管理システム

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