# プロジェクト開発環境の現状（2025年8月時点）

## 利用可能な開発環境

### 1. ローカル高速開発環境（推奨）
```bash
npm run dev:local
```
- **MongoDB**: Docker Compose（ローカル）
- **Firebase**: Emulator
- **パフォーマンス**: 最高速（1-5ms DB接続）
- **用途**: 日常開発、機能実装、デバッグ

### 2. クラウド統合環境
```bash
npm run dev:cloud
```
- **MongoDB**: Atlas（クラウド）
- **Firebase**: Emulator  
- **パフォーマンス**: 中程度（50-200ms DB接続）
- **用途**: 統合テスト、本番近似テスト

### 3. 従来環境
```bash
npm run dev
```
- **MongoDB**: Atlas（クラウド）
- **Firebase**: Emulator
- **用途**: 既存ワークフロー維持

## MongoDB管理コマンド

### 基本操作
```bash
npm run mongodb:start    # MongoDB起動
npm run mongodb:stop     # MongoDB停止
npm run mongodb:status   # 状態確認
```

### データ管理
```bash
npm run mongodb:reset    # 完全リセット
npm run mongodb:seed     # テストデータ投入
```

## アクセス可能なサービス

| サービス | URL | 説明 |
|---------|-----|------|
| Frontend | http://localhost:5173 | Vue.js アプリ |
| Backend API | http://localhost:8080 | Go API サーバー |
| Mongo Express | http://localhost:8081 | DB管理画面 |
| Firebase Auth | http://localhost:4000/auth | 認証エミュレータ |
| Swagger UI | http://localhost:8080/docs | API仕様書 |

## 開発ツール

### API関連
```bash
npm run api:sync         # API型定義同期
npm run test             # テスト実行
npm run lint             # コード品質チェック
```

### 環境管理
```bash
npm run setup            # 初回セットアップ
npm run reset            # 完全リセット
npm run status           # 状況確認
```

## テストデータ構成

### ユーザーアカウント
- **alice@example.com** / password123
- **bob@example.com** / password123  
- **charlie@example.com** / password123

### データ種別
- ユーザープロファイル
- 友達関係
- メッセージ（各種ステータス）
- スケジュール（送信予定）
- 評価データ

## ファイル構成

### 設定ファイル
- `docker-compose.yml`: MongoDB環境定義
- `backend/.env.local`: ローカル環境変数
- `backend/.env`: クラウド環境変数

### スクリプト
- `scripts/mongodb-local.sh`: MongoDB管理
- `scripts/dev-local.sh`: ローカル環境起動
- `scripts/dev-firebase.sh`: クラウド環境起動

### ドキュメント
- `README-LOCAL-SETUP.md`: ローカル環境詳細ガイド
- `CLAUDE.md`: 開発コマンド一覧

## Unknown User問題関連

### 検証可能な環境
1. **ローカル環境**: 高速でのデバッグ・修正・検証
2. **Mongo Express**: リアルタイムデータ確認
3. **Swagger UI**: API動作確認
4. **テストデータ**: 既知の受信者データでの検証

### 解決済み部分
- `/messages/sent` API: recipientNameフィールド返却確認済み
- TypeScript型定義: ModelsMessageWithRecipientInfo生成済み
- フロントエンド: 型安全なAPI呼び出し実装済み

### 未解決部分
- スケジュール一覧表示でのrecipientName
- 受信ボックス表示でのsenderName
- 履歴詳細表示での手動取得ロジック

## 推奨開発フロー

### 1. 機能開発開始
```bash
npm run dev:local           # 高速ローカル環境起動
npm run mongodb:seed        # テストデータ確保
```

### 2. API修正時
```bash
npm run api:sync           # 型定義同期
npm run test               # テスト実行
```

### 3. 統合テスト
```bash
npm run dev:cloud          # 本番近似環境で検証
```

### 4. データ確認
- Mongo Express: http://localhost:8081
- Swagger UI: http://localhost:8080/docs

## 環境切り替えのメリット・デメリット

### ローカル環境
**メリット**:
- 超高速（1-5ms）
- 無料
- 完全制御
- オフライン可能

**デメリット**:
- Docker必須
- ローカルリソース使用

### クラウド環境  
**メリット**:
- 本番近似
- チーム共有データ
- セットアップ不要

**デメリット**:
- ネットワーク遅延
- 月額課金
- データ共有リスク

## 今後の改善点

### 短期
1. Unknown User問題の完全解決
2. テストデータの充実
3. 自動テストの拡充

### 中期
1. CI/CD環境での活用
2. ステージング環境構築
3. パフォーマンス監視

### 長期
1. マイクロサービス対応
2. Kubernetes対応
3. 他プロジェクトテンプレート化