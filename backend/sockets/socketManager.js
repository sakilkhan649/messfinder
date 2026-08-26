const { Server } = require('socket.io');
const { RtcTokenBuilder, RtcRole } = require('agora-token');

let io;
const onlineUsers = new Map(); // uid -> socket.id

const initSocket = (server, app) => {
  io = new Server(server, {
    cors: { origin: '*' }
  });

  const generateAgoraToken = (channelName, uid = 0) => {
    try {
      const appId = process.env.AGORA_APP_ID;
      const appCertificate = process.env.AGORA_APP_CERTIFICATE;
      if (!appId || !appCertificate) return '';
      const role = RtcRole.PUBLISHER;
      const expirationTimeInSeconds = 86400; // 24 hours
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

  io.on('connection', (socket) => {
    console.log('User connected:', socket.id);

    const queryUid = socket.handshake.query?.userId;
    if (queryUid) {
      socket.join(queryUid);
      onlineUsers.set(queryUid, socket.id);
      console.log(`User auto-joined room from query: ${queryUid}`);
      socket.broadcast.emit('user_online', { userId: queryUid });
    }

    socket.on('join_chat', (chatId) => {
      socket.join(chatId);
      console.log(`User joined chat: ${chatId}`);
    });

    socket.on('send_message', async (data) => {
      try {
        const { chatId, senderUid, targetUid, text, imageUrl, videoUrl, replyToMessageId, replyToMessageText, replyToMessageSender } = data;
        const pool = require('../config/db');

        const newMsg = await pool.query(
          `INSERT INTO messages (chat_id, sender_uid, text, image_url, video_url, reply_to_message_id, reply_to_message_text, reply_to_message_sender) 
           VALUES ($1, $2, $3, $4, $5, $6, $7, $8) RETURNING *, 
           reply_to_message_id as "replyToMessageId", 
           reply_to_message_text as "replyToMessageText", 
           reply_to_message_sender as "replyToMessageSender"`,
          [chatId, senderUid, text, imageUrl, videoUrl, replyToMessageId, replyToMessageText, replyToMessageSender]
        );

        await pool.query(
          'UPDATE chats SET last_message = $1, last_message_time = CURRENT_TIMESTAMP WHERE chat_id = $2',
          [text || 'Media', chatId]
        );

        io.to(chatId).emit('receive_message', newMsg.rows[0]);
        if (targetUid) {
          io.to(targetUid).emit('receive_message', newMsg.rows[0]);
        }
      } catch (error) {
        console.error('Socket send_message error:', error);
      }
    });

    socket.on('react_message', async (data) => {
      try {
        const { chatId, messageId, emoji, uid } = data;
        const pool = require('../config/db');
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
      try {
        const { chatId, messageId, text, senderUid } = data;
        const pool = require('../config/db');
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
      try {
        const { chatId, messageId, senderUid } = data;
        const pool = require('../config/db');
        const delRes = await pool.query(
          'UPDATE messages SET is_deleted = true, text = $1, image_url = null, video_url = null WHERE message_id = $2 AND sender_uid = $3 RETURNING *',
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

    socket.on('make_call', async (data) => {
      const token = generateAgoraToken(data.channelName, 0);
      const payload = { ...data, token };
      console.log(`Call initiated from ${data.callerName} (${data.callerId}) to ${data.targetUserId} [Token generated]`);
      
      const targetRoom = io.sockets.adapter.rooms.get(data.targetUserId);
      const isTargetOnline = targetRoom && targetRoom.size > 0;
      
      if (isTargetOnline) {
        io.to(data.targetUserId).emit('incoming_call', payload);
      } else {
        console.log(`Target user ${data.targetUserId} is currently offline over socket`);
      }

      try {
        const { internalSendPushNotification } = require('../controllers/notificationController');
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
      const token = generateAgoraToken(data.channelName, 0);
      const payload = { ...data, token };
      console.log(`Call accepted by ${socket.id} for caller ${data.callerId} [Token generated]`);
      io.to(data.callerId).emit('call_accepted', payload);
      socket.emit('call_joined_receiver', { token: token });
    });

    socket.on('reject_call', (data) => {
      console.log(`Call rejected for caller ${data.callerId}`);
      io.to(data.callerId).emit('call_rejected', data);
    });

    socket.on('end_call', async (data) => {
      console.log(`Call ended for ${data.targetUserId}`);
      io.to(data.targetUserId).emit('call_ended', data);
      
      try {
        const { internalSendPushNotification } = require('../controllers/notificationController');
        await internalSendPushNotification({
          receiverUid: data.targetUserId,
          title: 'Call Ended',
          body: 'The call has ended',
          type: 'call_ended',
          relatedId: data.channelName || '',
          senderUid: '',
          senderPhotoUrl: ''
        });
      } catch (e) {
        console.error('Failed to send call_ended push notification:', e);
      }
    });

    socket.on('typing_start', (data) => {
      socket.to(data.chatId).emit('user_typing', { chatId: data.chatId, userId: data.userId });
    });

    socket.on('typing_stop', (data) => {
      socket.to(data.chatId).emit('user_stop_typing', { chatId: data.chatId, userId: data.userId });
    });

    socket.on('mark_seen', (data) => {
      socket.to(data.chatId).emit('message_seen', { chatId: data.chatId, lastMessageId: data.lastMessageId, seenByUid: data.seenByUid });
    });

    socket.on('get_online_users', (uids) => {
      try {
        let uidsArray = [];
        if (Array.isArray(uids)) {
          uidsArray = uids;
        } else if (typeof uids === 'string') {
          uidsArray = [uids];
        }
        const onlineUids = uidsArray.filter(uid => onlineUsers.has(uid));
        socket.emit('online_users_list', onlineUids);
      } catch (error) {
        console.error('Socket get_online_users error:', error);
      }
    });

    socket.on('disconnect', () => {
      console.log('User disconnected:', socket.id);
      if (queryUid) {
        onlineUsers.delete(queryUid);
        socket.broadcast.emit('user_offline', { userId: queryUid });
      }
    });
  });

  app.post('/api/reject_call', (req, res) => {
    const { callerId, reason } = req.body;
    if (callerId) {
      io.to(callerId).emit('call_rejected', { callerId, reason: reason || 'declined' });
      console.log(`Call rejected via API for caller ${callerId}`);
    }
    res.json({ success: true });
  });

  app.post('/api/accept_call', (req, res) => {
    const { callerId, channelName } = req.body;
    const token = generateAgoraToken(channelName, 0);
    if (callerId) {
      io.to(callerId).emit('call_accepted', { callerId, channelName, token });
      console.log(`Call accepted via API for caller ${callerId} [Token generated]`);
    }
    res.json({ success: true, token });
  });

  return io;
};

const getIo = () => {
  if (!io) {
    throw new Error('Socket.io is not initialized');
  }
  return io;
};

module.exports = {
  initSocket,
  getIo
};
