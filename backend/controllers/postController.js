const pool = require('../config/db');

// Add new post
exports.createPost = async (req, res) => {
  const {
    title, rent, address, latitude, longitude, images, videoUrl,
    seatCount, seatDescription, division, district, bachelorType,
    preferredTenant, facilities, ownerPhone, paymentTrxId, senderNumber
  } = req.body;

  try {
    const newPost = await pool.query(
      `INSERT INTO posts (
        owner_uid, title, rent, address, latitude, longitude, images, video_url,
        seat_count, seat_description, division, district, bachelor_type,
        preferred_tenant, facilities, owner_phone, payment_trx_id, sender_number
      ) VALUES (
        $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18
      ) RETURNING *`,
      [
        req.user.uid, title, rent, address, latitude || 23.8103, longitude || 90.4125,
        JSON.stringify(images || []), videoUrl, seatCount || 1, seatDescription,
        division || 'Dhaka', district || 'Dhaka', bachelorType || 'male',
        preferredTenant || 'Student / Job holder', JSON.stringify(facilities || []),
        ownerPhone, paymentTrxId, senderNumber
      ]
    );

    res.status(201).json(newPost.rows[0]);
  } catch (error) {
    console.error('Error creating post:', error);
    res.status(500).json({ error: 'Server error' });
  }
};

// Get all published posts (with optional filtering)
exports.getPosts = async (req, res) => {
  try {
    const { district, division, bachelorType, ownerUid, owner_uid } = req.query;
    const targetOwner = ownerUid || owner_uid;
    
    let query = 'SELECT * FROM posts WHERE is_published = true AND is_available = true';
    const params = [];
    let paramIndex = 1;

    if (targetOwner) {
      query += ` AND owner_uid = $${paramIndex++}`;
      params.push(targetOwner);
    }
    if (district) {
      query += ` AND district = $${paramIndex++}`;
      params.push(district);
    }
    if (division) {
      query += ` AND division = $${paramIndex++}`;
      params.push(division);
    }
    if (bachelorType) {
      query += ` AND bachelor_type = $${paramIndex++}`;
      params.push(bachelorType);
    }

    query += ' ORDER BY created_at DESC';

    const result = await pool.query(query, params);
    
    // Parse JSONB strings if pg doesn't auto-parse
    const posts = result.rows.map(row => ({
      ...row,
      images: typeof row.images === 'string' ? JSON.parse(row.images) : row.images,
      facilities: typeof row.facilities === 'string' ? JSON.parse(row.facilities) : row.facilities
    }));

    res.status(200).json(posts);
  } catch (error) {
    console.error('Error fetching posts:', error);
    res.status(500).json({ error: 'Server error' });
  }
};

// Get single post
exports.getPostById = async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM posts WHERE post_id = $1', [req.params.id]);
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Post not found' });
    }
    const row = result.rows[0];
    row.images = typeof row.images === 'string' ? JSON.parse(row.images) : row.images;
    row.facilities = typeof row.facilities === 'string' ? JSON.parse(row.facilities) : row.facilities;
    
    res.status(200).json(row);
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
};

// Get My Posts
exports.getMyPosts = async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM posts WHERE owner_uid = $1 ORDER BY created_at DESC', [req.user.uid]);
    const posts = result.rows.map(row => ({
      ...row,
      images: typeof row.images === 'string' ? JSON.parse(row.images) : row.images,
      facilities: typeof row.facilities === 'string' ? JSON.parse(row.facilities) : row.facilities
    }));
    res.status(200).json(posts);
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
};

// Update Post
exports.updatePost = async (req, res) => {
  const { id } = req.params;
  const { title, rent, isAvailable } = req.body;
  try {
    const result = await pool.query(
      `UPDATE posts SET title = COALESCE($1, title), rent = COALESCE($2, rent), is_available = COALESCE($3, is_available) 
       WHERE post_id = $4 AND owner_uid = $5 RETURNING *`,
      [title, rent, isAvailable, id, req.user.uid]
    );
    if (result.rows.length === 0) return res.status(403).json({ error: 'Not authorized or post not found' });
    res.status(200).json(result.rows[0]);
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
};

// Delete Post
exports.deletePost = async (req, res) => {
  const { id } = req.params;
  try {
    const result = await pool.query('DELETE FROM posts WHERE post_id = $1 AND owner_uid = $2 RETURNING *', [id, req.user.uid]);
    if (result.rows.length === 0) return res.status(403).json({ error: 'Not authorized or post not found' });
    res.status(200).json({ message: 'Deleted successfully' });
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
};

// Toggle Availability
exports.toggleAvailability = async (req, res) => {
  const { id } = req.params;
  const { isAvailable } = req.body;
  try {
    const result = await pool.query('UPDATE posts SET is_available = $1 WHERE post_id = $2 AND owner_uid = $3 RETURNING *', [isAvailable, id, req.user.uid]);
    if (result.rows.length === 0) return res.status(403).json({ error: 'Not authorized or post not found' });
    res.status(200).json(result.rows[0]);
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
};
