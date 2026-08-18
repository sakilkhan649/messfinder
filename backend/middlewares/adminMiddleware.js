const pool = require('../config/db');

const adminMiddleware = async (req, res, next) => {
  try {
    if (!req.user || !req.user.uid) {
      return res.status(401).json({ error: 'Unauthorized, login required' });
    }

    const userResult = await pool.query('SELECT role, status FROM users WHERE uid = $1', [req.user.uid]);
    
    if (userResult.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }

    const user = userResult.rows[0];
    const role = (user.role || '').trim().toLowerCase();

    // Check if role is admin
    if (role !== 'admin') {
      return res.status(403).json({ error: 'Forbidden: Admin access required' });
    }

    if (user.status === 'banned' || user.status === 'suspended') {
      return res.status(403).json({ error: 'Account is restricted' });
    }

    next();
  } catch (error) {
    console.error('Admin middleware error:', error);
    res.status(500).json({ error: 'Server authorization check failed' });
  }
};

module.exports = adminMiddleware;
