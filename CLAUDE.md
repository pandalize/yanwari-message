# CLAUDE.md

このファイルは、Claude Code (claude.ai/code) がこのリポジトリで作業する際のガイダンスを提供します。

## プロジェクト概要

このファイルは、やんわり伝言サービスでの Claude Code との効率的な開発協働のためのガイドです。
プロジェクトの基本情報は `README.md` を参照してください。

## 技術スタック（開発者向け詳細）

- **バックエンド**: Go 1.24+ + Gin + JWT認証 (Argon2) + MongoDB Atlas
- **フロントエンド**: Vue 3 + TypeScript + Vite + Pinia
- **AI 連携**: Anthropic Claude API（トーン変換：gentle/constructive/casual）
- **認証**: JWT（アクセス15分/リフレッシュ14日）+ Argon2パスワードハッシュ

## Claude Code 運用ルール

### 必須ルール
1. **日本語コメント必須**: すべてのコメントは日本語で記述してください
2. **段階的思考**: 複雑な実装前は `/thinkharder` または `/think` を使用して段階的に考えてください
3. **コード品質**: 実装後は必ず `npm run lint` と `npm run test` を実行してください
4. **セキュリティ重視**: 認証・API キー・パスワード関連は慎重に扱ってください

### 推奨コマンド
```bash
# 深く考える必要がある場合
/thinkharder

# 段階的に考える場合  
/think

# ファイル構造を理解したい場合
/tree

# 特定機能の実装方針を相談したい場合
/plan
```

### コーディング規約
- **Go**: 関数・構造体・変数名は日本語コメント必須
- **Vue.js**: コンポーネント名は PascalCase、日本語コメント推奨
- **TypeScript**: 型定義には日本語での説明コメント
- **API エンドポイント**: RESTful 設計、エラーメッセージは日本語

## 開発コマンド

### セットアップとインストール
```bash
# すべての依存関係をインストール
npm run install:all

# 環境変数ファイルをセットアップ
npm run setup:env
# その後、backend/.env を実際の値で編集してください
```

### 開発
```bash
# フロントエンドとバックエンドを同時起動
npm run dev

# 個別起動
npm run dev:frontend  # Vue 開発サーバー :5173
npm run dev:backend   # Go サーバー :8080
```

### ビルド
```bash
# フロントエンドの本番ビルド
npm run build

# バックエンドのバイナリビルド
npm run build:backend
```

### テスト
```bash
# すべてのテストを実行
npm run test

# フロントエンドのテストのみ
npm run test:frontend  # Vitest ユニットテスト
npm run test:e2e      # Playwright E2E テスト

# バックエンドのテストのみ
npm run test:backend  # Go テスト
```

### コード品質チェック
```bash
# すべてのコードをリント
npm run lint

# フロントエンドコードのフォーマット
npm run format

# バックエンドのリント（lint に含まれる）
cd backend && go vet ./...
```

### クリーンアップ
```bash
# すべてのビルド成果物と依存関係をクリーン
npm run clean
```

## 現在の実装状況

**完了済み機能:**
- ✅ **F-01: JWT認証システム（MongoDB Atlas統合完全完了）**
  - Argon2 パスワードハッシュ化実装完了
  - JWT アクセストークン（15分）/ リフレッシュトークン（14日）
  - ユーザー登録・ログイン・トークンリフレッシュ・ログアウト機能
  - セキュリティ機能：定数時間比較、トークン検証、エラーハンドリング
  - **MongoDB Atlas 実データ保存・取得動作確認完了**
- ✅ **MongoDB Atlas 統合基盤完了**
  - database/connection.go: 接続管理・ヘルスチェック・プール設定
  - models/user.go: User モデル・UserService・CRUD操作・インデックス作成
  - 実際のデータベース接続・ユーザー作成・重複チェック動作確認済み
- ✅ **main.go システム強化完了**
  - ヘルスチェック強化（DB接続状況・サーバー稼働時間）
  - グレースフルシャットダウン実装（SIGINT/SIGTERM対応）
  - 環境変数読み込み・CORS設定改善・セキュリティヘッダー追加
