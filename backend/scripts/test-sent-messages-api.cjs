const { MongoClient } = require('mongodb');
const http = require('http');
require('dotenv').config();

const MONGODB_URI = process.env.MONGODB_URI;
const TEST_USER_EMAIL = 'test-user@example.com';

async function testSentMessagesAPI() {
  const client = new MongoClient(MONGODB_URI);
  
  try {
    console.log('🔍 送信済みメッセージAPIテスト開始...\n');
    
    // MongoDB接続
    await client.connect();
    const db = client.db('yanwari-message');
    const usersCollection = db.collection('users');
    const messagesCollection = db.collection('messages');
    
    // テストユーザー確認
    const testUser = await usersCollection.findOne({ email: TEST_USER_EMAIL });
    if (!testUser) {
      console.error('❌ テストユーザーが見つかりません');
      return;
    }
    
    console.log('👤 テストユーザー:', {
      id: testUser._id,
      email: testUser.email,
      name: testUser.name,
      firebaseUid: testUser.firebaseUid
    });
    
    // 送信済みメッセージ確認
    const sentMessages = await messagesCollection.find({
      senderId: testUser._id,
      status: { $in: ['sent', 'delivered', 'read'] }
    }).toArray();
    
    console.log('\n📬 送信済みメッセージ数:', sentMessages.length);
    
    if (sentMessages.length > 0) {
      console.log('\n送信メッセージ詳細:');
      for (const msg of sentMessages) {
        console.log(`  - ID: ${msg._id}`);
        console.log(`    受信者ID: ${msg.recipientId}`);
        console.log(`    ステータス: ${msg.status}`);
        console.log(`    送信日時: ${msg.sentAt || msg.updatedAt}`);
        
        // 受信者情報を取得
        if (msg.recipientId) {
          const recipient = await usersCollection.findOne({ _id: msg.recipientId });
          if (recipient) {
            console.log(`    受信者名: ${recipient.name || recipient.email}`);
            console.log(`    受信者メール: ${recipient.email}`);
          } else {
            console.log(`    ⚠️ 受信者情報が見つかりません`);
          }
        }
        console.log('');
      }
    }
    
    // API呼び出しテスト
    console.log('\n🔗 送信済みメッセージAPI呼び出しテスト...');
    
    // Firebaseトークン取得のためFirebase Emulatorでログイン
    const firebaseAuth = require('firebase/auth');
    const { initializeApp } = require('firebase/app');
    
    const firebaseConfig = {
      apiKey: "test-api-key",
      authDomain: "test-project.firebaseapp.com",
      projectId: "test-project",
      storageBucket: "test-project.appspot.com",
      messagingSenderId: "123456789",
      appId: "1:123456789:web:abcdef123456"
    };
    
    const app = initializeApp(firebaseConfig);
    const auth = firebaseAuth.getAuth(app);
    firebaseAuth.connectAuthEmulator(auth, 'http://localhost:9099');
    
    try {
      // Firebaseでログイン
      const userCredential = await firebaseAuth.signInWithEmailAndPassword(
        auth, 
        TEST_USER_EMAIL, 
        'testpassword123'
      );
      const idToken = await userCredential.user.getIdToken();
      
      // API呼び出し
      const options = {
        hostname: 'localhost',
        port: 8080,
        path: '/api/v1/messages/sent?page=1&limit=100',
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
      
      console.log('\nAPIレスポンス:');
      console.log('  ステータス:', apiResponse.status);
      console.log('  メッセージ数:', apiResponse.data?.messages?.length || 0);
      
      if (apiResponse.data?.messages?.length > 0) {
        console.log('\n  メッセージ詳細:');
        apiResponse.data.messages.forEach(msg => {
          console.log(`    - ID: ${msg.id || msg._id}`);
          console.log(`      受信者ID: ${msg.recipientId}`);
          console.log(`      受信者名: ${msg.recipientName || 'Unknown'}`);
          console.log(`      受信者メール: ${msg.recipientEmail || 'Unknown'}`);
          console.log('');
        });
      }
      
    } catch (error) {
      console.error('❌ API呼び出しエラー:', error.message);
    }
    
  } catch (error) {
    console.error('❌ エラー:', error);
  } finally {
    await client.close();
  }
}

testSentMessagesAPI();