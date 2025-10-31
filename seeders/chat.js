import { faker, simpleFaker } from "@faker-js/faker";
import { admin, db } from "../utils/features.js";

const createSingleChats = async (numChats) => {
  try {
    const usersSnapshot = await db.collection("users").get();
    const users = usersSnapshot.docs.map((doc) => doc.id); // Get UIDs

    const chatsPromise = [];

    for (let i = 0; i < users.length; i++) {
      for (let j = i + 1; j < users.length; j++) {
        chatsPromise.push(
          db.collection("chats").add({
            name: faker.lorem.words(2),
            members: [users[i], users[j]],
            groupChat: false,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
          })
        );
      }
    }

    await Promise.all(chatsPromise);

    console.log("Single chats created successfully");
    process.exit();
  } catch (error) {
    console.error(error);
    process.exit(1);
  }
};

const createGroupChats = async (numChats) => {
  try {
    const usersSnapshot = await db.collection("users").get();
    const users = usersSnapshot.docs.map((doc) => doc.id); // Get UIDs

    const chatsPromise = [];

    for (let i = 0; i < numChats; i++) {
      const numMembers = simpleFaker.number.int({ min: 3, max: users.length });
      const members = [];

      for (let j = 0; j < numMembers; j++) {
        const randomIndex = Math.floor(Math.random() * users.length);
        const randomUser = users[randomIndex];

        // Ensure the same user is not added twice
        if (!members.includes(randomUser)) {
          members.push(randomUser);
        }
      }

      const chat = db.collection("chats").add({
        groupChat: true,
        name: faker.lorem.words(1),
        members,
        creator: members[0], // Assign a random creator
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      chatsPromise.push(chat);
    }

    await Promise.all(chatsPromise);

    console.log("Group chats created successfully");
    process.exit();
  } catch (error) {
    console.error(error);
    process.exit(1);
  }
};

const createMessages = async (numMessages) => {
  try {
    const usersSnapshot = await db.collection("users").get();
    const users = usersSnapshot.docs.map((doc) => ({
      id: doc.id,
      name: doc.data().name,
    })); // Get UID and name

    const chatsSnapshot = await db.collection("chats").get();
    const chats = chatsSnapshot.docs.map((doc) => doc.id); // Get chat IDs

    const messagesPromise = [];

    for (let i = 0; i < numMessages; i++) {
      const randomUser = users[Math.floor(Math.random() * users.length)];
      const randomChat = chats[Math.floor(Math.random() * chats.length)];

      messagesPromise.push(
        db.collection("messages").add({
          chat: randomChat,
          // Denormalize sender data as per controller logic
          sender: {
            _id: randomUser.id,
            name: randomUser.name,
          },
          content: faker.lorem.sentence(),
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        })
      );
    }

    await Promise.all(messagesPromise);

    console.log("Messages created successfully");
    process.exit();
  } catch (error) {
    console.error(error);
    process.exit(1);
  }
};

const createMessagesInAChat = async (chatId, numMessages) => {
  try {
    const usersSnapshot = await db.collection("users").get();
    const users = usersSnapshot.docs.map((doc) => ({
      id: doc.id,
      name: doc.data().name,
    })); // Get UID and name

    const messagesPromise = [];

    for (let i = 0; i < numMessages; i++) {
      const randomUser = users[Math.floor(Math.random() * users.length)];

      messagesPromise.push(
        db.collection("messages").add({
          chat: chatId,
          sender: {
            _id: randomUser.id,
            name: randomUser.name,
          },
          content: faker.lorem.sentence(),
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        })
      );
    }

    await Promise.all(messagesPromise);

    console.log("Messages created successfully in chat", chatId);
    process.exit();
  } catch (error) {
    console.error(error);
    process.exit(1);
  }
};

export {
  createGroupChats,
  createMessages,
  createMessagesInAChat,
  createSingleChats,
};