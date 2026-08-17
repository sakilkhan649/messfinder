const pool = require('../config/db');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const nodemailer = require('nodemailer');

// Helper to generate JWT
const generateToken = (uid) => {
  return jwt.sign({ uid }, process.env.JWT_SECRET, { expiresIn: '30d' });
};

// Mail transporter helper (uses environment SMTP or falls back to console logging)
const sendEmailOtp = async (toEmail, otp) => {
  try {
    const smtpHost = process.env.SMTP_HOST;
    const smtpPort = process.env.SMTP_PORT || 587;
    const smtpUser = process.env.SMTP_USER || process.env.EMAIL_USER;
    const smtpPass = process.env.SMTP_PASS || process.env.EMAIL_PASS;

    if (smtpUser && smtpPass) {
      const transporter = nodemailer.createTransport({
        service: 'gmail',
        auth: {
          user: smtpUser,
          pass: smtpPass,
        },
      });

      await transporter.sendMail({
        from: `"Mess Finder Support" <${smtpUser}>`,
        to: toEmail,
        subject: 'Password Reset OTP - Mess Finder',
        html: `
          <div style="font-family: Arial, sans-serif; max-width: 500px; margin: 0 auto; padding: 20px; border: 1px solid #e0e0e0; border-radius: 10px;">
            <h2 style="color: #059669; text-align: center;">Mess Finder</h2>
            <p>Hello,</p>
            <p>You requested to reset your password. Use the following 6-digit OTP code to complete the reset process:</p>
            <div style="text-align: center; margin: 24px 0;">
              <span style="font-size: 32px; font-weight: bold; letter-spacing: 6px; color: #059669; background: #f0fdf4; padding: 12px 24px; border-radius: 8px; border: 1px dashed #059669;">${otp}</span>
            </div>
            <p style="color: #666; font-size: 13px;">This code is valid for 10 minutes. If you did not request this, please ignore this email.</p>
            <hr style="border: none; border-top: 1px solid #eee; margin: 20px 0;" />
            <p style="font-size: 12px; color: #999; text-align: center;">Mess Finder Team</p>
          </div>
        `,
      });
      console.log(`[EMAIL] OTP sent to ${toEmail} via SMTP.`);
    } else {
      console.log('\n======================================================');
      console.log(`🔑 [PASSWORD RESET OTP] For ${toEmail}: 👉 ${otp} 👈`);
      console.log('======================================================\n');
    }
  } catch (err) {
    console.error('Error sending email via nodemailer:', err);
    console.log('\n======================================================');
    console.log(`🔑 [FALLBACK OTP] For ${toEmail}: 👉 ${otp} 👈`);
    console.log('======================================================\n');
  }
};

// Signup
exports.signup = async (req, res) => {
  const { name, phone, email, password, gender, role } = req.body;
  const crypto = require('crypto');

  try {
    const userCheck = await pool.query('SELECT * FROM users WHERE email = $1 OR phone = $2', [email, phone]);
    if (userCheck.rows.length > 0) {
      return res.status(400).json({ error: 'User with this email or phone already exists' });
    }

    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(password, salt);
    const uid = crypto.randomUUID();

    const newUser = await pool.query(
      `INSERT INTO users (uid, name, phone, email, password, gender, role) 
       VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING *`,
      [uid, name, phone, email, hashedPassword, gender || null, role || 'bachelor']
    );

    const user = newUser.rows[0];
    delete user.password;

    const token = generateToken(user.uid);
    res.status(201).json({ user, token });
  } catch (error) {
    console.error('Signup error:', error);
    res.status(500).json({ error: 'Server error during signup' });
  }
};

// Login (Supports Email OR Phone Number)
exports.login = async (req, res) => {
  const { email, password } = req.body;

  try {
    const userResult = await pool.query(
      'SELECT * FROM users WHERE email = $1 OR phone = $1',
      [email]
    );
    
    if (userResult.rows.length === 0) {
      return res.status(404).json({ error: 'Invalid email or password' });
    }

    const user = userResult.rows[0];
    
    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    delete user.password;

    const token = generateToken(user.uid);
    res.status(200).json({ user, token });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ error: 'Server error during login' });
  }
};

