# やんわり伝言 - クイックスタートガイド

## 🚀 全環境一括起動

### 方法1: スクリプト実行
```bash
# プロジェクトディレクトリで
./start-all.sh

# または任意の場所から（エイリアス設定後）
yanwari-start
```

### 方法2: 個別起動
```bash
# 1. バックエンド起動
cd backend
go run main.go

# 2. フロントエンド起動（別ターミナル）
cd frontend  
npm run dev

# 3. モバイルアプリ起動（別ターミナル）
cd mobile
flutter run
```

## 🛑 全環境停止

```bash
# スクリプト実行
./stop-all.sh

# またはエイリアス
yanwari-stop
```

## 📱 起動される環境

1. **バックエンドサーバー** (Go)
   - URL: http://localhost:8080
   - ヘルスチェック: http://localhost:8080/health

2. **フロントエンド** (Vue.js)
   - URL: http://localhost:5173
   - 開発サーバー with Hot Module Replacement

3. **モバイルアプリ** (Flutter)
   - iOSシミュレーター: 自動起動
   - Web版: http://localhost:3000 (シミュレーター不可時)

## 🔧 便利なエイリアス

```bash
# .zprofile に設定済み
yanwari-start  # 全環境起動
yanwari-stop   # 全環境停止  
yanwari-cd     # プロジェクトディレクトリへ移動

# Flutter関連
fd   # flutter devices
fr   # flutter run
fc   # flutter clean
fp   # flutter pub get
fdr  # flutter doctor
```

## 🏃‍♂️ 開発フロー

1. **朝の開始時**
   ```bash
   yanwari-start
   ```

2. **開発中**
   - バックエンド変更: Go は自動リビルド
   - フロントエンド変更: HMR で自動反映
   - Flutter変更: Hot Reload (r キー)

3. **終了時**
   ```bash
   yanwari-stop
   ```

## ⚡ トラブルシューティング

### ポートが使用中エラー
```bash
# 特定ポートのプロセスを確認
lsof -i :8080
lsof -i :5173
lsof -i :3000

# 強制終了
yanwari-stop
```

### Flutter起動エラー
```bash
# Flutter環境確認
flutter doctor

# クリーン起動
cd mobile
flutter clean
flutter pub get
flutter run
```

### シミュレーター起動失敗
```bash
# 利用可能なシミュレーター確認
xcrun simctl list devices

# 手動起動
open -a Simulator
```

## 📋 必要な環境

- **Go**: 1.24+
- **Node.js**: 18+  
- **Flutter**: 3.24.5+
- **Xcode**: iOS開発用
- **MongoDB**: Atlas接続設定

## 🎯 テスト手順

1. 全環境起動後、以下を確認:
   - バックエンド: `curl http://localhost:8080/health`
   - フロントエンド: ブラウザで http://localhost:5173
   - モバイル: シミュレーターまたは http://localhost:3000

2. 統合テスト:
   - フロントエンドでユーザー登録
   - モバイルアプリで同じアカウントでログイン
   - メッセージ作成・トーン変換・スケジュール設定

---

**更新日**: 2025年8月2日  
**作成者**: Claude Code Assistant