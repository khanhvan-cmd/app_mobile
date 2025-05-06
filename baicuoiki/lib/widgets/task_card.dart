import 'package:flutter/material.dart';
import 'package:baicuoiki/models/task.dart';
import 'package:intl/intl.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  TaskCard({
    required this.task,
    required this.onToggle,
    required this.onDelete,
    required this.onEdit,
  });

  String getPriorityText(int priority) {
    switch (priority) {
      case 1:
        return 'Thấp';
      case 2:
        return 'Trung bình';
      case 3:
        return 'Cao';
      default:
        return 'Thấp';
    }
  }

  Color getPriorityColor(int priority) {
    switch (priority) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.red;
      default:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.white, Color(0xFFF3F4F8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(15),
        ),
        child: ListTile(
          contentPadding: EdgeInsets.all(16),
          title: Text(
            task.title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: const Color(0xFF333333),
              decoration: task.completed ? TextDecoration.lineThrough : null,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (task.description.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    task.description,
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Hạn: ${task.dueDate != null ? DateFormat.yMd().format(task.dueDate!) : 'Không có'}',
                  style: const TextStyle(color: Color(0xFF6A82FB), fontSize: 14),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Ưu tiên: ${getPriorityText(task.priority)}',
                  style: TextStyle(
                    color: getPriorityColor(task.priority),
                    fontSize: 14,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Trạng thái: ${task.status}', // Hiển thị trạng thái (sẽ là "Done" khi completed là true)
                  style: TextStyle(
                    color: task.completed ? Colors.green : Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          leading: Checkbox(
            value: task.completed,
            activeColor: const Color(0xFF6A82FB),
            onChanged: (value) {
              if (value != null) onToggle(value);
            },
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit, color: Color(0xFF6A82FB)),
                onPressed: onEdit,
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Color(0xFFFC5C7D)),
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}