// 正しいbcryptハッシュでパスワード修正（最終版）

// データベース接続
const DB_NAME = 'yanwari-message';
db = db.getSiblingDB(DB_NAME);

print('🔑 正しいbcryptハッシュでパスワード修正中...');

// 実際のGoで生成されたbcryptハッシュ（password123用）
const correctHash = '$2a$10$267mmVDxCtcOxxZdsY7W2eor3GiVHheT58FUGnys/G0ApjERP11Ti';

// 全ユーザーのパスワードハッシュを正しいハッシュに更新
const result = db.users.updateMany(
  {}, 
  { $set: { password_hash: correctHash } }
);

print(`✅ ${result.modifiedCount}件のユーザーのパスワードハッシュを更新しました`);

// 確認
const users = db.users.find({}, {name: 1, email: 1, password_hash: 1}).limit(3);
print('=== 更新後のユーザー情報 ===');
users.forEach(user => {
  print(`👤 ${user.name} (${user.email})`);
  print(`   ハッシュ: ${user.password_hash.substring(0, 25)}...`);
});

print('');
print('✅ 全てのテストユーザーで password123 でログインできます');
print('📋 テストアカウント:');
print('   - alice@yanwari-message.com / password123');
print('   - bob@yanwari-message.com / password123');
print('   - charlie@yanwari-message.com / password123');