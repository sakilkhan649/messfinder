const express = require('express');
const router = express.Router();
const postController = require('../controllers/postController');
const authMiddleware = require('../middlewares/authMiddleware');

// Specific & public routes
router.get('/', postController.getPosts);
router.get('/user/my-posts', authMiddleware, postController.getMyPosts);

// Protected routes
router.post('/', authMiddleware, postController.createPost);
router.put('/:id', authMiddleware, postController.updatePost);
router.delete('/:id', authMiddleware, postController.deletePost);
router.put('/:id/availability', authMiddleware, postController.toggleAvailability);

// Dynamic parameter route (Must be after specific GET routes)
router.get('/:id', postController.getPostById);

module.exports = router;
