const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');
const authMiddleware = require('../middlewares/authMiddleware');

// Public routes
router.post('/signup', authController.signup);
router.post('/login', authController.login);
router.post('/google-login', authController.googleLogin);
router.post('/refresh-token', authController.refreshToken);

// Email OTP Password Reset Flow
router.post('/send-reset-otp', authController.sendResetOtp);
router.post('/forgot-password', authController.sendResetOtp); // Alias
router.post('/verify-reset-otp', authController.verifyResetOtp);
router.post('/reset-password-with-otp', authController.resetPasswordWithOtp);

router.get('/user/:uid', authController.getUserById);

// Protected routes
router.get('/profile', authMiddleware, authController.getProfile);
router.put('/profile', authMiddleware, authController.updateProfile);
router.put('/change-password', authMiddleware, authController.changePassword);
router.delete('/profile', authMiddleware, authController.deleteAccount);

module.exports = router;
