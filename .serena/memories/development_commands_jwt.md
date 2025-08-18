# 開発コマンド・操作ガイド - JWT認証対応版

## 🚀 基本開発フロー

### 初回セットアップ
```bash
# 依存関係インストール
npm run install:all

# 環境変数設定
npm run setup:env
# 手動で .env ファイルを編集してJWT秘密鍵を設定

# MongoDB起動
npm run mongodb:start

# 開発サーバー起動
npm run dev:backend
```

### 日常開発コマンド
```bash
# 開発サーバー起動（推奨）
npm run dev:local          # MongoDB + Backend同時起動
npm run dev                # Frontend + Backend同時起動

# 個別起動
npm run dev:backend        # Go サーバー :8080
npm run dev:frontend       # Vue 開発サーバー :5173
npm run mongodb:start      # MongoDB Docker起動
npm run mongodb:admin      # MongoDB + Mongo Express起動

# 品質チェック・テスト
npm run test              # 全テスト実行
npm run lint              # 全コード品質チェック
npm run build             # プロダクションビルド
```

### MongoDB管理
```bash
# MongoDB起動・停止
npm run mongodb:start     # MongoDB Dockerコンテナ起動
npm run mongodb:stop      # MongoDB Dockerコンテナ停止
npm run mongodb:admin     # Mongo Express管理画面も起動

# 直接接続
mongosh mongodb://localhost:27017/yanwari-message
```

## 🔐 JWT認証テスト

### cURLによる認証テスト
```bash
# ユーザー登録
curl -X POST http://localhost:8080/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"name":"テストユーザー","email":"test@example.com","password":"password123"}'

# ログイン
curl -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123"}'

# 認証が必要なAPI呼び出し
curl -X GET http://localhost:8080/api/v1/users/me \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

### HTMLテストページ
```bash
# ブラウザで jwt-auth-test.html を開く
open jwt-auth-test.html
```

## 🏗️ ビルド・デプロイ

### バックエンドビルド
```bash
cd backend
go build -o bin/server main.go
./bin/server  # 実行
```

### フロントエンドビルド
```bash
cd frontend
npm run build
npm run preview  # ビルド結果プレビュー
```

## 🐛 デバッグ・トラブルシューティング

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

### ログ確認
```bash
# バックエンドログ（開発時）
npm run dev:backend

# MongoDBログ
docker logs yanwari-mongodb

# システム全体状況
npm run status  # カスタムステータス確認コマンド
```

## 📊 開発環境チェックリスト

### 起動前確認
- [ ] Docker Desktop起動済み
- [ ] `.env`ファイル設定済み
- [ ] MongoDB起動済み (`npm run mongodb:start`)
- [ ] Go 1.23+インストール済み
- [ ] Node.js 18+インストール済み

### 動作確認URL
- [ ] Backend Health: http://localhost:8080/health
- [ ] Frontend: http://localhost:5173
- [ ] MongoDB管理: http://localhost:8081
- [ ] API Status: http://localhost:8080/api/status

## 🔧 環境設定詳細

### 必須環境変数
```bash
# JWT認証（必須）
JWT_SECRET_KEY=minimum-32-characters-secret-key
JWT_REFRESH_SECRET_KEY=minimum-32-characters-refresh-key

# MongoDB（ローカル開発）
MONGODB_URI=mongodb://localhost:27017/
MONGODB_DATABASE=yanwari-message

# AI API（機能テスト用）
ANTHROPIC_API_KEY=sk-ant-api03-...

# サーバー設定
PORT=8080
GIN_MODE=debug

# CORS
ALLOWED_ORIGINS=http://localhost:5173,http://localhost:3000
```