const express = require('express');
const router = express.Router();
const admin = require('firebase-admin');
const User = require('../models/User');
const { v4: uuidv4 } = require('uuid');

// Middleware xác thực token Firebase và kiểm tra quyền admin
const authenticateToken = async (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];
  if (!token) {
    return res.status(401).json({ error: 'Token required' });
  }

  try {
    const decodedToken = await admin.auth().verifyIdToken(token);
    req.user = decodedToken;
    next();
  } catch (error) {
    return res.status(403).json({ error: 'Invalid token' });
  }
};

const isAdmin = (req, res, next) => {
  if (req.user.role !== 'admin') {
    return res.status(403).json({ error: 'Admin access required' });
  }
  next();
};

// Đăng ký người dùng
router.post('/register', async (req, res) => {
  const { email, password, username } = req.body;

  if (!email || !password || !username) {
    return res.status(400).json({ error: 'Email, password, and username are required' });
  }

  try {
    const userRecord = await admin.auth().createUser({
      email,
      password,
      displayName: username,
    });

    const newUser = new User({
      id: userRecord.uid,
      username,
      email,
      avatar: '',
      createdAt: new Date(),
      lastActive: new Date(),
      role: 'user',
    });

    await newUser.save();

    await admin.auth().setCustomUserClaims(userRecord.uid, { role: newUser.role });

    res.status(201).json({ message: 'User registered successfully', uid: userRecord.uid });
  } catch (error) {
    console.error('Error registering user:', error.message);
    res.status(400).json({ error: error.message });
  }
});

// Đăng nhập người dùng - cần làm từ phía client
router.post('/login', async (req, res) => {
  const { email } = req.body;

  if (!email) {
    return res.status(400).json({ error: 'Email is required' });
  }

  try {
    const user = await User.findOne({ email });
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    res.status(200).json({
      message: 'User fetched',
      user: {
        id: user.id,
        email: user.email,
        username: user.username,
        avatar: user.avatar,
        role: user.role,
        createdAt: user.createdAt,
        lastActive: user.lastActive,
      },
    });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

// Cập nhật vai trò người dùng (chỉ cho admin)
router.put('/update-role/:id', authenticateToken, isAdmin, async (req, res) => {
  const { id } = req.params;
  const { role } = req.body;

  if (!id || !role) {
    return res.status(400).json({ error: 'User ID and role are required' });
  }

  try {
    const user = await User.findOneAndUpdate({ id }, { role }, { new: true });
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    await admin.auth().setCustomUserClaims(id, { role });

    res.status(200).json({ message: 'User role updated successfully', user });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

module.exports = router;
