import { TryCatch } from "../middlewares/error.js";
import {
  admin,
  db,
  deletFilesFromCloudinary,
  emitEvent,
  uploadFilesToCloudinary,
} from "../utils/features.js";
import { ErrorHandler } from "../utils/utility.js";
import { getOtherMember } from "../lib/helper.js";
import { NEW_REQUEST, REFETCH_CHATS } from "../constants/events.js";

// Create a new user in Firebase Auth and a user profile in Firestore
const newUser = TryCatch(async (req, res, next) => {
  const { name, username, password, bio, email } = req.body;

  const file = req.file;

  if (!file) return next(new ErrorHandler("Please Upload Avatar"));

  const result = await uploadFilesToCloudinary([file]);

  const avatar = {
    public_id: result[0].public_id,
    url: result[0].url,
  };

  // 1. Create user in Firebase Auth
  const userRecord = await admin.auth().createUser({
    email,
    password,
    displayName: name,
    photoURL: avatar.url,
  });

  // 2. Create user document in Firestore
  await db.collection("users").doc(userRecord.uid).set({
    name,
    bio,
    username,
    avatar,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  return res.status(201).json({
    success: true,
    message: "User created successfully. Please log in.",
  });
});

// Login is now handled by the client (Firebase SDK).
// Client will call signInWithEmailAndPassword() and get an ID token.
const login = TryCatch(async (req, res, next) => {
  return next(
    new ErrorHandler(
      "Login is handled by the client SDK. This route is not used.",
      400
    )
  );
});

// Get user profile from Firestore using the UID from the verified token
const getMyProfile = TryCatch(async (req, res, next) => {
  const userDoc = await db.collection("users").doc(req.user).get(); // req.user is UID

  if (!userDoc.exists) return next(new ErrorHandler("User not found", 404));

  const user = { _id: userDoc.id, ...userDoc.data() };

  res.status(200).json({
    success: true,
    user,
  });
});

// Logout is handled by the client (Firebase SDK's signOut())
const logout = TryCatch(async (req, res) => {
  return res.status(200).json({
    success: true,
    message: "Logout is handled by the client.",
  });
});

// Search for users
const searchUser = TryCatch(async (req, res) => {
  const { name = "" } = req.query;
  const myUid = req.user;

  // 1. Find all my chats to identify friends
  const myChatsSnapshot = await db
    .collection("chats")
    .where("groupChat", "==", false)
    .where("members", "array-contains", myUid)
    .get();

  const myChatMembers = myChatsSnapshot.docs.flatMap(
    (doc) => doc.data().members
  );
  const allUsersFromMyChats = [...new Set(myChatMembers)]; // Unique list of my friends + me

  // 2. Find all users matching name (prefix search)
  // This is a basic prefix search. For full-text search, consider Algolia/Elasticsearch.
  const allUsersSnapshot = await db
    .collection("users")
    .where("name", ">=", name)
    .where("name", "<=", name + "\uf8ff")
    .get();

  const allUsers = allUsersSnapshot.docs.map((doc) => ({
    _id: doc.id,
    ...doc.data(),
  }));

  // 3. Filter out myself and users I'm already chatting with
  const users = allUsers
    .filter((user) => !allUsersFromMyChats.includes(user._id))
    .map(({ _id, name, avatar }) => ({
      _id,
      name,
      avatar: avatar.url,
    }));

  return res.status(200).json({
    success: true,
    users,
  });
});

// Send a friend request
const sendFriendRequest = TryCatch(async (req, res, next) => {
  const { userId } = req.body; // UID of the receiver
  const senderId = req.user; // My UID

  // Check if a request already exists
  const q1 = db
    .collection("requests")
    .where("sender", "==", senderId)
    .where("receiver", "==", userId);
  const q2 = db
    .collection("requests")
    .where("sender", "==", userId)
    .where("receiver", "==", senderId);

  const [snap1, snap2] = await Promise.all([q1.get(), q2.get()]);

  if (!snap1.empty || !snap2.empty) {
    return next(new ErrorHandler("Request already sent", 400));
  }

  // Create new request
  await db.collection("requests").add({
    sender: senderId,
    receiver: userId,
    status: "pending",
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  emitEvent(req, NEW_REQUEST, [userId]);

  return res.status(200).json({
    success: true,
    message: "Friend Request Sent",
  });
});

// Accept or reject a friend request
const acceptFriendRequest = TryCatch(async (req, res, next) => {
  const { requestId, accept } = req.body;
  const myUid = req.user;

  const requestRef = db.collection("requests").doc(requestId);
  const requestDoc = await requestRef.get();

  if (!requestDoc.exists)
    return next(new ErrorHandler("Request not found", 404));

  const request = requestDoc.data();

  if (request.receiver !== myUid)
    return next(
      new ErrorHandler("You are not authorized to accept this request", 401)
    );

  if (!accept) {
    await requestRef.delete();
    return res.status(200).json({
      success: true,
      message: "Friend Request Rejected",
    });
  }

  const members = [request.sender, request.receiver];

  // Manually fetch user names to create the chat name
  const [senderDoc, receiverDoc] = await Promise.all([
    db.collection("users").doc(request.sender).get(),
    db.collection("users").doc(request.receiver).get(),
  ]);

  const senderName = senderDoc.data()?.name || "User";
  const receiverName = receiverDoc.data()?.name || "User";

  // Create a new 1-on-1 chat
  await Promise.all([
    db.collection("chats").add({
      members,
      name: `${senderName}-${receiverName}`,
      groupChat: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    }),
    requestRef.delete(),
  ]);

  emitEvent(req, REFETCH_CHATS, members);

  return res.status(200).json({
    success: true,
    message: "Friend Request Accepted",
    senderId: request.sender,
  });
});

// Get all my friend requests
const getMyNotifications = TryCatch(async (req, res) => {
  const requestsSnapshot = await db
    .collection("requests")
    .where("receiver", "==", req.user)
    .get();

  // Manually "populate" sender data for each request
  const allRequests = await Promise.all(
    requestsSnapshot.docs.map(async (doc) => {
      const request = doc.data();
      const senderDoc = await db
        .collection("users")
        .doc(request.sender)
        .get();
      const senderData = senderDoc.data();

      return {
        _id: doc.id,
        sender: {
          _id: senderDoc.id,
          name: senderData.name,
          avatar: senderData.avatar.url,
        },
      };
    })
  );

  return res.status(200).json({
    success: true,
    allRequests,
  });
});

// Get all my friends
const getMyFriends = TryCatch(async (req, res) => {
  const chatId = req.query.chatId;
  const myUid = req.user;

  const chatsSnapshot = await db
    .collection("chats")
    .where("members", "array-contains", myUid)
    .where("groupChat", "==", false)
    .get();

  // Manually "populate" friend data from each 1-on-1 chat
  const friends = await Promise.all(
    chatsSnapshot.docs.map(async (doc) => {
      const chat = doc.data();
      const otherUserId = getOtherMember(chat.members, myUid);
      const userDoc = await db.collection("users").doc(otherUserId).get();
      const userData = userDoc.data();

      return {
        _id: userDoc.id,
        name: userData.name,
        avatar: userData.avatar.url,
      };
    })
  );

  if (chatId) {
    const chatDoc = await db.collection("chats").doc(chatId).get();
    if (!chatDoc.exists)
      return next(new ErrorHandler("Chat not found", 404));

    const chat = chatDoc.data();
    const availableFriends = friends.filter(
      (friend) => !chat.members.includes(friend._id)
    );

    return res.status(200).json({
      success: true,
      friends: availableFriends,
    });
  } else {
    return res.status(200).json({
      success: true,
      friends,
    });
  }
});

export {
  acceptFriendRequest,
  getMyFriends,
  getMyNotifications,
  getMyProfile,
  login,
  logout,
  newUser,
  searchUser,
  sendFriendRequest,
};