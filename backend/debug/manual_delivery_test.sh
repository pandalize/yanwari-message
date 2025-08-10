#!/bin/bash

echo "🚀 Manual Delivery Service Test"
echo "================================"

# Test if the DeliverNow endpoint exists
echo "📡 Testing manual delivery endpoint..."

# Assuming you have JWT authentication
echo "First, let's try without authentication:"
curl -X POST http://localhost:8080/api/v1/delivery/now \
  -H "Content-Type: application/json" \
  2>/dev/null || echo "Endpoint may not exist or requires authentication"

echo ""
echo "📋 Alternative: Check server logs for delivery service status"
echo "Look for messages like:"
echo "  - '配信エンジンを開始しました（間隔: 1m0s）'"  
echo "  - '🔍 スケジュール配信チェック開始'"
echo "  - '📋 配信対象メッセージ: X件'"