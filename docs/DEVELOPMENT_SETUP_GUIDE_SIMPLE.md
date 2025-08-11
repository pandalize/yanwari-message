# 開発環境クイックガイド

## 🚀 初回セットアップ

```bash
# 1. リポジトリクローン
git clone <repository-url>
cd yanwari-message

# 2. 環境構築
npm run setup

# 3. MongoDB Atlas URI設定
# backend/.env を編集してMONGODB_URIを正しい値に設定
```

## 🔥 開発開始

```bash
# インタラクティブメニュー（推奨）
npm run dev

# または直接指定
npm run dev:firebase  # Firebase付き（推奨）
npm run dev:local     # ローカルのみ
```

## 📝 日常コマンド

| コマンド | 用途 |
|---------|------|
| `npm run dev` | 開発サーバー起動（メニュー） |
| `npm run reset` | 環境完全リセット |
| `npm run status` | 起動状況確認 |
| `npm run stop` | サーバー停止 |
| `npm run api:sync` | API型定義同期 |
| `npm run test` | テスト実行 |
| `npm run lint` | コード品質チェック |

## 🧪 テストアカウント

Firebase付き起動時に自動作成されます：
- **alice@yanwari.com** / `password123`
- **bob@yanwari.com** / `password123`
- **charlie@yanwari.com** / `password123`

## 🔗 サービスURL

- **Frontend**: http://localhost:5173
- **Backend**: http://localhost:8080
- **Swagger API**: http://localhost:8080/swagger/index.html
- **Firebase UI**: http://localhost:4000

## ⚠️ トラブルシューティング

### ログインできない
```bash
npm run reset  # 環境リセット
npm run dev:firebase  # Firebase付きで再起動
```

### ポートエラー
```bash
npm run stop   # プロセス停止
npm run status # 確認
npm run dev    # 再起動
```

### MongoDB接続エラー
- `backend/.env` のMONGODB_URIを確認
- MongoDB Atlas接続状況を確認

---

**詳細情報**: [完全ガイド](./DEVELOPMENT_SETUP_GUIDE.md) | [API設計](./API_DEVELOPMENT_WORKFLOW.md)