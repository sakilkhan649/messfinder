const pool = require('../config/db');

// ─── 1. Dashboard Stats & Analytics ─────────────────────────────────────────
exports.getDashboardStats = async (req, res) => {
  try {
    // 1. Posts counts
    const postCountsRes = await pool.query(`
      SELECT 
        COUNT(*)::int AS total,
        COUNT(*) FILTER (WHERE LOWER(TRIM(payment_status)) = 'pending')::int AS pending,
        COUNT(*) FILTER (WHERE LOWER(TRIM(payment_status)) = 'approved' OR is_published = true)::int AS approved,
        COUNT(*) FILTER (WHERE LOWER(TRIM(payment_status)) = 'rejected')::int AS rejected
      FROM posts
    `);
    const postStats = postCountsRes.rows[0] || { total: 0, pending: 0, approved: 0, rejected: 0 };

    // 2. Bookings counts
    const bookingCountsRes = await pool.query(`
      SELECT 
        COUNT(*)::int AS total,
        COUNT(*) FILTER (WHERE LOWER(TRIM(payment_status)) = 'pending')::int AS pending,
        COUNT(*) FILTER (WHERE LOWER(TRIM(payment_status)) = 'approved' OR is_unlocked = true)::int AS approved,
        COUNT(*) FILTER (WHERE LOWER(TRIM(payment_status)) = 'rejected')::int AS rejected
      FROM bookings
    `);
    const bookingStats = bookingCountsRes.rows[0] || { total: 0, pending: 0, approved: 0, rejected: 0 };

    // 3. Users counts
    const userCountsRes = await pool.query(`
      SELECT 
        COUNT(*)::int AS total,
        COUNT(*) FILTER (WHERE LOWER(TRIM(role)) = 'landlord')::int AS landlords,
        COUNT(*) FILTER (WHERE LOWER(TRIM(role)) = 'bachelor')::int AS bachelors,
        COUNT(*) FILTER (WHERE LOWER(TRIM(role)) = 'admin')::int AS admins
      FROM users
    `);
    const userStats = userCountsRes.rows[0] || { total: 0, landlords: 0, bachelors: 0, admins: 0 };

    // 4. Payments counts & Revenue
    // Revenue calculations: 70 BDT per approved post, 50 BDT per approved booking
    const postRevenue = (postStats.approved || 0) * 70;
    const bookingRevenue = (bookingStats.approved || 0) * 50;
    const totalRevenue = postRevenue + bookingRevenue;

    res.status(200).json({
      totalRevenue,
      postRevenue,
      bookingRevenue,
      posts: {
        total: postStats.total,
        pending: postStats.pending,
        approved: postStats.approved,
        rejected: postStats.rejected,
      },
      bookings: {
        total: bookingStats.total,
        pending: bookingStats.pending,
        approved: bookingStats.approved,
        rejected: bookingStats.rejected,
      },
      users: {
        total: userStats.total,
        landlords: userStats.landlords,
        bachelors: userStats.bachelors,
        admins: userStats.admins,
      },
      summary: {
        totalPending: (postStats.pending || 0) + (bookingStats.pending || 0),
        totalApproved: (postStats.approved || 0) + (bookingStats.approved || 0),
        totalRejected: (postStats.rejected || 0) + (bookingStats.rejected || 0),
      }
    });
  } catch (error) {
    console.error('Error fetching admin dashboard stats:', error);
    res.status(500).json({ error: 'Server error fetching stats' });
  }
};

