const prisma = require('../config/prisma');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const nodemailer = require('nodemailer');

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
  const crypto = require('crypto');

  try {
    const cleanEmail = email ? email.trim().toLowerCase() : null;
    const cleanPhone = phone ? phone.trim() : null;

    const existingUser = await prisma.users.findFirst({
      where: {
        OR: [
          { email: cleanEmail !== null ? cleanEmail : undefined },
          { phone: cleanPhone !== null ? cleanPhone : undefined }
        ]
      }
    });

    if (existingUser) {
      return res.status(400).json({ error: 'User with this email or phone already exists' });
    }

    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(password, salt);
    const uid = crypto.randomUUID();

    const newUser = await prisma.users.create({
      data: {
        uid,
        name: name ? name.trim() : '',
        phone: cleanPhone,
        email: cleanEmail,
        password: hashedPassword,
        gender: gender || null,
        role: role || 'bachelor'
      }
    });

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

  const cleanIdentifier = email.trim();

  try {
    const userResult = await prisma.$queryRaw`SELECT * FROM users WHERE LOWER(email) = LOWER(${cleanIdentifier}) OR phone = ${cleanIdentifier}`;
    
    if (userResult.length === 0) {
      return res.status(404).json({ error: 'No account found with this email/phone. Please create an account first.' });
    }

    const user = userResult[0];
    
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
    
    const user = await prisma.users.findUnique({
      where: { uid: decoded.uid },
      select: { uid: true, name: true, email: true, phone: true, role: true, status: true, profile_image: true, created_at: true }
    });
    
    if (!user) {
      return res.status(401).json({ error: 'User no longer exists' });
    }

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
  const crypto = require('crypto');

  try {
    let user = await prisma.users.findFirst({
      where: { email: cleanEmail }
    });

    if (user) {
      if ((!user.profile_image && profileImage) || (!user.google_id && googleId)) {
        user = await prisma.users.update({
          where: { uid: user.uid },
          data: {
            profile_image: user.profile_image || profileImage,
            google_id: user.google_id || googleId,
            updated_at: new Date()
          }
        });
      }
    } else {
      const uid = crypto.randomUUID();
      const newRole = role || 'bachelor';

      user = await prisma.users.create({
        data: {
          uid,
          name: name || 'Google User',
          email: cleanEmail,
          profile_image: profileImage || null,
          google_id: googleId || null,
          role: newRole,
          status: 'active'
        }
      });
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
    const user = await prisma.users.findUnique({
      where: { uid: req.user.uid },
      select: { uid: true, name: true, phone: true, email: true, gender: true, role: true, status: true, profile_image: true, created_at: true, updated_at: true }
    });
    
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }
    res.status(200).json(user);
  } catch (error) {
    console.error('getProfile error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};

// Get Public User Profile by UID
exports.getUserById = async (req, res) => {
  try {
    const user = await prisma.users.findUnique({
      where: { uid: req.params.uid },
      select: { uid: true, name: true, phone: true, email: true, gender: true, role: true, status: true, profile_image: true, created_at: true }
    });
    
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }
    res.status(200).json(user);
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
    const updatedUser = await prisma.users.update({
      where: { uid: req.user.uid },
      data: {
        ...(safeName && { name: safeName }),
        ...(safeEmail && { email: safeEmail }),
        ...(safeGender && { gender: safeGender }),
        ...(imageToUse && { profile_image: imageToUse }),
        ...(safePhone && { phone: safePhone }),
        updated_at: new Date()
      },
      select: { uid: true, name: true, phone: true, email: true, gender: true, role: true, status: true, profile_image: true, created_at: true, updated_at: true }
    });

    res.status(200).json(updatedUser);
  } catch (error) {
    console.error('Update profile error:', error);
    res.status(500).json({ error: 'Failed to update profile' });
  }
};

// Update FCM Token
exports.updateFcmToken = async (req, res) => {
  const { fcmToken } = req.body;
  if (!fcmToken) {
    return res.status(400).json({ error: 'fcmToken is required' });
  }
  try {
    await prisma.users.update({
      where: { uid: req.user.uid },
      data: {
        fcm_token: fcmToken,
        updated_at: new Date()
      }
    });
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
    const user = await prisma.users.findFirst({
      where: { email: cleanEmail }
    });
    if (!user) {
      return res.status(404).json({ error: 'No user found with this email address' });
    }

    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    const expiresAt = new Date(Date.now() + 10 * 60 * 1000);

    await prisma.password_resets.upsert({
      where: { email: cleanEmail },
      update: { otp, expires_at: expiresAt, created_at: new Date() },
      create: { email: cleanEmail, otp, expires_at: expiresAt, created_at: new Date() }
    });

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
    const resetRecord = await prisma.password_resets.findUnique({
      where: { email: cleanEmail }
    });

    if (!resetRecord) {
      return res.status(400).json({ error: 'No OTP request found for this email' });
    }

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
    const resetRecord = await prisma.password_resets.findUnique({
      where: { email: cleanEmail }
    });

    if (!resetRecord) {
      return res.status(400).json({ error: 'Invalid or expired OTP session' });
    }

    if (new Date() > new Date(resetRecord.expires_at)) {
      return res.status(400).json({ error: 'OTP has expired. Please request a new one.' });
    }

    if (resetRecord.otp !== cleanOtp) {
      return res.status(400).json({ error: 'Invalid OTP code' });
    }

    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(newPassword, salt);

    await prisma.users.updateMany({
      where: { email: cleanEmail },
      data: { password: hashedPassword, updated_at: new Date() }
    });

    await prisma.password_resets.delete({
      where: { email: cleanEmail }
    });

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
    const user = await prisma.users.findUnique({
      where: { uid: req.user.uid },
      select: { password: true }
    });
    
    if (!user) return res.status(404).json({ error: 'User not found' });

    const isMatch = await bcrypt.compare(oldPassword, user.password);
    if (!isMatch) return res.status(400).json({ error: 'Incorrect current password' });

    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(newPassword, salt);

    await prisma.users.update({
      where: { uid: req.user.uid },
      data: { password: hashedPassword, updated_at: new Date() }
    });
    
    res.status(200).json({ message: 'Password updated successfully' });
  } catch (error) {
    console.error('Change password error:', error);
    res.status(500).json({ error: 'Failed to update password' });
  }
};

// Delete Account
exports.deleteAccount = async (req, res) => {
  try {
    await prisma.users.delete({
      where: { uid: req.user.uid }
    });
    res.status(200).json({ message: 'Account deleted successfully' });
  } catch (error) {
    console.error('Delete account error:', error);
    res.status(500).json({ error: 'Failed to delete account' });
  }
};
