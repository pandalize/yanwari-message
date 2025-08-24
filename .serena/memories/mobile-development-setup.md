# モバイル開発環境セットアップ

## 環境変数の管理方法（標準的な.env.local方式）

### ファイル構成
- `/yanwari-message/.env` - バックエンド設定のみ（ANTHROPIC_API_KEY、JWT、MongoDB）
- `/frontend/.env` - フロントエンド共通設定（リポジトリにコミット）
- `/frontend/.env.local` - 各開発者のローカル設定（gitignore対象）
- `/frontend/.env.example` - 環境変数のテンプレート

### iOS/Android開発手順

1. **ローカルIPアドレスを確認**
```bash
# Mac
ifconfig | grep "inet " | grep -v 127.0.0.1
# Windows
ipconfig
```

2. **.env.localを作成**
```bash
cd frontend
echo "VITE_CAPACITOR_API_URL=http://[あなたのIP]:8080/api/v1" > .env.local
```

3. **ビルドと実行**
```bash
npm run build
npx cap sync ios  # または android
npx cap run ios   # または android
```

### Capacitor設定
- `capacitor.config.ts`は固定設定（動的生成なし）
- `cleartext: true`でHTTP接続を許可
- IPアドレスは.env.localで管理

### 注意事項
- 開発PCとモバイルデバイスは同じWi-Fiネットワークに接続
- バックエンドは`docker-compose up -d`で起動
- `.env.local`はgitignoreで除外される

### トラブルシューティング
- ネットワークエラー: IPアドレスとポート8080の確認
- 代替案: ngrokを使用して公開URL経由でアクセス