// ─── 2. User Management ──────────────────────────────────────────────────────
exports.getAllUsers = async (req, res) => {
  try {
    const { role, search, status } = req.query;
    let query = `
      SELECT 
        u.uid, u.name, u.phone, u.email, u.gender, u.role, u.status, u.profile_image, u.created_at,
        (SELECT COUNT(*)::int FROM posts p WHERE p.owner_uid = u.uid) AS post_count,
        (SELECT COUNT(*)::int FROM bookings b WHERE b.bachelor_uid = u.uid) AS booking_count
      FROM users u
      WHERE 1=1
    `;
    const params = [];
    let paramIndex = 1;

    if (role && role !== 'all') {
      query += ` AND LOWER(TRIM(u.role)) = $${paramIndex++}`;
      params.push(role.toLowerCase().trim());
    }

    if (status && status !== 'all') {
      query += ` AND LOWER(TRIM(u.status)) = $${paramIndex++}`;
      params.push(status.toLowerCase().trim());
    }

    if (search) {
      query += ` AND (
        LOWER(u.name) LIKE $${paramIndex} OR 
        LOWER(u.phone) LIKE $${paramIndex} OR 
        LOWER(u.email) LIKE $${paramIndex} OR 
        LOWER(u.uid) LIKE $${paramIndex}
      )`;
      params.push(`%${search.toLowerCase().trim()}%`);
      paramIndex++;
    }

    query += ' ORDER BY u.created_at DESC';

    const result = await pool.query(query, params);
    res.status(200).json(result.rows);
  } catch (error) {
    console.error('Error fetching users for admin:', error);
    res.status(500).json({ error: 'Server error fetching users' });
  }
};

exports.deleteUser = async (req, res) => {
  const { uid } = req.params;
  try {
    const userRes = await pool.query('SELECT name FROM users WHERE uid = $1', [uid]);
    if (userRes.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }

    // Cascade delete user
    await pool.query('DELETE FROM users WHERE uid = $1', [uid]);
    res.status(200).json({ message: `User "${userRes.rows[0].name}" deleted successfully` });
  } catch (error) {
    console.error('Error deleting user by admin:', error);
    res.status(500).json({ error: 'Server error deleting user' });
  }
};

exports.updateUserRole = async (req, res) => {
  const { uid } = req.params;
  const { role } = req.body;
  if (!role) return res.status(400).json({ error: 'Role is required' });

  try {
    const result = await pool.query(
      'UPDATE users SET role = $1, updated_at = CURRENT_TIMESTAMP WHERE uid = $2 RETURNING *',
      [role.toLowerCase().trim(), uid]
    );
    if (result.rows.length === 0) return res.status(404).json({ error: 'User not found' });
    res.status(200).json(result.rows[0]);
  } catch (error) {
    console.error('Error updating user role:', error);
    res.status(500).json({ error: 'Server error updating role' });
  }
};

exports.updateUserStatus = async (req, res) => {
  const { uid } = req.params;
  const { status } = req.body; // active, suspended, banned
  if (!status) return res.status(400).json({ error: 'Status is required' });

  try {
    const result = await pool.query(
      'UPDATE users SET status = $1, updated_at = CURRENT_TIMESTAMP WHERE uid = $2 RETURNING *',
      [status.toLowerCase().trim(), uid]
    );
    if (result.rows.length === 0) return res.status(404).json({ error: 'User not found' });
    res.status(200).json(result.rows[0]);
  } catch (error) {
    console.error('Error updating user status:', error);
    res.status(500).json({ error: 'Server error updating status' });
  }
};

