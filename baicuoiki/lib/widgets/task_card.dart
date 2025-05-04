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

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
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
              color: Color(0xFF333333),
              decoration: task.completed ? TextDecoration.lineThrough : null,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (task.description.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    task.description,
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ),
              Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Hạn: ${task.dueDate != null ? DateFormat.yMd().format(task.dueDate!) : 'Không có'}',
                  style: TextStyle(color: Color(0xFF6A82FB), fontSize: 14),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Ưu tiên: ${task.priority == 'low' ? 'Thấp' : task.priority == 'medium' ? 'Trung bình' : 'Cao'}',
                  style: TextStyle(
                    color: task.priority == 'high' ? Colors.red : task.priority == 'medium' ? Colors.orange : Colors.green,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          leading: Checkbox(
            value: task.completed,
            activeColor: Color(0xFF6A82FB),
            onChanged: (value) {
              if (value != null) onToggle(value);
            },
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.edit, color: Color(0xFF6A82FB)),
                onPressed: onEdit,
              ),
              IconButton(
                icon: Icon(Icons.delete, color: Color(0xFFFC5C7D)),
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}