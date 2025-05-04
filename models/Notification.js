const mongoose = require('mongoose');

const notificationSchema = new mongoose.Schema({
  taskId: { type: String, required: true },
  userId: { type: String, required: true },
  action: { type: String, required: true },
  title: { type: String, required: true },
  body: { type: String, required: true },
  createdAt: { type: Date, default: Date.now },
});

module.exports = mongoose.model('Notification', notificationSchema);