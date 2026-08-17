const pool = require('../config/db');

const clearAllAccounts = async () => {
  try {
    console.log('Connecting to database...');
    
    // Count existing users
    const countRes = await pool.query('SELECT COUNT(*) FROM users');
    console.log(`Found ${countRes.rows[0].count} users in the database.`);

    // Truncate users table and all referencing tables with CASCADE
    await pool.query('TRUNCATE TABLE users, posts, chats, messages, notifications, password_resets CASCADE;');
    
    console.log('✅ Successfully deleted all user accounts and associated records (posts, chats, messages, notifications, password resets).');
    process.exit(0);
  } catch (error) {
    console.error('❌ Error clearing accounts:', error);
    process.exit(1);
  }
};

clearAllAccounts();
