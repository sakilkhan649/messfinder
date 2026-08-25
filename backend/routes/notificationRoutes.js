const express = require('express');
const router = express.Router();
const notificationController = require('../controllers/notificationController');

// POST /api/notifications/send
router.post('/send', notificationController.sendPushNotification);
router.get('/:uid', notificationController.getNotifications);
router.put('/:id/read', notificationController.markAsRead);

module.exports = router;
