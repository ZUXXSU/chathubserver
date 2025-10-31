import { faker } from "@faker-js/faker";
import { admin, db } from "../utils/features.js";

const createUser = async (numUsers) => {
  try {
    const usersPromise = [];

    for (let i = 0; i < numUsers; i++) {
      const userPromise = async () => {
        const name = faker.person.fullName();
        const username = faker.internet.userName();
        const email = faker.internet.email();
        const password = "password"; // Default password for all seeded users
        const avatarUrl = faker.image.avatar();

        // 1. Create user in Firebase Authentication
        const userRecord = await admin.auth().createUser({
          email,
          password,
          displayName: name,
          photoURL: avatarUrl,
        });

        // 2. Create user document in Firestore
        await db.collection("users").doc(userRecord.uid).set({
          name,
          username,
          bio: faker.lorem.sentence(10),
          avatar: {
            url: avatarUrl,
            public_id: faker.system.fileName(),
          },
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      };
      usersPromise.push(userPromise());
    }

    await Promise.all(usersPromise);

    console.log("Users created", numUsers);
    process.exit(1);
  } catch (error) {
    console.error(error);
    process.exit(1);
  }
};

export { createUser };