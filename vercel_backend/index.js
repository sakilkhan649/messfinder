const express = require("express");
const admin = require("firebase-admin");
const cors = require("cors");

const app = express();
app.use(cors());
app.use(express.json());

// Initialize Firebase Admin using Environment Variables
if (!admin.apps.length) {
  try {
    admin.initializeApp({
      credential: admin.credential.cert({
        projectId: process.env.FIREBASE_PROJECT_ID,
        clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
        // Handle newline characters in the private key
        privateKey: process.env.FIREBASE_PRIVATE_KEY
          ? process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, "\n")
          : undefined,
      }),
    });
  } catch (error) {
    console.error("Firebase Admin initialization error", error);
  }
}

app.post("/api/send", async (req, res) => {
  const { receiverUid, title, body, type, relatedId } = req.body;

  if (!receiverUid) {
    return res.status(400).json({ error: "receiverUid is required" });
  }

  // FCM HTTP v1 API payload format
  const message = {
    notification: {
      title: title || "MessFinder",
      body: body || "",
    },
    data: {
      type: type || "",
      relatedId: relatedId || "",
    },
    android: {
      priority: "high",
      notification: {
        channelId: "messfinder_high_importance_v2",
        sound: "default",
      },
    },
    apns: {
      payload: {
        aps: {
          contentAvailable: true,
          sound: "default",
        },
      },
    },
  };

  try {
    if (receiverUid === "all" || receiverUid.startsWith("/topics/")) {
      const topicName =
        receiverUid === "all"
          ? "all_users"
          : receiverUid.replace("/topics/", "");

      message.topic = topicName;

      const response = await admin.messaging().send(message);
      return res.status(200).json({ success: true, response });
    } else {
      // Fetch token from Firestore and send
      const userDoc = await admin
        .firestore()
        .collection("users")
        .doc(receiverUid)
        .get();

      if (userDoc.exists) {
        const userData = userDoc.data();
        const fcmToken = userData.fcmToken;

        if (fcmToken) {
          message.token = fcmToken;
          const response = await admin.messaging().send(message);
          return res.status(200).json({ success: true, response });
        } else {
          return res
            .status(404)
            .json({ error: `User ${receiverUid} does not have an fcmToken.` });
        }
      } else {
        return res
          .status(404)
          .json({ error: `User ${receiverUid} not found.` });
      }
    }
  } catch (error) {
    console.error("Error sending push notification:", error);
    return res.status(500).json({ error: error.toString() });
  }
});

// Start the server (for local testing)
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});

module.exports = app;
