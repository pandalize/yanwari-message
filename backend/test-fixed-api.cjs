const { MongoClient } = require('mongodb');
const http = require('http');
const firebaseAuth = require('firebase/auth');
const { initializeApp } = require('firebase/app');
require('dotenv').config();

async function testFixedAPI() {
  console.log('🔧 修正版APIテスト開始...\n');
  
  try {
    // Firebaseログイン
    const firebaseConfig = {
      apiKey: "test-api-key",
      authDomain: "test-project.firebaseapp.com",
      projectId: "test-project",
    };
    
    const app = initializeApp(firebaseConfig);
    const auth = firebaseAuth.getAuth(app);
    firebaseAuth.connectAuthEmulator(auth, 'http://localhost:9099');
    
    // Alice でログイン
    const userCredential = await firebaseAuth.signInWithEmailAndPassword(
      auth, 
      'alice@yanwari.com', 
      'testpassword123'
    );
    const idToken = await userCredential.user.getIdToken();
    console.log('🔐 Firebase認証成功\n');
    
    // API呼び出し
    const options = {
      hostname: 'localhost',
      port: 8080,
      path: '/api/v1/messages/sent?page=1&limit=5',
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${idToken}`,
        'Content-Type': 'application/json'
      }
    };
    
    const apiResponse = await new Promise((resolve, reject) => {
      const req = http.request(options, (res) => {
        let data = '';
        res.on('data', (chunk) => { data += chunk; });
        res.on('end', () => {
          try {
            resolve(JSON.parse(data));
          } catch (e) {
            reject(e);
          }
        });
      });
      req.on('error', reject);
      req.end();
    });
    
    console.log('📡 APIレスポンス:');
    console.log('  ステータス:', apiResponse.status || 'no status');
    console.log('  メッセージ:', apiResponse.message || 'no message');
    
    if (apiResponse.data && apiResponse.data.messages) {
      console.log('  送信済みメッセージ数:', apiResponse.data.messages.length);
      console.log('\n📋 詳細:');
      
      apiResponse.data.messages.forEach((msg, index) => {
        console.log('\n--- メッセージ', index + 1, '---');
        console.log('  ID:', msg.id || msg._id || 'NO ID');
        console.log('  受信者ID:', msg.recipientId || 'NO RECIPIENT');
        console.log('  受信者名:', msg.recipientName || 'NO NAME');
        console.log('  受信者メール:', msg.recipientEmail || 'NO EMAIL');
        console.log('  ステータス:', msg.status);
        console.log('  送信日時:', msg.sentAt || msg.updatedAt);
        
        // IDの型を確認
        const msgId = msg.id || msg._id;
        if (msgId) {
          console.log('  ID型:', typeof msgId);
          console.log('  ID値:', msgId);
          if (msgId === '000000000000000000000000') {
            console.log('  ⚠️ 無効なObjectIDが検出されました！');
          }
        } else {
          console.log('  ⚠️ IDフィールドが見つかりません');
        }
      });
    } else {
      console.log('  ⚠️ メッセージデータがありません');
      console.log('  レスポンス全体:', JSON.stringify(apiResponse, null, 2));
    }
    
  } catch (error) {
    console.error('❌ テストエラー:', error.message);
  }
}

testFixedAPI();