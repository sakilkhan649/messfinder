const express = require('express');
const router = express.Router();
const adminController = require('../controllers/adminController');
const authMiddleware = require('../middlewares/authMiddleware');
const adminMiddleware = require('../middlewares/adminMiddleware');

// All admin routes require authentication and admin privileges
router.use(authMiddleware);
router.use(adminMiddleware);

// 1. Dashboard Stats
router.get('/stats', adminController.getDashboardStats);

// 2. User Management
router.get('/users', adminController.getAllUsers);
router.delete('/users/:uid', adminController.deleteUser);
router.put('/users/:uid/role', adminController.updateUserRole);
router.put('/users/:uid/status', adminController.updateUserStatus);

// 3. Post Management
router.get('/posts', adminController.getAllPosts);
router.put('/posts/:id/approve', adminController.approvePost);
router.put('/posts/:id/reject', adminController.rejectPost);
router.delete('/posts/:id', adminController.deletePost);

// 4. Booking Management
router.get('/bookings', adminController.getAllBookings);
router.put('/bookings/:id/approve', adminController.approveBooking);
router.put('/bookings/:id/reject', adminController.rejectBooking);
router.delete('/bookings/:id', adminController.deleteBooking);

// 5. Payment Management
router.get('/payments', adminController.getAllPayments);

// 6. Global Broadcast Announcements
router.post('/broadcast', adminController.broadcastNotification);

module.exports = router;
