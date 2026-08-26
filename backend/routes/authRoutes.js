const express = require('express');
const router = express.Router();
const rateLimit = require('express-rate-limit');
const authController = require('../controllers/authController');
const authMiddleware = require('../middlewares/authMiddleware');

// Rate Limiter: Max 5 requests per 15 minutes
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 5,
  message: { error: 'Too many requests from this IP, please try again after 15 minutes' }
});

// Public routes
router.post('/signup', authController.signup);
router.post('/login', authLimiter, authController.login);
router.post('/google-login', authController.googleLogin);
router.post('/refresh-token', authController.refreshToken);

// Email OTP Password Reset Flow
router.post('/send-reset-otp', authLimiter, authController.sendResetOtp);
router.post('/forgot-password', authLimiter, authController.sendResetOtp); // Alias
router.post('/verify-reset-otp', authController.verifyResetOtp);
router.post('/reset-password-with-otp', authController.resetPasswordWithOtp);

router.get('/user/:uid', authController.getUserById);

// Protected routes
router.get('/profile', authMiddleware, authController.getProfile);
router.put('/profile', authMiddleware, authController.updateProfile);
router.put('/fcm-token', authMiddleware, authController.updateFcmToken);
router.put('/change-password', authMiddleware, authController.changePassword);
router.delete('/profile', authMiddleware, authController.deleteAccount);

module.exports = router;
