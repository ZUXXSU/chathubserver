import { ErrorHandler } from "../utils/utility.js";
import { TryCatch } from "./error.js";
import { admin, db, sendPushNotification } from "../utils/features.js"; // *** IMPORT sendPushNotification ***

// Middleware to verify Firebase ID Token for standard HTTP requests
const isAuthenticated = TryCatch(async (req, res, next) => {
  const token = req.headers.authorization?.split(" ")[1];

  if (!token)
    return next(new ErrorHandler("Please login to access this route", 401));

  // Verify the token using Firebase Admin SDK
  const decodedToken = await admin.auth().verifyIdToken(token);

  // Store the Firebase UID in req.user
  req.user = decodedToken.uid;

  next();
});

// Middleware to verify the user is an admin
// It checks for a custom claim 'admin: true' on the Firebase ID Token
const adminOnly = TryCatch(async (req, res, next) => {
  const token = req.headers.authorization?.split(" ")[1];

  if (!token)
    return next(new ErrorHandler("Only Admin can access this route", 401));

  const decodedToken = await admin.auth().verifyIdToken(token);

  // Check for the custom claim
  if (!decodedToken.admin)
    return next(new ErrorHandler("Only Admin can access this route", 401));

  req.user = decodedToken.uid;

  next();
});

// *** NEW MIDDLEWARE ***
// Checks for a user but does not throw an error if not found
// Sets req.user = "unknown" if no token is provided
const checkAuth = TryCatch(async (req, res, next) => {
  const token = req.headers.authorization?.split(" ")[1];

  if (!token) {
    req.user = "unknown";
    return next();
  }

  try {
    const decodedToken = await admin.auth().verifyIdToken(token);
    req.user = decodedToken.uid;
    next();
  } catch (error) {
    // If token is expired or invalid, treat as unknown
    req.user = "unknown";
    next();
  }
});

// Authenticator for Socket.io connections
// *** MODIFIED FUNCTION ***
const socketAuthenticator = async (err, socket, next) => {
  try {
    if (err) return next(err);

    // Get token from the 'auth' object on connection
    const authToken = socket.handshake.auth.token;

    if (!authToken)
      return next(new ErrorHandler("Please login to access this route", 401));

    const decodedToken = await admin.auth().verifyIdToken(authToken);
    const uid = decodedToken.uid;

    // *** NEW FCM LOGIC STARTS HERE ***

    // 1. Get the new FCM token from the mobile client's handshake
    const newFcmToken = socket.handshake.auth.fcmToken;

    // 2. Fetch the user's document
    const userDocRef = db.collection("users").doc(uid);
    const userDoc = await userDocRef.get();

    if (!userDoc.exists)
      return next(new ErrorHandler("User not found", 401));

    const userData = userDoc.data();
    const oldFcmToken = userData.fcmToken; // Get the token stored in DB

    let tokenToUpdate = null;

    // 3. If a new mobile token is provided:
    if (newFcmToken) {
      // 4. Check if it's different from the one in the DB
      if (oldFcmToken && newFcmToken !== oldFcmToken) {
        // 5. Send a push notification to the *old* device
        await sendPushNotification(
          oldFcmToken,
          "ChatHub Security Alert",
          "A new device has logged into your account."
        );
      }
      // 6. This new token should be saved.
      tokenToUpdate = newFcmToken;
    }

    // 7. Update the FCM token in Firestore if it's new
    if (tokenToUpdate) {
      await userDocRef.update({ fcmToken: tokenToUpdate });
      userData.fcmToken = tokenToUpdate; // Update in-memory data
    }
    // *** NEW FCM LOGIC ENDS HERE ***

    // Attach the Firestore user data (with updated token) to the socket object
    socket.user = { _id: userDoc.id, ...userData };

    return next();
  } catch (error) {
    console.log(error);
    return next(new ErrorHandler("Please login to access this route", 401));
  }
};

export { isAuthenticated, adminOnly, checkAuth, socketAuthenticator };