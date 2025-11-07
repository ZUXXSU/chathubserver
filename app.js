import express from "express";
import dotenv from "dotenv";
import { Server } from "socket.io";
import { createServer } from "http";
import cors from "cors";
import { v4 as uuid } from "uuid";
import { v2 as cloudinary } from "cloudinary";

// Import Firebase admin and db from features
import { db, admin, sendPushNotification } from "./utils/features.js"; // *** IMPORT sendPushNotification ***
import { errorMiddleware } from "./middlewares/error.js";
import {
  CHAT_JOINED,
  CHAT_LEAVED,
  NEW_MESSAGE,
  NEW_MESSAGE_ALERT,
  ONLINE_USERS,
  START_TYPING,
  STOP_TYPING,
} from "./constants/events.js";
import { getSockets } from "./lib/helper.js";
import { corsOptions } from "./constants/config.js";
import { socketAuthenticator } from "./middlewares/auth.js";
import { initializeApp } from "firebase/app";
import { getAnalytics } from "firebase/analytics";

// Import routes
import userRoute from "./routes/user.js";
import chatRoute from "./routes/chat.js";
import adminRoute from "./routes/admin.js";
import dataRoute from "./routes/data.js"; // *** IMPORT NEW ROUTE ***

dotenv.config({
  path: "./.env",
});

const port = process.env.PORT || 3000;
const envMode = process.env.NODE_ENV.trim() || "PRODUCTION";
const adminSecretKey = process.env.ADMIN_SECRET_KEY;
const userSocketIDs = new Map();
const onlineUsers = new Set();

// connectDB(mongoURI); // No longer needed; Firebase is initialized in features.js

const firebaseConfig = {
  apiKey: "AIzaSyBj3eR_62gp8kOMQmeDKe_7UsYIi2rVdNk",
  authDomain: "t35t-32882.firebaseapp.com",
  databaseURL: "https://t35t-32882-default-rtdb.firebaseio.com",
  projectId: "t35t-32882",
  storageBucket: "t35t-32882.firebasestorage.app",
  messagingSenderId: "860997172903",
  appId: "1:860997172903:web:9e8e9de9174a993026e582",
  measurementId: "G-E111M1N516"
};

// Initialize Firebase
// const firebaseapp = initializeApp(firebaseConfig);
// const analytics = getAnalytics(firebaseapp);
cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET,
});

const app = express();
const server = createServer(app);
const io = new Server(server, {
  cors: corsOptions,
});

app.set("io", io);

// Using Middlewares Here
app.use(express.json());
// app.use(cookieParser()); // No longer needed for auth
app.use(cors(corsOptions));

app.use("/api/v1/user", userRoute);
app.use("/api/v1/chat", chatRoute);
app.use("/api/v1/admin", adminRoute);
app.use("/api/v1/data", dataRoute); // *** MOUNT NEW ROUTE ***

app.get("/", (req, res) => {
  res.send("Hello World");
});

// Use socket authenticator (no cookie parser needed)
io.use((socket, next) => {
  // Pass null for err, as we're not using cookie parser's callback
  socketAuthenticator(null, socket, next);
});

io.on("connection", (socket) => {
  const user = socket.user; // This user object comes from socketAuthenticator
  userSocketIDs.set(user._id.toString(), socket.id);

  // *** MODIFIED FUNCTION ***
  socket.on(NEW_MESSAGE, async ({ chatId, members, message }) => {
    const messageForRealTime = {
      content: message,
      _id: uuid(),
      sender: {
        _id: user._id,
        name: user.name,
      },
      chat: chatId,
      createdAt: new Date().toISOString(),
    };

    const messageForDB = {
      content: message,
      sender: {
        // Denormalize sender data for Firestore
        _id: user._id,
        name: user.name,
      },
      chat: chatId,
      createdAt: admin.firestore.FieldValue.serverTimestamp(), // Use server timestamp
    };

    const membersSocket = getSockets(members);
    io.to(membersSocket).emit(NEW_MESSAGE, {
      chatId,
      message: messageForRealTime,
    });
    io.to(membersSocket).emit(NEW_MESSAGE_ALERT, { chatId });

    try {
      // Save message to Firestore
      await db.collection("messages").add(messageForDB);

      // *** NEW PUSH NOTIFICATION LOGIC ***
      // Send push notification to offline members
      const senderName = user.name;
      const recipients = members.filter(
        (memberId) => memberId.toString() !== user._id.toString()
      );

      for (const memberId of recipients) {
        // Check if user is NOT online (no active socket)
        if (!userSocketIDs.has(memberId.toString())) {
          try {
            const userDoc = await db.collection("users").doc(memberId).get();
            if (userDoc.exists) {
              const fcmToken = userDoc.data().fcmToken;
              if (fcmToken) {
                await sendPushNotification(
                  fcmToken,
                  `New Message from ${senderName}`,
                  message // The message content
                );
              }
            }
          } catch (error) {
            console.log("Error fetching user for push notification", error);
          }
        }
      }
      // *** END NEW LOGIC ***
    } catch (error) {
      console.log("Error saving message to Firestore:", error);
    }
  });

  socket.on(START_TYPING, ({ members, chatId }) => {
    const membersSockets = getSockets(members);
    socket.to(membersSockets).emit(START_TYPING, { chatId });
  });

  socket.on(STOP_TYPING, ({ members, chatId }) => {
    const membersSockets = getSockets(members);
    socket.to(membersSockets).emit(STOP_TYPING, { chatId });
  });

  socket.on(CHAT_JOINED, ({ userId, members }) => {
    onlineUsers.add(userId.toString());

    const membersSocket = getSockets(members);
    io.to(membersSocket).emit(ONLINE_USERS, Array.from(onlineUsers));
  });

  socket.on(CHAT_LEAVED, ({ userId, members }) => {
    onlineUsers.delete(userId.toString());

    const membersSocket = getSockets(members);
    io.to(membersSocket).emit(ONLINE_USERS, Array.from(onlineUsers));
  });

  socket.on("disconnect", () => {
    if (user) {
      userSocketIDs.delete(user._id.toString());
      onlineUsers.delete(user._id.toString());
      socket.broadcast.emit(ONLINE_USERS, Array.from(onlineUsers));
    }
  });
});

app.use(errorMiddleware);

server.listen(port, () => {
  // analytics;
  console.log(`Server is running on port ${port} in ${envMode} Mode`);
});

export { envMode, adminSecretKey, userSocketIDs };