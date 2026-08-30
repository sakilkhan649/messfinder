const express = require('express');
const cors = require('cors');
const path = require('path');
const dotenv = require('dotenv');

// Load env vars from backend directory
dotenv.config({ path: path.join(__dirname, '.env') });

const app = express();
const PORT = process.env.PORT || 5000;



// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Basic route
app.get('/', (req, res) => {
  res.send('Mess Finder Backend API is running!');
});

// API Routes
app.use('/api/auth', require('./routes/authRoutes'));
app.use('/api/posts', require('./routes/postRoutes'));
app.use('/api/products', require('./routes/productRoutes'));
app.use('/api/chats', require('./routes/chatRoutes'));
app.use('/api/upload', require('./routes/uploadRoutes'));
app.use('/api/admin', require('./routes/adminRoutes'));
app.use('/api/bookings', require('./routes/bookingRoutes'));
app.use('/api/notifications', require('./routes/notificationRoutes'));
app.use('/api/reports', require('./routes/reportRoutes'));

// Serve uploaded files as static
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

const http = require('http');
const socketManager = require('./sockets/socketManager');

const server = http.createServer(app);

// Initialize Socket.io and attach API endpoints that interact with it
socketManager.initSocket(server, app);

// Start Server
server.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
