const admin = require('firebase-admin');
const pool = require('../config/db');
const path = require('path');
const fs = require('fs');

// Ensure notifications table exists
const initNotificationsTable = async () => {
  try {
    await pool.query(`
      CREATE TABLE IF NOT EXISTS notifications (
        id SERIAL PRIMARY KEY,
        receiver_uid VARCHAR(255) NOT NULL,
        sender_uid VARCHAR(255),
        title VARCHAR(255) NOT NULL,
        body TEXT NOT NULL,
        type VARCHAR(50) DEFAULT 'general',
        related_id VARCHAR(255),
        is_read BOOLEAN DEFAULT false,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);
  } catch (err) {
    console.error('Error creating notifications table:', err);
  }
};

initNotificationsTable();

// Initialize Firebase Admin lazily to prevent crashing if the key is missing
let isFirebaseInitialized = false;

function initFirebase() {
  if (isFirebaseInitialized) return true;
  
  try {
    const serviceAccountPath = path.join(__dirname, '..', 'config', 'firebase-service-account.json');
    let serviceAccount;
    
    if (fs.existsSync(serviceAccountPath)) {
      serviceAccount = require(serviceAccountPath);
    } else if (process.env.FIREBASE_SERVICE_ACCOUNT) {
      serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
    }

    if (serviceAccount) {
      const { initializeApp, cert } = require('firebase-admin/app');
      initializeApp({
        credential: cert(serviceAccount)
      });
      isFirebaseInitialized = true;
      console.log('Firebase Admin initialized successfully.');
      return true;
    } else {
      console.error('Firebase Admin initialization failed: firebase-service-account.json not found, and FIREBASE_SERVICE_ACCOUNT env var is missing.');
      return false;
    }
  } catch (error) {
    console.error('Firebase Admin initialization error:', error);
    return false;
  }
}

// Ensure it tries to initialize on startup
initFirebase();

// Internal function to send push notification from other backend modules (e.g. sockets)
exports.internalSendPushNotification = async ({ receiverUid, title, body, type, relatedId, senderUid, senderPhotoUrl }) => {
  if (!receiverUid || !title || !body) {
    return { success: false, error: 'receiverUid, title, and body are required' };
  }

  // Prevent self notification
  if (senderUid && senderUid === receiverUid) {
    return { success: true, message: 'Skipped self notification' };
  }

  // SAVE TO POSTGRES
  try {
    const isTopic = receiverUid.startsWith('/topics/');
    if (!isTopic) {
      await pool.query(
        `INSERT INTO notifications (receiver_uid, sender_uid, title, body, type, related_id)
         VALUES ($1, $2, $3, $4, $5, $6)`,
        [receiverUid, senderUid || null, title, body, type || 'general', relatedId || null]
      );
    }
  } catch (dbError) {
    console.error('Error saving notification to DB:', dbError);
  }

  if (!initFirebase()) {
    return { success: false, error: 'Firebase Admin SDK not configured on server' };
  }

  try {
    const isTopic = receiverUid.startsWith('/topics/');
    const topicName = isTopic ? receiverUid.replace('/topics/', '') : null;

    let fcmToken = null;
    if (!isTopic) {
      // 1. Get user's FCM token from PostgreSQL
      const userRes = await pool.query('SELECT fcm_token FROM users WHERE uid = $1', [receiverUid]);
      if (userRes.rows.length === 0) {
        return { success: false, error: 'User not found' };
      }
      fcmToken = userRes.rows[0].fcm_token;
      if (!fcmToken) {
        return { success: false, error: 'User does not have an FCM token registered' };
      }
    }

    // 2. Build the payload
    const message = {
      ...(isTopic ? { topic: topicName } : { token: fcmToken }),
      ...(!['call', 'call_ended'].includes(type) && {
        notification: {
          title: title,
          body: body,
        }
      }),
      data: {
        type: type || 'general',
        title: title || '',
        body: body || '',
        relatedId: relatedId || '',
        senderUid: senderUid || '',
        senderPhotoUrl: senderPhotoUrl || '',
        click_action: 'FLUTTER_NOTIFICATION_CLICK'
      },
      android: {
        priority: 'high',
        notification: {
          sound: 'default',
          channelId: 'high_importance_channel'
        }
      },
      apns: {
        payload: {
          aps: {
            sound: 'default'
          }
        }
      }
    };

    // 3. Send the notification
    const { getMessaging } = require('firebase-admin/messaging');
    const response = await getMessaging().send(message);
    console.log('Successfully sent internal push message:', response);
    return { success: true, messageId: response };
  } catch (error) {
    console.error('Error sending internal push notification:', error);
    return { success: false, error: 'Failed to send push notification', details: error.message };
  }
};

exports.sendPushNotification = async (req, res) => {
  const { receiverUid, title, body, type, relatedId, senderUid, senderPhotoUrl } = req.body;
  const result = await exports.internalSendPushNotification({ receiverUid, title, body, type, relatedId, senderUid, senderPhotoUrl });
  
  if (result.success) {
    return res.status(200).json(result);
  } else {
    const statusCode = result.error === 'User not found' || result.error === 'User does not have an FCM token registered' ? 404 
      : result.error === 'Firebase Admin SDK not configured on server' ? 503 
      : result.error.includes('required') ? 400 : 500;
    return res.status(statusCode).json(result);
  }
};

exports.getNotifications = async (req, res) => {
  try {
    const { uid } = req.params;
    const result = await pool.query(
      `SELECT n.*, u.name as sender_name, u.profile_image as sender_photo_url
       FROM notifications n
       LEFT JOIN users u ON n.sender_uid = u.uid
       WHERE n.receiver_uid = $1
       ORDER BY n.created_at DESC
       LIMIT 50`,
      [uid]
    );

    const notifications = result.rows.map(row => ({
      id: row.id.toString(),
      receiverUid: row.receiver_uid,
      senderUid: row.sender_uid,
      senderName: row.sender_name || 'System',
      senderPhotoUrl: row.sender_photo_url || '',
      title: row.title,
      body: row.body,
      type: row.type,
      relatedId: row.related_id,
      isRead: row.is_read,
      createdAt: row.created_at,
    }));

    res.setHeader('Cache-Control', 'no-store, no-cache, must-revalidate, proxy-revalidate');
    res.status(200).json(notifications);
  } catch (error) {
    console.error('Error fetching notifications:', error);
    res.status(500).json({ error: 'Server error' });
  }
};

exports.markAsRead = async (req, res) => {
  try {
    const { id } = req.params;
    await pool.query('UPDATE notifications SET is_read = true WHERE id = $1', [id]);
    res.status(200).json({ success: true });
  } catch (error) {
    console.error('Error marking notification read:', error);
    res.status(500).json({ error: 'Server error' });
  }
};

exports.deleteNotification = async (req, res) => {
  try {
    const { id } = req.params;
    await pool.query('DELETE FROM notifications WHERE id = $1', [id]);
    res.status(200).json({ success: true });
  } catch (error) {
    console.error('Error deleting notification:', error);
    res.status(500).json({ error: 'Server error' });
  }
};

exports.deleteAllNotifications = async (req, res) => {
  try {
    const { uid } = req.params;
    await pool.query('DELETE FROM notifications WHERE receiver_uid = $1', [uid]);
    res.status(200).json({ success: true });
  } catch (error) {
    console.error('Error deleting all notifications:', error);
    res.status(500).json({ error: 'Server error' });
  }
};
