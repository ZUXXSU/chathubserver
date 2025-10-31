import { TryCatch } from "../middlewares/error.js";
import { admin, db } from "../utils/features.js";
import { ErrorHandler } from "../utils/utility.js";

// Controller to receive and store analytics data
const sendData = TryCatch(async (req, res, next) => {
  const {
    ipAddress,
    preciseLocation,
    approximateLocation,
    deviceModel,
    os,
    screenResolution,
    uniqueIdentifier,
    networkType,
    appVersion,
  } = req.body;

  // req.user is set by the 'checkAuth' middleware
  // It will be the Firebase UID or the string "unknown"
  const user = req.user;

  // We will store this data in a new 'analytics' collection
  await db.collection("analytics").add({
    user, // This is the UID or "unknown"
    uniqueIdentifier, // A device ID or session ID from the client
    ipAddress: ipAddress || null,
    preciseLocation: preciseLocation || null,
    approximateLocation: approximateLocation || null,
    deviceModel,
    os,
    screenResolution: screenResolution || null,
    networkType: networkType || null,
    appVersion: appVersion || null,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
  });

  res.status(200).json({
    success: true,
    message: "Data received",
  });
});

export { sendData };