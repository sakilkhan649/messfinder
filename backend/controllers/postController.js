const pool = require('../config/db');

// Add new post
exports.createPost = async (req, res) => {
  const {
    title, rent, address, latitude, longitude, images, videoUrl,
    seatCount, seatDescription, division, district, bachelorType,
    preferredTenant, facilities, ownerPhone, paymentTrxId, senderNumber,
    isAvailable, isPublished, paymentStatus
  } = req.body;

  try {
    const newPost = await pool.query(
      `INSERT INTO posts (
        owner_uid, title, rent, address, latitude, longitude, images, video_url,
        seat_count, seat_description, division, district, bachelor_type,
        preferred_tenant, facilities, owner_phone, payment_trx_id, sender_number,
        is_available, is_published, payment_status
      ) VALUES (
        $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20, $21
      ) RETURNING *`,
      [
        req.user.uid,
        title,
        rent,
        address,
        latitude || 23.8103,
        longitude || 90.4125,
        JSON.stringify(images || []),
        videoUrl || null,
        seatCount || 1,
        seatDescription || null,
        division || 'Dhaka',
        district || 'Dhaka',
        bachelorType || 'male',
        preferredTenant || 'Student / Job holder',
        JSON.stringify(facilities || []),
        ownerPhone || null,
        paymentTrxId || null,
        senderNumber || null,
        isAvailable !== undefined ? isAvailable : true,
        isPublished !== undefined ? isPublished : true,
        paymentStatus || 'approved'
      ]
    );

    const post = newPost.rows[0];
    post.images = typeof post.images === 'string' ? JSON.parse(post.images) : post.images;
    post.facilities = typeof post.facilities === 'string' ? JSON.parse(post.facilities) : post.facilities;

    res.status(201).json(post);
  } catch (error) {
    console.error('Error creating post:', error);
    res.status(500).json({ error: 'Server error creating post' });
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
    if (district && district !== 'All') {
      query += ` AND district = $${paramIndex++}`;
      params.push(district);
    }
    if (division && division !== 'All') {
      query += ` AND division = $${paramIndex++}`;
      params.push(division);
    }
    if (bachelorType && bachelorType !== 'all') {
      query += ` AND bachelor_type = $${paramIndex++}`;
      params.push(bachelorType);
    }

    query += ' ORDER BY created_at DESC';

    const result = await pool.query(query, params);
    
    const posts = result.rows.map(row => ({
      ...row,
      images: typeof row.images === 'string' ? JSON.parse(row.images) : row.images,
      facilities: typeof row.facilities === 'string' ? JSON.parse(row.facilities) : row.facilities
    }));

    res.status(200).json(posts);
  } catch (error) {
    console.error('Error fetching posts:', error);
    res.status(500).json({ error: 'Server error fetching posts' });
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
    console.error('Error fetching post by ID:', error);
    res.status(500).json({ error: 'Server error' });
  }
};

// Get My Posts (for logged-in landlord)
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
    console.error('Error fetching my posts:', error);
    res.status(500).json({ error: 'Server error' });
  }
};

