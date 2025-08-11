#!/bin/bash

echo "🔄 API仕様書と型定義の自動生成開始..."

# 1. Swaggerドキュメント生成
cd backend
echo "📝 Swagger仕様書生成中..."
swag init -g main.go -o docs/ --parseInternal --parseDependency
if [ $? -ne 0 ]; then
    echo "❌ Swagger生成に失敗しました"
    exit 1
fi

# 2. フロントエンド型定義生成
cd ../frontend
echo "🔄 TypeScript型定義生成中..."
npx swagger-typescript-api generate -p ../backend/docs/swagger.json -o src/types/api --name api.ts --no-client

echo "✅ 生成完了！"
echo "📋 生成されたファイル:"
echo "  - backend/docs/swagger.json"
echo "  - backend/docs/swagger.yaml" 
echo "  - frontend/src/types/api/api.ts"