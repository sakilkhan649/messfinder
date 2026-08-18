const pool = require('../config/db');
const bcrypt = require('bcrypt');
const { v4: uuidv4 } = require('uuid');

async function createOrUpdateAdmin() {
  const adminEmail = 'admin@messfinder.com';
  const adminPhone = '01700000000';
  const adminPass = 'admin123456';
  const adminName = 'System Admin';
  const adminRole = 'admin';

  try {
    console.log('🔄 Checking existing admin user...');
    const existing = await pool.query(
      'SELECT * FROM users WHERE LOWER(email) = LOWER($1) OR phone = $2',
      [adminEmail, adminPhone]
    );

    const hashedPassword = await bcrypt.hash(adminPass, 10);

    if (existing.rows.length > 0) {
      const user = existing.rows[0];
      console.log(`ℹ️ User found (UID: ${user.uid}). Updating to Admin role and resetting password...`);
      await pool.query(
        `UPDATE users 
         SET name = $1, email = $2, phone = $3, password = $4, role = $5, status = 'active', updated_at = CURRENT_TIMESTAMP
         WHERE uid = $6`,
        [adminName, adminEmail, adminPhone, hashedPassword, adminRole, user.uid]
      );
      console.log('✅ Admin user updated successfully!');
    } else {
      const uid = 'admin_' + uuidv4().replace(/-/g, '').substring(0, 16);
      console.log(`ℹ️ Creating new Admin user (UID: ${uid})...`);
      await pool.query(
        `INSERT INTO users (uid, name, email, phone, password, gender, role, status)
         VALUES ($1, $2, $3, $4, $5, 'male', $6, 'active')`,
        [uid, adminName, adminEmail, adminPhone, hashedPassword, adminRole]
      );
      console.log('✅ New Admin user created successfully!');
    }

    console.log('\n=============================================');
    console.log('       👑 ADMIN LOGIN CREDENTIALS 👑');
    console.log('=============================================');
    console.log(`📧 Email:    ${adminEmail}`);
    console.log(`📱 Phone:    ${adminPhone}`);
    console.log(`🔑 Password: ${adminPass}`);
    console.log(`🛡️ Role:     ${adminRole}`);
    console.log('=============================================\n');

    process.exit(0);
  } catch (error) {
    console.error('❌ Error creating admin user:', error);
    process.exit(1);
  }
}

createOrUpdateAdmin();
