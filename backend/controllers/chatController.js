const pool = require('../config/db');

// Get all chats for the current user
exports.getChats = async (req, res) => {
  try {
    const uid = req.user.uid;
    const result = await pool.query(
      `SELECT c.*, 
        CASE WHEN c.user1_uid = $1 THEN u2.name ELSE u1.name END as other_user_name,
        CASE WHEN c.user1_uid = $1 THEN u2.profile_image ELSE u1.profile_image END as other_user_image,
        CASE WHEN c.user1_uid = $1 THEN u2.uid ELSE u1.uid END as other_user_uid
       FROM chats c
       JOIN users u1 ON c.user1_uid = u1.uid
       JOIN users u2 ON c.user2_uid = u2.uid
       WHERE c.user1_uid = $1 OR c.user2_uid = $1
       ORDER BY c.last_message_time DESC`,
      [uid]
    );
    res.status(200).json(result.rows);
  } catch (error) {
    console.error('Error fetching chats:', error);
    res.status(500).json({ error: 'Server error' });
  }
};

// Get messages for a specific chat (with optional pagination)
exports.getMessages = async (req, res) => {
  try {
    const { chatId } = req.params;
    const { limit, offset } = req.query;
    
    // Check if user is part of the chat
    const chatCheck = await pool.query(
      'SELECT * FROM chats WHERE chat_id = $1 AND (user1_uid = $2 OR user2_uid = $2)',
      [chatId, req.user.uid]
    );
    if (chatCheck.rows.length === 0) {
      return res.status(403).json({ error: 'Not authorized to view this chat' });
    }

    let query = 'SELECT * FROM messages WHERE chat_id = $1 ORDER BY created_at ASC';
    const params = [chatId];

    if (limit && limit !== 'all') {
      const parsedLimit = parseInt(limit) || 50;
      const parsedOffset = parseInt(offset) || 0;
      query += ' LIMIT $2 OFFSET $3';
      params.push(parsedLimit, parsedOffset);
    }

    const result = await pool.query(query, params);
    res.status(200).json(result.rows);
  } catch (error) {
    console.error('Error fetching messages:', error);
    res.status(500).json({ error: 'Server error' });
  }
};

// Create a new chat room
exports.createChat = async (req, res) => {
  const { targetUserId } = req.body;
  const currentUserId = req.user.uid;

  // Consistent chat ID generation (same logic as flutter app)
  const chatRoomId = currentUserId.localeCompare(targetUserId) > 0
      ? `${currentUserId}_${targetUserId}`
      : `${targetUserId}_${currentUserId}`;

  try {
    // Check if chat exists
    const chatCheck = await pool.query('SELECT * FROM chats WHERE chat_id = $1', [chatRoomId]);
    if (chatCheck.rows.length === 0) {
      // Create chat
      await pool.query(
        'INSERT INTO chats (chat_id, user1_uid, user2_uid) VALUES ($1, $2, $3)',
        [chatRoomId, currentUserId, targetUserId]
      );
    }
    res.status(200).json({ chatId: chatRoomId });
  } catch (error) {
    console.error('Error creating chat:', error);
    res.status(500).json({ error: 'Server error' });
  }
};

// Edit message
exports.editMessage = async (req, res) => {
  const { messageId } = req.params;
  const { text } = req.body;
  try {
    const result = await pool.query(
      'UPDATE messages SET text = $1, is_edited = true WHERE message_id = $2 AND sender_uid = $3 RETURNING *',
      [text, messageId, req.user.uid]
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Message not found or unauthorized' });
    }
    res.status(200).json(result.rows[0]);
  } catch (error) {
    console.error('Edit message error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};

// Delete message
exports.deleteMessage = async (req, res) => {
  const { messageId } = req.params;
  try {
    const result = await pool.query(
      'UPDATE messages SET is_deleted = true, text = $1 WHERE message_id = $2 AND sender_uid = $3 RETURNING *',
      ['', messageId, req.user.uid]
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Message not found or unauthorized' });
    }
    res.status(200).json({ success: true, message: result.rows[0] });
  } catch (error) {
    console.error('Delete message error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};

// Toggle reaction on message
exports.toggleReaction = async (req, res) => {
  const { messageId } = req.params;
  const { emoji } = req.body;
  const uid = req.user.uid;
  try {
    const msgRes = await pool.query('SELECT reactions FROM messages WHERE message_id = $1', [messageId]);
    if (msgRes.rows.length === 0) {
      return res.status(404).json({ error: 'Message not found' });
    }
    let reactions = msgRes.rows[0].reactions || {};
    if (reactions[uid] === emoji) {
      delete reactions[uid];
    } else {
      reactions[uid] = emoji;
    }
    const updateRes = await pool.query(
      'UPDATE messages SET reactions = $1 WHERE message_id = $2 RETURNING *',
      [JSON.stringify(reactions), messageId]
    );
    res.status(200).json(updateRes.rows[0]);
  } catch (error) {
    console.error('Reaction error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};
