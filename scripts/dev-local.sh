#!/bin/bash

# ローカル開発環境起動スクリプト（MongoDB + Firebase Emulator）

set -e

# 色定義
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# プロジェクトルートに移動
cd "$(dirname "$0")/.."

echo -e "${CYAN}🚀 ローカル開発環境起動中...${NC}"
echo "  - ローカルMongoDB"
echo "  - Firebase Emulator"
echo ""

# MongoDB起動確認
if ! docker ps | grep -q yanwari-mongodb; then
    echo -e "${YELLOW}MongoDBを起動しています...${NC}"
    ./scripts/mongodb-local.sh start
fi

# 環境変数設定（ローカル用）
export MONGODB_URI="mongodb://admin:password123@localhost:27017/yanwari-message?authSource=admin"
export FIREBASE_AUTH_EMULATOR_HOST="127.0.0.1:9099"

echo -e "${GREEN}✅ ローカル環境で起動します${NC}"
echo ""

# 並列起動
concurrently \
    --prefix-colors "green,yellow,cyan" \
    --names "🟢BACKEND,🌐FRONTEND,🔥FIREBASE" \
    "cd backend && MONGODB_URI=$MONGODB_URI FIREBASE_AUTH_EMULATOR_HOST=$FIREBASE_AUTH_EMULATOR_HOST PORT=8080 go run main.go" \
    "cd frontend && npm run dev -- --port=5173 --host=localhost" \
    "firebase emulators:start --only auth --project yanwari-message"