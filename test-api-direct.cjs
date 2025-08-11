const { MongoClient, ObjectId } = require('mongodb');
require('dotenv').config();

async function testAPI() {
  const client = new MongoClient(process.env.MONGODB_URI);
  
  try {
    console.log('🔍 送信済みメッセージのデータ構造確認...\n');
    
    await client.connect();
    const db = client.db('yanwari-message');
    const messagesCollection = db.collection('messages');
    
    // 送信済みメッセージの確認
    const messages = await messagesCollection.find({
      status: { $in: ['sent', 'delivered', 'read'] }
    }).limit(5).toArray();
    
    console.log(`📬 送信済みメッセージ数: ${messages.length}`);
    
    if (messages.length > 0) {
      console.log('\n📝 メッセージ詳細:');
      messages.forEach((msg, index) => {
        console.log(`\n--- メッセージ ${index + 1} ---`);
        console.log(`  ID: ${msg._id}`);
        console.log(`  送信者ID: ${msg.senderId}`);
        console.log(`  受信者ID: ${msg.recipientId}`);
        console.log(`  ステータス: ${msg.status}`);
        console.log(`  送信日時: ${msg.sentAt || msg.updatedAt}`);
        console.log(`  元テキスト: ${(msg.originalText || '').substring(0, 50)}...`);
        console.log(`  最終テキスト: ${(msg.finalText || '').substring(0, 50)}...`);
      });
    }
    
    // 集約パイプラインのテスト（backendのGetSentMessagesと同様）
    console.log('\n🔗 集約パイプラインテスト:');
    
    const pipeline = [
      {
        $match: {
          status: { $in: ['sent', 'delivered', 'read'] }
        }
      },
      {
        $lookup: {
          from: 'users',
          localField: 'recipientId',
          foreignField: '_id',
          as: 'recipient'
        }
      },
      {
        $unwind: {
          path: '$recipient',
          preserveNullAndEmptyArrays: true
        }
      },
      {
        $addFields: {
          recipientName: {
            $ifNull: [
              '$recipient.name',
              {
                $ifNull: [
                  {
                    $arrayElemAt: [
                      { $split: ['$recipient.email', '@'] },
                      0
                    ]
                  },
                  'Unknown User'
                ]
              }
            ]
          },
          recipientEmail: {
            $ifNull: ['$recipient.email', 'unknown@example.com']
          }
        }
      },
      { $limit: 5 }
    ];
    
    const aggregatedMessages = await messagesCollection.aggregate(pipeline).toArray();
    console.log(`📊 集約結果: ${aggregatedMessages.length} 件`);
    
    if (aggregatedMessages.length > 0) {
      console.log('\n📋 集約されたメッセージ:');
      aggregatedMessages.forEach((msg, index) => {
        console.log(`\n--- 集約メッセージ ${index + 1} ---`);
        console.log(`  ID: ${msg._id}`);
        console.log(`  受信者名: ${msg.recipientName}`);
        console.log(`  受信者メール: ${msg.recipientEmail}`);
        console.log(`  ステータス: ${msg.status}`);
      });
    }
    
  } catch (error) {
    console.error('❌ エラー:', error);
  } finally {
    await client.close();
  }
}

testAPI();