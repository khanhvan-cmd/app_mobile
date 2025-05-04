const express = require('express');
const router = express.Router();
const admin = require('firebase-admin');
const Notification = require('../models/Notification');
const User = require('../models/User');
const authenticateToken = require('../middlewares/authenticateToken');

router.post('/', authenticateToken, async (req, res) => {
  const { taskId, userId, action, title, body } = req.body;

  if (!taskId || !userId || !action || !title || !body) {
    return res.status(400).json({ error: 'taskId, userId, action, title, and body are required' });
  }

  try {
    const user = await User.findOne({ id: userId });
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    const notification = new Notification({
      taskId,
      userId,
      action,
      title,
      body,
      createdAt: new Date(),
    });
    await notification.save();

    if (user.fcmToken && user.notificationsEnabled) {
      const message = {
        notification: { title, body },
        token: user.fcmToken,
      };
      await admin.messaging().send(message);
      console.log('Notification sent to FCM:', message);
    }

    res.status(200).json({ message: 'Notification processed successfully', notification });
  } catch (error) {
    console.error('Error processing notification:', error.message);
    res.status(500).json({ error: 'Failed to process notification' });
  }
});

router.get('/:userId', authenticateToken, async (req, res) => {
  try {
    const notifications = await Notification.find({ userId: req.params.userId }).sort({ createdAt: -1 });
    res.status(200).json(notifications);
  } catch (error) {
    console.error('Error fetching notifications:', error.message);
    res.status(500).json({ error: 'Failed to fetch notifications' });
  }
});

module.exports = router;