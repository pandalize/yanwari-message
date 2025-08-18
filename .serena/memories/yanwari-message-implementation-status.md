# やんわり伝言サービス - 実装状況まとめ

## 技術スタック（実装済み）

### バックエンド
- **Go 1.23+ + Gin**: RESTful API
- **JWT認証**: 完全実装（Firebase廃止済み）
- **MongoDB**: データベース
- **Anthropic Claude API**: AIトーン変換（実働確認済み）

### フロントエンド
- **Vue 3 + TypeScript + Vite + Pinia**: SPA
- **Nginx**: リバースプロキシ・静的ファイル配信

### モバイル
- **Flutter**: iOS/Androidアプリ（実装済み）

### インフラ
- **Docker + Docker Compose**: 完全コンテナ化
- **MongoDB Express**: 管理UI（開発用）
- **Redis**: 将来利用予定（プロファイル設定済み）

## 開発環境構成

### 起動方法
```bash
npm run dev                 # 全サービス起動（フォアグラウンド）
npm run dev:detached       # 全サービス起動（バックグラウンド）
npm run stop               # 全サービス停止
npm run restart            # サービス再起動
```

### アクセスURL
- フロントエンド: http://localhost
- バックエンドAPI: http://localhost:8080  
- MongoDB管理UI: http://localhost:8081 (admin/admin123)
- JWT認証テストページ: http://localhost/test/jwt-auth-test.html

### 環境変数
- メイン設定: `/Users/fujinoyuki/Documents/yanwari-message/.env`
- テンプレート: `/Users/fujinoyuki/Documents/yanwari-message/.env.example`
- Docker Compose環境変数による設定上書き

## 完了済み機能

- ✅ JWT認証システム（完全移行、Firebase廃止）
- ✅ ユーザー登録・ログイン
- ✅ メッセージ作成・AIトーン変換（3つのトーン：gentle, constructive, casual）
- ✅ スケジュール配信・時間提案機能
- ✅ 友達申請システム
- ✅ メッセージ評価システム
- ✅ 受信メッセージ一覧（インボックス）
- ✅ Flutter iOSアプリ
- ✅ 完全コンテナ化（Docker Compose）
- ✅ サンプルデータ管理システム

## データベース管理

### サンプルデータ操作
```bash
npm run db:seed            # サンプルデータ投入
npm run db:clean           # 全データクリア
npm run db:reset           # クリア後再投入
npm run db:status          # データベース状況確認
```

### テストユーザー（パスワード: password123）
- 田中 あかり（デザイナー） - alice@yanwari-message.com
- 佐藤 ひろし（エンジニア） - bob@yanwari-message.com
- 鈴木 みゆき（PM） - charlie@yanwari-message.com

## コンテナ構成

### サービス
1. **yanwari-backend**: Go API サーバー（ポート8080）
2. **yanwari-frontend**: Vue.js + Nginx（ポート80）
3. **yanwari-mongodb**: MongoDB データベース（ポート27017）
4. **yanwari-mongo-express**: 管理UI（ポート8081）
5. **yanwari-redis**: キャッシュ（将来利用、プロファイル dev）

### ネットワーク・ボリューム
- ネットワーク: yanwari-network
- 永続ボリューム: yanwari-mongodb-data, yanwari-redis-data

## JWT認証システム

### エンドポイント
- POST /api/v1/auth/register - ユーザー登録
- POST /api/v1/auth/login - ログイン
- POST /api/v1/auth/refresh - トークン更新
- POST /api/v1/auth/logout - ログアウト

### 設定
- アクセストークン有効期限: 15分
- リフレッシュトークン有効期限: 7日
- 全APIエンドポイントで認証必須（/auth除く）

## AI機能

### トーン変換
- エンドポイント: POST /api/v1/transform/tones
- 3つのトーン並行処理: gentle（優しめ）、constructive（建設的）、casual（カジュアル）
- YAML設定ファイル対応: backend/config/tone_prompts.yaml
- フォールバック: デフォルトプロンプト

### スケジュール提案
- AI による最適送信時間提案
- 配信エンジン: 1分間隔でチェック、自動配信

## 品質・テスト

### コマンド
```bash
npm run test               # 全テスト
npm run lint              # 全体lint
npm run build             # イメージビルド
```

### テスト用ページ
- JWT認証テスト: /test/jwt-auth-test.html
- APIエンドポイント動作確認
- ワンクリックログイン（Alice/Bob）

## ファイル構成

### 重要ファイル
- backend/main.go: サーバーエントリーポイント
- backend/handlers/auth.go: JWT認証ハンドラー
- backend/middleware/jwt_auth.go: JWT認証ミドルウェア
- backend/handlers/transform.go: AIトーン変換
- docker-compose.yml: インフラ定義
- package.json: 開発コマンド定義

### 削除済みファイル
- backend/.env*: 重複・混乱回避のため削除
- Firebase関連設定: JWT認証移行により不要

## 現在の状況
- 全システム正常動作
- Anthropic API認証確認済み
- Docker環境で完全動作
- 開発者向けテストツール整備済み