// ─── 3. Post Management ──────────────────────────────────────────────────────
exports.getAllPosts = async (req, res) => {
  try {
    const { status, search, limit, page } = req.query;
    let query = `
      SELECT p.*, u.name AS owner_name, u.phone AS owner_user_phone
      FROM posts p
      LEFT JOIN users u ON p.owner_uid = u.uid
      WHERE 1=1
    `;
    const params = [];
    let paramIndex = 1;

    if (status && status !== 'all') {
      if (status === 'pending') {
        query += ` AND LOWER(TRIM(p.payment_status)) = 'pending'`;
      } else if (status === 'approved') {
        query += ` AND (LOWER(TRIM(p.payment_status)) = 'approved' OR p.is_published = true)`;
      } else if (status === 'rejected') {
        query += ` AND LOWER(TRIM(p.payment_status)) = 'rejected'`;
      }
    }

    if (search) {
      query += ` AND (
        LOWER(p.title) LIKE $${paramIndex} OR 
        LOWER(COALESCE(p.owner_phone, '')) LIKE $${paramIndex} OR 
        LOWER(COALESCE(p.payment_trx_id, '')) LIKE $${paramIndex} OR 
        LOWER(COALESCE(p.sender_number, '')) LIKE $${paramIndex} OR
        LOWER(COALESCE(u.name, '')) LIKE $${paramIndex}
      )`;
      params.push(`%${search.toLowerCase().trim()}%`);
      paramIndex++;
    }

    query += ' ORDER BY p.created_at DESC';

    if (limit && limit !== 'all') {
      const parsedLimit = parseInt(limit) || 20;
      const parsedPage = parseInt(page) || 1;
      const offset = (parsedPage - 1) * parsedLimit;
      query += ` LIMIT $${paramIndex++} OFFSET $${paramIndex++}`;
      params.push(parsedLimit, offset);
    }

    const result = await pool.query(query, params);
    const posts = result.rows.map(row => ({
      ...row,
      images: typeof row.images === 'string' ? JSON.parse(row.images) : row.images,
      facilities: typeof row.facilities === 'string' ? JSON.parse(row.facilities) : row.facilities,
    }));

    res.status(200).json(posts);
  } catch (error) {
    console.error('Error fetching posts for admin:', error);
    res.status(500).json({ error: 'Server error fetching posts' });
  }
};

exports.approvePost = async (req, res) => {
  const { id } = req.params;
  try {
    const result = await pool.query(
      `UPDATE posts SET 
        payment_status = 'approved', 
        is_published = true, 
        is_available = true, 
        updated_at = CURRENT_TIMESTAMP 
       WHERE post_id = $1 RETURNING *`,
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Post not found' });
    }

    const post = result.rows[0];
    post.images = typeof post.images === 'string' ? JSON.parse(post.images) : post.images;
    post.facilities = typeof post.facilities === 'string' ? JSON.parse(post.facilities) : post.facilities;

    // Send in-app notification
    if (post.owner_uid) {
      await pool.query(
        `INSERT INTO notifications (title, body, type, receiver_uid, sender_uid)
         VALUES ($1, $2, $3, $4, $5)`,
        [
          'Post Approved! 🎉',
          `Your mess post "${post.title}" has been verified and published!`,
          'postApproved',
          post.owner_uid,
          req.user.uid
        ]
      ).catch(e => console.error('Notification error:', e));
    }

    res.status(200).json(post);
  } catch (error) {
    console.error('Error approving post:', error);
    res.status(500).json({ error: 'Server error approving post' });
  }
};

exports.rejectPost = async (req, res) => {
  const { id } = req.params;
  try {
    const result = await pool.query(
      `UPDATE posts SET 
        payment_status = 'rejected', 
        is_published = false, 
        updated_at = CURRENT_TIMESTAMP 
       WHERE post_id = $1 RETURNING *`,
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Post not found' });
    }

    const post = result.rows[0];
    post.images = typeof post.images === 'string' ? JSON.parse(post.images) : post.images;
    post.facilities = typeof post.facilities === 'string' ? JSON.parse(post.facilities) : post.facilities;

    if (post.owner_uid) {
      await pool.query(
        `INSERT INTO notifications (title, body, type, receiver_uid, sender_uid)
         VALUES ($1, $2, $3, $4, $5)`,
        [
          'Post Rejected ❌',
          `Your mess post "${post.title}" was not approved or payment could not be verified.`,
          'postRejected',
          post.owner_uid,
          req.user.uid
        ]
      ).catch(e => console.error('Notification error:', e));
    }

    res.status(200).json(post);
  } catch (error) {
    console.error('Error rejecting post:', error);
    res.status(500).json({ error: 'Server error rejecting post' });
  }
};

exports.deletePost = async (req, res) => {
  const { id } = req.params;
  try {
    const result = await pool.query('DELETE FROM posts WHERE post_id = $1 RETURNING *', [id]);
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Post not found' });
    }
    res.status(200).json({ message: 'Post deleted successfully' });
  } catch (error) {
    console.error('Error deleting post:', error);
    res.status(500).json({ error: 'Server error deleting post' });
  }
};

