const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
  id: { type: String, required: true, unique: true },
  username: { type: String, required: true },
  email: { type: String, required: true, unique: true },
  avatar: { type: String },
  fcmToken: { type: String },
  notificationsEnabled: { type: Boolean, default: true },
  role: { type: String, default: 'user' },
  createdAt: { type: Date, default: Date.now },
  lastActive: { type: Date, default: Date.now },
});

module.exports = mongoose.model('User', userSchema);