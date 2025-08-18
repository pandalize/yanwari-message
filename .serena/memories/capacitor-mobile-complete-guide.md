# Capacitor モバイルアプリ完全セットアップガイド

## ✅ 実装完了状況（2025/08/18）
- **ブランチ**: `feature/web-capacitor-mobile` → developマージ済み
- **iPhone実機テスト**: ✅ 完全動作確認済み
- **ネットワーク接続**: ✅ 解決済み（CORS + ATS設定）

## 🚀 初回セットアップ（完了済み）

### 1. Capacitor導入
```bash
# 依存関係インストール（完了済み）
npm install @capacitor/core @capacitor/cli @capacitor/ios @capacitor/android

# プラットフォーム追加（完了済み）
npx cap add ios
npx cap add android
```

### 2. 設定ファイル
#### capacitor.config.ts（設定完了）
```typescript
const config: CapacitorConfig = {
  appId: 'com.yanwari.message',
  appName: 'やんわり伝言',
  webDir: 'dist',
  server: {
    androidScheme: 'https',
    // 開発環境: 実機からMacのローカルサーバーへアクセス許可
    allowNavigation: ['http://192.168.0.7:8080', 'http://localhost:8080'],
    iosScheme: 'http'
  },
  plugins: {
    SplashScreen: {
      launchShowDuration: 2000,
      backgroundColor: "#4f46e5",
      showSpinner: true,
      androidSpinnerStyle: "large",
      iosSpinnerStyle: "small"
    }
  }
};
```

## 📱 日常開発フロー

### iOSアプリ開発・テスト
```bash
# 1. Webアプリビルド + Capacitor同期
npm run cap:build

# 2. Xcodeを起動してiOSプロジェクト開く
npm run cap:ios

# 3. Xcode内で実機選択→⌘+R でビルド・実行
```

### Androidアプリ開発・テスト
```bash
# 1. Webアプリビルド + Capacitor同期
npm run cap:build

# 2. Android Studioを起動
npm run cap:android

# 3. Android Studio内で実機選択→Runボタン
```

### 設定変更時の同期
```bash
# Capacitor設定やプラグイン変更後
npm run cap:sync
```

## 🔧 ネットワーク設定（解決済み）

### バックエンドCORS設定
- **開発環境**: `ALLOWED_ORIGINS=*` （全origin許可）
- **本番環境**: 適切なドメインに限定要

### iOS App Transport Security設定
`ios/App/App/Info.plist` に以下追加済み:
```xml
<key>NSAppTransportSecurity</key>
<dict>
  <key>NSAllowsArbitraryLoads</key>
  <true/>
  <key>NSAllowsLocalNetworking</key>
  <true/>
</dict>
```

### API URL動的切り替え
`src/services/api.ts` で自動判定:
- **Web版**: `http://localhost:8080/api/v1`
- **Capacitor版**: `http://192.168.0.7:8080/api/v1`

## 📂 プロジェクト構成

```
yanwari-message/
├── frontend/              # Vue.js Webアプリ
│   ├── ios/              # Capacitor iOSプロジェクト
│   ├── android/          # Capacitor Androidプロジェクト
│   ├── capacitor.config.ts
│   └── src/
├── mobile/               # Flutter版（並行保持）
└── backend/              # Go API
```

## 🛠️ npmスクリプト

```json
{
  "cap:build": "npm run build && npx cap copy",
  "cap:ios": "npm run cap:build && npx cap open ios",
  "cap:android": "npm run cap:build && npx cap open android",
  "cap:sync": "npx cap sync"
}
```

## ⚠️ 重要な注意事項

### 開発環境要件
- **iOS**: Xcode (Mac必須) + iOS Developer証明書
- **Android**: Android Studio + Android SDK
- **バックエンド**: Docker Compose環境起動必須

### IPアドレス設定
- `192.168.0.7` は開発マシンのローカルIP
- 環境に応じて `capacitor.config.ts` と `api.ts` を調整

### Flutter版との関係
- Capacitor版とFlutter版は並行保持
- 将来的な技術選択のための比較検討用

## 🐛 トラブルシューティング

### 1. ネットワークエラー
- Docker Compose起動確認: `npm run dev`
- CORS設定確認: `docker logs yanwari-backend`

### 2. iOSビルドエラー
- Developer証明書確認
- Xcode設定でチーム選択

### 3. 設定変更反映されない
```bash
npm run cap:sync
# 必要に応じてXcode/Android Studioでクリーンビルド
```

## 📝 次期アップデート計画
- プッシュ通知プラグイン導入
- 本番環境用セキュリティ強化
- CI/CDパイプライン構築