// ─── 4. Booking Management ───────────────────────────────────────────────────
exports.getAllBookings = async (req, res) => {
  try {
    const { status, search } = req.query;
    let query = `
      SELECT 
        b.*,
        p.title AS post_title,
        p.rent AS post_rent,
        p.address AS post_address,
        u_bach.name AS bachelor_name_from_user,
        u_bach.phone AS bachelor_phone_from_user,
        u_land.name AS landlord_name,
        u_land.phone AS landlord_phone
      FROM bookings b
      LEFT JOIN posts p ON b.post_id::text = p.post_id::text
      LEFT JOIN users u_bach ON b.bachelor_uid = u_bach.uid
      LEFT JOIN users u_land ON b.landlord_uid = u_land.uid
      WHERE 1=1
    `;
    const params = [];
    let paramIndex = 1;

    if (status && status !== 'all') {
      if (status === 'pending') {
        query += ` AND LOWER(TRIM(b.payment_status)) = 'pending'`;
      } else if (status === 'approved') {
        query += ` AND (LOWER(TRIM(b.payment_status)) = 'approved' OR b.is_unlocked = true)`;
      } else if (status === 'rejected') {
        query += ` AND LOWER(TRIM(b.payment_status)) = 'rejected'`;
      }
    }

    if (search) {
      query += ` AND (
        LOWER(COALESCE(b.bachelor_name, u_bach.name, '')) LIKE $${paramIndex} OR 
        LOWER(COALESCE(b.bachelor_phone, u_bach.phone, '')) LIKE $${paramIndex} OR 
        LOWER(COALESCE(b.trx_id, '')) LIKE $${paramIndex} OR 
        LOWER(COALESCE(b.sender_number, '')) LIKE $${paramIndex} OR
        LOWER(COALESCE(p.title, '')) LIKE $${paramIndex}
      )`;
      params.push(`%${search.toLowerCase().trim()}%`);
      paramIndex++;
    }

    query += ' ORDER BY b.created_at DESC';

    const result = await pool.query(query, params);
    const bookings = result.rows.map(row => ({
      bookingId: row.booking_id,
      postId: row.post_id,
      bachelorUid: row.bachelor_uid,
      landlordUid: row.landlord_uid,
      bachelorName: row.bachelor_name || row.bachelor_name_from_user || 'Unknown Bachelor',
      bachelorPhone: row.bachelor_phone || row.bachelor_phone_from_user || '',
      trxId: row.trx_id || '',
      senderNumber: row.sender_number || '',
      paymentStatus: row.payment_status || 'pending',
      isUnlocked: row.is_unlocked || false,
      createdAt: row.created_at,
      postTitle: row.post_title,
      postRent: row.post_rent,
      landlordName: row.landlord_name,
      landlordPhone: row.landlord_phone,
    }));

    res.status(200).json(bookings);
  } catch (error) {
    console.error('Error fetching bookings for admin:', error);
    res.status(500).json({ error: 'Server error fetching bookings' });
  }
};