- ✅ **環境設定・ドキュメント整備完了**
  - .env.example: 環境変数テンプレート作成
  - SETUP_GUIDE.md: セットアップ・トラブルシューティングガイド
  - API_TEST_COMMANDS.md: 手動テスト用curlコマンド集
- 基本的なプロジェクト構造と開発環境
- ローカル開発用の CORS 設定完了
- Go 1.24.4 インストール・依存関係解決完了

**進行中/予定:**
- F-02: AI トーン変換を伴う下書き作成機能 (ハンドラーはスタブ状態)
- F-03: 送信スケジュールシステム (ハンドラーはスタブ状態)
- F-04: 下書き/送信履歴と検索機能
- フロントエンド-バックエンド API 連携
- 認証システムのユニットテスト作成

## 主要なアーキテクチャパターン

### バックエンド構造
- `backend/main.go`: Gin ルーター と CORS セットアップを伴うサーバーエントリーポイント
- `backend/handlers/`: 機能ベースのハンドラー構成
  - `auth.go`: Argon2 を使った完全な JWT 認証 (532行)
  - `drafts.go`: 下書き管理 (F-02 用スタブ)
  - `schedules.go`: 送信スケジュール (F-03 用スタブ)

### フロントエンド構造
- TypeScript を使った Vue 3 コンポーネントベースアーキテクチャ
- `src/components/[feature]/` での機能別コンポーネント構成
- 状態管理用の Pinia (`src/stores/` 内)
- ナビゲーション用の Vue Router (`src/router/` で設定)

### 認証フロー
- ランダムソルトを使った Argon2 パスワードハッシュ化 (64MB メモリ、3回反復、2並列)
- 15分のアクセストークンと14日のリフレッシュトークンを使った JWT
- **MongoDB Atlas実データベース認証**: 実際のユーザー登録・ログイン・重複チェック

### API動作確認済みエンドポイント
```bash
# サーバー動作確認
GET /health                    # ✅ 正常動作確認済み
GET /api/status               # ✅ 正常動作確認済み

# 認証エンドポイント
POST /api/v1/auth/register    # ✅ Argon2ハッシュ化 + JWT発行確認済み
POST /api/v1/auth/login       # ✅ JWT認証成功確認済み
POST /api/v1/auth/refresh     # ✅ トークンリフレッシュ成功確認済み
POST /api/v1/auth/logout      # ✅ トークン検証 + ログアウト成功確認済み
```

### 動作確認詳細（2025年6月21日実施）
- **ユーザー登録**: 新規ユーザー作成、Argon2ハッシュ化、JWT発行成功
- **重複チェック**: 既存メールアドレスでの適切なエラーレスポンス確認
- **ログイン**: デモアカウントでのJWT認証成功
- **トークンリフレッシュ**: 新しいアクセストークン・リフレッシュトークン生成成功
- **ログアウト**: Authorizationヘッダー検証、ログアウト処理成功
- **エラーハンドリング**: 無効トークン、認証ヘッダー無しの適切な処理確認
- **サーバー状態**: `http://localhost:8080` で安定動作中
- **テストコマンド**: `API_TEST_COMMANDS.md` にcurlコマンド集を作成済み

## 環境設定

### バックエンド (.env)
```env
PORT=8080
MONGODB_URI=mongodb+srv://username:password@cluster.mongodb.net/yanwari-message
ANTHROPIC_API_KEY=your_anthropic_api_key_here  
JWT_SECRET=your_jwt_secret_here
```

### API ベース URL
- 開発環境: `http://localhost:8080/api/v1`
- フロントエンドオリジン用 CORS 設定: `http://localhost:5173`, `http://localhost:3000`

## 開発ワークフロー

### ブランチ戦略 (GitFlow)
- `main`: 本番デプロイ用
- `develop`: 統合ブランチ
- `feature/*`: 機能開発ブランチ

### 現在のブランチ: `feature/auth-system`
認証システムが完了し、統合テストの準備が整っています。

## 詳細なブランチ戦略

### 作成済みブランチ一覧

**メインブランチ:**
- `main` - 本番環境用（保護設定）
- `develop` - 開発統合用

