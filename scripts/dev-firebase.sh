#!/bin/bash

echo "🔥 Firebase付き開発環境起動中..."
echo "  - Firebase認証エミュレーター込み"
echo "  - フル機能テスト可能"
echo ""

concurrently \
    --prefix-colors "blue,green,yellow" \
    --names "🔥FIREBASE,🟢BACKEND,🌐FRONTEND" \
    "./scripts/firebase-with-users.sh" \
    "sleep 8 && cd backend && FIREBASE_AUTH_EMULATOR_HOST=127.0.0.1:9099 PORT=8080 go run main.go" \
    "sleep 10 && cd frontend && npm run dev -- --port=5173 --host=localhost"