const { Pool } = require('pg');
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '../.env') });

const pool = new Pool({
  user: process.env.PGUSER || process.env.DB_USER || 'postgres',
  host: process.env.PGHOST || process.env.DB_HOST || 'localhost',
  database: process.env.PGDATABASE || process.env.DB_NAME || 'mess_finder',
  password: String(process.env.PGPASSWORD || process.env.DB_PASSWORD || 'mess1234'),
  port: parseInt(process.env.PGPORT || process.env.DB_PORT || '5432', 10),
  ssl: process.env.PGHOST ? { rejectUnauthorized: false } : false
});

pool.on('error', (err, client) => {
  console.error('Unexpected error on idle client', err);
  process.exit(-1);
});

module.exports = pool;