**機能ブランチ:**
- `feature/auth-system` - F-01: 認証システム（BE Lead担当）★★★
- `feature/message-drafts` - F-02: 下書き・トーン変換（BE+FE協力）★★★
- `feature/schedule-system` - F-03: 送信スケジュール（BE Lead担当）★★★
- `feature/history-management` - F-04: 履歴管理（FE+BE協力）★★☆
- `feature/frontend-ui` - UI/UX基盤（FE Lead担当）★★★
- `feature/infrastructure` - インフラ・CI/CD（DevOps担当）★★☆

### よく使うGitコマンド

#### リモートブランチをローカルに持ってくる（チームメンバー向け）

```bash
# リモートの最新情報を取得
git fetch origin

# リモートにあるブランチ一覧を確認
git branch -r

# リモートブランチをローカルに作成して追跡設定
git checkout -b develop origin/develop
git checkout -b feature/auth-system origin/feature/auth-system
git checkout -b feature/message-drafts origin/feature/message-drafts
git checkout -b feature/schedule-system origin/feature/schedule-system
git checkout -b feature/history-management origin/feature/history-management
git checkout -b feature/frontend-ui origin/feature/frontend-ui
git checkout -b feature/infrastructure origin/feature/infrastructure

# 現在のローカルブランチ確認
git branch
```

#### 日常的な開発作業

```bash
# ブランチ切り替え
git checkout feature/auth-system
git checkout develop

# 最新の変更を取得
git fetch origin
git checkout develop
git pull origin develop

# 機能ブランチにdevelopの変更をマージ
git checkout feature/auth-system
git merge develop

# 変更をコミット・プッシュ
git add .
git commit -m "feat: 認証API実装"
git push origin feature/auth-system
```

#### 新しいリモートブランチが追加された場合

```bash
# リモートの最新情報を取得
git fetch origin

# 新しいリモートブランチをローカルに追跡
git checkout -b feature/new-feature origin/feature/new-feature
```

### プルリクエストフロー
1. 機能ブランチで開発完了
2. GitHubでPR作成（`feature/xxx` → `develop`）
3. コードレビュー実施
4. CI/CDテスト通過確認
5. `develop`にマージ
6. 統合テスト実施
7. `main`にマージしてリリース

### 重要な注意事項

⚠️ **重要**: 直接`main`ブランチにプッシュしないでください  
✅ **推奨**: 必ず`develop`経由でマージしてください  
🔄 **定期実行**: `develop`の変更を定期的に機能ブランチに取り込んでください

### コンフリクト解決

```bash
# developの最新を取得
git checkout develop
git pull origin develop

# 機能ブランチでマージ
git checkout feature/your-feature
git merge develop

# コンフリクト解決後
git add .
git commit -m "resolve: developとのコンフリクト解決"
```

### 間違ったブランチでの作業修正

```bash
# 変更を一時保存
git stash

# 正しいブランチに切り替え
git checkout feature/correct-branch

# 変更を復元
git stash pop
```

### 各機能ブランチの詳細

**feature/auth-system (F-01)**
- 担当: BE Lead、優先度: ★★★
- 実装内容: メール・パスワード認証、JWT発行・検証、Argon2ハッシュ化
- API: `/api/v1/auth/register`, `/api/v1/auth/login`, `/api/v1/auth/refresh`, `/api/v1/auth/logout`

**feature/message-drafts (F-02)**
- 担当: BE Lead + FE Lead協力、優先度: ★★★
- 実装内容: 下書き作成・編集、Anthropic API連携、トーン変換機能
- API: `/api/v1/drafts`, `/api/v1/drafts/:id`, `/api/v1/drafts/:id/transform`

**feature/schedule-system (F-03)**
- 担当: BE Lead、優先度: ★★★
- 実装内容: スケジュール設定、時間指定送信、タイムゾーン対応
- API: `/api/v1/schedules`, `/api/v1/schedules/:id`

**feature/history-management (F-04)**
- 担当: FE Lead + BE Lead協力、優先度: ★★☆
- 実装内容: 送信履歴一覧、検索・フィルタリング、ページネーション
- API: `/api/v1/history`, `/api/v1/history/search`

### ファイル構成によるコンフリクト回避戦略

