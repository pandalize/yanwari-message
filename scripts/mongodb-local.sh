#!/bin/bash

# ローカルMongoDB管理スクリプト

set -e

# 色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# プロジェクトルートに移動
cd "$(dirname "$0")/.."

function start_mongodb() {
    echo -e "${BLUE}🚀 ローカルMongoDB起動中...${NC}"
    
    # Docker Composeで起動
    docker-compose up -d mongodb mongo-express
    
    # 起動待機
    echo -e "${YELLOW}⏳ MongoDB起動待機中...${NC}"
    for i in {1..30}; do
        if docker exec yanwari-mongodb mongosh --eval "db.adminCommand('ping')" &>/dev/null; then
            echo -e "${GREEN}✅ MongoDB起動完了！${NC}"
            echo -e "${GREEN}📊 Mongo Express: http://localhost:8081${NC}"
            return 0
        fi
        sleep 1
        echo -n "."
    done
    
    echo -e "${RED}❌ MongoDB起動タイムアウト${NC}"
    return 1
}

function stop_mongodb() {
    echo -e "${BLUE}🛑 ローカルMongoDB停止中...${NC}"
    docker-compose down
    echo -e "${GREEN}✅ MongoDB停止完了${NC}"
}

function reset_mongodb() {
    echo -e "${YELLOW}⚠️  MongoDBデータをリセットしますか？ (y/N)${NC}"
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        echo -e "${RED}🗑️  MongoDBデータ削除中...${NC}"
        docker-compose down -v
        echo -e "${GREEN}✅ リセット完了${NC}"
    else
        echo "キャンセルしました"
    fi
}

function seed_mongodb() {
    echo -e "${BLUE}🌱 テストデータ投入中...${NC}"
    
    # 環境変数を一時的にローカルに設定
    export MONGODB_URI="mongodb://admin:password123@localhost:27017/yanwari-message?authSource=admin"
    
    # 既存のシードスクリプトを実行
    cd backend
    node scripts/db-seed.cjs --local
    cd ..
    
    echo -e "${GREEN}✅ テストデータ投入完了${NC}"
}

function status_mongodb() {
    echo -e "${BLUE}📊 MongoDB状態確認${NC}"
    
    if docker ps | grep -q yanwari-mongodb; then
        echo -e "${GREEN}✅ MongoDB: 起動中${NC}"
        
        # 接続テスト
        if docker exec yanwari-mongodb mongosh --eval "db.adminCommand('ping')" &>/dev/null; then
            echo -e "${GREEN}✅ 接続: 正常${NC}"
            
            # データベース情報取得
            docker exec yanwari-mongodb mongosh yanwari-message --eval "
                print('データベース統計:');
                print('- Users: ' + db.users.countDocuments());
                print('- Messages: ' + db.messages.countDocuments());
                print('- Schedules: ' + db.schedules.countDocuments());
            " --quiet 2>/dev/null || echo "データベース情報取得失敗"
        else
            echo -e "${RED}❌ 接続: 失敗${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  MongoDB: 停止中${NC}"
    fi
    
    if docker ps | grep -q yanwari-mongo-express; then
        echo -e "${GREEN}✅ Mongo Express: http://localhost:8081${NC}"
    fi
}

# メインメニュー
case "${1:-}" in
    start)
        start_mongodb
        ;;
    stop)
        stop_mongodb
        ;;
    restart)
        stop_mongodb
        start_mongodb
        ;;
    reset)
        reset_mongodb
        ;;
    seed)
        seed_mongodb
        ;;
    status)
        status_mongodb
        ;;
    *)
        echo "使用方法: $0 {start|stop|restart|reset|seed|status}"
        echo ""
        echo "コマンド:"
        echo "  start   - MongoDBを起動"
        echo "  stop    - MongoDBを停止"
        echo "  restart - MongoDBを再起動"
        echo "  reset   - MongoDBデータをリセット"
        echo "  seed    - テストデータを投入"
        echo "  status  - MongoDB状態確認"
        exit 1
        ;;
esac