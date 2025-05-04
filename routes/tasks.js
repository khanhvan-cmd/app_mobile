const express = require('express');
const router = express.Router();
const multer = require('multer');
const { v4: uuidv4 } = require('uuid');
const verifyToken = require('../middlewares/authenticateToken');
const Task = require('../models/Task');

const storage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, 'uploads/'),
  filename: (req, file, cb) => cb(null, Date.now() + '-' + file.originalname),
});
const upload = multer({ storage });

// GET /api/tasks/:userId
router.get('/:userId', verifyToken, async (req, res) => {
  try {
    const tasks = await Task.find({ createdBy: req.params.userId });
    res.status(200).json(tasks);
  } catch (err) {
    res.status(500).json({ error: 'Failed to fetch tasks', details: err.message });
  }
});

// POST /api/tasks
router.post('/', verifyToken, upload.array('attachments'), async (req, res) => {
  try {
    const parsedTask = JSON.parse(req.body.task);
    const {
      title,
      description,
      status,
      priority,
      dueDate,
      createdBy,
      assignedTo,
      category,
    } = parsedTask;

    if (!title || !description || !createdBy) {
      return res.status(400).json({ error: 'Title, description, and createdBy are required.' });
    }

    const task = new Task({
      id: uuidv4(),
      title,
      description,
      status,
      priority,
      dueDate: dueDate ? new Date(dueDate) : null,
      createdBy,
      assignedTo,
      category,
      attachments: req.files ? req.files.map(f => f.path) : [],
    });

    await task.save();
    res.status(201).json(task);
  } catch (err) {
    console.error('Error creating task:', err);
    res.status(500).json({ error: 'Failed to create task', details: err.message });
  }
});

// PUT /api/tasks/:id
router.put('/:id', verifyToken, upload.array('attachments'), async (req, res) => {
  try {
    const parsedTask = JSON.parse(req.body.task);
    const {
      title,
      description,
      status,
      priority,
      dueDate,
      createdBy,
      assignedTo,
      category,
      completed,
    } = parsedTask;

    const updatedFields = {
      title,
      description,
      status,
      priority,
      dueDate: dueDate ? new Date(dueDate) : null,
      createdBy,
      assignedTo,
      category,
      completed,
      updatedAt: new Date(),
    };

    if (req.files && req.files.length > 0) {
      updatedFields.attachments = req.files.map(file => file.path);
    }

    const updatedTask = await Task.findOneAndUpdate(
      { id: req.params.id },
      updatedFields,
      { new: true }
    );

    if (!updatedTask) {
      return res.status(404).json({ error: 'Task not found' });
    }

    res.status(200).json(updatedTask);
  } catch (err) {
    console.error('Error updating task:', err);
    res.status(500).json({ error: 'Failed to update task', details: err.message });
  }
});

// DELETE /api/tasks/:id
router.delete('/:id', verifyToken, async (req, res) => {
  try {
    const { createdBy } = req.body;

    if (!createdBy) {
      return res.status(400).json({ error: 'createdBy is required for deletion.' });
    }

    const deletedTask = await Task.findOneAndDelete({ id: req.params.id, createdBy });

    if (!deletedTask) {
      return res.status(404).json({ error: 'Task not found or unauthorized' });
    }

    res.status(200).json({ message: 'Task deleted successfully' });
  } catch (err) {
    console.error('Error deleting task:', err);
    res.status(500).json({ error: 'Failed to delete task', details: err.message });
  }
});

module.exports = router;
