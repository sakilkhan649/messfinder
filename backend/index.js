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

// Serve uploaded files as static
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

  const queryUid = socket.handshake.query?.userId;
  if (queryUid) {
    socket.join(queryUid);
    console.log(`User auto-joined room from query: ${queryUid}`);
  }

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

  socket.on('react_message', async (data) => {
    // data: { chatId, messageId, emoji, uid }
    try {
      const { chatId, messageId, emoji, uid } = data;
      const pool = require('./config/db');
      const msgRes = await pool.query('SELECT reactions FROM messages WHERE message_id = $1', [messageId]);
      if (msgRes.rows.length > 0) {
        let reactions = msgRes.rows[0].reactions || {};
        if (reactions[uid] === emoji) {
          delete reactions[uid];
        } else {
          reactions[uid] = emoji;
        }
        await pool.query('UPDATE messages SET reactions = $1 WHERE message_id = $2', [JSON.stringify(reactions), messageId]);
        io.to(chatId).emit('message_reacted', { messageId, chatId, reactions });
      }
    } catch (error) {
      console.error('Socket react_message error:', error);
    }
  });

  socket.on('edit_message', async (data) => {
    // data: { chatId, messageId, text, senderUid }
    try {
      const { chatId, messageId, text, senderUid } = data;
      const pool = require('./config/db');
      const updateRes = await pool.query(
        'UPDATE messages SET text = $1, is_edited = true WHERE message_id = $2 AND sender_uid = $3 RETURNING *',
        [text, messageId, senderUid]
      );
      if (updateRes.rows.length > 0) {
        io.to(chatId).emit('message_edited', { messageId, chatId, text, isEdited: true });
      }
    } catch (error) {
      console.error('Socket edit_message error:', error);
    }
  });

  socket.on('delete_message', async (data) => {
    // data: { chatId, messageId, senderUid }
    try {
      const { chatId, messageId, senderUid } = data;
      const pool = require('./config/db');
      const delRes = await pool.query(
        'UPDATE messages SET is_deleted = true, text = $1 WHERE message_id = $2 AND sender_uid = $3 RETURNING *',
        ['', messageId, senderUid]
      );
      if (delRes.rows.length > 0) {
        io.to(chatId).emit('message_deleted', { messageId, chatId });
      }
    } catch (error) {
      console.error('Socket delete_message error:', error);
    }
  });

  socket.on('join_user_room', (uid) => {
    if (uid) {
      socket.join(uid);
      console.log(`User joined personal room: ${uid}`);
    }
  });

  // ── Agora Call Signaling & Token Generation ───────────────────────
  const { RtcTokenBuilder, RtcRole } = require('agora-token');

  const generateAgoraToken = (channelName, uid = 0) => {
    try {
      const appId = process.env.AGORA_APP_ID;
      const appCertificate = process.env.AGORA_APP_CERTIFICATE;
      if (!appId || !appCertificate) return '';
      const role = RtcRole.PUBLISHER;
      const expirationTimeInSeconds = 3600;
      const currentTimestamp = Math.floor(Date.now() / 1000);
      const privilegeExpiredTs = currentTimestamp + expirationTimeInSeconds;

      return RtcTokenBuilder.buildTokenWithUid(
        appId,
        appCertificate,
        channelName,
        uid,
        role,
        privilegeExpiredTs,
        privilegeExpiredTs
      );
    } catch (err) {
      console.error('Agora token generation error:', err);
      return '';
    }
  };

  socket.on('make_call', async (data) => {
    // data: { targetUserId, channelName, isVideo, callerId, callerName, callerPhoto }
    const token = generateAgoraToken(data.channelName, 0);
    const payload = { ...data, token };
    console.log(`Call initiated from ${data.callerName} (${data.callerId}) to ${data.targetUserId} [Token generated]`);
    
    const targetRoom = io.sockets.adapter.rooms.get(data.targetUserId);
    const isTargetOnline = targetRoom && targetRoom.size > 0;
    
    if (isTargetOnline) {
      io.to(data.targetUserId).emit('incoming_call', payload);
    } else {
      console.log(`Target user ${data.targetUserId} is currently offline over socket`);
      // Optional: Inform caller immediately that user is offline, but wait to see if push wakes them up
      // socket.emit('call_user_offline', { targetUserId: data.targetUserId, message: 'User is offline' });
    }

    // Always send an FCM push notification to wake up the app if it's in the background
    try {
      const { internalSendPushNotification } = require('./controllers/notificationController');
      await internalSendPushNotification({
        receiverUid: data.targetUserId,
        title: data.isVideo ? '🎥 Incoming Video Call' : '📞 Incoming Audio Call',
        body: `Incoming call from ${data.callerName}`,
        type: 'call',
        relatedId: data.channelName,
        senderUid: data.callerId,
        senderPhotoUrl: data.callerPhoto
      });
    } catch (e) {
      console.error('Failed to send call push notification:', e);
    }
  });

  socket.on('accept_call', (data) => {
    // data: { callerId, channelName }
    const token = generateAgoraToken(data.channelName, 0);
    const payload = { ...data, token };
    console.log(`Call accepted by ${socket.id} for caller ${data.callerId} [Token generated]`);
    io.to(data.callerId).emit('call_accepted', payload);
  });

  socket.on('reject_call', (data) => {
    // data: { callerId }
    console.log(`Call rejected for caller ${data.callerId}`);
    io.to(data.callerId).emit('call_rejected', data);
  });

  socket.on('end_call', (data) => {
    // data: { targetUserId }
    console.log(`Call ended for ${data.targetUserId}`);
    io.to(data.targetUserId).emit('call_ended', data);
  });

  socket.on('disconnect', () => {
    console.log('User disconnected:', socket.id);
  });
});

// Start Server
server.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
