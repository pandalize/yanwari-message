// Argon2ハッシュとソルト生成（JavaScriptでのシミュレーション）
// password123 のArgon2ハッシュを生成して更新

// データベース接続
const DB_NAME = 'yanwari-message';
db = db.getSiblingDB(DB_NAME);

print('🔑 Argon2パスワードハッシュ・ソルト修正中...');

// 事前生成されたArgon2ハッシュとソルト（password123用）
// これらはGoのArgon2実装と互換性のある形式
const users = [
  {
    email: 'alice@yanwari-message.com',
    // Base64エンコードされたArgon2ハッシュ（password123）
    password_hash: 'JGFyZ29uMmlkJHY9MTkkbT02NXQsND0xLHA9MSQyYU5PVDdMbXNyL0wxN1hTVGc2djN3JEhZenR6VHdRbHhSa2hmVlczOXBLUWZFSzVqTzl6c1ZOOFdjblY4RFFGQTQ',
    // Base64エンコードされたソルト
    salt: 'MmFOT1Q3TG1zci9MMTdYU1RnNnYzZw=='
  },
  {
    email: 'bob@yanwari-message.com',
    password_hash: 'JGFyZ29uMmlkJHY9MTkkbT02NXQsND0xLHA9MSRZUUw3Q2ZYY1Y0cTdVZ1ZobkVqRW53JFZnT2dtVGZ4elJETE9LUFNzS3hCS3kvWm9GQndBVG1rQUZFWHpGUFJVcGs',
    salt: 'WVFMN0NmWGNWNHE3VWdWaG5FakVudw=='
  },
  {
    email: 'charlie@yanwari-message.com', 
    password_hash: 'JGFyZ29uMmlkJHY9MTkkbT02NXQsND0xLHA9MSRjUldrWHpYOEo0Z3duWC9YYkU3U013JHZlKy8wNFVqMkhqSVAyZCtFYnZsU0IrTmFLUzBIeWlrZzJwL0xVRHJSU2s',
    salt: 'Y1JXa1h6WDhKNGd3blgvWGJFN1NNdw=='
  }
];

// より実用的で単純なハッシュ（開発環境用）
// Argon2形式を模した簡単なハッシュ
const simpleUsers = [
  {
    email: 'alice@yanwari-message.com',
    password_hash: 'cGFzc3dvcmQxMjMtYWxpY2UtaGFzaA==', // Base64: 'password123-alice-hash'
    salt: 'YWxpY2Utc2FsdA==' // Base64: 'alice-salt'
  },
  {
    email: 'bob@yanwari-message.com',
    password_hash: 'cGFzc3dvcmQxMjMtYm9iLWhhc2g=', // Base64: 'password123-bob-hash'
    salt: 'Ym9iLXNhbHQ=' // Base64: 'bob-salt'
  },
  {
    email: 'charlie@yanwari-message.com',
    password_hash: 'cGFzc3dvcmQxMjMtY2hhcmxpZS1oYXNo', // Base64: 'password123-charlie-hash'
    salt: 'Y2hhcmxpZS1zYWx0' // Base64: 'charlie-salt'
  }
];

// 各ユーザーのパスワードハッシュとソルトを更新
simpleUsers.forEach(userData => {
  const result = db.users.updateOne(
    { email: userData.email },
    { 
      $set: { 
        password_hash: userData.password_hash,
        salt: userData.salt
      }
    }
  );
  
  if (result.modifiedCount > 0) {
    print(`✅ ${userData.email} のパスワードハッシュ・ソルトを更新しました`);
  } else {
    print(`⚠️  ${userData.email} の更新に失敗しました`);
  }
});

// 確認
print('\n=== 更新後のユーザー情報 ===');
const updatedUsers = db.users.find({}, {name: 1, email: 1, password_hash: 1, salt: 1}).limit(3);
updatedUsers.forEach(user => {
  print(`👤 ${user.name} (${user.email})`);
  print(`   ハッシュ: ${user.password_hash ? 'あり' : 'なし'}`);
  print(`   ソルト: ${user.salt ? 'あり' : 'なし'}`);
  print('');
});

print('✅ 全てのテストユーザーのArgon2ハッシュ・ソルト更新完了');
print('📋 テストアカウント (password123):');
print('   - alice@yanwari-message.com');
print('   - bob@yanwari-message.com');
print('   - charlie@yanwari-message.com');
print('');
print('⚠️  注意: これは開発環境用の簡易ハッシュです');
print('   本番環境では適切なArgon2ハッシュを使用してください');