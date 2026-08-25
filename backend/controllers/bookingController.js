const pool = require('../config/db');

exports.getLandlordLeads = async (req, res) => {
  try {
    const { uid } = req.params;
    const result = await pool.query(
      `SELECT b.*, u.name as user_table_name, u.phone as user_table_phone, u.email as user_table_email
       FROM bookings b
       LEFT JOIN users u ON b.bachelor_uid = u.uid
       WHERE b.landlord_uid = $1
       ORDER BY b.created_at DESC`,
      [uid]
    );

    const leads = result.rows.map(row => {
      // Resolve name
      let finalName = row.bachelor_name;
      if (!finalName || finalName.toLowerCase() === 'user' || finalName.toLowerCase() === 'unknown') {
        finalName = row.user_table_name;
      }
      if (!finalName || finalName.toLowerCase() === 'user' || finalName.toLowerCase() === 'unknown') {
        if (row.user_table_email) {
          finalName = row.user_table_email.split('@')[0];
        } else {
          finalName = 'Bachelor Tenant';
        }
      }

      // Resolve phone
      let finalPhone = row.bachelor_phone;
      if (!finalPhone || finalPhone === '—' || finalPhone === '') {
        finalPhone = row.user_table_phone;
      }
      if (!finalPhone || finalPhone === '—' || finalPhone === '') {
        finalPhone = row.sender_number || 'Not provided';
      }

      return {
        bookingId: row.booking_id,
        postId: row.post_id,
        bachelorUid: row.bachelor_uid,
        landlordUid: row.landlord_uid,
        bachelorName: finalName,
        bachelorPhone: finalPhone,
        trxId: row.trx_id || '',
        senderNumber: row.sender_number || '',
        paymentStatus: row.payment_status,
        isUnlocked: row.is_unlocked,
        createdAt: row.created_at,
      };
    });

    res.status(200).json(leads);
  } catch (error) {
    console.error('Error fetching landlord leads:', error);
    res.status(500).json({ error: 'Server error' });
  }
};

exports.createBooking = async (req, res) => {
  try {
    const {
      bookingId,
      postId,
      bachelorUid,
      landlordUid,
      bachelorName,
      bachelorPhone,
      trxId,
      senderNumber,
      paymentStatus,
      isUnlocked,
    } = req.body;

    const result = await pool.query(
      `INSERT INTO bookings 
      (booking_id, post_id, bachelor_uid, landlord_uid, bachelor_name, bachelor_phone, trx_id, sender_number, payment_status, is_unlocked, created_at, updated_at) 
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP) 
      RETURNING *`,
      [
        bookingId,
        postId,
        bachelorUid,
        landlordUid,
        bachelorName || null,
        bachelorPhone || null,
        trxId || '',
        senderNumber || '',
        paymentStatus || 'pending',
        isUnlocked || false
      ]
    );

    res.status(201).json(result.rows[0]);
  } catch (error) {
    console.error('Error creating booking:', error);
    res.status(500).json({ error: 'Server error' });
  }
};

exports.getPostLeads = async (req, res) => {
  try {
    const { postId } = req.params;
    const result = await pool.query(
      `SELECT b.*, u.name as user_table_name, u.phone as user_table_phone, u.email as user_table_email
       FROM bookings b
       LEFT JOIN users u ON b.bachelor_uid = u.uid
       WHERE b.post_id = $1
       ORDER BY b.created_at DESC`,
      [postId]
    );

    const leads = result.rows.map(row => {
      let finalName = row.bachelor_name;
      if (!finalName || finalName.toLowerCase() === 'user' || finalName.toLowerCase() === 'unknown') {
        finalName = row.user_table_name;
      }
      if (!finalName || finalName.toLowerCase() === 'user' || finalName.toLowerCase() === 'unknown') {
        if (row.user_table_email) {
          finalName = row.user_table_email.split('@')[0];
        } else {
          finalName = 'Bachelor Tenant';
        }
      }

      let finalPhone = row.bachelor_phone;
      if (!finalPhone || finalPhone === '—' || finalPhone === '') {
        finalPhone = row.user_table_phone;
      }
      if (!finalPhone || finalPhone === '—' || finalPhone === '') {
        finalPhone = row.sender_number || 'Not provided';
      }

      return {
        bookingId: row.booking_id,
        postId: row.post_id,
        bachelorUid: row.bachelor_uid,
        landlordUid: row.landlord_uid,
        bachelorName: finalName,
        bachelorPhone: finalPhone,
        trxId: row.trx_id || '',
        senderNumber: row.sender_number || '',
        paymentStatus: row.payment_status,
        isUnlocked: row.is_unlocked,
        createdAt: row.created_at,
      };
    });

    res.status(200).json(leads);
  } catch (error) {
    console.error('Error fetching post leads:', error);
    res.status(500).json({ error: 'Server error' });
  }
};

exports.approveLead = async (req, res) => {
  try {
    const { id } = req.params;
    const result = await pool.query(
      "UPDATE bookings SET payment_status = 'approved', is_unlocked = true, updated_at = CURRENT_TIMESTAMP WHERE booking_id = $1 RETURNING *",
      [id]
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Booking not found' });
    }
    // Note: We might want to trigger a notification here if we port NotificationService to backend.
    res.status(200).json(result.rows[0]);
  } catch (error) {
    console.error('Error approving lead:', error);
    res.status(500).json({ error: 'Server error' });
  }
};

exports.rejectLead = async (req, res) => {
  try {
    const { id } = req.params;
    const result = await pool.query(
      "UPDATE bookings SET payment_status = 'rejected', is_unlocked = false, updated_at = CURRENT_TIMESTAMP WHERE booking_id = $1 RETURNING *",
      [id]
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Booking not found' });
    }
    res.status(200).json(result.rows[0]);
  } catch (error) {
    console.error('Error rejecting lead:', error);
    res.status(500).json({ error: 'Server error' });
  }
};

exports.deleteLead = async (req, res) => {
  try {
    const { id } = req.params;
    const result = await pool.query('DELETE FROM bookings WHERE booking_id = $1 RETURNING *', [id]);
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Booking not found' });
    }
    res.status(200).json({ message: 'Booking deleted successfully' });
  } catch (error) {
    console.error('Error deleting lead:', error);
    res.status(500).json({ error: 'Server error' });
  }
};
