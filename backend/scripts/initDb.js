const pool = require('../config/db');

const initSql = `
  CREATE TABLE IF NOT EXISTS users (
    uid VARCHAR(255) PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    phone VARCHAR(20) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE,
    password TEXT NOT NULL,
    gender VARCHAR(20),
    role VARCHAR(50) DEFAULT 'bachelor',
    status VARCHAR(50) DEFAULT 'active',
    fcm_token VARCHAR(255),
    profile_image TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
  );

  CREATE TABLE IF NOT EXISTS posts (
    post_id SERIAL PRIMARY KEY,
    owner_uid VARCHAR(255) REFERENCES users(uid) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    rent NUMERIC(10, 2) NOT NULL,
    address TEXT NOT NULL,
    latitude NUMERIC(10, 6) DEFAULT 23.8103,
    longitude NUMERIC(10, 6) DEFAULT 90.4125,
    images JSONB DEFAULT '[]',
    video_url TEXT,
    seat_count INTEGER DEFAULT 1,
    seat_description VARCHAR(255),
    division VARCHAR(100) DEFAULT 'Dhaka',
    district VARCHAR(100) DEFAULT 'Dhaka',
    bachelor_type VARCHAR(50) DEFAULT 'male',
    preferred_tenant VARCHAR(100) DEFAULT 'Student / Job holder',
    facilities JSONB DEFAULT '[]',
    is_available BOOLEAN DEFAULT true,
    is_published BOOLEAN DEFAULT true,
    payment_status VARCHAR(50) DEFAULT 'approved',
    payment_trx_id VARCHAR(100),
    sender_number VARCHAR(20),
    owner_phone VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
  );

  CREATE TABLE IF NOT EXISTS chats (
    chat_id VARCHAR(255) PRIMARY KEY,
    user1_uid VARCHAR(255) REFERENCES users(uid) ON DELETE CASCADE,
    user2_uid VARCHAR(255) REFERENCES users(uid) ON DELETE CASCADE,
    last_message TEXT,
    last_message_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
  );

  CREATE TABLE IF NOT EXISTS messages (
    message_id SERIAL PRIMARY KEY,
    chat_id VARCHAR(255) REFERENCES chats(chat_id) ON DELETE CASCADE,
    sender_uid VARCHAR(255) REFERENCES users(uid) ON DELETE CASCADE,
    text TEXT,
    image_url TEXT,
    video_url TEXT,
    is_read BOOLEAN DEFAULT false,
    is_edited BOOLEAN DEFAULT false,
    is_deleted BOOLEAN DEFAULT false,
    reactions JSONB DEFAULT '{}',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
  );

  CREATE TABLE IF NOT EXISTS notifications (
    id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    body TEXT NOT NULL,
    type VARCHAR(100),
    receiver_uid VARCHAR(255) NOT NULL,
    sender_uid VARCHAR(255),
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
  );

  -- Ensure missing columns exist in case tables were previously created
  ALTER TABLE messages ADD COLUMN IF NOT EXISTS is_edited BOOLEAN DEFAULT false;
  ALTER TABLE messages ADD COLUMN IF NOT EXISTS is_deleted BOOLEAN DEFAULT false;
  ALTER TABLE messages ADD COLUMN IF NOT EXISTS reactions JSONB DEFAULT '{}';
  ALTER TABLE posts ADD COLUMN IF NOT EXISTS video_url TEXT;
  ALTER TABLE posts ADD COLUMN IF NOT EXISTS seat_description VARCHAR(255);
`;

const setupDatabase = async () => {
  try {
    console.log('Initializing database tables & migrations...');
    await pool.query(initSql);
    console.log('Database tables & migrations executed successfully!');
    process.exit(0);
  } catch (error) {
    console.error('Error creating database tables:', error);
    process.exit(1);
  }
};

setupDatabase();
