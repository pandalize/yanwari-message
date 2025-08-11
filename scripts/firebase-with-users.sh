#!/bin/bash

echo "🔥 Firebase Emulator + テストユーザー自動作成"

# Firebase Emulator起動
firebase emulators:start --only auth &
FIREBASE_PID=$!

# 起動待機
echo "⏳ Firebase Emulator起動待機中..."
sleep 6

# テストユーザー作成
echo "👥 Firebaseテストユーザー自動作成中..."
node backend/scripts/test-firebase-integration.cjs

echo "✅ Firebase環境準備完了"

# Emulatorを継続
wait $FIREBASE_PID