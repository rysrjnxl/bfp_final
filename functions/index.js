const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getMessaging } = require("firebase-admin/messaging");

initializeApp();

exports.sendAlarmNotification = onDocumentCreated(
  "alarms/{alarmId}",
  async (event) => {
    const data = event.data.data();

    const message = {
      topic: "station_alerts",
      data: {
        fireType: data.fireType ?? "Fire Alert",
        location: data.location ?? "Unknown Location",
        note: data.note ?? "",
        triggeredBy: data.triggeredBy ?? "",
        lat: data.lat?.toString() ?? "",
        lng: data.lng?.toString() ?? "",
      },
      android: {
        priority: "high",
        ttl: 30000,
      },
    };

    await getMessaging().send(message);
  }
);