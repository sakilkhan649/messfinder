const express = require('express');
const router = express.Router();
const chatController = require('../controllers/chatController');
const authMiddleware = require('../middlewares/authMiddleware');

router.use(authMiddleware);

router.get('/', chatController.getChats);
router.post('/', chatController.createChat);
router.get('/:chatId/messages', chatController.getMessages);

module.exports = router;
