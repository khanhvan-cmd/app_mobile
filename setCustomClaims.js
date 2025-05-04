const admin = require('firebase-admin');

// Initialize Firebase Admin
const serviceAccount = require(process.env.FIREBASE_CREDENTIALS_PATH);
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

// Function to set custom claims for a user
async function setCustomClaims(userId, claims) {
  try {
    await admin.auth().setCustomUserClaims(userId, claims);
    console.log(`Custom claims set for user ${userId}:`, claims);
  } catch (error) {
    console.error('Error setting custom claims:', error);
    throw error;
  }
}

module.exports = setCustomClaims;