exports.approveBooking = async (req, res) => {
  const { id } = req.params;
  try {
    const result = await pool.query(
      `UPDATE bookings SET 
        payment_status = 'approved', 
        is_unlocked = true, 
        updated_at = CURRENT_TIMESTAMP 
       WHERE booking_id = $1 RETURNING *`,
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Booking not found' });
    }

    const booking = result.rows[0];

    // Automatically close / update the post
    if (booking.post_id) {
      await pool.query(
        'UPDATE posts SET is_available = false, updated_at = CURRENT_TIMESTAMP WHERE post_id::text = $1',
        [booking.post_id.toString()]
      ).catch(e => console.warn('Could not auto-close post on booking approval:', e));
    }

    // Send notifications to bachelor & landlord
    if (booking.bachelor_uid) {
      await pool.query(
        `INSERT INTO notifications (title, body, type, receiver_uid, sender_uid)
         VALUES ($1, $2, $3, $4, $5)`,
        [
          'Booking Approved! 🎉',
          'Your payment was verified. You can now contact the landlord directly.',
          'bookingApproved',
          booking.bachelor_uid,
          req.user.uid
        ]
      ).catch(e => console.error('Notification error:', e));
    }

    if (booking.landlord_uid) {
      await pool.query(
        `INSERT INTO notifications (title, body, type, receiver_uid, sender_uid)
         VALUES ($1, $2, $3, $4, $5)`,
        [
          'Booking Payment Verified 💰',
          `${booking.bachelor_name || 'A bachelor'} has paid the booking fee. They might contact you soon.`,
          'paymentVerified',
          booking.landlord_uid,
          req.user.uid
        ]
      ).catch(e => console.error('Notification error:', e));
    }

    res.status(200).json(booking);
  } catch (error) {
    console.error('Error approving booking:', error);
    res.status(500).json({ error: 'Server error approving booking' });
  }
};

exports.rejectBooking = async (req, res) => {
  const { id } = req.params;
  try {
    const result = await pool.query(
      `UPDATE bookings SET 
        payment_status = 'rejected', 
        is_unlocked = false, 
        updated_at = CURRENT_TIMESTAMP 
       WHERE booking_id = $1 RETURNING *`,
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Booking not found' });
    }

    const booking = result.rows[0];

    if (booking.bachelor_uid) {
      await pool.query(
        `INSERT INTO notifications (title, body, type, receiver_uid, sender_uid)
         VALUES ($1, $2, $3, $4, $5)`,
        [
          'Booking Rejected ❌',
          'Your booking request was rejected or payment could not be verified.',
          'bookingRejected',
          booking.bachelor_uid,
          req.user.uid
        ]
      ).catch(e => console.error('Notification error:', e));
    }

    res.status(200).json(booking);
  } catch (error) {
    console.error('Error rejecting booking:', error);
    res.status(500).json({ error: 'Server error rejecting booking' });
  }
};

exports.deleteBooking = async (req, res) => {
  const { id } = req.params;
  try {
    const result = await pool.query('DELETE FROM bookings WHERE booking_id = $1 RETURNING *', [id]);
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Booking not found' });
    }
    res.status(200).json({ message: 'Booking deleted successfully' });
  } catch (error) {
    console.error('Error deleting booking:', error);
    res.status(500).json({ error: 'Server error deleting booking' });
  }
};

// ─── 5. Payment Records Management ──────────────────────────────────────────
exports.getAllPayments = async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM payments ORDER BY created_at DESC');
    res.status(200).json(result.rows);
  } catch (error) {
    console.error('Error fetching payments:', error);
    res.status(500).json({ error: 'Server error fetching payments' });
  }
};

// ─── 6. Global Broadcast Announcements ──────────────────────────────────────
exports.broadcastNotification = async (req, res) => {
  const { title, body, targetRole } = req.body;
  if (!title || !body) {
    return res.status(400).json({ error: 'Title and body are required' });
  }

  try {
    let userQuery = 'SELECT uid FROM users';
    const params = [];
    if (targetRole && targetRole !== 'all') {
      userQuery += ' WHERE LOWER(TRIM(role)) = $1';
      params.push(targetRole.toLowerCase().trim());
    }

    const users = await pool.query(userQuery, params);
    
    for (const u of users.rows) {
      await pool.query(
        `INSERT INTO notifications (title, body, type, receiver_uid, sender_uid)
         VALUES ($1, $2, 'announcement', $3, $4)`,
        [title, body, u.uid, req.user.uid]
      ).catch(() => {});
    }

    res.status(200).json({
      message: `Announcement broadcasted to ${users.rows.length} users successfully!`,
      count: users.rows.length
    });
  } catch (error) {
    console.error('Error broadcasting notification:', error);
    res.status(500).json({ error: 'Server error broadcasting notification' });
  }
};