// Google Sign-In Login & Auto-Registration
exports.googleLogin = async (req, res) => {
  const { email, name, profileImage, googleId, role } = req.body;

  if (!email) {
    return res.status(400).json({ error: 'Email is required for Google Sign-In' });
  }

  const cleanEmail = email.trim().toLowerCase();
  const crypto = require('crypto');

  try {
    const userResult = await pool.query('SELECT * FROM users WHERE LOWER(email) = $1', [cleanEmail]);

    let user;
    if (userResult.rows.length > 0) {
      user = userResult.rows[0];

      if ((!user.profile_image && profileImage) || (!user.google_id && googleId)) {
        const updateRes = await pool.query(
          `UPDATE users SET 
            profile_image = COALESCE(profile_image, $1), 
            google_id = COALESCE(google_id, $2),
            updated_at = CURRENT_TIMESTAMP
           WHERE uid = $3 RETURNING *`,
          [profileImage, googleId, user.uid]
        );
        user = updateRes.rows[0];
      }
    } else {
      const uid = crypto.randomUUID();
      const newRole = role || 'bachelor';

      const insertRes = await pool.query(
        `INSERT INTO users (uid, name, email, profile_image, google_id, role, status)
         VALUES ($1, $2, $3, $4, $5, $6, 'active') RETURNING *`,
        [uid, name || 'Google User', cleanEmail, profileImage || null, googleId || null, newRole]
      );
      user = insertRes.rows[0];
    }

    delete user.password;
    const token = generateToken(user.uid);

    res.status(200).json({ user, token });
  } catch (error) {
    console.error('Google login error:', error);
    res.status(500).json({ error: 'Server error during Google Sign-In' });
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
    console.error('getProfile error:', error);
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

// ─── Password Reset with Email OTP ──────────────────────────────────────────

// Step 1: Send Reset OTP to Email
exports.sendResetOtp = async (req, res) => {
  const { email } = req.body;
  if (!email || email.trim().isEmpty) {
    return res.status(400).json({ error: 'Please provide a valid email address' });
  }

  const cleanEmail = email.trim().toLowerCase();

  try {
    const userResult = await pool.query('SELECT * FROM users WHERE LOWER(email) = $1', [cleanEmail]);
    if (userResult.rows.length === 0) {
      return res.status(404).json({ error: 'No user found with this email address' });
    }

    // Generate 6-digit OTP
    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    // Expiry: 10 minutes from now
    const expiresAt = new Date(Date.now() + 10 * 60 * 1000);

    // Store/Upsert in password_resets table
    await pool.query(
      `INSERT INTO password_resets (email, otp, expires_at)
       VALUES ($1, $2, $3)
       ON CONFLICT (email)
       DO UPDATE SET otp = $2, expires_at = $3, created_at = CURRENT_TIMESTAMP`,
      [cleanEmail, otp, expiresAt]
    );

    // Send email (or log to console)
    await sendEmailOtp(cleanEmail, otp);

    res.status(200).json({
      success: true,
      message: 'OTP has been sent to your email address.',
    });
  } catch (error) {
    console.error('Send reset OTP error:', error);
    res.status(500).json({ error: 'Server error sending OTP' });
  }
};

// Step 2: Verify OTP
exports.verifyResetOtp = async (req, res) => {
  const { email, otp } = req.body;
  if (!email || !otp) {
    return res.status(400).json({ error: 'Email and OTP are required' });
  }

  const cleanEmail = email.trim().toLowerCase();
  const cleanOtp = otp.trim();

  try {
    const resetRecord = await pool.query(
      'SELECT * FROM password_resets WHERE email = $1',
      [cleanEmail]
    );

    if (resetRecord.rows.length === 0) {
      return res.status(400).json({ error: 'No OTP request found for this email' });
    }

    const { otp: storedOtp, expires_at } = resetRecord.rows[0];

    if (new Date() > new Date(expires_at)) {
      return res.status(400).json({ error: 'OTP has expired. Please request a new one.' });
    }

    if (storedOtp !== cleanOtp) {
      return res.status(400).json({ error: 'Invalid OTP code. Please check and try again.' });
    }

    res.status(200).json({
      success: true,
      message: 'OTP verified successfully.',
    });
  } catch (error) {
    console.error('Verify reset OTP error:', error);
    res.status(500).json({ error: 'Server error verifying OTP' });
  }
};

// Step 3: Reset Password with OTP
exports.resetPasswordWithOtp = async (req, res) => {
  const { email, otp, newPassword } = req.body;
  if (!email || !otp || !newPassword) {
    return res.status(400).json({ error: 'Email, OTP, and new password are required' });
  }

  if (newPassword.length < 6) {
    return res.status(400).json({ error: 'Password must be at least 6 characters long' });
  }

  const cleanEmail = email.trim().toLowerCase();
  const cleanOtp = otp.trim();

  try {
    // Validate OTP again
    const resetRecord = await pool.query(
      'SELECT * FROM password_resets WHERE email = $1',
      [cleanEmail]
    );

    if (resetRecord.rows.length === 0) {
      return res.status(400).json({ error: 'Invalid or expired OTP session' });
    }

    const { otp: storedOtp, expires_at } = resetRecord.rows[0];

    if (new Date() > new Date(expires_at)) {
      return res.status(400).json({ error: 'OTP has expired. Please request a new one.' });
    }

    if (storedOtp !== cleanOtp) {
      return res.status(400).json({ error: 'Invalid OTP code' });
    }

    // Hash new password
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(newPassword, salt);

    // Update password in users table
    await pool.query(
      'UPDATE users SET password = $1, updated_at = CURRENT_TIMESTAMP WHERE LOWER(email) = $2',
      [hashedPassword, cleanEmail]
    );

    // Delete used OTP
    await pool.query('DELETE FROM password_resets WHERE email = $1', [cleanEmail]);

    res.status(200).json({
      success: true,
      message: 'Password reset successful! Please log in with your new password.',
    });
  } catch (error) {
    console.error('Reset password with OTP error:', error);
    res.status(500).json({ error: 'Server error updating password' });
  }
};

// Change Password (Protected)
exports.changePassword = async (req, res) => {
  const { oldPassword, newPassword } = req.body;
  try {
    const userResult = await pool.query('SELECT password FROM users WHERE uid = $1', [req.user.uid]);
    if (userResult.rows.length === 0) return res.status(404).json({ error: 'User not found' });

    const isMatch = await bcrypt.compare(oldPassword, userResult.rows[0].password);
    if (!isMatch) return res.status(400).json({ error: 'Incorrect current password' });

    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(newPassword, salt);

    await pool.query('UPDATE users SET password = $1, updated_at = CURRENT_TIMESTAMP WHERE uid = $2', [hashedPassword, req.user.uid]);
    res.status(200).json({ message: 'Password updated successfully' });
  } catch (error) {
    console.error('Change password error:', error);
    res.status(500).json({ error: 'Failed to update password' });
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
