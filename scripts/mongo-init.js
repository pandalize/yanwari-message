// MongoDB初期化スクリプト
// データベース: yanwari-message

// デフォルトのデータベースに切り替え
db = db.getSiblingDB('yanwari-message');

// コレクションの作成（インデックス付き）
print('🚀 やんわり伝言サービス - MongoDB初期化開始');

// ユーザーコレクション
db.createCollection('users');
db.users.createIndex({ "email": 1 }, { unique: true });
db.users.createIndex({ "name": "text" });
print('✅ usersコレクション作成完了');

// メッセージコレクション
db.createCollection('messages');
db.messages.createIndex({ "sender_id": 1, "created_at": -1 });
db.messages.createIndex({ "recipient_id": 1, "created_at": -1 });
db.messages.createIndex({ "status": 1, "scheduled_at": 1 });
print('✅ messagesコレクション作成完了');

// ユーザー設定コレクション
db.createCollection('user_settings');
db.user_settings.createIndex({ "user_id": 1 }, { unique: true });
print('✅ user_settingsコレクション作成完了');

// 友達申請コレクション
db.createCollection('friend_requests');
db.friend_requests.createIndex({ "sender_id": 1, "recipient_id": 1 }, { unique: true });
db.friend_requests.createIndex({ "recipient_id": 1, "status": 1 });
print('✅ friend_requestsコレクション作成完了');

// 友達関係コレクション
db.createCollection('friendships');
db.friendships.createIndex({ "user1_id": 1, "user2_id": 1 }, { unique: true });
print('✅ friendshipsコレクション作成完了');

// メッセージ評価コレクション
db.createCollection('message_ratings');
db.message_ratings.createIndex({ "message_id": 1, "user_id": 1 }, { unique: true });
print('✅ message_ratingsコレクション作成完了');

// スケジュールコレクション
db.createCollection('schedules');
db.schedules.createIndex({ "message_id": 1 }, { unique: true });
db.schedules.createIndex({ "scheduled_at": 1, "status": 1 });
print('✅ schedulesコレクション作成完了');

print('🎉 MongoDB初期化完了 - 全てのコレクションとインデックスが作成されました');

// 開発用のテストデータ（オプション）
if (db.users.countDocuments() === 0) {
    print('📝 開発用テストデータを作成中...');
    
    // テスト用ユーザーを作成
    const testUser = {
        name: "開発用テストユーザー",
        email: "dev@yanwari-message.com", 
        password_hash: "$2a$10$example.hashed.password.here",
        timezone: "Asia/Tokyo",
        created_at: new Date(),
        updated_at: new Date()
    };
    
    db.users.insertOne(testUser);
    print('✅ 開発用テストユーザー作成完了');
}