const pool = require('./config/db');

async function seedProducts() {
  try {
    console.log('Connecting to database...');
    
    // Get a valid user to assign as seller
    const userRes = await pool.query('SELECT uid FROM users LIMIT 1');
    if (userRes.rows.length === 0) {
      console.error('No users found in database. Please create a user first.');
      process.exit(1);
    }
    const sellerUid = userRes.rows[0].uid;
    console.log(`Using seller UID: ${sellerUid}`);

    const categories = ['Furniture', 'Electronics', 'Books', 'Utensils', 'Others'];
    const divisions = ['Dhaka', 'Chittagong', 'Rajshahi', 'Sylhet', 'Khulna', 'Barishal', 'Rangpur', 'Mymensingh'];
    
    // Sample images
    const sampleImages = [
      'https://images.unsplash.com/photo-1592078615290-033ee584e267?q=80&w=600&auto=format&fit=crop', // Furniture
      'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?q=80&w=600&auto=format&fit=crop', // Electronics
      'https://images.unsplash.com/photo-1544947950-fa07a98d237f?q=80&w=600&auto=format&fit=crop', // Books
      'https://images.unsplash.com/photo-1583223616646-9d3e8e19e075?q=80&w=600&auto=format&fit=crop', // Utensils
      'https://images.unsplash.com/photo-1518770660439-4636190af475?q=80&w=600&auto=format&fit=crop'  // Others
    ];

    console.log('Inserting 20 products...');

    for (let i = 1; i <= 20; i++) {
      const category = categories[i % categories.length];
      const image = sampleImages[i % sampleImages.length];
      const division = divisions[i % divisions.length];
      const price = Math.floor(Math.random() * 5000) + 100;

      await pool.query(
        `INSERT INTO products (
          seller_uid, title, description, price, condition, category, images, division, district, status
        ) VALUES (
          $1, $2, $3, $4, $5, $6, $7, $8, $9, $10
        )`,
        [
          sellerUid,
          `Sample Product ${i} - ${category}`,
          `This is a mock description for product ${i}. It is in great condition.`,
          price,
          'used',
          category,
          JSON.stringify([image]),
          division,
          `${division} City`,
          'active'
        ]
      );
    }

    console.log('Successfully seeded 20 products!');
    process.exit(0);
  } catch (error) {
    console.error('Error seeding products:', error);
    process.exit(1);
  }
}

seedProducts();
