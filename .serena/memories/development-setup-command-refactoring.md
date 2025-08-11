# 開発環境コマンド整理・作り直し

## 実装した改善内容

### 1. package.jsonコマンド体系の整理

元の複雑で重複の多いコマンドを、目的別にカテゴライズして整理：

#### 🚀 基本コマンド
- `dev`: インタラクティブメニュー（推奨）
- `build`: フロント+バックエンド統合ビルド
- `test`: 統合テスト実行
- `lint`: 統合リント実行
- `setup`: 初回セットアップ（依存関係+環境変数+ツール）

#### 🔥 開発サーバー
- `dev:firebase`: Firebase付き起動（フル機能）
- `dev:local`: ローカルのみ起動（APIテストのみ）
- `dev:status`: 環境状況確認
- `dev:stop`: サーバー停止

#### 🔥 Firebase エミュレーター
- `firebase:start`: エミュレーター起動
- `firebase:users`: テストユーザー作成
- `firebase:setup`: DB+ユーザー作成

#### 🗄️ データベース
- `db:reset`: データベースリセット
- `db:seed`: サンプルデータ投入（フル）
- `db:seed:basic`: 基本データのみ
- `db:seed:messages`: メッセージデータのみ

#### 🔄 環境リセット
- `reset`: 完全リセット（プロセス停止+DB初期化）
- `reset:quick`: クイックリセット（データのみ）

#### 📋 API設計
- `api:sync`: API仕様同期（生成+通知）
- `api:generate`: API仕様生成のみ

### 2. 作成したスクリプトファイル

#### scripts/dev-status.sh
開発環境の状況確認スクリプト：
- ポート使用状況（5173, 8080, 9099）
- Firebase Emulator状態
- Go Backend状態
- Vue Frontend状態
- サービスURL一覧

#### scripts/full-reset.sh  
完全環境リセットスクリプト：
- 既存プロセス停止
- データベース初期化
- サンプルデータ投入
- 次のステップガイド表示

#### scripts/dev-start.sh（改良）
シンプルなインタラクティブ起動スクリプト：
- メニュー形式での起動モード選択
- 引数による直接指定対応
- 依存関係チェック
- 新コマンド体系に対応

### 3. ドキュメント作成

#### docs/DEVELOPMENT_SETUP_GUIDE.md
包括的な開発環境ガイド：
- 初回セットアップ手順
- 日常的な開発ワークフロー
- データベース・テストデータ管理
- トラブルシューティング
- VSCode設定説明
- モバイル開発対応

#### CLAUDE.md更新
- 新しいコマンド体系に対応
- カテゴリ別整理
- 推奨コマンドの明示

### 4. 改善効果

#### Before（問題点）
- 48個の複雑で重複の多いコマンド
- 覚えにくい長いコマンド名
- テストユーザー作成の複雑なフロー
- Firebase統合の煩雑な手順
- ドキュメント不整備

#### After（改善点）
- 目的別に整理された明確なコマンド体系
- インタラクティブメニューによる直感的操作
- シンプルなFirebase統合（`firebase:setup`）
- 包括的なドキュメント整備
- 開発者の認知負荷大幅軽減

## 使用方法

### 初回セットアップ
```bash
npm run setup
```

### 日常開発
```bash
npm run dev  # メニューから選択
# または
npm run dev:firebase  # Firebase付き
npm run dev:local     # ローカルのみ
```

### 環境リセット
```bash
npm run reset
```

### API変更時
```bash
npm run api:sync
```

### 状況確認
```bash
npm run dev:status
```

## ファイル構成

```
package.json                          # 整理されたコマンド体系
scripts/
├── dev-start.sh                     # インタラクティブ起動（改良）
├── dev-status.sh                    # 状況確認（新規）
├── full-reset.sh                    # 完全リセット（新規）
└── swagger-generate.sh              # API生成（改良）
docs/
├── DEVELOPMENT_SETUP_GUIDE.md       # 開発ガイド（新規）
└── API_DEVELOPMENT_WORKFLOW.md      # API設計ガイド（既存）
CLAUDE.md                            # プロジェクト説明（更新）
```