import { TryCatch } from "../middlewares/error.js";
import { db, admin } from "../utils/features.js";
import { ErrorHandler } from "../utils/utility.js";

// Verify a user as Admin by checking a secret key and setting a custom claim
const adminLogin = TryCatch(async (req, res, next) => {
  const { secretKey } = req.body;
  const myUid = req.user; // UID from isAuthenticated middleware

  const adminSecretKey = process.env.ADMIN_SECRET_KEY || "adsasdsdfsdfsdfd";

  const isMatched = secretKey === adminSecretKey;

  if (!isMatched) return next(new ErrorHandler("Invalid Admin Key", 401));

  // Set custom claim on the user
  await admin.auth().setCustomUserClaims(myUid, { admin: true });

  return res.status(200).json({
    success: true,
    message:
      "Admin claim set. Please log out and log back in to apply changes.",
  });
});

// Logout is client-side, but we can revoke the admin token if needed.
// For simplicity, we'll tell the client to sign out.
const adminLogout = TryCatch(async (req, res, next) => {
  return res.status(200).json({
    success: true,
    message: "Logout is handled by the client.",
  });
});

// This route is just to verify if the token has the admin claim (via adminOnly middleware)
const getAdminData = TryCatch(async (req, res, next) => {
  return res.status(200).json({
    admin: true,
  });
});

// *** MODIFIED CONTROLLER ***
// Get all users OR all unknown analytics data
const allUsers = TryCatch(async (req, res) => {
  const { unknown } = req.query;

  if (unknown === "true") {
    // --- Fetch "unknown" users from analytics ---
    const analyticsSnapshot = await db
      .collection("analytics")
      .where("user", "==", "unknown")
      .get();

    const unknownUsers = analyticsSnapshot.docs.map((doc) => {
      const data = doc.data();
      return {
        _id: doc.id,
        name: data.deviceModel, // Use deviceModel as name
        username: data.uniqueIdentifier, // Use uniqueIdentifier as username
        avatar: "", // No avatar for unknown users
        os: data.os,
        network: data.networkType,
        ip: data.ipAddress,
        createdAt: data.timestamp.toDate().toISOString(),
      };
    });

    return res.status(200).json({
      status: "success",
      users: unknownUsers,
    });
  } else {
    // --- Fetch registered users from 'users' collection (original logic) ---
    const usersSnapshot = await db.collection("users").get();
    const users = usersSnapshot.docs.map((doc) => ({
      _id: doc.id,
      ...doc.data(),
    }));

    const transformedUsers = await Promise.all(
      users.map(async ({ name, username, avatar, _id, createdAt }) => {
        const [groupsSnapshot, friendsSnapshot] = await Promise.all([
          db
            .collection("chats")
            .where("groupChat", "==", true)
            .where("members", "array-contains", _id)
            .count()
            .get(),
          db
            .collection("chats")
            .where("groupChat", "==", false)
            .where("members", "array-contains", _id)
            .count()
            .get(),
        ]);

        return {
          name,
          username,
          avatar: avatar.url,
          _id,
          groups: groupsSnapshot.data().count,
          friends: friendsSnapshot.data().count,
          createdAt: createdAt?.toDate().toISOString() || "N/A",
        };
      })
    );

    return res.status(200).json({
      status: "success",
      users: transformedUsers,
    });
  }
});

// Get all chats
const allChats = TryCatch(async (req, res) => {
  const chatsSnapshot = await db.collection("chats").get();

  const transformedChats = await Promise.all(
    chatsSnapshot.docs.map(async (doc) => {
      const data = doc.data();
      const { members, _id, groupChat, name, creator } = data;

      const [totalMessagesSnapshot, creatorDoc, memberDocs] =
        await Promise.all([
          db
            .collection("messages")
            .where("chat", "==", doc.id)
            .count()
            .get(),
          creator ? db.collection("users").doc(creator).get() : null,
          Promise.all(
            members.map((id) => db.collection("users").doc(id).get())
          ),
        ]);

      const creatorData = creatorDoc?.data() || {};
      const totalMessages = totalMessagesSnapshot.data().count;

      return {
        _id: doc.id,
        groupChat,
        name,
        avatar: memberDocs
          .slice(0, 3)
          .map((doc) => doc.data()?.avatar?.url || ""),
        members: memberDocs.map((doc) => ({
          _id: doc.id,
          name: doc.data()?.name || "User",
          avatar: doc.data()?.avatar?.url || "",
        })),
        creator: {
          name: creatorData.name || "None",
          avatar: creatorData.avatar?.url || "",
        },
        totalMembers: members.length,
        totalMessages,
      };
    })
  );

  return res.status(200).json({
    status: "success",
    chats: transformedChats,
  });
});

// Get all messages
const allMessages = TryCatch(async (req, res) => {
  const messagesSnapshot = await db
    .collection("messages")
    .orderBy("createdAt", "desc")
    .get();

  // NOTE: This assumes messages have denormalized sender data.
  // If not, you must fetch the sender for each message, which is very slow.
  // We added denormalized sender data in chat.controller.js
  const transformedMessages = messagesSnapshot.docs.map((doc) => {
    const { content, attachments, _id, sender, createdAt, chat } =
      doc.data();
    return {
      _id: doc.id,
      attachments,
      content,
      createdAt: createdAt.toDate().toISOString(),
      chat,
      groupChat: doc.data().groupChat, // This would need to be populated from the chat
      sender: {
        _id: sender._id,
        name: sender.name,
        avatar: sender.avatar?.url || "",
      },
    };
  });

  return res.status(200).json({
    success: true,
    messages: transformedMessages,
  });
});

// Get dashboard statistics
const getDashboardStats = TryCatch(async (req, res) => {
  const [
    groupsCountSnap,
    usersCountSnap,
    messagesCountSnap,
    totalChatsCountSnap,
  ] = await Promise.all([
    db.collection("chats").where("groupChat", "==", true).count().get(),
    db.collection("users").count().get(),
    db.collection("messages").count().get(),
    db.collection("chats").count().get(),
  ]);

  const groupsCount = groupsCountSnap.data().count;
  const usersCount = usersCountSnap.data().count;
  const messagesCount = messagesCountSnap.data().count;
  const totalChatsCount = totalChatsCountSnap.data().count;

  const today = new Date();
  const last7Days = new Date();
  last7Days.setDate(last7Days.getDate() - 7);

  const last7DaysMessagesSnapshot = await db
    .collection("messages")
    .where("createdAt", ">=", last7Days)
    .where("createdAt", "<=", today)
    .get();

  const messages = new Array(7).fill(0);
  const dayInMiliseconds = 1000 * 60 * 60 * 24;

  last7DaysMessagesSnapshot.docs.forEach((doc) => {
    const message = doc.data();
    const messageDate = message.createdAt.toDate();
    const indexApprox =
      (today.getTime() - messageDate.getTime()) / dayInMiliseconds;
    const index = Math.floor(indexApprox);
    if (index < 7) {
      messages[6 - index]++;
    }
  });

  const stats = {
    groupsCount,
    usersCount,
    messagesCount,
    totalChatsCount,
    messagesChart: messages,
  };

  return res.status(200).json({
    success: true,
    stats,
  });
});

export {
  allUsers,
  allChats,
  allMessages,
  getDashboardStats,
  adminLogin,
  adminLogout,
  getAdminData,
};