const admin = require('firebase-admin');
const pool = require('../config/db');
const path = require('path');
const fs = require('fs');

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
      notification: {
        title: title,
        body: body,
      },
      data: {
        type: type || 'general',
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
  const { receiverUid, title, body, type, relatedId, senderUid } = req.body;
  const result = await exports.internalSendPushNotification({ receiverUid, title, body, type, relatedId, senderUid });
  
  if (result.success) {
    return res.status(200).json(result);
  } else {
    const statusCode = result.error === 'User not found' || result.error === 'User does not have an FCM token registered' ? 404 
      : result.error === 'Firebase Admin SDK not configured on server' ? 503 
      : result.error.includes('required') ? 400 : 500;
    return res.status(statusCode).json(result);
  }
};


