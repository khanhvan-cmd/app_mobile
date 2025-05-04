const express = require('express');
const router = express.Router();
const User = require('../models/User');
const authenticateToken = require('../middlewares/authenticateToken');

router.get('/', authenticateToken, async (req, res) => {
  try {
    const users = await User.find({}, 'id username email avatar');
    res.status(200).json(users);
  } catch (error) {
    console.error('Error fetching users:', error.message);
    res.status(500).json({ error: 'Failed to fetch users' });
  }
});

module.exports = router;