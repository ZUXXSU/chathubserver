import { TryCatch } from "../middlewares/error.js";
import { ErrorHandler } from "../utils/utility.js";
import {
  admin,
  db,
  deletFilesFromCloudinary,
  emitEvent,
  uploadFilesToCloudinary,
} from "../utils/features.js";
import {
  ALERT,
  NEW_MESSAGE,
  NEW_MESSAGE_ALERT,
  REFETCH_CHATS,
} from "../constants/events.js";
import { getOtherMember } from "../lib/helper.js";

// Create a new group chat
const newGroupChat = TryCatch(async (req, res, next) => {
  const { name, members } = req.body;
  const creator = req.user;

  const allMembers = [...members, creator];

  await db.collection("chats").add({
    name,
    groupChat: true,
    creator,
    members: allMembers,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  emitEvent(req, ALERT, allMembers, `Welcome to ${name} group`);
  emitEvent(req, REFETCH_CHATS, members);

  return res.status(201).json({
    success: true,
    message: "Group Created",
  });
});

// Get all chats (groups and 1-on-1) for the logged-in user
const getMyChats = TryCatch(async (req, res, next) => {
  const myUid = req.user;

  const chatsSnapshot = await db
    .collection("chats")
    .where("members", "array-contains", myUid)
    .get();

  const chats = chatsSnapshot.docs.map((doc) => ({
    _id: doc.id,
    ...doc.data(),
  }));

  // Manually "populate" data
  const transformedChats = await Promise.all(
    chats.map(async ({ _id, name, members, groupChat }) => {
      const otherMemberId = groupChat ? null : getOtherMember(members, myUid);

      let otherMemberData = {};
      if (otherMemberId) {
        const userDoc = await db.collection("users").doc(otherMemberId).get();
        if (userDoc.exists) {
          otherMemberData = userDoc.data();
        }
      }

      let avatars = [];
      if (groupChat) {
        const memberDocs = await Promise.all(
          members
            .slice(0, 3)
            .map((id) => db.collection("users").doc(id).get())
        );
        avatars = memberDocs.map(
          (doc) => doc.data()?.avatar?.url || ""
        );
      } else {
        avatars = [otherMemberData.avatar?.url || ""];
      }

      return {
        _id,
        groupChat,
        avatar: avatars,
        name: groupChat ? name : otherMemberData.name || "User",
        members: members.filter((id) => id !== myUid),
      };
    })
  );

  return res.status(200).json({
    success: true,
    chats: transformedChats,
  });
});

// Get only groups where the user is a member
const getMyGroups = TryCatch(async (req, res, next) => {
  const myUid = req.user;

  const chatsSnapshot = await db
    .collection("chats")
    .where("members", "array-contains", myUid)
    .where("groupChat", "==", true)
    // .where("creator", "==", myUid) // Original code had this, uncomment if you only want groups *created* by user
    .get();

  const groups = await Promise.all(
    chatsSnapshot.docs.map(async (doc) => {
      const { members, _id, groupChat, name } = doc.data();
      const memberDocs = await Promise.all(
        members
          .slice(0, 3)
          .map((id) => db.collection("users").doc(id).get())
      );
      const avatars = memberDocs.map(
        (doc) => doc.data()?.avatar?.url || ""
      );

      return {
        _id: doc.id,
        groupChat,
        name,
        avatar: avatars,
      };
    })
  );

  return res.status(200).json({
    success: true,
    groups,
  });
});

// Add members to a group
const addMembers = TryCatch(async (req, res, next) => {
  const { chatId, members } = req.body;

  const chatRef = db.collection("chats").doc(chatId);
  const chatDoc = await chatRef.get();

  if (!chatDoc.exists) return next(new ErrorHandler("Chat not found", 404));

  const chat = chatDoc.data();

  if (!chat.groupChat)
    return next(new ErrorHandler("This is not a group chat", 400));

  if (chat.creator.toString() !== req.user.toString())
    return next(new ErrorHandler("You are not allowed to add members", 403));

  if (chat.members.length + members.length > 100)
    return next(new ErrorHandler("Group members limit reached", 400));

  // Manually get names for the alert
  const allNewMembersPromise = members.map((i) =>
    db.collection("users").doc(i).get()
  );
  const allNewMembers = await Promise.all(allNewMembersPromise);
  const allUsersName = allNewMembers
    .map((doc) => doc.data()?.name || "User")
    .join(", ");

  await chatRef.update({
    members: admin.firestore.FieldValue.arrayUnion(...members),
  });

  emitEvent(
    req,
    ALERT,
    chat.members,
    `${allUsersName} has been added in the group`
  );
  emitEvent(req, REFETCH_CHATS, chat.members);

  return res.status(200).json({
    success: true,
    message: "Members added successfully",
  });
});

// Remove a member from a group
const removeMember = TryCatch(async (req, res, next) => {
  const { userId, chatId } = req.body;

  const chatRef = db.collection("chats").doc(chatId);
  const userDoc = await db.collection("users").doc(userId).get();

  const [chatDoc, userThatWillBeRemoved] = await Promise.all([
    chatRef.get(),
    userDoc,
  ]);

  if (!chatDoc.exists) return next(new ErrorHandler("Chat not found", 404));
  if (!userThatWillBeRemoved.exists)
    return next(new ErrorHandler("User not found", 404));

  const chat = chatDoc.data();
  const userName = userThatWillBeRemoved.data().name;

  if (!chat.groupChat)
    return next(new ErrorHandler("This is not a group chat", 400));

  if (chat.creator.toString() !== req.user.toString())
    return next(new ErrorHandler("You are not allowed to remove members", 403));

  if (chat.members.length <= 3)
    return next(new ErrorHandler("Group must have at least 3 members", 400));

  await chatRef.update({
    members: admin.firestore.FieldValue.arrayRemove(userId),
  });

  emitEvent(req, ALERT, chat.members, {
    message: `${userName} has been removed from the group`,
    chatId,
  });
  emitEvent(req, REFETCH_CHATS, chat.members);

  return res.status(200).json({
    success: true,
    message: "Member removed successfully",
  });
});

// Leave a group
const leaveGroup = TryCatch(async (req, res, next) => {
  const chatId = req.params.id;
  const myUid = req.user;

  const chatRef = db.collection("chats").doc(chatId);
  const chatDoc = await chatRef.get();

  if (!chatDoc.exists) return next(new ErrorHandler("Chat not found", 404));

  const chat = chatDoc.data();

  if (!chat.groupChat)
    return next(new ErrorHandler("This is not a group chat", 400));

  const remainingMembers = chat.members.filter(
    (member) => member.toString() !== myUid.toString()
  );

  if (remainingMembers.length < 3)
    return next(new ErrorHandler("Group must have at least 3 members", 400));

  const updateData = {
    members: remainingMembers,
  };

  if (chat.creator.toString() === myUid.toString()) {
    const randomElement = Math.floor(Math.random() * remainingMembers.length);
    const newCreator = remainingMembers[randomElement];
    updateData.creator = newCreator;
  }

  const userDoc = await db.collection("users").doc(myUid).get();
  const userName = userDoc.data()?.name || "User";

  await chatRef.update(updateData);

  emitEvent(req, ALERT, remainingMembers, {
    chatId,
    message: `User ${userName} has left the group`,
  });

  return res.status(200).json({
    success: true,
    message: "Left Group Successfully",
  });
});

// Send attachments in a chat
const sendAttachments = TryCatch(async (req, res, next) => {
  const { chatId } = req.body;
  const files = req.files || [];
  const myUid = req.user;

  if (files.length < 1)
    return next(new ErrorHandler("Please Upload Attachments", 400));
  if (files.length > 5)
    return next(new ErrorHandler("Files Can't be more than 5", 400));

  const [chatDoc, meDoc] = await Promise.all([
    db.collection("chats").doc(chatId).get(),
    db.collection("users").doc(myUid).get(),
  ]);

  if (!chatDoc.exists) return next(new ErrorHandler("Chat not found", 404));

  const chat = chatDoc.data();
  const me = meDoc.data();

  const attachments = await uploadFilesToCloudinary(files);

  // Store denormalized sender data for easier retrieval
  const messageForDB = {
    content: "",
    attachments,
    sender: {
      _id: myUid,
      name: me.name,
    },
    chat: chatId,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  };

  const messageForRealTime = {
    ...messageForDB,
    createdAt: new Date().toISOString(), // Convert server timestamp for client
  };

  const message = await db.collection("messages").add(messageForDB);

  emitEvent(req, NEW_MESSAGE, chat.members, {
    message: { ...messageForRealTime, _id: message.id },
    chatId,
  });
  emitEvent(req, NEW_MESSAGE_ALERT, chat.members, { chatId });

  return res.status(200).json({
    success: true,
    message: "Attachments sent successfully",
  });
});

// Get details of a chat
const getChatDetails = TryCatch(async (req, res, next) => {
  const chatId = req.params.id;
  const chatDoc = await db.collection("chats").doc(chatId).get();

  if (!chatDoc.exists) return next(new ErrorHandler("Chat not found", 404));

  const chat = { _id: chatDoc.id, ...chatDoc.data() };

  if (req.query.populate === "true") {
    // Manually "populate" members
    const memberPromises = chat.members.map((id) =>
      db.collection("users").doc(id).get()
    );
    const memberDocs = await Promise.all(memberPromises);
    chat.members = memberDocs.map((doc) => {
      const userData = doc.data();
      return {
        _id: doc.id,
        name: userData.name,
        avatar: userData.avatar.url,
      };
    });
  }

  return res.status(200).json({
    success: true,
    chat,
  });
});

// Rename a group
const renameGroup = TryCatch(async (req, res, next) => {
  const chatId = req.params.id;
  const { name } = req.body;

  const chatRef = db.collection("chats").doc(chatId);
  const chatDoc = await chatRef.get();

  if (!chatDoc.exists) return next(new ErrorHandler("Chat not found", 404));

  const chat = chatDoc.data();

  if (!chat.groupChat)
    return next(new ErrorHandler("This is not a group chat", 400));

  if (chat.creator.toString() !== req.user.toString())
    return next(
      new ErrorHandler("You are not allowed to rename the group", 403)
    );

  await chatRef.update({ name });

  emitEvent(req, REFETCH_CHATS, chat.members);

  return res.status(200).json({
    success: true,
    message: "Group renamed successfully",
  });
});

// Delete a chat (1-on-1) or group
const deleteChat = TryCatch(async (req, res, next) => {
  const chatId = req.params.id;
  const myUid = req.user;

  const chatRef = db.collection("chats").doc(chatId);
  const chatDoc = await chatRef.get();

  if (!chatDoc.exists) return next(new ErrorHandler("Chat not found", 404));

  const chat = chatDoc.data();
  const members = chat.members;

  if (chat.groupChat && chat.creator.toString() !== myUid.toString())
    return next(
      new ErrorHandler("You are not allowed to delete the group", 403)
    );

  if (!chat.groupChat && !chat.members.includes(myUid.toString())) {
    return next(
      new ErrorHandler("You are not allowed to delete the chat", 403)
    );
  }

  // Find all messages and their attachments
  const messagesSnapshot = await db
    .collection("messages")
    .where("chat", "==", chatId)
    .get();

  const public_ids = [];
  messagesSnapshot.docs.forEach((doc) => {
    const message = doc.data();
    if (message.attachments && message.attachments.length > 0) {
      message.attachments.forEach(({ public_id }) =>
        public_ids.push(public_id)
      );
    }
  });

  // Batch delete all messages
  const batch = db.batch();
  messagesSnapshot.docs.forEach((doc) => batch.delete(doc.ref));

  await Promise.all([
    deletFilesFromCloudinary(public_ids), // Delete from Cloudinary
    chatRef.delete(), // Delete chat doc
    batch.commit(), // Delete all message docs
  ]);

  emitEvent(req, REFETCH_CHATS, members);

  return res.status(200).json({
    success: true,
    message: "Chat deleted successfully",
  });
});

// Get messages for a chat with pagination
const getMessages = TryCatch(async (req, res, next) => {
  const chatId = req.params.id;
  const { page = 1 } = req.query;
  const myUid = req.user;

  const resultPerPage = 20;
  const skip = (page - 1) * resultPerPage;

  const chatDoc = await db.collection("chats").doc(chatId).get();
  if (!chatDoc.exists) return next(new ErrorHandler("Chat not found", 404));

  if (!chatDoc.data().members.includes(myUid))
    return next(
      new ErrorHandler("You are not allowed to access this chat", 403)
    );

  // Get total count for pagination
  const countSnapshot = await db
    .collection("messages")
    .where("chat", "==", chatId)
    .count()
    .get();
  const totalMessagesCount = countSnapshot.data().count;

  // Get messages with pagination
  const messagesSnapshot = await db
    .collection("messages")
    .where("chat", "==", chatId)
    .orderBy("createdAt", "desc")
    .limit(resultPerPage)
    .offset(skip)
    .get();

  const messages = messagesSnapshot.docs.map((doc) => {
    const data = doc.data();
    return {
      _id: doc.id,
      ...data,
      // Convert Firestore Timestamp to ISO string for client
      createdAt: data.createdAt.toDate().toISOString(),
    };
  });

  const totalPages = Math.ceil(totalMessagesCount / resultPerPage) || 0;

  return res.status(200).json({
    success: true,
    messages: messages.reverse(),
    totalPages,
  });
});

export {
  newGroupChat,
  getMyChats,
  getMyGroups,
  addMembers,
  removeMember,
  leaveGroup,
  sendAttachments,
  getChatDetails,
  renameGroup,
  deleteChat,
  getMessages,
};