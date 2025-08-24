# モバイル開発環境セットアップ

## 環境変数の管理方法（.envのみ使用）

### ファイル構成
- `/yanwari-message/.env` - バックエンド設定のみ（ANTHROPIC_API_KEY、JWT、MongoDB）
- `/frontend/.env` - フロントエンド設定（gitignore対象、各開発者が設定）
- `/frontend/.env.example` - 環境変数のテンプレート

### iOS/Android開発手順

1. **環境変数をコピー**
```bash
cd frontend
cp .env.example .env
```

2. **ローカルIPアドレスを確認**
```bash
# Mac
ifconfig | grep "inet " | grep -v 127.0.0.1
# Windows
ipconfig
```

3. **.envファイルを編集**
```bash
# VITE_CAPACITOR_API_URLを自分のIPアドレスに変更
VITE_CAPACITOR_API_URL=http://192.168.1.100:8080/api/v1
```

4. **ビルドと実行**
```bash
npm run build
npx cap sync ios  # または android
npx cap run ios   # または android
```

### Capacitor設定
- `capacitor.config.ts`は固定設定（動的生成なし）
- `cleartext: true`でHTTP接続を許可

### 注意事項
- 開発PCとモバイルデバイスは同じWi-Fiネットワークに接続
- バックエンドは`docker-compose up -d`で起動
- `.env`はgitignoreで除外される

### トラブルシューティング
- ネットワークエラー: IPアドレスとポート8080の確認
- 代替案: ngrokを使用して公開URL経由でアクセス