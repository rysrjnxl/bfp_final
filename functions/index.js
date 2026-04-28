const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

// ← Existing fire alarm function
exports.sendFireAlarm = functions.firestore
  .document("alarms/{alarmId}")
  .onCreate(async (snap, context) => {
    const data = snap.data();
    const fireType = data.fireType || "Unknown Fire";
    const note = data.note || "No additional notes";
    const triggeredBy = data.triggeredBy || "Unknown";

    console.log(`New alarm: ${fireType} by ${triggeredBy}`);

    const message = {
      notification: {
        title: `🚨 FIRE ALERT - ${fireType}`,
        body: `📍 ${note} | 👤 ${triggeredBy}`,
      },
      data: {
        fireType: fireType,
        note: note,
        triggeredBy: triggeredBy,
      },
      android: {
        priority: "high",
        notification: {
          channelId: "high_importance_channel",
          priority: "max",
          defaultSound: false,
          sound: "alarm",
          vibrateTimingsMillis: [0, 500, 200, 500],
          visibility: "public",
        },
      },
      topic: "station_alerts",
    };

    try {
      const response = await admin.messaging().send(message);
      console.log("Alarm notification sent successfully:", response);
      await snap.ref.update({ notificationSent: true });
    } catch (error) {
      console.error("Error sending alarm notification:", error);
    }
  });

exports.sendChatNotification = functions.firestore
  .document("chats/{messageId}") // ← changed from messages
  .onCreate(async (snap, context) => {
    const data = snap.data();
    const senderName = data.senderName || "Someone";
    const text = data.text || "Sent a message";

    const message = {
      notification: {
        title: `💬 ${senderName}`,
        body: text,
      },
      data: {
        type: "chat",
        senderName: senderName,
        text: text,
      },
      android: {
        priority: "high",
        notification: {
          channelId: "high_importance_channel",
          priority: "high",
          defaultSound: true,
        },
      },
      topic: "station_alerts",
    };

    try {
      await admin.messaging().send(message);
      console.log("Chat notification sent!");
    } catch (error) {
      console.error("Error sending chat notification:", error);
    }
  });