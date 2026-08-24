const pool = require('./config/db');

async function clearData() {
  try {
    console.log('Starting data wipe...');

    // 1. Truncate all tables in PostgreSQL
    console.log('Clearing PostgreSQL tables...');
    const tables = ['users', 'posts', 'products', 'chats', 'messages', 'notifications', 'bookings', 'comments', 'likes', 'post_likes', 'post_comments'];
    for (const table of tables) {
      try {
        await pool.query(`TRUNCATE TABLE ${table} CASCADE;`);
        console.log(`- Cleared ${table}`);
      } catch (e) {
        console.log(`- Skipped ${table} (might not exist)`);
      }
    }
    
    // 2. Delete all users from Firebase Auth
    console.log('Clearing Firebase Auth users...');
    try {
      const serviceAccount = require('./config/firebase-service-account.json');
      const { initializeApp, cert, getApps } = require('firebase-admin/app');
      const { getAuth } = require('firebase-admin/auth');

      if (!getApps().length) {
        initializeApp({
          credential: cert(serviceAccount)
        });
      }

      let listUsersResult = await getAuth().listUsers();
      let users = listUsersResult.users;
      while (users.length > 0) {
        const uids = users.map(user => user.uid);
        await getAuth().deleteUsers(uids);
        console.log(`- Deleted ${uids.length} users from Firebase Auth`);
        
        if (listUsersResult.pageToken) {
          listUsersResult = await getAuth().listUsers(1000, listUsersResult.pageToken);
          users = listUsersResult.users;
        } else {
          break;
        }
      }
    } catch (e) {
      console.log('Skipping Firebase Auth clear (admin not initialized or error):', e.message);
    }

    console.log('✅ All data cleared successfully!');
    process.exit(0);
  } catch (err) {
    console.error('Error clearing data:', err);
    process.exit(1);
  }
}

clearData();
