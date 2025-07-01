# CLAUDE.md

このファイルは、Claude Code (claude.ai/code) がこのリポジトリで作業する際のガイダンスを提供します。

## プロジェクト概要

このファイルは、やんわり伝言サービスでの Claude Code との効率的な開発協働のためのガイドです。
プロジェクトの基本情報は `README.md` を参照してください。

### **やんわり伝言アプリの詳細フロー**

#### ユーザー操作フロー
```
1. 送信者がメッセージを入力（例: 「明日の会議、準備できてないから延期してほしい」）
   ↓
2. 「変換」ボタンをクリック
   ↓  
3. バックエンドでAnthropic APIが複数トーン（優しめ、建設的、カジュアル）に並行変換
   ↓
4. 送信者に変換結果を表示（3つの選択肢として）
   ↓
5. 送信者がベストなトーンを選択
   ↓
6. 送信者が配信時間を設定（今すぐ / 1時間後 / 明日朝 / カスタム）
   ↓
7. 受信者に指定時間にやんわりメッセージが配信
```

#### 画面遷移イメージ
```
┌─────────────────────────────────┐
│ やんわり伝言 - メッセージ作成      │
├─────────────────────────────────┤
│ 送信先: user@example.com         │
│                                │
│ ┌─────────────────────────────┐ │
│ │ 明日の会議、準備できてない    │ │
│ │ から延期してほしい           │ │
│ └─────────────────────────────┘ │
│                                │
│ [🎭 トーン変換]                 │
└─────────────────────────────────┘

↓ 変換後

┌─────────────────────────────────┐
│ トーンを選択してください          │
├─────────────────────────────────┤
│ 💝 優しめトーン:                │
│ 「明日の会議についてですが、      │
│  もう少しお時間をいただけると    │
│  助かります😊」                 │
│                                │
│ 🏗️ 建設的トーン:               │
│ 「明日の会議の準備に追加時間が   │
│  必要です。延期をご検討いただけ  │
│  ますでしょうか？」             │
│                                │
│ 🎯 カジュアルトーン:            │
│ 「明日の会議なんですが、準備が   │
│  間に合わないので延期できますか？」│
│                                │
│ 📅 配信時間: [今すぐ ▼]         │
│   - 今すぐ                     │
│   - 1時間後                    │
│   - 明日の朝9時                 │
│   - カスタム設定               │
│                                │
│ [📨 送信]                      │
└─────────────────────────────────┘
```

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
- ✅ **F-01: JWT認証システム（バックエンド・フロントエンド完全統合完了）**
  - Argon2 パスワードハッシュ化実装完了
  - JWT アクセストークン（15分）/ リフレッシュトークン（14日）
  - ユーザー登録・ログイン・トークンリフレッシュ・ログアウト機能
  - セキュリティ機能：定数時間比較、トークン検証、エラーハンドリング
  - **MongoDB Atlas 実データ保存・取得動作確認完了**
  - **Vue.js認証フロントエンド完全実装・統合テスト完了**
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

- ✅ **Vue.js フロントエンド認証システム完全実装**
  - frontend/src/services/api.ts: axios APIサービス層・JWT自動リフレッシュ
  - frontend/src/stores/auth.ts: Pinia認証ストア・永続化・JWTトークン期限チェック
  - frontend/src/components/auth/: LoginForm・RegisterForm コンポーネント
  - frontend/src/views/: LoginView・RegisterView ページビュー  
  - frontend/src/router/: 認証ルーティング・ナビゲーションガード
  - App.vue: 認証状態対応ヘッダー・ログアウト機能
  - **フロントエンド・バックエンド完全統合動作確認済み**