// Update Post (supports full edit, status toggle, admin approve/reject)
exports.updatePost = async (req, res) => {
  const { id } = req.params;
  const {
    title, rent, address, latitude, longitude, images, videoUrl,
    seatCount, seatDescription, division, district, bachelorType,
    preferredTenant, facilities, ownerPhone, isAvailable, isPublished,
    paymentStatus, paymentTrxId, senderNumber
  } = req.body;

  try {
    // Check if post exists and user has rights (owner or admin)
    const existingPost = await pool.query('SELECT * FROM posts WHERE post_id = $1', [id]);
    if (existingPost.rows.length === 0) {
      return res.status(404).json({ error: 'Post not found' });
    }

    const userCheck = await pool.query('SELECT role FROM users WHERE uid = $1', [req.user.uid]);
    const userRole = userCheck.rows[0]?.role;
    const isOwner = existingPost.rows[0].owner_uid === req.user.uid;
    const isAdmin = userRole === 'admin';

    if (!isOwner && !isAdmin) {
      return res.status(403).json({ error: 'Not authorized to update this post' });
    }

    const current = existingPost.rows[0];

    const updatedImages = images !== undefined ? JSON.stringify(images) : current.images;
    const updatedFacilities = facilities !== undefined ? JSON.stringify(facilities) : current.facilities;

    const result = await pool.query(
      `UPDATE posts SET 
        title = COALESCE($1, title),
        rent = COALESCE($2, rent),
        address = COALESCE($3, address),
        latitude = COALESCE($4, latitude),
        longitude = COALESCE($5, longitude),
        images = COALESCE($6::jsonb, images),
        video_url = COALESCE($7, video_url),
        seat_count = COALESCE($8, seat_count),
        seat_description = COALESCE($9, seat_description),
        division = COALESCE($10, division),
        district = COALESCE($11, district),
        bachelor_type = COALESCE($12, bachelor_type),
        preferred_tenant = COALESCE($13, preferred_tenant),
        facilities = COALESCE($14::jsonb, facilities),
        owner_phone = COALESCE($15, owner_phone),
        is_available = COALESCE($16, is_available),
        is_published = COALESCE($17, is_published),
        payment_status = COALESCE($18, payment_status),
        payment_trx_id = COALESCE($19, payment_trx_id),
        sender_number = COALESCE($20, sender_number),
        updated_at = CURRENT_TIMESTAMP
       WHERE post_id = $21 RETURNING *`,
      [
        title,
        rent,
        address,
        latitude,
        longitude,
        updatedImages,
        videoUrl,
        seatCount,
        seatDescription,
        division,
        district,
        bachelorType,
        preferredTenant,
        updatedFacilities,
        ownerPhone,
        isAvailable,
        isPublished,
        paymentStatus,
        paymentTrxId,
        senderNumber,
        id
      ]
    );

    const post = result.rows[0];
    post.images = typeof post.images === 'string' ? JSON.parse(post.images) : post.images;
    post.facilities = typeof post.facilities === 'string' ? JSON.parse(post.facilities) : post.facilities;

    res.status(200).json(post);
  } catch (error) {
    console.error('Error updating post:', error);
    res.status(500).json({ error: 'Server error updating post' });
  }
};

// Delete Post
exports.deletePost = async (req, res) => {
  const { id } = req.params;
  try {
    const existingPost = await pool.query('SELECT * FROM posts WHERE post_id = $1', [id]);
    if (existingPost.rows.length === 0) {
      return res.status(404).json({ error: 'Post not found' });
    }

    const userCheck = await pool.query('SELECT role FROM users WHERE uid = $1', [req.user.uid]);
    const userRole = userCheck.rows[0]?.role;
    const isOwner = existingPost.rows[0].owner_uid === req.user.uid;
    const isAdmin = userRole === 'admin';

    if (!isOwner && !isAdmin) {
      return res.status(403).json({ error: 'Not authorized to delete this post' });
    }

    await pool.query('DELETE FROM posts WHERE post_id = $1', [id]);
    res.status(200).json({ message: 'Deleted successfully' });
  } catch (error) {
    console.error('Error deleting post:', error);
    res.status(500).json({ error: 'Server error' });
  }
};

// Toggle Availability
exports.toggleAvailability = async (req, res) => {
  const { id } = req.params;
  const { isAvailable } = req.body;
  try {
    const result = await pool.query(
      'UPDATE posts SET is_available = $1, updated_at = CURRENT_TIMESTAMP WHERE post_id = $2 AND owner_uid = $3 RETURNING *',
      [isAvailable, id, req.user.uid]
    );
    if (result.rows.length === 0) return res.status(403).json({ error: 'Not authorized or post not found' });
    
    const post = result.rows[0];
    post.images = typeof post.images === 'string' ? JSON.parse(post.images) : post.images;
    post.facilities = typeof post.facilities === 'string' ? JSON.parse(post.facilities) : post.facilities;

    res.status(200).json(post);
  } catch (error) {
    console.error('Error toggling post availability:', error);
    res.status(500).json({ error: 'Server error' });
  }
};
