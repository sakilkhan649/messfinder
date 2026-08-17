const express = require('express');
const router = express.Router();
const postController = require('../controllers/postController');
const authMiddleware = require('../middlewares/authMiddleware');

// Public routes
router.get('/', postController.getPosts);
router.get('/:id', postController.getPostById);

// Protected routes
router.post('/', authMiddleware, postController.createPost);
router.get('/user/my-posts', authMiddleware, postController.getMyPosts);
router.put('/:id', authMiddleware, postController.updatePost);
router.delete('/:id', authMiddleware, postController.deletePost);
router.put('/:id/availability', authMiddleware, postController.toggleAvailability);

module.exports = router;
