# ローカル開発環境セットアップ情報

## 🚀 最新のセットアップフロー

### 初回セットアップ
```bash
# ターミナル1
npm run dev:local      # 開発環境起動

# ターミナル2（起動完了後）
npm run setup:local    # 全データ一括セットアップ
```

### 統合セットアップコマンド
`npm run setup:local` は以下を自動実行：
1. MongoDB テストデータ投入 (`npm run mongodb:seed`)
2. Firebase Emulator ユーザー作成 (`npm run firebase:seed`)
3. Firebase UID と MongoDB 同期 (`npm run sync:users`)

## 📋 作成されるテストユーザー

| Email | Password | Firebase UID |
|-------|----------|--------------|
| alice@yanwari.com | password123 | hz2QyzxqXex0fIjcgyzwNBZWStJb |
| bob@yanwari.com | password123 | bzdW6Dg7ja4vL7pOc3LEzG7lFayU |
| charlie@yanwari.com | password123 | xsKDz3tEZpBfJ2tgucEdUXdWLNLD |

## 🔄 データ同期タイミング

`npm run sync:users` が必要なケース：
- 初回セットアップ時（setup:localに含まれる）
- Firebase Emulator リセット後
- MongoDB リセット後

日常の開発では不要（データは永続化される）

## 📊 環境構成

- **MongoDB**: Docker コンテナ（常時起動推奨）
- **Firebase Emulator**: 開発サーバー起動時に自動起動
- **認証**: Firebase Authentication
- **データ**: MongoDB

## 🔧 トラブルシューティング

### ログインできない場合
```bash
npm run setup:local  # データ再同期
```

### Docker関連
```bash
docker ps            # コンテナ確認
npm run mongodb:status  # MongoDB状態確認
```

## 📚 ドキュメント

メインドキュメント: `/docs/LOCAL_DEVELOPMENT_GUIDE.md`

更新日: 2025-08-14