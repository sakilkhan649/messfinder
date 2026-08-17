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

// Get messages for a specific chat
exports.getMessages = async (req, res) => {
  try {
    const { chatId } = req.params;
    
    // Check if user is part of the chat
    const chatCheck = await pool.query('SELECT * FROM chats WHERE chat_id = $1 AND (user1_uid = $2 OR user2_uid = $2)', [chatId, req.user.uid]);
    if (chatCheck.rows.length === 0) {
      return res.status(403).json({ error: 'Not authorized to view this chat' });
    }

    const result = await pool.query('SELECT * FROM messages WHERE chat_id = $1 ORDER BY created_at ASC', [chatId]);
    res.status(200).json(result.rows);
  } catch (error) {
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
