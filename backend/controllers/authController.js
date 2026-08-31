const pool = require('../config/db');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const nodemailer = require('nodemailer');
const crypto = require('crypto');

const JWT_SECRET = process.env.JWT_SECRET || 'secret_key_mess_finder';
const REFRESH_TOKEN_SECRET = process.env.REFRESH_TOKEN_SECRET || (JWT_SECRET + '_refresh');

// Helper to generate both Access Token and Refresh Token
const generateTokens = (uid) => {
  const accessToken = jwt.sign({ uid }, JWT_SECRET, { expiresIn: '1d' });
  const refreshToken = jwt.sign({ uid }, REFRESH_TOKEN_SECRET, { expiresIn: '90d' });
  return { accessToken, refreshToken, token: accessToken };
};

const generateToken = (uid) => generateTokens(uid).accessToken;

// Mail transporter helper
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
  }
};

// Signup
exports.signup = async (req, res) => {
  const { name, phone, email, password, gender, role } = req.body;

  try {
    const cleanEmail = email ? email.trim().toLowerCase() : null;
    const cleanPhone = phone ? phone.trim() : null;

    if (!cleanEmail && !cleanPhone) {
      return res.status(400).json({ error: 'Email or Phone must be provided' });
    }

    const { rows: existingUsers } = await pool.query(
      'SELECT * FROM users WHERE email = $1 OR phone = $2',
      [cleanEmail, cleanPhone]
    );

    if (existingUsers.length > 0) {
      return res.status(400).json({ error: 'User with this email or phone already exists' });
    }

    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(password, salt);
    const uid = crypto.randomUUID();

    const { rows: newUsers } = await pool.query(
      `INSERT INTO users (uid, name, phone, email, password, gender, role, status)
       VALUES ($1, $2, $3, $4, $5, $6, $7, 'active') RETURNING *`,
      [uid, name ? name.trim() : '', cleanPhone, cleanEmail, hashedPassword, gender || null, role || 'bachelor']
    );

    const newUser = newUsers[0];
    delete newUser.password;

    const tokens = generateTokens(newUser.uid);
    res.status(201).json({ user: newUser, ...tokens });
  } catch (error) {
    console.error('Signup error:', error);
    res.status(500).json({ error: 'Server error during signup' });
  }
};

// Login
exports.login = async (req, res) => {
  const { email, password } = req.body;

  if (!email || !password) {
    return res.status(400).json({ error: 'Email/Phone and password are required' });
  }

  const cleanIdentifier = email.trim().toLowerCase();

  try {
    const { rows: users } = await pool.query(
      'SELECT * FROM users WHERE email = $1 OR phone = $1',
      [cleanIdentifier]
    );

    if (users.length === 0) {
      return res.status(404).json({ error: 'No account found with this email/phone. Please create an account first.' });
    }

    const user = users[0];
    
    if (!user.password) {
      return res.status(400).json({ error: 'This account was created with Google Sign-In. Please click "Continue with Google".' });
    }

    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
      return res.status(401).json({ error: 'Invalid password. Please try again.' });
    }

    delete user.password;

    const tokens = generateTokens(user.uid);
    res.status(200).json({ user, ...tokens });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ error: 'Server error during login' });
  }
};

// Refresh Token
exports.refreshToken = async (req, res) => {
  const { refreshToken } = req.body;

  if (!refreshToken) {
    return res.status(400).json({ error: 'Refresh token is required' });
  }

  try {
    const decoded = jwt.verify(refreshToken, REFRESH_TOKEN_SECRET);
    
    const { rows: users } = await pool.query(
      'SELECT uid, name, email, phone, role, status, profile_image, created_at FROM users WHERE uid = $1',
      [decoded.uid]
    );
    
    if (users.length === 0) {
      return res.status(401).json({ error: 'User no longer exists' });
    }

    const user = users[0];
    const tokens = generateTokens(user.uid);

    res.status(200).json({
      user,
      ...tokens
    });
  } catch (err) {
    console.error('Refresh token error:', err.message);
    return res.status(401).json({ error: 'Invalid or expired refresh token' });
  }
};

