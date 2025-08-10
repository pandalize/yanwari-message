#\!/bin/bash

# Firebase認証でログインしてトークンを取得する簡易スクリプト
echo "テストメッセージを作成します..."

# 実際のFirebaseトークンが必要なので、ブラウザのコンソールから取得する必要があります
echo "ブラウザのコンソールで以下を実行してトークンを取得してください："
echo "await firebase.auth().currentUser.getIdToken()"
echo ""
echo "取得したトークンを環境変数に設定してください："
echo "export FIREBASE_TOKEN='取得したトークン'"
echo ""
echo "その後、以下のコマンドでテストメッセージを作成できます："
echo ""
echo "# メッセージ作成"
echo 'curl -X POST http://localhost:8080/api/v1/messages/draft \'
echo '  -H "Authorization: Bearer $FIREBASE_TOKEN" \'
echo '  -H "Content-Type: application/json" \'
echo '  -d "{"originalText":"テストメッセージです","recipientEmail":"あなたのメールアドレス"}"'

