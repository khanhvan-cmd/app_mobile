const admin = require('firebase-admin');
const User = require('./models/User.js');

// Initialize Firebase Admin
const serviceAccount = require(process.env.FIREBASE_CREDENTIALS_PATH);
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

// Function to update user role and custom claims
async function updateUserRole(userId, newRole) {
  if (!['user', 'admin'].includes(newRole)) {
    throw new Error('Invalid role');
  }

  try {
    // Update role in MongoDB
    const user = await User.findOne({ id: userId });
    if (!user) {
      throw new Error('User not found');
    }
    user.role = newRole;
    await user.save();

    // Update Firebase custom claims
    await admin.auth().setCustomUserClaims(userId, { role: newRole });
    console.log(`Role updated for user ${userId} to ${newRole}`);
  } catch (error) {
    console.error('Error updating user role:', error);
    throw error;
  }
}

module.exports = updateUserRole;