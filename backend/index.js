const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');

// Load env vars
dotenv.config();

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
app.use('/api/chats', require('./routes/chatRoutes'));
app.use('/api/upload', require('./routes/uploadRoutes'));

// Serve uploaded files as static
const path = require('path');
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

const http = require('http');
const { Server } = require('socket.io');

const server = http.createServer(app);
const io = new Server(server, {
  cors: { origin: '*' }
});

// Socket.io integration
io.on('connection', (socket) => {
  console.log('User connected:', socket.id);

  socket.on('join_chat', (chatId) => {
    socket.join(chatId);
    console.log(`User joined chat: ${chatId}`);
  });

  socket.on('send_message', async (data) => {
    // data: { chatId, senderUid, text, imageUrl, videoUrl }
    try {
      const { chatId, senderUid, text, imageUrl, videoUrl } = data;
      const pool = require('./config/db');

      // Save message to database
      const newMsg = await pool.query(
        `INSERT INTO messages (chat_id, sender_uid, text, image_url, video_url) 
         VALUES ($1, $2, $3, $4, $5) RETURNING *`,
        [chatId, senderUid, text, imageUrl, videoUrl]
      );

      // Update chat last message
      await pool.query(
        'UPDATE chats SET last_message = $1, last_message_time = CURRENT_TIMESTAMP WHERE chat_id = $2',
        [text || 'Media', chatId]
      );

      // Broadcast to room
      io.to(chatId).emit('receive_message', newMsg.rows[0]);
    } catch (error) {
      console.error('Socket send_message error:', error);
    }
  });

  socket.on('disconnect', () => {
    console.log('User disconnected:', socket.id);
  });
});

// Start Server
server.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
