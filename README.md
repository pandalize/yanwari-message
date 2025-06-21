# やんわり伝言サービス

AI を使って気まずい用件を優しく伝えるサービスです。上司⇔部下・恋人など「気まずい用件」を AI で優しく変換し、デリケートなコミュニケーションを支援します。

## 🚀 機能

### 現在利用可能
- ✅ **ユーザー認証** - セキュアなメール・パスワード認証（JWT + Argon2）
- ✅ **API サーバー** - Go + Gin による高性能バックエンド

### 開発予定
- 🔄 **メッセージ下書き作成** - AI によるトーン変換（gentle/constructive/casual）
- 🔄 **送信スケジュール設定** - 指定時刻での自動送信
- 🔄 **履歴管理** - 送信履歴の一覧・検索機能

## 🛠 技術スタック

- **フロントエンド**: Vue 3 + TypeScript + Vite + Pinia
- **バックエンド**: Go 1.24+ + Gin + JWT認証
- **データベース**: MongoDB Atlas
- **AI連携**: Anthropic Claude API
- **認証**: Argon2 パスワードハッシュ化 + JWT

## 📦 セットアップ

### 必要な環境
- Go 1.23.0+
- Node.js 18.0+
- MongoDB Atlas アカウント
- Anthropic API キー

### インストール手順

1. **リポジトリのクローン**
```bash
git clone <repository-url>
cd yanwari-message
```

2. **依存関係のインストール**
```bash
npm run install:all
```

3. **環境変数の設定**
```bash
npm run setup:env
```

その後、`backend/.env` ファイルを編集して実際の値を設定：
```env
PORT=8080
MONGODB_URI=mongodb+srv://username:password@cluster.mongodb.net/yanwari-message
ANTHROPIC_API_KEY=your_anthropic_api_key_here  
JWT_SECRET=your_jwt_secret_here
```

## 🚦 使用方法

### 開発サーバーの起動

**すべて同時起動（推奨）:**
```bash
npm run dev
```

**個別起動:**
```bash
# バックエンドのみ（Go サーバー）
npm run dev:backend    # http://localhost:8080

# フロントエンドのみ（Vue 開発サーバー）
npm run dev:frontend   # http://localhost:5173
```

### APIテスト

認証システムの動作確認：
```bash
# サーバー動作確認
curl -X GET http://localhost:8080/health

# ユーザー登録
curl -X POST http://localhost:8080/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"newuser@example.com","password":"password123"}'
```

詳細なAPIテストコマンドは `API_TEST_COMMANDS.md` を参照してください。

## 🧪 テスト

```bash
# すべてのテストを実行
npm run test

# フロントエンドテストのみ
npm run test:frontend

# バックエンドテストのみ
npm run test:backend

# E2Eテスト
npm run test:e2e
```

## 🔧 開発用コマンド

```bash
# コード品質チェック
npm run lint

# コードフォーマット
npm run format

# プロダクションビルド
npm run build

# 依存関係のクリーンアップ
npm run clean
```

## 📁 プロジェクト構成

```
yanwari-message/
├── backend/              # Go + Gin APIサーバー
│   ├── main.go          # サーバーエントリーポイント
│   └── handlers/        # API ハンドラー
├── frontend/            # Vue 3 + TypeScript
│   ├── src/
│   │   ├── components/  # Vue コンポーネント
│   │   ├── stores/      # Pinia 状態管理
│   │   └── router/      # Vue Router 設定
│   └── package.json
├── API_TEST_COMMANDS.md # APIテスト用コマンド集
├── CLAUDE.md           # AI開発アシスタント用ガイド
└── package.json        # プロジェクト管理用スクリプト
```

## 🔐 セキュリティ

- Argon2 による暗号学的に安全なパスワードハッシュ化
- JWT トークン（アクセス15分、リフレッシュ14日）
- CORS 適切な設定
- OWASP Top 10 準拠を目指した実装

## 🤝 開発に参加する

### ブランチ戦略
- `main` - 本番環境用
- `develop` - 開発統合用  
- `feature/*` - 機能開発用

### 開発フロー
1. feature ブランチで開発
2. Pull Request 作成
3. コードレビュー
4. develop ブランチにマージ

詳細な開発ガイドラインは `CLAUDE.md` を参照してください。

## 📄 ライセンス

MIT License

## 🆘 サポート

問題が発生した場合：
1. `API_TEST_COMMANDS.md` でAPIの動作確認
2. Issues ページで既知の問題を確認
3. 新しい Issue を作成

---

**Status**: 🚧 開発中 - F-01 認証システム完了、F-02+ 実装予定