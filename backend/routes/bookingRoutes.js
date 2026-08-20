const express = require('express');
const router = express.Router();
const bookingController = require('../controllers/bookingController');

// Routes for landlord leads
router.get('/landlord/:uid', bookingController.getLandlordLeads);
router.get('/post/:postId', bookingController.getPostLeads);

// Actions for leads
router.put('/:id/approve', bookingController.approveLead);
router.put('/:id/reject', bookingController.rejectLead);
router.delete('/:id', bookingController.deleteLead);

module.exports = router;
