const admin = require("firebase-admin");

// Load Firebase credentials from JSON file
const serviceAccount = require("./firebaseConfig.json");

if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });
}

const db = admin.firestore();

module.exports = { admin, db };
