#!/bin/bash

echo "🚀 ローカル開発環境起動中..."
echo "  - Firebase認証なし"
echo "  - APIテストのみ"
echo ""

concurrently \
    --prefix-colors "green,yellow" \
    --names "🟢BACKEND,🌐FRONTEND" \
    "cd backend && PORT=8080 go run main.go" \
    "cd frontend && npm run dev -- --port=5173 --host=localhost"