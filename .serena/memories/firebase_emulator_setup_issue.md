# Firebase Emulator セットアップ問題

## 問題
Firebase Emulator起動時のエラー:
```
Error: Cannot start the Authentication Emulator without a project: run 'firebase init' or provide the --project flag
```

## 原因分析
1. **firebase.json が存在しない**: プロジェクトルートにFirebase設定ファイルがない
2. **Firebase プロジェクト未初期化**: `firebase init` が実行されていない
3. **プロジェクト設定不足**: Firebase CLI がプロジェクトを認識できない

## 現在の Firebase 設定状況
- ✅ **Firebase Admin SDK**: `backend/config/firebase-admin-key.json` 存在
- ✅ **プロジェクトID**: `yanwari-message` 確認済み
- ❌ **Firebase CLI設定**: `firebase.json` 不在
- ❌ **Emulator設定**: 未設定

## 解決方法

### Option 1: Firebase プロジェクト初期化（推奨）
```bash
# Firebase プロジェクト初期化
firebase init

# または既存プロジェクトIDを指定
firebase init --project yanwari-message

# Emulator設定を選択：
# - Authentication Emulator
# - (他のエミュレータは必要に応じて)
```

### Option 2: 手動でfirebase.json作成
```json
{
  "emulators": {
    "auth": {
      "port": 9099
    },
    "ui": {
      "enabled": true,
      "port": 4000
    }
  }
}
```

### Option 3: プロジェクトフラグ使用
```bash
firebase emulators:start --only auth --project yanwari-message
```

## 推奨セットアップ手順

### 1. Firebase プロジェクト初期化
```bash
cd /Users/fujinoyuki/Documents/yanwari-message
firebase init
```

**設定選択肢:**
- ✅ Emulators (Emulator suite)
- ✅ Use an existing project: yanwari-message
- ✅ Authentication Emulator: port 9099
- ❌ その他のエミュレータ（必要に応じて）

### 2. firebase.json 設定例
```json
{
  "emulators": {
    "auth": {
      "port": 9099
    },
    "ui": {
      "enabled": true,
      "port": 4000
    }
  }
}
```

### 3. .firebaserc 設定
```json
{
  "projects": {
    "default": "yanwari-message"
  }
}
```

## テストデータ初期化戦略への影響

### Firebase Emulator使用時の利点
1. **完全ローカル制御**: テスト用Firebaseユーザーの作成・削除
2. **高速リセット**: エミュレータ再起動で認証データ初期化
3. **本番分離**: 本番Firebase認証に影響なし

### 初期化スクリプト統合
```bash
# 完全な環境初期化
npm run test-env:reset
# ↓
# 1. Firebase Emulator 起動
# 2. MongoDB 初期化
# 3. テストユーザー作成 (Firebase + MongoDB)
```

## Firebase Emulator + MongoDB 統合フロー

### 1. 環境起動
```bash
firebase emulators:start --only auth &  # バックグラウンド起動
npm run db:reset                        # MongoDB初期化
```

### 2. テストユーザー作成
```javascript
// Firebase Emulator にテストユーザー作成
const testUser = await auth.createUser({
  uid: 'test_firebase_uid_001',
  email: 'alice@yanwari.com',
  password: 'testpassword123'
});

// MongoDB にユーザーレコード作成
const mongoUser = {
  firebase_uid: 'test_firebase_uid_001',
  email: 'alice@yanwari.com',
  name: 'Alice テスター'
};
```

### 3. 環境停止
```bash
firebase emulators:stop  # Firebase Emulator停止
# MongoDB は通常通り
```

## 次のアクション
1. `firebase init` でEmulator設定作成
2. テストデータ初期化スクリプトにEmulator統合
3. 開発ワークフローに組み込み