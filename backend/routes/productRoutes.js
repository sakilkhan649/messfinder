const express = require('express');
const router = express.Router();
const productController = require('../controllers/productController');
const authMiddleware = require('../middlewares/authMiddleware');

// Public routes (or routes that can be accessed without auth, though marketplace usually requires auth)
// Let's protect them as users need to be logged in to buy/sell
router.get('/', authMiddleware, productController.getProducts);
router.get('/:id', authMiddleware, productController.getProductById);
router.get('/user/:uid', authMiddleware, productController.getUserProducts);

// Protected routes (require auth)
router.post('/', authMiddleware, productController.createProduct);
router.put('/:id', authMiddleware, productController.updateProduct);
router.delete('/:id', authMiddleware, productController.deleteProduct);

module.exports = router;