// Google Sign-In
exports.googleLogin = async (req, res) => {
  const { email, name, profileImage, googleId, role } = req.body;

  if (!email) {
    return res.status(400).json({ error: 'Email is required for Google Sign-In' });
  }

  const cleanEmail = email.trim().toLowerCase();

  try {
    const { rows: users } = await pool.query(
      'SELECT * FROM users WHERE email = $1',
      [cleanEmail]
    );

    let user;

    if (users.length > 0) {
      user = users[0];
      if ((!user.profile_image && profileImage) || (!user.google_id && googleId)) {
        const { rows: updatedUsers } = await pool.query(
          `UPDATE users SET profile_image = $1, google_id = $2, updated_at = NOW() WHERE uid = $3 RETURNING *`,
          [user.profile_image || profileImage, user.google_id || googleId, user.uid]
        );
        user = updatedUsers[0];
      }
    } else {
      const uid = crypto.randomUUID();
      const newRole = role || 'bachelor';

      const { rows: newUsers } = await pool.query(
        `INSERT INTO users (uid, name, email, profile_image, google_id, role, status)
         VALUES ($1, $2, $3, $4, $5, $6, 'active') RETURNING *`,
        [uid, name || 'Google User', cleanEmail, profileImage || null, googleId || null, newRole]
      );
      user = newUsers[0];
    }

    delete user.password;
    const tokens = generateTokens(user.uid);

    res.status(200).json({ user, ...tokens });
  } catch (error) {
    console.error('Google login error:', error);
    res.status(500).json({ error: 'Server error during Google Sign-In' });
  }
};

