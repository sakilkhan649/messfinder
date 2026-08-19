const pool = require('../config/db');

// Create a new product
exports.createProduct = async (req, res) => {
  const { title, description, price, condition, category, images, division, district } = req.body;

  try {
    const newProduct = await pool.query(
      `INSERT INTO products (
        seller_uid, title, description, price, condition, category, images, division, district
      ) VALUES (
        $1, $2, $3, $4, $5, $6, $7, $8, $9
      ) RETURNING *`,
      [
        req.user.uid,
        title,
        description || '',
        price,
        condition || 'used',
        category || 'Others',
        JSON.stringify(images || []),
        division || 'Dhaka',
        district || 'Dhaka'
      ]
    );

    const product = newProduct.rows[0];
    product.images = typeof product.images === 'string' ? JSON.parse(product.images) : product.images;

    res.status(201).json(product);
  } catch (error) {
    console.error('Error creating product:', error);
    res.status(500).json({ error: 'Server error creating product' });
  }
};

// Get all active products with optional filters
exports.getProducts = async (req, res) => {
  try {
    const { division, district, category, limit = 20, offset = 0 } = req.query;

    let queryStr = `
      SELECT p.*, u.name as seller_name, u.profile_image as seller_image
      FROM products p
      LEFT JOIN users u ON p.seller_uid = u.uid
      WHERE p.status = 'active'
    `;
    const queryParams = [];
    let paramCount = 1;

    if (division) {
      queryStr += ` AND p.division = $${paramCount++}`;
      queryParams.push(division);
    }
    
    if (district) {
      queryStr += ` AND p.district = $${paramCount++}`;
      queryParams.push(district);
    }

    if (category) {
      queryStr += ` AND p.category = $${paramCount++}`;
      queryParams.push(category);
    }

    queryStr += ` ORDER BY p.created_at DESC LIMIT $${paramCount++} OFFSET $${paramCount++}`;
    queryParams.push(parseInt(limit, 10));
    queryParams.push(parseInt(offset, 10));

    const products = await pool.query(queryStr, queryParams);

    const formattedProducts = products.rows.map(product => ({
      ...product,
      images: typeof product.images === 'string' ? JSON.parse(product.images) : product.images
    }));

    res.json(formattedProducts);
  } catch (error) {
    console.error('Error fetching products:', error);
    res.status(500).json({ error: 'Server error fetching products' });
  }
};

// Get a single product by ID
exports.getProductById = async (req, res) => {
  try {
    const { id } = req.params;
    const productData = await pool.query(
      `SELECT p.*, u.name as seller_name, u.profile_image as seller_image, u.phone as seller_phone
       FROM products p
       LEFT JOIN users u ON p.seller_uid = u.uid
       WHERE p.product_id = $1`,
      [id]
    );

    if (productData.rows.length === 0) {
      return res.status(404).json({ error: 'Product not found' });
    }

    const product = productData.rows[0];
    product.images = typeof product.images === 'string' ? JSON.parse(product.images) : product.images;

    res.json(product);
  } catch (error) {
    console.error('Error fetching product:', error);
    res.status(500).json({ error: 'Server error fetching product' });
  }
};

// Get products by a specific user (seller)
exports.getUserProducts = async (req, res) => {
  try {
    const { uid } = req.params;
    
    const products = await pool.query(
      `SELECT * FROM products WHERE seller_uid = $1 ORDER BY created_at DESC`,
      [uid]
    );

    const formattedProducts = products.rows.map(product => ({
      ...product,
      images: typeof product.images === 'string' ? JSON.parse(product.images) : product.images
    }));

    res.json(formattedProducts);
  } catch (error) {
    console.error('Error fetching user products:', error);
    res.status(500).json({ error: 'Server error fetching user products' });
  }
};

// Update an existing product
exports.updateProduct = async (req, res) => {
  try {
    const { id } = req.params;
    const { title, description, price, condition, category, images, division, district, status } = req.body;
    
    // Ensure only the seller can edit
    const existing = await pool.query(`SELECT seller_uid FROM products WHERE product_id = $1`, [id]);
    if (existing.rows.length === 0) {
      return res.status(404).json({ error: 'Product not found' });
    }
    if (existing.rows[0].seller_uid !== req.user.uid) {
      return res.status(403).json({ error: 'Unauthorized to edit this product' });
    }

    const updatedProduct = await pool.query(
      `UPDATE products SET
        title = COALESCE($1, title),
        description = COALESCE($2, description),
        price = COALESCE($3, price),
        condition = COALESCE($4, condition),
        category = COALESCE($5, category),
        images = COALESCE($6, images),
        division = COALESCE($7, division),
        district = COALESCE($8, district),
        status = COALESCE($9, status),
        updated_at = CURRENT_TIMESTAMP
       WHERE product_id = $10 RETURNING *`,
      [
        title,
        description,
        price,
        condition,
        category,
        images ? JSON.stringify(images) : null,
        division,
        district,
        status,
        id
      ]
    );

    const product = updatedProduct.rows[0];
    product.images = typeof product.images === 'string' ? JSON.parse(product.images) : product.images;

    res.json(product);
  } catch (error) {
    console.error('Error updating product:', error);
    res.status(500).json({ error: 'Server error updating product' });
  }
};

// Delete a product
exports.deleteProduct = async (req, res) => {
  try {
    const { id } = req.params;
    
    // Ensure only the seller can delete
    const existing = await pool.query(`SELECT seller_uid FROM products WHERE product_id = $1`, [id]);
    if (existing.rows.length === 0) {
      return res.status(404).json({ error: 'Product not found' });
    }
    if (existing.rows[0].seller_uid !== req.user.uid) {
      return res.status(403).json({ error: 'Unauthorized to delete this product' });
    }

    await pool.query(`DELETE FROM products WHERE product_id = $1`, [id]);

    res.json({ message: 'Product deleted successfully' });
  } catch (error) {
    console.error('Error deleting product:', error);
    res.status(500).json({ error: 'Server error deleting product' });
  }
};
