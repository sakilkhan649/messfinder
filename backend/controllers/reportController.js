const pool = require('../config/db');

// Ensure reports table exists
const initReportsTable = async () => {
  try {
    await pool.query(`
      CREATE TABLE IF NOT EXISTS reports (
        id SERIAL PRIMARY KEY,
        reporter_uid VARCHAR(255) NOT NULL,
        post_id VARCHAR(255) NOT NULL,
        reason TEXT NOT NULL,
        details TEXT,
        status VARCHAR(50) DEFAULT 'pending',
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);
  } catch (err) {
    console.error('Error creating reports table:', err);
  }
};

initReportsTable();

exports.createReport = async (req, res) => {
  try {
    const { reporterUid, postId, reason, details } = req.body;

    if (!reporterUid || !postId || !reason) {
      return res.status(400).json({ error: 'Missing required fields' });
    }

    const result = await pool.query(
      `INSERT INTO reports (reporter_uid, post_id, reason, details) 
       VALUES ($1, $2, $3, $4) RETURNING *`,
      [reporterUid, postId, reason, details || '']
    );

    res.status(201).json(result.rows[0]);
  } catch (error) {
    console.error('Error creating report:', error);
    res.status(500).json({ error: 'Server error' });
  }
};