// Get User Profile
exports.getProfile = async (req, res) => {
  try {
    const { rows: users } = await pool.query(
      'SELECT uid, name, phone, email, gender, role, status, profile_image, created_at, updated_at FROM users WHERE uid = $1',
      [req.user.uid]
    );
    
    if (users.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }
    res.status(200).json(users[0]);
  } catch (error) {
    console.error('getProfile error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};

// Get Public User Profile by UID
exports.getUserById = async (req, res) => {
  try {
    const { rows: users } = await pool.query(
      'SELECT uid, name, phone, email, gender, role, status, profile_image, created_at FROM users WHERE uid = $1',
      [req.params.uid]
    );
    
    if (users.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }
    res.status(200).json(users[0]);
  } catch (error) {
    console.error('getUserById error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};

// Update Profile
exports.updateProfile = async (req, res) => {
  const { name, email, gender, profile_image, photoUrl, phone } = req.body;
  const imageToUse = profile_image || photoUrl || null;

  const safeName = name && name.trim() !== '' ? name.trim() : undefined;
  const safeEmail = email && email.trim() !== '' ? email.trim().toLowerCase() : undefined;
  const safeGender = gender && gender.trim() !== '' ? gender.trim() : undefined;
  const safePhone = phone && phone.trim() !== '' ? phone.trim() : undefined;

  try {
    let updateFields = [];
    let values = [];
    let queryIndex = 1;

    if (safeName) {
      updateFields.push(`name = $${queryIndex++}`);
      values.push(safeName);
    }
    if (safeEmail) {
      updateFields.push(`email = $${queryIndex++}`);
      values.push(safeEmail);
    }
    if (safeGender) {
      updateFields.push(`gender = $${queryIndex++}`);
      values.push(safeGender);
    }
    if (imageToUse) {
      updateFields.push(`profile_image = $${queryIndex++}`);
      values.push(imageToUse);
    }
    if (safePhone) {
      updateFields.push(`phone = $${queryIndex++}`);
      values.push(safePhone);
    }

    if (updateFields.length === 0) {
      return res.status(400).json({ error: 'No fields to update' });
    }

    updateFields.push(`updated_at = NOW()`);
    
    values.push(req.user.uid);
    const query = `
      UPDATE users 
      SET ${updateFields.join(', ')} 
      WHERE uid = $${queryIndex} 
      RETURNING uid, name, phone, email, gender, role, status, profile_image, created_at, updated_at
    `;

    const { rows: updatedUsers } = await pool.query(query, values);

    res.status(200).json(updatedUsers[0]);
  } catch (error) {
    console.error('Update profile error:', error);
    res.status(500).json({ error: 'Failed to update profile' });
  }
};

// Update FCM Token
exports.updateFcmToken = async (req, res) => {
  const { fcmToken } = req.body;
  if (fcmToken === undefined) {
    return res.status(400).json({ error: 'fcmToken is required' });
  }
  try {
    await pool.query(
      'UPDATE users SET fcm_token = $1, updated_at = NOW() WHERE uid = $2',
      [fcmToken || null, req.user.uid]
    );
    res.status(200).json({ message: 'FCM Token updated successfully' });
  } catch (error) {
    console.error('Update FCM Token error:', error);
    res.status(500).json({ error: 'Failed to update FCM Token' });
  }
};

// Send Reset OTP
exports.sendResetOtp = async (req, res) => {
  const { email } = req.body;
  if (!email || email.trim() === '') {
    return res.status(400).json({ error: 'Please provide a valid email address' });
  }

  const cleanEmail = email.trim().toLowerCase();

  try {
    const { rows: users } = await pool.query(
      'SELECT * FROM users WHERE email = $1',
      [cleanEmail]
    );
    if (users.length === 0) {
      return res.status(404).json({ error: 'No user found with this email address' });
    }

    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    const expiresAt = new Date(Date.now() + 10 * 60 * 1000);

    await pool.query(`
      INSERT INTO password_resets (email, otp, expires_at, created_at)
      VALUES ($1, $2, $3, NOW())
      ON CONFLICT (email) DO UPDATE 
      SET otp = EXCLUDED.otp, expires_at = EXCLUDED.expires_at, created_at = NOW()
    `, [cleanEmail, otp, expiresAt]);

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

// Verify OTP
exports.verifyResetOtp = async (req, res) => {
  const { email, otp } = req.body;
  if (!email || !otp) {
    return res.status(400).json({ error: 'Email and OTP are required' });
  }

  const cleanEmail = email.trim().toLowerCase();
  const cleanOtp = otp.trim();

  try {
    const { rows: resets } = await pool.query(
      'SELECT * FROM password_resets WHERE email = $1',
      [cleanEmail]
    );

    if (resets.length === 0) {
      return res.status(400).json({ error: 'No OTP request found for this email' });
    }

    const resetRecord = resets[0];

    if (new Date() > new Date(resetRecord.expires_at)) {
      return res.status(400).json({ error: 'OTP has expired. Please request a new one.' });
    }

    if (resetRecord.otp !== cleanOtp) {
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

// Reset Password with OTP
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
    const { rows: resets } = await pool.query(
      'SELECT * FROM password_resets WHERE email = $1',
      [cleanEmail]
    );

    if (resets.length === 0) {
      return res.status(400).json({ error: 'Invalid or expired OTP session' });
    }

    const resetRecord = resets[0];

    if (new Date() > new Date(resetRecord.expires_at)) {
      return res.status(400).json({ error: 'OTP has expired. Please request a new one.' });
    }

    if (resetRecord.otp !== cleanOtp) {
      return res.status(400).json({ error: 'Invalid OTP code' });
    }

    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(newPassword, salt);

    await pool.query(
      'UPDATE users SET password = $1, updated_at = NOW() WHERE email = $2',
      [hashedPassword, cleanEmail]
    );

    await pool.query(
      'DELETE FROM password_resets WHERE email = $1',
      [cleanEmail]
    );

    res.status(200).json({
      success: true,
      message: 'Password reset successful! Please log in with your new password.',
    });
  } catch (error) {
    console.error('Reset password with OTP error:', error);
    res.status(500).json({ error: 'Server error updating password' });
  }
};

// Change Password
exports.changePassword = async (req, res) => {
  const { oldPassword, newPassword } = req.body;
  try {
    const { rows: users } = await pool.query(
      'SELECT password FROM users WHERE uid = $1',
      [req.user.uid]
    );
    
    if (users.length === 0) return res.status(404).json({ error: 'User not found' });

    const user = users[0];
    const isMatch = await bcrypt.compare(oldPassword, user.password);
    if (!isMatch) return res.status(400).json({ error: 'Incorrect current password' });

    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(newPassword, salt);

    await pool.query(
      'UPDATE users SET password = $1, updated_at = NOW() WHERE uid = $2',
      [hashedPassword, req.user.uid]
    );
    
    res.status(200).json({ message: 'Password updated successfully' });
  } catch (error) {
    console.error('Change password error:', error);
    res.status(500).json({ error: 'Failed to update password' });
  }
};

// Delete Account
exports.deleteAccount = async (req, res) => {
  try {
    await pool.query(
      'DELETE FROM users WHERE uid = $1',
      [req.user.uid]
    );
    res.status(200).json({ message: 'Account deleted successfully' });
  } catch (error) {
    console.error('Delete account error:', error);
    res.status(500).json({ error: 'Failed to delete account' });
  }
};
