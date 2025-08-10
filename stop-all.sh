#!/bin/bash

# やんわり伝言 - 全環境停止スクリプト

# 色付き出力用の定義
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}🛑 やんわり伝言 - 全環境停止開始${NC}"
echo "=================================="

# 1. Flutterプロセスの停止
echo -e "\n${YELLOW}1. Flutterアプリを停止中...${NC}"
pkill -f "flutter.*run" 2>/dev/null
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Flutterアプリを停止しました${NC}"
else
    echo "Flutterアプリは起動していません"
fi

# 2. フロントエンドサーバーの停止（ポート5173）
echo -e "\n${YELLOW}2. フロントエンドサーバーを停止中...${NC}"
lsof -ti:5173 | xargs kill -9 2>/dev/null
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ フロントエンドサーバーを停止しました${NC}"
else
    echo "フロントエンドサーバーは起動していません"
fi

# 3. バックエンドサーバーの停止（ポート8080）
echo -e "\n${YELLOW}3. バックエンドサーバーを停止中...${NC}"
lsof -ti:8080 | xargs kill -9 2>/dev/null
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ バックエンドサーバーを停止しました${NC}"
else
    echo "バックエンドサーバーは起動していません"
fi

# 4. ポート3000のサービス停止（Flutter Web）
echo -e "\n${YELLOW}4. Flutter Webサーバーを停止中...${NC}"
lsof -ti:3000 | xargs kill -9 2>/dev/null
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Flutter Webサーバーを停止しました${NC}"
else
    echo "Flutter Webサーバーは起動していません"
fi

# 5. Node.jsプロセスのクリーンアップ
echo -e "\n${YELLOW}5. Node.jsプロセスをクリーンアップ中...${NC}"
pkill -f "node.*dev" 2>/dev/null

# 6. シミュレーターは維持（必要に応じて手動で閉じる）
echo -e "\n${BLUE}ℹ️  iOSシミュレーターは起動したままです${NC}"
echo "  必要に応じて手動で閉じてください"

echo -e "\n${BLUE}=================================="
echo -e "✅ 全環境停止完了！"
echo -e "==================================${NC}"
echo
echo -e "${GREEN}確認コマンド:${NC}"
echo "  lsof -i :8080  # バックエンドポート確認"
echo "  lsof -i :5173  # フロントエンドポート確認"
echo "  lsof -i :3000  # Flutter Webポート確認"