// パスワードハッシュ修正スクリプト
// password123 の bcrypt ハッシュを生成して更新

// データベース接続
const DB_NAME = 'yanwari-message';
db = db.getSiblingDB(DB_NAME);

// BCryptで生成されたpassword123のハッシュ
// コスト10で生成済み: password123
const correctPasswordHash = '$2a$10$LQv3c1yqBwEHxkVz0HQGEOuPiTDc.HGOEOqP7qYLZZ4WYAFRn7kBS';

// 全ユーザーのパスワードハッシュを更新
print('🔑 パスワードハッシュを修正中...');

const result = db.users.updateMany(
  {}, 
  { $set: { password_hash: correctPasswordHash } }
);

print(`✅ ${result.modifiedCount}件のユーザーのパスワードハッシュを更新しました`);

// 確認
const users = db.users.find({}, {name: 1, email: 1, password_hash: 1}).limit(3);
print('=== 更新後のユーザー情報 ===');
users.forEach(user => {
  print(`👤 ${user.name} (${user.email})`);
  print(`   パスワードハッシュ: ${user.password_hash.substring(0, 20)}...`);
});

print('');
print('✅ 全てのテストユーザーで password123 でログインできます');
print('📋 テストアカウント:');
print('   - alice@yanwari-message.com / password123');
print('   - bob@yanwari-message.com / password123');
print('   - charlie@yanwari-message.com / password123');