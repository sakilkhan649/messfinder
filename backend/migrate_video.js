const pool = require('./config/db');

async function migrate() {
  try {
    console.log('Adding video_url to products table...');
    await pool.query('ALTER TABLE products ADD COLUMN video_url TEXT;');
    console.log('Successfully added video_url to products table.');
  } catch (error) {
    if (error.code === '42701') {
      console.log('Column video_url already exists.');
    } else {
      console.error('Error:', error);
    }
  } finally {
    process.exit();
  }
}

migrate();
