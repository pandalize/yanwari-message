# コードベース構造

## プロジェクトルート構造
```
yanwari-message/
├── backend/           # Go バックエンドAPI
├── frontend/          # Vue 3 フロントエンドアプリ
├── mobile/            # Flutter モバイルアプリ
├── docs/              # プロジェクトドキュメント
├── claude-setting/    # Claude Code設定
├── CLAUDE.md          # Claude Code協働ガイド
├── README.md          # プロジェクト公式文書
├── package.json       # プロジェクト全体の管理スクリプト
├── yanwari-start      # 統合起動スクリプト
└── start-all.sh       # 個別起動スクリプト
```

## バックエンド構造 (Go)
```
backend/
├── main.go                 # エントリーポイント
├── go.mod/go.sum          # 依存関係管理
├── handlers/              # APIハンドラー（機能別）
│   ├── auth.go            # 認証API (削除予定：Firebase移行済み)
│   ├── firebase_auth.go   # Firebase認証API
│   ├── messages.go        # メッセージCRUD API
│   ├── transform.go       # AIトーン変換API
│   ├── schedules.go       # スケジュール管理API
│   ├── settings.go        # 設定管理API
│   ├── friend_requests.go # 友達申請API
│   └── message_ratings.go # メッセージ評価API
├── models/                # データモデル・サービス層
│   ├── user.go           # ユーザーモデル・サービス
│   ├── message.go        # メッセージモデル・サービス
│   ├── schedule.go       # スケジュールモデル・サービス
│   └── [その他モデル]
├── middleware/           # ミドルウェア
│   ├── firebase_auth.go  # Firebase認証ミドルウェア
│   └── auth.go          # 従来認証（削除予定）
├── services/            # 外部サービス連携
│   └── firebase_service.go # Firebase Admin SDK
├── database/            # データベース接続管理
├── config/              # 設定ファイル（YAML等）
└── migration/           # DB移行スクリプト
```

## フロントエンド構造 (Vue 3)
```
frontend/src/
├── main.ts                    # エントリーポイント
├── App.vue                    # ルートコンポーネント
├── components/                # 機能別コンポーネント
│   ├── auth/                  # 認証コンポーネント
│   ├── messages/              # メッセージ関連
│   ├── schedule/              # スケジュール関連
│   ├── friends/               # 友達管理
│   ├── rating/                # 評価システム
│   └── visualization/         # ツリーマップ等
├── views/                     # ページコンポーネント
│   ├── LoginView.vue          # ログインページ
│   ├── MessageComposeView.vue # メッセージ作成
│   ├── SettingsView.vue       # 設定画面
│   └── [その他ビュー]
├── stores/                    # Pinia状態管理
│   ├── auth.ts               # 認証ストア
│   ├── messages.ts           # メッセージストア
│   ├── friends.ts            # 友達管理ストア
│   └── [機能別ストア]
├── services/                  # API呼び出しサービス層
│   ├── api.ts                # 共通APIサービス
│   ├── authService.ts        # 認証API
│   ├── messageService.ts     # メッセージAPI
│   └── [機能別サービス]
├── router/                   # ルーティング
│   └── index.ts              # ルート定義・認証ガード
└── assets/                   # 静的アセット
```

## モバイルアプリ構造 (Flutter)
```
mobile/lib/
├── main.dart              # エントリーポイント
├── screens/               # 画面コンポーネント
│   ├── login_screen.dart  # ログイン画面
│   ├── home_screen.dart   # ホーム画面
│   ├── inbox_screen.dart  # 受信トレイ（実装済み）
│   └── [その他画面]
├── services/              # APIサービス層
│   └── api_service.dart   # APIアクセス
├── models/                # データモデル
└── widgets/               # 再利用可能ウィジェット
```

## 主要な実装済み機能
- ✅ Firebase認証システム完全実装
- ✅ メッセージ作成・下書き・編集機能
- ✅ AIトーン変換（3種並行処理）
- ✅ スケジュール・AI時間提案機能
- ✅ 設定画面（プロフィール・パスワード・通知・メッセージ設定）
- ✅ 友達申請・管理システム
- ✅ メッセージ評価システム・ツリーマップ可視化
- ✅ Flutter iOSアプリ受信トレイ機能