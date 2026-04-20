const {setGlobalOptions} = require("firebase-functions");
const {onRequest} = require("firebase-functions/https");
const logger = require("firebase-functions/logger");

setGlobalOptions({ maxInstances: 10 });

const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

exports.triggerFireAlarm = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Login required.");
  }

  const payload = {
    topic: "station_alerts",
    notification: {
      title: `🚨 ${data.fireType} ALERT!`,
      body: data.note || "Immediate response required at station.",
    },
    android: {
      priority: "high",
      notification: {
        channelId: "high_importance_channel",
        sound: "default",
      },
    },
    data: {
      fireType: data.fireType,
      note: data.note || "",
      click_action: "FLUTTER_NOTIFICATION_CLICK",
    },
  };

  return admin.messaging().send(payload);
});