**機能単位でのファイル分離原則:**
- 各機能（F-01, F-02, F-03...）につき、フロントエンドとバックエンドでそれぞれ専用ファイルを用意
- ファイル間の依存関係を最小化することで、並行開発時のコンフリクトを防止
- 複数人が同じファイルを編集するリスクを大幅に削減

**具体的なファイル分離例:**

```
バックエンド構成:
backend/handlers/
├── auth.go           # F-01: 認証機能専用
├── drafts.go         # F-02: 下書き機能専用  
├── schedules.go      # F-03: スケジュール機能専用
└── history.go        # F-04: 履歴機能専用

フロントエンド構成:
frontend/src/components/
├── auth/
│   └── LoginForm.vue     # F-01: 認証UI専用
├── drafts/
│   └── DraftEditor.vue   # F-02: 下書きUI専用
├── schedule/
│   └── ScheduleForm.vue  # F-03: スケジュールUI専用
└── history/
    └── HistoryList.vue   # F-04: 履歴UI専用
```

**この方針の利点:**
- ✅ **コンフリクト回避**: 異なる機能を担当する開発者が同じファイルを編集しない
- ✅ **責任の明確化**: 各ファイルの担当者と責任範囲が明確
- ✅ **レビューの効率化**: 機能単位でのコードレビューが可能
- ✅ **デバッグの容易性**: 問題発生時の原因特定が迅速
- ✅ **テストの独立性**: 機能ごとの単体テストが独立

### 並行開発の調整ポイント

1. **API設計の事前合意**: OpenAPI仕様書作成・共有
2. **データベーススキーマの共有**: MongoDB コレクション設計
3. **環境変数の管理**: `.env.example`の更新
4. **共通コンポーネントの調整**: UIライブラリ選定、型定義共有
5. **ファイル分離の徹底**: 機能ごとの専用ファイル作成でコンフリクト防止

## テスト戦略

### バックエンドテスト
- `go test ./...` を使った Go 標準テスト
- 認証ハンドラーのユニットテスト
- データベース操作の統合テスト (予定)

### フロントエンドテスト
- Vue コンポーネントの Vitest ユニットテスト
- エンドツーエンドの Playwright テスト
- Vue Test Utils を使ったコンポーネントテスト

## AI 連携ノート

### トーン変換
- Anthropic Claude API を使用 (ANTHROPIC_API_KEY 環境変数にキー設定)
- 3つのトーンプリセット: `gentle`, `constructive`, `casual`
- 要件からのプロンプトテンプレート: コミュニケーションコーチとしてのシステムロール

### API 連携状況
現在は `backend/handlers/drafts.go` でスタブ実装 - F-02 で実装が必要です。

## データベーススキーマ (予定)

### Users コレクション
- `_id`: ObjectId (PK)
- `email`: string (ユニーク)
- `passwordHash`: string (Argon2)
- `salt`: string
- `timezone`: string (デフォルト: "Asia/Tokyo")

### Drafts コレクション
- `_id`: ObjectId (PK)
- `userId`: ObjectId (users への FK)
- `originalText`: string
- `tonePreset`: enum ("gentle" | "constructive" | "casual")
- `transformedText`: string (AI 出力)
- `status`: enum ("pending" | "sent")

## セキュリティ考慮事項

- 暗号学的に安全なソルト生成を伴う Argon2 パスワードハッシュ化
- 短い有効期限の JWT トークン (アクセス15分、リフレッシュ14日)
- 開発用に適切に設定された CORS
- パスワード検証 (最低8文字)
- パスワード検証でのタイミング攻撃保護
- TODO: ログアウト機能用の JWT ブラックリスト実装

## APIテスト手順

### 手動テスト
詳細なAPIテストコマンドは `API_TEST_COMMANDS.md` を参照してください。

**主要テストコマンド:**
```bash
# サーバー動作確認
curl -X GET http://localhost:8080/health
curl -X GET http://localhost:8080/api/status

# 新規ユーザー登録テスト（MongoDB Atlas実保存）
curl -X POST http://localhost:8080/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"newuser@example.com","password":"password123"}'

# 登録済みユーザーログインテスト（実データベース認証）
curl -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test-user@example.com","password":"testpassword123"}'
```

