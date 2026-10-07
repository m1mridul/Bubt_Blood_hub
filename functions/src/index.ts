import {onDocumentCreated} from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";

// Initialize the Firebase Admin SDK
admin.initializeApp();

// Use the new v2 syntax for the Cloud Function
export const onBloodRequestCreated = onDocumentCreated("blood_requests/{requestId}", async (event) => {

  const snapshot = event.data;
  if (!snapshot) {
    console.log("No data associated with the event");
    return;
  }

  const requestData = snapshot.data();
  const bloodGroup = requestData.bloodGroup;
  const location = requestData.location;

  // --- Create the Notification Payload ---
  const payload = {
    notification: {
      title: "Urgent Blood Request!",
      body: `Blood Group: ${bloodGroup} needed at ${location}`,
      sound: "default",
    },
    data: {
      "click_action": "FLUTTER_NOTIFICATION_CLICK",
      "requestId": event.params.requestId,
    },
  };

  // --- Send the Notification ---
  const topic = "all_requests";

  try {
    console.log("Sending notification to topic:", topic);
    await admin.messaging().sendToTopic(topic, payload);
    console.log("Successfully sent notification");
  } catch (error) {
    console.error("Error sending notification:", error);
  }
});
