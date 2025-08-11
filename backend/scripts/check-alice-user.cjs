require('dotenv').config({ path: require('path').join(__dirname, '../.env') });
const { MongoClient } = require('mongodb');

async function checkAliceUser() {
  console.log('🔍 Alice ユーザー状態確認\n');
  
  const client = new MongoClient(process.env.MONGODB_URI);
  
  try {
    await client.connect();
    console.log('✅ MongoDB Atlas 接続完了\n');
    
    const db = client.db(process.env.DB_NAME);
    const usersCollection = db.collection('users');
    
    // Alice関連のユーザーを全て検索
    console.log('📊 alice@yanwari.com 関連のユーザー:');
    const aliceUsers = await usersCollection.find({ 
      email: 'alice@yanwari.com' 
    }).toArray();
    
    if (aliceUsers.length === 0) {
      console.log('  ❌ ユーザーが見つかりません');
    } else {
      aliceUsers.forEach((user, index) => {
        console.log(`\n  [${index + 1}] ユーザー詳細:`);
        console.log(`    - ID: ${user._id}`);
        console.log(`    - 名前: ${user.name}`);
        console.log(`    - Firebase UID: ${user.firebaseUid || '(未設定)'}`);
        console.log(`    - 作成日: ${user.createdAt}`);
        console.log(`    - 更新日: ${user.updatedAt}`);
      });
    }
    
    // Firebase UID別の統計
    console.log('\n📊 Firebase UID別のユーザー数:');
    const uidStats = await usersCollection.aggregate([
      { $group: { 
        _id: '$firebaseUid', 
        count: { $sum: 1 },
        emails: { $push: '$email' }
      }},
      { $sort: { count: -1 } }
    ]).toArray();
    
    uidStats.forEach(stat => {
      const uid = stat._id || '(未設定)';
      console.log(`  - ${uid}: ${stat.count}人`);
      console.log(`    対象メール: ${stat.emails.join(', ')}`);
    });
    
    // 重複したFirebase UIDの検出
    console.log('\n⚠️  重複したFirebase UID:');
    const duplicates = uidStats.filter(stat => stat._id && stat.count > 1);
    if (duplicates.length === 0) {
      console.log('  ✅ 重複なし');
    } else {
      duplicates.forEach(dup => {
        console.log(`  - ${dup._id}: ${dup.count}人のユーザーで使用`);
      });
    }
    
  } catch (error) {
    console.error('❌ エラー:', error);
  } finally {
    await client.close();
    console.log('\n🔌 データベース接続を閉じました');
  }
}

checkAliceUser();