### テストファイル構成
- `API_TEST_COMMANDS.md`: 全APIエンドポイントのcurlコマンド集
  - 基本動作確認（ヘルスチェック、ステータス）
  - 認証システムテスト（登録、ログイン、リフレッシュ、ログアウト）
  - エラーハンドリングテスト（無効トークン、バリデーションエラー）
  - 完全テストシーケンス
  - トラブルシューティング情報

## ドキュメント構成

### ファイル使い分け
- **README.md**: プロジェクトの公式文書（外部向け、新規参加者向け）
- **CLAUDE.md**: AI開発アシスタント専用ガイド（内部開発用）
- **API_TEST_COMMANDS.md**: 手動APIテスト用コマンド集
- **SETUP.md**: README.mdに統合済み（削除予定）

### 最新更新履歴
- 2025年6月21日: README.md を外部向け公式文書として全面リニューアル
- 2025年6月21日: CLAUDE.md を AI協働専用ガイドとして特化
- 2025年6月21日: API_TEST_COMMANDS.md 作成（手動テスト用）

## セッション管理

### 現在のセッション状況
- **開発者**: fujinoyuki
- **現在のブランチ**: feature/auth-system  
- **最終更新**: 2025年6月21日 13:30
- **セッション状態**: F-01認証システム完全実装・テスト完了

### 完了したタスク（本セッション）
- ✅ Go 1.24.4 のインストール
- ✅ main.go への認証ルート統合・システム強化
- ✅ **MongoDB Atlas 統合完全実装・動作確認**
  - database/connection.go: 接続管理・ヘルスチェック実装
  - models/user.go: User モデル・UserService・CRUD操作実装
  - handlers/auth.go: 実際のDB操作に変更（モックデータ削除）
  - 実データでのユーザー登録・ログイン・重複チェック動作確認完了
- ✅ main.go システム強化（ヘルスチェック・グレースフルシャットダウン・セキュリティ）
- ✅ 環境設定整備（.env.example, SETUP_GUIDE.md作成）
- ✅ F-01認証システム完全動作確認（登録・ログイン・リフレッシュ・ログアウト）
- ✅ API_TEST_COMMANDS.md 作成（手動テスト用コマンド集）
- ✅ README.md リニューアル（外部向け公式文書化）
- ✅ CLAUDE.md の AI協働特化への整理

### 次回セッションで取り組むべきタスク
**優先順位順:**

1. **F-02: 下書き・トーン変換機能実装**
   - 現状: backend/handlers/drafts.go はスタブ状態
   - 必要: Anthropic API 連携、プロンプトテンプレート実装
   - ブランチ: feature/message-drafts

2. **フロントエンド認証画面実装**
   - 現状: frontend/src/components/auth/LoginForm.vue は未実装
   - 必要: API連携、JWT保存、ルーティング

3. **認証システムのユニットテスト作成**
   - 対象: backend/handlers/auth.go の各関数
   - Go テスト実装

### 開発環境状態
- **サーバー**: `http://localhost:8080` で動作中
- **認証API**: 全エンドポイント動作確認済み
- **MongoDB Atlas**: 実接続・データ永続化確認済み
- **テストユーザー**: test-user@example.com で実際にDB登録済み

### 環境設定
- ✅ .env.example ファイル作成済み
- ✅ MongoDB Atlas URI 設定済み（実動作確認済み）
- ✅ JWT_SECRET 設定済み
- ✅ SETUP_GUIDE.md でセットアップ手順文書化済み

## メモリ

- プロジェクトファイル整理完了: README.md（公式）+ CLAUDE.md（AI用）+ API_TEST_COMMANDS.md（テスト用）
- **MongoDB Atlas 統合完全実装・動作確認完了**（fujinoyuki, 2025-06-21 17:10）
  - 実際のMongoDB AtlasにユーザーデータID `6856690091b5f3e54b80270d` で保存済み
  - 登録147ms/ログイン97ms/ヘルスチェック13msのパフォーマンス確認
- F-01認証システム完全実装・MongoDB統合完了（fujinoyuki, 2025-06-21）
- 次回優先: F-02 下書き・トーン変換機能実装（Anthropic API連携）