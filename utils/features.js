import admin from "firebase-admin";
import { v4 as uuid } from "uuid";
import { v2 as cloudinary } from "cloudinary";
import { getBase64, getSockets } from "../lib/helper.js";
// import serviceAccount from "../serviceAccountKey.json" with { type: "json" };

const serviceAccountConfig = JSON.parse(process.env.FIREBASE_CREDENTIALS_JSON || `{}`);
// Initialize Firebase Admin SDK
admin.initializeApp({
  credential: admin.credential.cert(serviceAccountConfig),
});

// Initialize Firestore
const db = admin.firestore();

// *** NEW FUNCTION ***
// Function to send an FCM push notification
const sendPushNotification = async (token, title, body) => {
  if (!token) return;

  const message = {
    notification: {
      title,
      body,
    },
    token: token,
  };

  try {
    await admin.messaging().send(message);
    console.log("Successfully sent push notification");
  } catch (error) {
    console.error("Error sending push notification:", error);
  }
};

const emitEvent = (req, event, users, data) => {
  const io = req.app.get("io");
  const usersSocket = getSockets(users);
  io.to(usersSocket).emit(event, data);
};

const uploadFilesToCloudinary = async (files = []) => {
  const uploadPromises = files.map((file) => {
    return new Promise((resolve, reject) => {
      cloudinary.uploader.upload(
        getBase64(file),
        {
          resource_type: "auto",
          public_id: uuid(),
        },
        (error, result) => {
          if (error) return reject(error);
          resolve(result);
        }
      );
    });
  });

  try {
    const results = await Promise.all(uploadPromises);

    const formattedResults = results.map((result) => ({
      public_id: result.public_id,
      url: result.secure_url,
    }));
    return formattedResults;
  } catch (err) {
    throw new Error("Error uploading files to cloudinary", err);
  }
};

const deletFilesFromCloudinary = async (public_ids) => {
  // This logic remains the same.
  // Add your Cloudinary delete logic here if needed.
  // Example:
  if (!public_ids || public_ids.length === 0) return;
  try {
    await cloudinary.api.delete_resources(public_ids);
  } catch (error) {
    console.error("Error deleting files from Cloudinary", error);
  }
};

export {
  admin, // Export Firebase Admin
  db, // Export Firestore
  emitEvent,
  deletFilesFromCloudinary,
  uploadFilesToCloudinary,
  sendPushNotification, // *** EXPORT NEW FUNCTION ***
};