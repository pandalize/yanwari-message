# 推奨コマンド一覧

## 開発環境セットアップ
```bash
# 全依存関係のインストール
npm run install:all

# 環境変数セットアップ
npm run setup:env
# 後で backend/.env を実際の値で編集が必要
```

## 開発・実行コマンド
```bash
# フロントエンドとバックエンドを同時起動
npm run dev

# 個別起動
npm run dev:backend   # Go サーバー :8080
npm run dev:frontend  # Vue 開発サーバー :5173

# 統合起動スクリプト（推奨）
./yanwari-start       # 全環境起動
./yanwari-start stop  # 全環境停止
./start-all.sh        # 個別起動スクリプト
./stop-all.sh         # 個別停止スクリプト
```

## ビルド・テスト・品質チェック
```bash
# ビルド
npm run build         # フロントエンドビルド
npm run build:backend # バックエンドバイナリビルド

# テスト実行
npm run test          # 全てのテスト実行
npm run test:backend  # Go テスト
npm run test:frontend # Vitest ユニットテスト
npm run test:e2e      # Playwright E2E テスト

# コード品質チェック
npm run lint          # 全コードリント
npm run lint:backend  # Go vet
npm run lint:frontend # ESLint
npm run format        # フロントエンドフォーマット
```

## Git・ブランチ操作
```bash
# 最新情報取得
git fetch origin

# developブランチ更新
git checkout develop
git pull origin develop

# 機能ブランチ作成
git checkout develop
git checkout -b feature/[機能名]

# プッシュ・プルリクエスト
git push origin feature/[機能名]
```

## 便利なスクリプト
```bash
# APIテスト用コマンド集
./test_message.sh     # メッセージAPIテスト
./check_backend_log.sh # バックエンドログ確認

# プロジェクト情報
cat API_TEST_COMMANDS.md # APIテストコマンド一覧
cat CLAUDE.md           # Claude Code協働ガイド
cat QUICK_START.md      # クイックスタートガイド
```