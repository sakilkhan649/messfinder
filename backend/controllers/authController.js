const pool = require('../config/db');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');

// Helper to generate JWT
const generateToken = (uid) => {
  return jwt.sign({ uid }, process.env.JWT_SECRET, { expiresIn: '30d' });
};

// Signup
exports.signup = async (req, res) => {
  const { name, phone, email, password, gender, role } = req.body;
  const crypto = require('crypto');

  try {
    // Check if user exists by email or phone
    const userCheck = await pool.query('SELECT * FROM users WHERE email = $1 OR phone = $2', [email, phone]);
    if (userCheck.rows.length > 0) {
      return res.status(400).json({ error: 'User with this email or phone already exists' });
    }

    // Hash password
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(password, salt);
    const uid = crypto.randomUUID();

    console.log('--- DBG ---');
    console.log('uid:', uid);
    console.log('password:', password);
    console.log('hashedPassword:', hashedPassword);
    console.log('-------------');

    const newUser = await pool.query(
      `INSERT INTO users (uid, name, phone, email, password, gender, role) 
       VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING *`,
      [uid, name, phone, email, hashedPassword, gender, role || 'bachelor']
    );

    const user = newUser.rows[0];
    delete user.password; // Don't return password

    const token = generateToken(user.uid);
    res.status(201).json({ user, token });
  } catch (error) {
    console.error('Signup error:', error);
    res.status(500).json({ error: 'Server error during signup' });
  }
};

// Login
exports.login = async (req, res) => {
  const { email, password } = req.body;

  try {
    const userResult = await pool.query('SELECT * FROM users WHERE email = $1', [email]);
    
    if (userResult.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }

    const user = userResult.rows[0];
    
    // Verify password
    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    delete user.password; // Don't return password

    const token = generateToken(user.uid);
    res.status(200).json({ user, token });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ error: 'Server error during login' });
  }
};

// Get User Profile (Current logged in user)
exports.getProfile = async (req, res) => {
  try {
    const userResult = await pool.query(
      'SELECT uid, name, phone, email, gender, role, status, profile_image, created_at, updated_at FROM users WHERE uid = $1',
      [req.user.uid]
    );
    if (userResult.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }
    res.status(200).json(userResult.rows[0]);
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
};

// Get Public User Profile by UID
exports.getUserById = async (req, res) => {
  try {
    const userResult = await pool.query(
      'SELECT uid, name, phone, email, gender, role, status, profile_image, created_at FROM users WHERE uid = $1',
      [req.params.uid]
    );
    if (userResult.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }
    res.status(200).json(userResult.rows[0]);
  } catch (error) {
    console.error('getUserById error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};

// Update Profile
exports.updateProfile = async (req, res) => {
  const { name, email, gender, profile_image, photoUrl, phone } = req.body;
  const imageToUse = profile_image || photoUrl;
  try {
    const updatedUser = await pool.query(
      `UPDATE users SET 
        name = COALESCE($1, name), 
        email = COALESCE($2, email), 
        gender = COALESCE($3, gender), 
        profile_image = COALESCE($4, profile_image),
        phone = COALESCE($5, phone),
        updated_at = CURRENT_TIMESTAMP
       WHERE uid = $6
       RETURNING uid, name, phone, email, gender, role, status, profile_image, created_at, updated_at`,
      [name, email, gender, imageToUse, phone, req.user.uid]
    );

    res.status(200).json(updatedUser.rows[0]);
  } catch (error) {
    console.error('Update profile error:', error);
    res.status(500).json({ error: 'Failed to update profile' });
  }
};

// Delete Account
exports.deleteAccount = async (req, res) => {
  try {
    const result = await pool.query(
      'DELETE FROM users WHERE uid = $1 RETURNING uid',
      [req.user.uid]
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }
    res.status(200).json({ message: 'Account deleted successfully' });
  } catch (error) {
    console.error('Delete account error:', error);
    res.status(500).json({ error: 'Failed to delete account' });
  }
};
