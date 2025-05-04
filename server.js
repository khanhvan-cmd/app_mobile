const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const admin = require('firebase-admin');
const taskRouter = require('./routes/tasks');
const authRouter = require('./routes/auth');
const attachmentRouter = require('./routes/attachments');
const notificationRouter = require('./routes/notifications');
const User = require('./models/User');
const Task = require('./models/Task');
const path = require('path');
const fs = require('fs');

const app = express();

// Tạo thư mục uploads nếu chưa tồn tại
const uploadDir = path.join(__dirname, 'uploads');
if (!fs.existsSync(uploadDir)) {
  fs.mkdirSync(uploadDir);
  console.log('Created uploads directory');
}

// Khởi tạo Firebase Admin
try {
  const serviceAccount = require(process.env.FIREBASE_CREDENTIALS_PATH || './ltmb786-firebase-adminsdk-fbsvc-4b434ad56b.json');
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });
  console.log('Firebase Admin initialized successfully');
} catch (error) {
  console.error('Error initializing Firebase Admin:', error.message);
  process.exit(1);
}

// Middleware
app.use(express.json());
app.use(cors());

// Phục vụ tệp tĩnh từ thư mục uploads
app.use('/uploads', express.static(uploadDir));

// Kết nối MongoDB
mongoose.connect('mongodb://localhost:27017/task-manager', {
  useNewUrlParser: true,
  useUnifiedTopology: true,
})
  .then(() => console.log('MongoDB connected'))
  .catch(err => console.error('MongoDB connection error:', err));

// Middleware xác thực Firebase token
const authenticateToken = async (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];
  if (!token) {
    console.log('No token provided in request');
    return res.status(401).json({ error: 'Token required' });
  }

  try {
    const decodedToken = await admin.auth().verifyIdToken(token);
    console.log('Decoded token:', decodedToken);
    req.user = decodedToken;
    next();
  } catch (error) {
    console.error('Error verifying token:', error);
    res.status(403).json({ error: 'Invalid token' });
  }
};

// Routes
app.use('/api/tasks', taskRouter);
app.use('/api/auth', authRouter);
app.use('/api/attachments', attachmentRouter);
app.use('/api/notifications', notificationRouter);

// Lấy danh sách người dùng với số lượng công việc
app.get('/api/users', authenticateToken, async (req, res) => {
  try {
    const users = await User.find();
    const usersWithTaskCount = await Promise.all(
      users.map(async (user) => {
        const tasks = await Task.find({ createdBy: user.id });
        const taskCount = tasks.length;
        return {
          id: user.id,
          email: user.email,
          username: user.username,
          avatar: user.avatar,
          role: user.role,
          tasks: tasks.map(task => ({
            id: task.id,
            createdBy: task.createdBy,
            title: task.title,
            description: task.description,
            status: task.status,
            priority: task.priority,
            dueDate: task.dueDate ? task.dueDate.toISOString() : null,
            createdAt: task.createdAt.toISOString(),
            updatedAt: task.updatedAt.toISOString(),
            assignedTo: task.assignedTo,
            category: task.category,
            attachments: task.attachments,
            completed: task.completed,
          })),
          taskCount,
          createdAt: user.createdAt.toISOString(),
          lastActive: user.lastActive.toISOString(),
        };
      })
    );
    res.status(200).json(usersWithTaskCount);
  } catch (err) {
    console.error('Error fetching users:', err);
    res.status(500).json({ error: err.message });
  }
});

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => console.log(`Server running on port ${PORT}`));