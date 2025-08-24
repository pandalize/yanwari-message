# やんわり伝言 - フロントエンド

Vue 3 + TypeScript + Vite + Capacitorを使用したWebおよびモバイルアプリケーション

## 🚀 開発環境セットアップ

### Web開発

```bash
# 依存関係をインストール
npm install

# 環境変数をセットアップ
cp .env.example .env

# 開発サーバーを起動
npm run dev
```

### 📱 iOS/Android開発

他の開発者がモバイル開発を行う場合の手順：

#### 1. 環境変数の設定

```bash
# .env.localファイルを作成（gitignore対象）
echo "VITE_CAPACITOR_API_URL=http://[あなたのローカルIP]:8080/api/v1" > .env.local

# ローカルIPの確認方法
# Mac: ifconfig | grep "inet " | grep -v 127.0.0.1
# Windows: ipconfig
```

例：
```bash
echo "VITE_CAPACITOR_API_URL=http://192.168.1.100:8080/api/v1" > .env.local
```

#### 2. ビルドと同期

```bash
# フロントエンドをビルド
npm run build

# Capacitorプロジェクトを同期
npx cap sync

# iOS開発
npx cap run ios

# Android開発
npx cap run android
```

### 📝 重要な注意事項

- **`.env`ファイル**: リポジトリにコミット（共通設定）
- **`.env.local`ファイル**: 各開発者のローカル設定（gitignore対象）
- **IPアドレス**: 開発PCとモバイルデバイスが同じネットワークに接続されている必要があります
- **バックエンド**: `docker-compose up -d`でバックエンドを起動してください

### 🛠️ その他のコマンド

```bash
# 型チェック
npm run type-check

# Lintとフォーマット
npm run lint
npm run format

# テスト
npm run test:unit
npm run test:e2e

# プロダクションビルド
npm run build
```

## 🔧 トラブルシューティング

### iOS/Androidでネットワークエラーが発生する場合

1. バックエンドが起動していることを確認
   ```bash
   docker ps | grep backend
   ```

2. ローカルIPが正しいことを確認
   ```bash
   cat .env.local
   ```

3. ファイアウォールが8080ポートをブロックしていないか確認

4. モバイルデバイスとPCが同じWi-Fiネットワークに接続されているか確認

### ngrokを使用した代替方法

IPアドレスの設定が面倒な場合、ngrokを使用できます：

```bash
# ngrokをインストール
npm install -g ngrok

# バックエンドを公開
ngrok http 8080

# 生成されたURLを.env.localに設定
echo "VITE_CAPACITOR_API_URL=https://abc123.ngrok.io/api/v1" > .env.local
```