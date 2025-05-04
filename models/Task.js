const mongoose = require('mongoose');

const taskSchema = new mongoose.Schema({
  id: { type: String, required: true, unique: true },
  title: { type: String, required: true },
  description: { type: String, required: true }, // hoặc `required: false` nếu không bắt buộc
  status: {
    type: String,
    enum: ['To do', 'In progress', 'Done', 'Canceled'],
    default: 'To do',
  },
  priority: {
    type: Number,
    enum: [1, 2, 3],
    default: 1,
    set: (v) => {
      const priorityMap = {
        'low': 1, '1': 1, 1: 1,
        'medium': 2, '2': 2, 2: 2,
        'high': 3, '3': 3, 3: 3,
      };
      return priorityMap[v] || 1;
    },
  },
  dueDate: { type: Date },
  createdAt: { type: Date, default: Date.now },
  updatedAt: { type: Date, default: Date.now },
  assignedTo: { type: String, default: null },
  createdBy: { type: String, required: true },
  category: { type: String, default: '' },
  attachments: { type: [String], default: [] },
  completed: { type: Boolean, default: false },
});

module.exports = mongoose.model('Task', taskSchema);
