# やんわり伝言サービス - 開発環境セットアップガイド

## 概要

このドキュメントは、やんわり伝言サービスの開発環境を新しい開発者が簡単にセットアップできるよう作成されています。

## プロジェクト構成

```
yanwari-message/
├── backend/          # Go + Gin APIサーバー
├── frontend/         # Vue 3 + Vite フロントエンド
├── SETUP.md         # このファイル
├── README.md        # プロジェクト要件定義書
└── package.json     # 開発用スクリプト
```

## 必要な環境

### 必須ツール

| ツール | バージョン | 用途 |
|--------|-----------|------|
| **Go** | 1.23.0+ | バックエンドAPI開発 |
| **Node.js** | 18.0+ | フロントエンド開発・ビルド |
| **npm** | 9.0+ | パッケージ管理 |
| **Git** | 2.30+ | バージョン管理 |

### 推奨ツール

- **VS Code** + Go拡張機能
- **MongoDB Compass** (データベース管理)
- **Postman** または **Thunder Client** (API テスト)

## セットアップ手順

### 1. リポジトリのクローン

```bash
git clone <repository-url>
cd yanwari-message
```

### 2. 環境変数の設定

バックエンドの環境変数ファイルを作成：

```bash
cp backend/.env.example backend/.env
```

`backend/.env` ファイルを編集して、以下の値を設定：

```env
# サーバーポート設定
PORT=8080

# MongoDB接続URI (MongoDB Atlasまたはローカル)
MONGODB_URI=mongodb+srv://username:password@cluster.mongodb.net/yanwari-message?retryWrites=true&w=majority

# Anthropic API キー (実際のキーに置き換え)
ANTHROPIC_API_KEY=your_anthropic_api_key_here

# JWT秘密鍵 (本番環境では強力なランダム文字列を使用)
JWT_SECRET=your_jwt_secret_here
```

### 3. 依存関係のインストール

#### バックエンド (Go)

```bash
cd backend
go mod download
go mod tidy
```

#### フロントエンド (Node.js)

```bash
cd frontend
npm install
```

### 4. 開発サーバーの起動

#### 方法1: 個別起動

**バックエンド:**
```bash
cd backend
go run main.go
```
サーバーは `http://localhost:8080` で起動します。

**フロントエンド:**
```bash
cd frontend
npm run dev
```
開発サーバーは `http://localhost:5173` で起動します。

#### 方法2: 一括起動 (推奨)

プロジェクトルートから：
```bash
npm run dev
```

## 開発用スクリプト

プロジェクトルートの `package.json` で定義されている便利なスクリプト：

| コマンド | 説明 |
|----------|------|
| `npm run dev` | フロントエンド・バックエンドを同時起動 |
| `npm run build` | フロントエンドをビルド |
| `npm run test` | 全テストを実行 |
| `npm run lint` | コードの静的解析 |
| `npm run format` | コードフォーマット |

## API エンドポイント

開発環境でのAPIベースURL: `http://localhost:8080/api/v1`

主要エンドポイント：
- `POST /api/v1/auth/login` - ユーザーログイン
- `POST /api/v1/drafts` - 下書き作成
- `GET /api/v1/drafts/:id` - 下書き取得
- `POST /api/v1/schedules` - 送信スケジュール設定

## データベース設定

### MongoDB Atlas (推奨)

1. [MongoDB Atlas](https://www.mongodb.com/atlas) でアカウント作成
2. 新しいクラスターを作成 (M0 Sandbox - 無料)
3. データベースユーザーを作成
4. ネットワークアクセスを設定 (開発時は `0.0.0.0/0` を許可)
5. 接続文字列を `backend/.env` の `MONGODB_URI` に設定

### ローカルMongoDB (オプション)

```bash
# macOS (Homebrew)
brew install mongodb-community
brew services start mongodb-community

# 接続URI
MONGODB_URI=mongodb://localhost:27017/yanwari-message
```

## 外部サービス設定

### Anthropic API

1. [Anthropic Console](https://console.anthropic.com/) でアカウント作成
2. APIキーを生成
3. `backend/.env` の `ANTHROPIC_API_KEY` に設定

## トラブルシューティング

### よくある問題

**1. ポートが既に使用されている**
```bash
# ポート8080を使用しているプロセスを確認
lsof -i :8080
# プロセスを終了
kill -9 <PID>
```

**2. Go モジュールの依存関係エラー**
```bash
cd backend
go clean -modcache
go mod download
```

**3. Node.js パッケージのインストールエラー**
```bash
cd frontend
rm -rf node_modules package-lock.json
npm install
```

**4. MongoDB接続エラー**
- 接続文字列の確認
- ネットワークアクセス設定の確認
- データベースユーザーの認証情報確認

### ログの確認

**バックエンドログ:**
- コンソール出力を確認
- エラーメッセージに注意

**フロントエンドログ:**
- ブラウザの開発者ツール > Console
- ネットワークタブでAPI通信を確認

## 開発ワークフロー

### ブランチ戦略

- `main`: 本番環境用
- `develop`: 開発統合用
- `feature/*`: 機能開発用

### コミット前チェック

```bash
# コードフォーマット
npm run format

# リント実行
npm run lint

# テスト実行
npm run test
```

## 参考リンク

- [Go公式ドキュメント](https://golang.org/doc/)
- [Gin Webフレームワーク](https://gin-gonic.com/)
- [Vue 3公式ガイド](https://vuejs.org/guide/)
- [Vite公式ドキュメント](https://vitejs.dev/)
- [MongoDB Atlas ドキュメント](https://docs.atlas.mongodb.com/)
- [Anthropic API ドキュメント](https://docs.anthropic.com/)

## サポート

問題が発生した場合は、以下を確認してください：

1. このセットアップガイドの手順を再確認
2. 環境変数の設定を確認
3. 依存関係のバージョンを確認
4. チームメンバーに相談

---

**最終更新:** 2025年6月15日