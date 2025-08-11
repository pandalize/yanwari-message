require('dotenv').config({ path: require('path').join(__dirname, '../.env') });
const { MongoClient } = require('mongodb');
const admin = require('firebase-admin');

// Firebase Admin SDK初期化
if (!admin.apps.length) {
  admin.initializeApp({
    projectId: process.env.FIREBASE_PROJECT_ID || 'demo-yanwari-message',
  });
}

async function cleanupTestUsers() {
  console.log('🧹 テストユーザークリーンアップ開始\n');
  
  const client = new MongoClient(process.env.MONGODB_URI);
  
  try {
    // MongoDB接続
    await client.connect();
    console.log('✅ MongoDB Atlas 接続完了\n');
    
    const db = client.db(process.env.DB_NAME);
    const usersCollection = db.collection('users');
    
    // テスト用メールアドレス
    const testEmails = [
      'alice@yanwari.com',
      'bob@yanwari.com',
      'charlie@yanwari.com'
    ];
    
    // 1. Firebase UIDが未設定のテストユーザーを削除
    console.log('📊 Firebase UID未設定のテストユーザーを削除:');
    const deleteResult = await usersCollection.deleteMany({
      email: { $in: testEmails },
      $or: [
        { firebaseUid: null },
        { firebaseUid: '' },
        { firebaseUid: { $exists: false } }
      ]
    });
    console.log(`  ✅ ${deleteResult.deletedCount}人のユーザーを削除\n`);
    
    // 2. 正しいFirebase UIDを持つテストユーザーを保持/作成
    const testUsers = [
      {
        email: 'alice@yanwari.com',
        name: 'Alice テスター',
        firebaseUid: 'test_firebase_uid_001',
        password: '$2a$10$AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA',
        createdAt: new Date('2025-01-01T00:00:00Z'),
        updatedAt: new Date('2025-01-01T00:00:00Z')
      },
      {
        email: 'bob@yanwari.com',
        name: 'Bob テスター',
        firebaseUid: 'test_firebase_uid_002',
        password: '$2a$10$BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB',
        createdAt: new Date('2025-01-01T00:00:00Z'),
        updatedAt: new Date('2025-01-01T00:00:00Z')
      },
      {
        email: 'charlie@yanwari.com',
        name: 'Charlie テスター',
        firebaseUid: 'test_firebase_uid_003',
        password: '$2a$10$CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC',
        createdAt: new Date('2025-01-01T00:00:00Z'),
        updatedAt: new Date('2025-01-01T00:00:00Z')
      }
    ];
    
    console.log('📝 テストユーザーを更新/作成:');
    for (const user of testUsers) {
      const result = await usersCollection.replaceOne(
        { email: user.email },
        user,
        { upsert: true }
      );
      
      if (result.upsertedCount > 0) {
        console.log(`  ✅ ${user.email} を新規作成 (UID: ${user.firebaseUid})`);
      } else if (result.modifiedCount > 0) {
        console.log(`  ✅ ${user.email} を更新 (UID: ${user.firebaseUid})`);
      } else {
        console.log(`  ⏭️  ${user.email} は既に正しい状態`);
      }
    }
    
    // 3. Firebase Emulator のユーザーも同期
    console.log('\n🔥 Firebase Emulator ユーザーを同期:');
    
    // Firebase Auth Emulatorに接続
    process.env.FIREBASE_AUTH_EMULATOR_HOST = '127.0.0.1:9099';
    
    for (const user of testUsers) {
      try {
        // 既存ユーザーを削除
        try {
          await admin.auth().deleteUser(user.firebaseUid);
          console.log(`  🗑️  既存ユーザー ${user.email} を削除`);
        } catch (err) {
          // ユーザーが存在しない場合は無視
        }
        
        // 新しいユーザーを作成
        await admin.auth().createUser({
          uid: user.firebaseUid,
          email: user.email,
          displayName: user.name,
          password: 'testpassword123',
          emailVerified: true
        });
        console.log(`  ✅ ${user.email} を作成 (UID: ${user.firebaseUid})`);
      } catch (error) {
        console.log(`  ⚠️  ${user.email}: ${error.message}`);
      }
    }
    
    // 4. 最終確認
    console.log('\n📊 クリーンアップ後の状態:');
    const finalUsers = await usersCollection.find({ 
      email: { $in: testEmails } 
    }).toArray();
    
    finalUsers.forEach(user => {
      console.log(`  ✅ ${user.email} - Firebase UID: ${user.firebaseUid}`);
    });
    
    console.log('\n✨ クリーンアップ完了！');
    
  } catch (error) {
    console.error('❌ エラー:', error);
  } finally {
    await client.close();
    console.log('🔌 データベース接続を閉じました');
  }
}

cleanupTestUsers();