- ✅ **F-04: メッセージ作成機能完全実装・統合完了**（fujinoyuki, 2025-06-22 09:30）
  - Backend: メッセージCRUD API完全実装（/api/v1/messages/*）
  - Backend: ユーザー検索API実装（/api/v1/users/search）
  - Frontend: MessageComposer.vue + RecipientSelector.vue実装
  - Frontend: リアルタイムユーザー検索（デバウンス300ms）
  - Frontend: 下書き保存・管理・一覧表示機能
  - Backend/Frontend完全統合・API連携動作確認済み
  - Navigation: ヘッダー・ホームページからアクセス可能
  - Test: curl API + ブラウザUI両方で動作確認完了

- ✅ **F-02: AIトーン変換機能完全実装・統合完了**（fujinoyuki, 2025-06-22 21:10）
  - Backend: Anthropic Claude API統合実装（/api/v1/transform/*）
  - Backend: 3トーン並行変換機能（gentle/constructive/casual）
  - Backend: YAML設定ファイル外部化・ライブリロード機能
  - Backend: チューニング専門者向けガイド・テスト手法確立
  - Frontend: ToneSelector.vue + ToneTransformView.vue実装
  - Frontend: メッセージ作成→トーン変換→選択フロー完成
  - **ボタンイベント・ルーティング問題解決完了**
    - MessageComposer.vue: updateDraft メソッド統一・エラーハンドリング改善
    - ToneTransformView.vue: API連携修正・必須パラメータ追加
    - ApiService: 公開メソッド追加（get/post/put/delete）
    - MessageService/TransformService: API連携統一
  - **Backend/Frontend完全統合・E2Eフロー動作確認済み**
  - Test: curl API + ブラウザUI完全動作確認完了

**進行中/予定:**
- F-03: 送信スケジュールシステム (ハンドラーはスタブ状態)
- 認証システムのユニットテスト作成

## 主要なアーキテクチャパターン

### コンポーネント化設計方針

#### 再利用可能な独立コンポーネント設計
- **機能別API分割**: 各機能は独立したAPIエンドポイント・データモデル・UIコンポーネントを持つ
- **他アプリでの再利用性**: 他のアプリケーションでの再利用を前提とした疎結合設計
- **最小依存関係**: 機能間の依存関係を最小限に抑制、プラグイン的な組み込み・取り外しが可能
- **Go並行処理最適化**: goroutine・channelを活用した高性能な非同期処理

#### API設計の独立性（再利用可能コンポーネント）
```bash
# 各機能が独立したAPIエンドポイントを持つ（他アプリでも再利用可能）
/api/v1/auth/*              # 認証システム（完了済み）
/api/v1/users/*             # ユーザー検索・連絡先管理
/api/v1/messages/*          # メッセージ作成・管理
/api/v1/transform/*         # AIトーン変換（3種並行処理）
/api/v1/schedules/*         # 配信スケジュール管理
/api/v1/notifications/*     # SSE通知・配信
/api/v1/dashboard           # BFF統合エンドポイント（必要時）
```

#### API設計戦略（機能別独立アプローチ）
- **初期**: 機能別独立API設計（再利用性・クリーンアーキテクチャ）
- **成長期**: 各機能APIの最適化・拡張
- **拡大期**: BFF/GraphQL追加（パフォーマンス最適化）

#### パフォーマンス最適化戦略（段階的導入）
- **MongoDB M0対応**: 適度な接続プール設定・クエリ最適化
- **goroutine並行処理**: 複数データソースへの同時アクセス（成長期以降）
- **channel活用**: SSE通知・リアルタイムデータストリーミング（必要時）
- **非同期バックグラウンド処理**: 重い処理（AI変換・メール送信）の分離（成長期以降）

#### データベース設計（やんわり伝言特化）
```javascript
// やんわり伝言アプリのコレクション設計
collections: {
  users: {
    _id: ObjectId,
    email: string,
    passwordHash: string,
    timezone: string
  },
  
  messages: {
    _id: ObjectId,
    senderId: ObjectId,           // 送信者
    recipientId: ObjectId,        // 受信者
    originalText: string,         // 元のメッセージ
    variations: {                 // AI変換結果
      gentle: string,             // 優しめトーン
      constructive: string,       // 建設的トーン
      casual: string              // カジュアルトーン
    },
    selectedTone: string,         // 送信者が選択したトーン
    finalText: string,            // 最終的に送信されるテキスト
    scheduledAt: Date,            // 配信予定時刻
    status: "draft|processing|scheduled|sent|delivered|read",
    createdAt: Date,
    sentAt: Date,
    readAt: Date
  },
  
  contacts: {
    _id: ObjectId,
    userId: ObjectId,            // 自分のID
    contactUserId: ObjectId,     // 連絡先のユーザーID
    nickname: string,            // 表示名
    lastMessageAt: Date,         // 最後のメッセージ時刻
    addedAt: Date
  }
}
```

### バックエンド構造
- `backend/main.go`: Gin ルーター と CORS セットアップを伴うサーバーエントリーポイント
- `backend/handlers/`: 機能ベースのハンドラー構成（並行処理最適化）
  - `auth.go`: Argon2 を使った完全な JWT 認証 (532行)
  - `users.go`: ユーザー検索・連絡先管理（並行検索処理）
  - `messages.go`: メッセージ送受信（非同期送信処理）
  - `notifications.go`: SSE通知（channel活用）
  - `schedules.go`: 送信スケジュール（バックグラウンド処理）
  - `transform.go`: AIトーン変換（並行AI API呼び出し）

### フロントエンド構造（コンポーネント化）
- TypeScript を使った Vue 3 コンポーネントベースアーキテクチャ
- **機能別独立コンポーネント設計**: 各機能が独立したコンポーネント・ストア・サービスを持つ

#### コンポーネント設計の独立性
```bash
frontend/src/
├── components/
│   ├── auth/           # 認証コンポーネント（完了済み）
│   ├── users/          # ユーザー検索・連絡先UI
│   ├── messages/       # メッセージ送受信UI
│   ├── notifications/  # 通知表示UI
│   ├── scheduling/     # スケジュール管理UI
│   └── transform/      # AIトーン変換UI
├── stores/
│   ├── auth.ts         # 認証ストア（完了済み）
│   ├── users.ts        # ユーザー検索・連絡先ストア
│   ├── messages.ts     # メッセージストア
│   ├── notifications.ts # 通知ストア（SSE管理）
│   ├── schedules.ts    # スケジュールストア
│   └── transform.ts    # AI変換ストア
└── services/
    ├── api.ts          # 共通APIサービス（完了済み）
    ├── userService.ts  # ユーザー検索API
    ├── messageService.ts # メッセージAPI
    ├── sseService.ts   # SSE通知API
    ├── scheduleService.ts # スケジュールAPI
    └── transformService.ts # AI変換API
```

#### フロントエンド最適化戦略
- **独立ストア管理**: 各機能のPiniaストアが独立動作
- **サービス層分離**: API呼び出しロジックの再利用可能性
- **コンポーネント疎結合**: 他アプリでの個別コンポーネント利用
- **型定義共有**: TypeScript型定義での安全性確保

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

**⚠️ 重要なテスト注意事項:**
- **JWTトークン**: 15分で期限切れのため、テスト時は必ず新しいトークンを取得
- **テスト用受信者アドレス**: `hnn-a@gmail.com` を使用（実際にDB登録済み）
- **テスト用送信者**: `test-user@example.com` / `testpassword123`

**主要テストコマンド:**
```bash
# 1. サーバー動作確認
curl -X GET http://localhost:8080/health
curl -X GET http://localhost:8080/api/status

# 2. 新しいJWTトークン取得（必須）
JWT_TOKEN=$(curl -s -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test-user@example.com","password":"testpassword123"}' \
  | python3 -c "import sys, json; print(json.load(sys.stdin)['data']['access_token'])")

# 3. メッセージ作成テスト（hnn-a@gmail.com宛）
curl -X POST http://localhost:8080/api/v1/messages/draft \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $JWT_TOKEN" \
  -d '{"originalText":"テストメッセージです","recipientEmail":"hnn-a@gmail.com"}'

# 4. トーン変換テスト
curl -X POST http://localhost:8080/api/v1/transform/tones \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $JWT_TOKEN" \
  -d '{"messageId":"[メッセージID]","originalText":"テストメッセージです"}'

# 5. スケジュール提案テスト
curl -X POST http://localhost:8080/api/v1/schedule/suggest \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $JWT_TOKEN" \
  -d '{"messageId":"[メッセージID]","messageText":"テストメッセージです","selectedTone":"gentle"}'
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
- **現在のブランチ**: feature/ai-tone-transform  
- **最終更新**: 2025年6月23日 05:35
- **セッション状態**: F-03スケジュール機能フロントエンド・バックエンド統合完了・一部問題あり

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
- ✅ **Vue.js認証フロントエンド完全実装・統合テスト完了**
  - frontend/src/services/api.ts: axios APIサービス・JWT自動リフレッシュ
  - frontend/src/stores/auth.ts: Pinia認証ストア・JWTトークン期限チェック・永続化
  - frontend/src/components/auth/: LoginForm・RegisterForm コンポーネント実装
  - frontend/src/views/: LoginView・RegisterView ページ実装
  - frontend/src/router/: 認証ルーティング・ナビゲーションガード実装
  - App.vue: 認証状態対応UI・ログアウト機能実装
  - **フロントエンド・バックエンド完全統合動作確認済み（リロード問題解決済み）**
- ✅ **F-03: スケジュール機能完全実装・テスト完了**（2025年6月23日 05:10）
  - backend/models/schedule.go: Schedule モデル・ScheduleService・CRUD操作完全実装
  - backend/handlers/schedules.go: スケジュールAPI完全実装（432行）
  - backend/config/schedule_prompts.yaml: AI分析用プロンプト設定
  - **Anthropic Claude API統合成功**: メッセージ分析による最適時間提案
  - **AI提案機能動作確認**: 謝罪・依頼メッセージの緊急度判定・時間提案
  - **CRUD API動作確認**: スケジュール作成・一覧・更新・削除全機能
  - **MongoDB統合**: スケジュールデータ永続化・インデックス作成完了
  - **受信者連携**: hnn-a@gmail.com での実際のメッセージ・スケジュール連携テスト成功

### 次回セッションで取り組むべきタスク
**優先順位順:**

1. **🚨 AI時間提案フロントエンド問題修正** - 優先度: 緊急
   - **問題**: AI時間提案がフロントエンドで応答が返らない（500エラー発生）
   - **再現状況**: curlでは正常動作・ブラウザでローディングが終わらない
   - **調査点**: 
     - frontend/src/components/schedule/ScheduleWizard.vue のloadAISuggestion関数
     - frontend/src/services/scheduleService.ts のgetSuggestion関数
     - エラーハンドリング・タイムアウト設定・レスポンス解析処理
   - **サーバーログ**: `[GIN] 2025/06/23 - 05:31:47 | 500 | 3.472543334s | POST "/api/v1/schedule/suggest"`

1.1. **🐛 UI/UX問題修正** - 優先度: 高
   - **カスタム時刻デフォルト**: 過去時間になる問題修正
   - **認証バイパス**: 未ログイン状態でのページアクセス制御強化
   - **修正ファイル**: ScheduleWizard.vue・router/index.ts・認証ガード

2. **バックグラウンド送信処理実装**
   - スケジュール実行エンジン開発
   - 定期実行・バックグラウンドプロセス
   - メール送信・通知連携
   - ブランチ: feature/schedule-execution

3. **認証システムのユニットテスト作成**
   - 対象: backend/handlers/auth.go の各関数
   - Go テスト実装

### 開発環境状態
- **バックエンドサーバー**: `http://localhost:8080` で動作中
- **フロントエンドサーバー**: `http://localhost:5173` で動作中（CORS設定済み）
- **認証API**: 全エンドポイント動作確認済み
- **スケジュールAPI**: バックエンド動作確認済み・フロントエンドAI提案で問題あり
- **MongoDB Atlas**: 実接続・データ永続化確認済み
- **フロントエンド認証**: Vue.js認証画面・API統合・リロード対応済み
- **テストユーザー**: test-user@example.com で実際にDB登録済み
- **受信者テストアカウント**: hnn-a@gmail.com で動作確認済み

### 🔧 技術的問題・トラブルシューティング情報

#### AI時間提案API問題（2025-06-23 05:35）
**問題**: フロントエンドからAI時間提案API呼び出し時に500エラーまたは応答なし
**サーバーログ例**: 
```
[GIN] 2025/06/23 - 05:31:47 | 500 | 3.472543334s | POST "/api/v1/schedule/suggest"
[GIN] 2025/06/23 - 05:31:53 | 200 | 6.519817833s | POST "/api/v1/schedule/suggest"
```

**正常パターン**: curlでのAPIテスト（6.5-6.8秒で成功）
**問題パターン**: フロントエンドブラウザで無限ローディング・500エラー

**調査済み項目**:
- ✅ CORS設定: localhost:5173 追加済み・正常動作
- ✅ JWT認証: 正常動作・トークンリフレッシュ正常
- ✅ バックエンドAPI: curl単体テストで正常動作
- ❌ フロントエンドAPI呼び出し: 断続的に失敗

**未調査項目**:
- フロントエンドAPIタイムアウト設定
- Anthropic API レート制限・接続制限
- フロントエンド→バックエンドAPI呼び出し時のリクエストヘッダー
- エラーレスポンス処理・JSON解析エラー

#### その他のフロントエンド問題（2025-06-23 05:35）

**🐛 カスタム時刻設定問題**:
- **問題**: カスタム時刻のデフォルト値が過去の時間になっている
- **場所**: frontend/src/components/schedule/ScheduleWizard.vue の onMounted()
- **修正要**: デフォルト時間を現在時刻の1時間後に設定するロジック確認

**🔒 認証バイパス問題**:
- **問題**: ログインしていなくてもメッセージ一覧が見れている可能性
- **場所**: Vue Router認証ガード・コンポーネントレベルの認証チェック
- **調査要**: 
  - frontend/src/router/index.ts の beforeEach 認証ガード
  - frontend/src/views/ の各ページコンポーネントでの認証状態確認
  - スケジュール一覧・メッセージ一覧への未認証アクセス可否

**🔧 修正対象ファイル**:
- frontend/src/components/schedule/ScheduleWizard.vue: カスタム時刻デフォルト修正
- frontend/src/router/index.ts: 認証ガード強化
- frontend/src/components/schedule/ScheduleList.vue: 認証状態チェック追加

### 環境設定
- ✅ .env.example ファイル作成済み
- ✅ MongoDB Atlas URI 設定済み（実動作確認済み）
- ✅ JWT_SECRET 設定済み
- ✅ SETUP_GUIDE.md でセットアップ手順文書化済み

## やんわり伝言アプリの実装設計

### **フロー別ブランチ設計**

#### **Core 実装ブランチ（必須機能）**
```bash
feature/message-compose         # 1. メッセージ作成・入力UI
feature/ai-tone-transform       # 2. Anthropic API複数トーン変換（並行処理）
feature/tone-selection         # 3. トーン選択UI・UX
feature/message-scheduling     # 4. 配信時間設定・スケジューラー
feature/message-delivery       # 5. 受信者への配信・通知
```

#### **Supporting 実装ブランチ（支援機能）**
```bash
feature/user-contacts          # ユーザー検索・連絡先管理
feature/inbox-history          # 受信トレイ・送信履歴UI
feature/sse-notifications      # リアルタイム通知（SSE）
```

#### **Integration ブランチ**
```bash
feature/message-system-integration  # 全機能統合・E2Eテスト
```

### **実装順序（UXフロー優先）**

#### **Phase 1: コアUXフロー実装**
```bash
Week 1: feature/message-compose        # メッセージ入力画面
Week 2: feature/ai-tone-transform      # AI変換バックエンド（3トーン並行処理）
Week 3: feature/tone-selection        # トーン選択画面
Week 4: feature/message-scheduling    # 配信時間設定
```

#### **Phase 2: 配信・通知システム**
```bash
Week 5: feature/message-delivery      # 配信システム・受信者通知
Week 6: feature/user-contacts         # ユーザー検索・連絡先
Week 7: feature/inbox-history         # 受信トレイ・履歴UI
```

#### **Phase 3: リアルタイム・統合**
```bash
Week 8: feature/sse-notifications     # SSEリアルタイム通知
Week 9: feature/message-system-integration  # 全機能統合
```

### **技術実装アプローチ（確定方針）**

#### **API設計**: 機能別API → BFF/GraphQL（必要時）
- **理由**: やんわり伝言は要件明確 + 再利用性重視のため、最初から適切な設計で実装
- **初期**: 機能別独立API設計（再利用可能なコンポーネント）
- **成長期**: 各機能APIの最適化・拡張
- **拡大期**: BFF/GraphQL追加（パフォーマンス最適化・統合クエリ）

#### **機能別APIエンドポイント設計**
```bash
/api/v1/auth/*              # 認証システム（完了済み）
/api/v1/users/*             # ユーザー検索・連絡先管理
/api/v1/messages/*          # メッセージ作成・管理
/api/v1/transform/*         # AIトーン変換（3種並行処理）
/api/v1/schedules/*         # 配信スケジュール管理
/api/v1/notifications/*     # SSE通知・配信
/api/v1/dashboard           # BFF統合エンドポイント（必要時）
```

#### **非同期処理**: 必要最小限から段階的導入
- **Phase 1**: AIトーン変換の並行処理（3トーン同時変換）
- **Phase 2**: スケジュール送信のバックグラウンド処理
- **Phase 3**: SSE通知のchannel活用

#### **MongoDB M0対応**: 安定性重視
- 接続プール最大10、goroutine最大3の控えめ設定
- クエリ最適化・インデックス活用でパフォーマンス確保

## メモリ

- プロジェクトファイル整理完了: README.md（公式）+ CLAUDE.md（AI用）+ API_TEST_COMMANDS.md（テスト用）
- **MongoDB Atlas 統合完全実装・動作確認完了**（fujinoyuki, 2025-06-21 17:10）
  - 実際のMongoDB AtlasにユーザーデータID `6856690091b5f3e54b80270d` で保存済み
  - 登録147ms/ログイン97ms/ヘルスチェック13msのパフォーマンス確認
- F-01認証システム完全実装・MongoDB統合完了（fujinoyuki, 2025-06-21）
- **Vue.js認証フロントエンド完全実装・統合完了**（fujinoyuki, 2025-06-21 18:10）
  - フロントエンド・バックエンド完全統合動作確認済み
  - JWTトークン期限チェック・自動リフレッシュ・リロード対応済み
  - 認証状態永続化・ルーティングガード・UI状態管理完了
- **メッセージ作成機能完全実装・統合完了**（fujinoyuki, 2025-06-22 09:30）
  - Backend: メッセージCRUD API完全実装（/api/v1/messages/*）
  - Backend: ユーザー検索API実装（/api/v1/users/search）
  - Frontend: MessageComposer.vue + RecipientSelector.vue実装
  - Frontend: リアルタイムユーザー検索（デバウンス300ms）
  - Frontend: 下書き保存・管理・一覧表示機能
  - Backend/Frontend完全統合・API連携動作確認済み
  - Navigation: ヘッダー・ホームページからアクセス可能
  - Test: curl API + ブラウザUI両方で動作確認完了
- **F-03: スケジュール機能バックエンド完全実装・テスト完了**（fujinoyuki, 2025-06-23 05:10）
  - **AI時間提案機能**: Anthropic Claude API統合成功・メッセージ分析による最適時間提案動作確認
  - **スケジュールCRUD API**: 作成・一覧・更新・削除全機能実装・動作確認完了
  - **MongoDB統合**: スケジュールデータ永続化・インデックス作成・性能最適化完了
  - **受信者連携**: hnn-a@gmail.com での実際のメッセージ・スケジュール連携テスト成功
  - **API実行時間**: AI提案6.5秒・CRUD操作30ms台の高性能動作確認
  - **404エラー解決**: サーバー再起動により全エンドポイント正常動作確認
- **F-03: フロントエンドスケジュール機能完全実装・統合完了**（fujinoyuki, 2025-06-23 05:35）
  - **フロントエンド実装**: scheduleService.ts・ScheduleWizard.vue・ScheduleList.vue・ビュー層完全実装
  - **UI/UX実装**: AI時間提案表示・スケジュール選択・カスタム時間設定・レスポンシブ対応
  - **ルーティング統合**: Vue Router設定・認証ガード・ナビゲーションメニュー統合
  - **E2Eフロー実装**: メッセージ作成→トーン変換→AI提案→スケジュール設定の完全フロー
  - **フロントエンド・バックエンド統合テスト完了**: http://localhost:5173でブラウザ動作確認
  - **⚠️ 未解決問題**: AI時間提案がフロントエンドで応答が返らない場合がある（500エラー発生時）

- **F-02: AIトーン変換機能バックエンド実装完了**（fujinoyuki, 2025-06-22 14:45）
  - ✅ **Backend完全実装・動作確認済み**
    - handlers/transform.go: Anthropic Claude API統合完全実装
    - 3トーン並行変換（gentle/constructive/casual）をgoroutine使用で実装
    - POST /api/v1/transform/tones エンドポイント実装
    - models/message.go: トーン変換結果保存機能追加
    - **curl APIテスト成功**: 「会議延期」メッセージを3トーンに完全変換確認
    - 実際のAnthropic Claude APIとの連携動作確認済み
  - ✅ **Frontend実装済み（動作確認中）**
    - ToneSelector.vue: トーン選択UI実装済み
    - ToneTransformView.vue: トーン変換ページ実装済み
    - transformService.ts + transform.ts store実装済み
    - MessageComposer.vue: トーン変換フロー統合済み
    - ルーティング設定済み（/messages/:id/transform）
  - 🚧 **Frontend統合課題**
    - ボタンクリックイベントの動作確認中
    - デバッグログ追加済み、トラブルシューティング中

- **F-02: AIトーン変換 設定分離・チューニングシステム完成**（fujinoyuki, 2025-06-22 20:47）
  - ✅ **プロンプト設定完全分離**
    - config/tone_prompts.yaml: チューニング担当者が編集可能な設定ファイル
    - config/config.go: YAML読み込み・テンプレート処理機能
    - Go text/template使用でプロンプト動的生成
    - 環境変数TONE_CONFIG_PATHで設定ファイルパス指定可能
  - ✅ **ライブリロード機能**
    - POST /api/v1/transform/reload-config: サーバー再起動不要で設定更新
    - リアルタイム設定反映機能完全動作確認済み
    - フォールバック機能: 設定ファイル破損時も継続動作
  - ✅ **チューニング担当者向けドキュメント完備**
    - config/README.md: 設定ファイル編集ガイド
    - config/TUNING_TEST_GUIDE.md: テスト方法・Before/After比較手順
    - 実践的調整例・トラブルシューティング完備
  - ✅ **動作テスト完了**
    - 設定調整前後でトーン変換結果の変化を確認
    - ライブリロード機能の完全動作確認済み
    - Before/After比較で調整効果を実証

## **現在の完成状況**

### ✅ **完了済み機能**
- **F-01: 認証システム** - 完全実装済み
  - ユーザー登録・ログイン（Argon2+JWT）
  - トークンリフレッシュ・認証ガード
  - フロントエンド認証UI・状態管理
  
- **F-04: メッセージ作成機能** - 完全実装済み
  - メッセージ下書きCRUD操作
  - リアルタイムユーザー検索・受信者選択
  - 文字数カウント・エラーハンドリング
  - フロントエンドUI・バックエンドAPI統合

- **F-02: AIトーン変換機能** - 完全実装済み
  - Anthropic Claude API統合完了
  - 3トーン並行変換（gentle/constructive/casual）
  - 設定ファイル分離・ライブリロード機能完成
  - チューニングシステム・担当者向けドキュメント完備
  - フロントエンド・バックエンド統合完了

- **F-03: スケジュール機能** - 完全実装済み
  - **Backend完全実装**: AI時間提案・スケジュールCRUD・MongoDB統合完了
  - **Frontend完全実装**: ScheduleWizard.vue・AI提案UI・時間選択フロー完成
  - **AI時間提案機能**: Anthropic Claude API統合・メッセージ分析・フロントエンド表示完了
  - **フロントエンド問題修正完了**（fujinoyuki, 2025-07-01 21:59）：
    - APIタイムアウト延長（10秒→15秒）
    - delay_minutes文字列形式対応（"next_business_day_8:30am"等）
    - エラーハンドリング強化・ユーザーフレンドリーメッセージ
    - カスタム時刻デフォルト値修正（過去時間→1時間後）
  - **E2Eフロー**: メッセージ作成→トーン変換→AI提案→スケジュール設定の完全動作確認

### 🎯 **次の実装目標**
- **バックグラウンド送信処理** - 優先度: 最高
  - スケジュール実行エンジン開発
  - 定期実行・メール送信連携
  - cron・goroutineによる自動配信システム
  
- **認証システム強化** - 優先度: 中
  - 認証バイパス問題の調査・修正
  - ユニットテスト作成

### 📝 **次回作業計画**
1. **バックグラウンド送信処理実装**: スケジュール実行エンジン開発
2. **定期実行システム構築**: cron・goroutineによる自動配信
3. **メール・通知連携**: 実際の受信者への配信機能
4. **認証バイパス問題修正**: 未ログイン状態でのページアクセス制御
5. **ユニットテスト作成**: 認証・スケジュール機能のテスト

## セッション管理

### 現在のセッション状況
- **開発者**: fujinoyuki
- **現在のブランチ**: feature/ai-tone-transform  
- **最終更新**: 2025年7月1日 21:59
- **セッション状態**: F-03スケジュール機能フロントエンド問題修正完了

### 完了したタスク（本セッション）
- ✅ **F-03スケジュール機能フロントエンド問題修正完了**
  - APIタイムアウト延長（10秒→15秒）でAI処理時間に対応
  - delay_minutes文字列形式対応（"next_business_day_8:30am"等）
  - エラーハンドリング強化・ユーザーフレンドリーメッセージ実装
  - カスタム時刻デフォルト値修正（過去時間→1時間後）
  - ブラウザでのAI時間提案表示問題解決
- ✅ **E2Eフロー動作確認**: メッセージ作成→トーン変換→AI提案→スケジュール設定の完全フロー

### 開発環境状態
- **バックエンドサーバー**: `http://localhost:8080` で動作中
- **フロントエンドサーバー**: `http://localhost:5173` で動作中（CORS設定済み）
- **AI時間提案機能**: フロントエンド・バックエンド統合動作確認済み
- **MongoDB Atlas**: 実接続・データ永続化確認済み
- **テストユーザー**: test-user@example.com で実際にDB登録済み
- **受信者テストアカウント**: hnn-a@gmail.com で動作確認済み