import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:baicuoiki/models/task.dart';
import 'package:baicuoiki/services/task_service.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:html_unescape/html_unescape.dart'; // Correct import
import 'package:baicuoiki/screens/task_screen.dart';

class TaskDetailScreen extends StatefulWidget {
  final Task task;

  const TaskDetailScreen({super.key, required this.task});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  late Task _task;
  late String _status;
  final TaskService _taskService = TaskService();
  List<dynamic> _notifications = [];
  bool _isLoading = false;
  final HtmlUnescape _htmlUnescape = HtmlUnescape();

  @override
  void initState() {
    super.initState();
    _task = widget.task;
    _status = _task.status.isNotEmpty ? _task.status : 'To do';
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final token = await firebase_auth.FirebaseAuth.instance.currentUser?.getIdToken();
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:5000/api/notifications/${_task.createdBy}'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final notifications = jsonDecode(response.body) as List;
        setState(() {
          _notifications = notifications.where((n) => n['taskId'] == _task.id).toList();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load notifications: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading notifications: $e')),
      );
    }
  }

  Future<void> _openAttachment(String url) async {
    final fullUrl = url.startsWith('http') ? url : 'http://10.0.2.2:5000$url';
    if (await canLaunch(fullUrl)) {
      await launch(fullUrl);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cannot open attachment')),
      );
    }
  }

  void _editTask() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AddTaskDialog(userId: _task.createdBy, task: _task),
    );

    if (result != null) {
      final updatedTask = result['task'] as Task;
      final newAttachments = result['attachments'] as List<http.MultipartFile>;
      setState(() => _isLoading = true);
      try {
        final task = await _taskService.updateTask(updatedTask, newAttachments: newAttachments);
        if (task != null) {
          setState(() {
            _task = task;
            _status = task.status;
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Task updated successfully')),
          );
          _loadNotifications();
        }
      } catch (e) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating task: $e')),
        );
      }
    }
  }

  void _deleteTask() async {
    setState(() => _isLoading = true);
    try {
      final success = await _taskService.deleteTask(_task.id, _task.createdBy);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Task deleted successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting task: $e')),
      );
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Done':
        return Color(0xFF2ECC71);
      case 'In progress':
        return Color(0xFF3498DB);
      case 'Canceled':
        return Color(0xFFE74C3C);
      case 'To do':
      default:
        return Color(0xFF95A5A6);
    }
  }

  Widget _buildSectionTitle(String title, {IconData? icon}) {
    return Row(
      children: [
        Icon(icon, color: Color(0xFF4A90E2), size: 22),
        SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Row(
              children: [
                Icon(icon, color: Color(0xFF9B59B6), size: 20),
                SizedBox(width: 8),
                Text(
                  '$label:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Text(
              _htmlUnescape.convert(value),
              style: TextStyle(
                fontSize: 16,
                color: Colors.black54,
                height: 1.4,
              ),
              softWrap: true,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF4A90E2), Color(0xFF9B59B6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: [0.2, 0.8],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF4A90E2).withOpacity(0.9),
                          Color(0xFF9B59B6).withOpacity(0.9)
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 2))
                      ],
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 24),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Expanded(
                          child: Text(
                            _htmlUnescape.convert(_task.title.isNotEmpty ? _task.title : 'Untitled Task'),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.2,
                              shadows: [
                                Shadow(color: Colors.black38, blurRadius: 6, offset: Offset(2, 2))
                              ],
                            ),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.edit, color: Colors.white, size: 24),
                          onPressed: _editTask,
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.white, size: 24),
                          onPressed: _deleteTask,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Container(
                      margin: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 15,
                            offset: Offset(0, 6),
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(25),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionTitle('Trạng thái', icon: Icons.check_circle_outline),
                            SizedBox(height: 12),
                            AnimatedContainer(
                              duration: Duration(milliseconds: 300),
                              padding: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [_getStatusColor(_status), Color(0xFF3498DB)],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _status.isEmpty ? 'To do' : _status,
                                  isExpanded: true,
                                  dropdownColor: Colors.white,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  icon: Icon(Icons.arrow_drop_down, color: Colors.white),
                                  items: ['To do', 'In progress', 'Done', 'Canceled']
                                      .map((status) => DropdownMenuItem(
                                    value: status,
                                    child: Text(
                                      status,
                                      style: TextStyle(fontSize: 17, color: Colors.blue),
                                    ),
                                  ))
                                      .toList(),
                                  onChanged: (value) async {
                                    if (value != null) {
                                      final updatedTask = _task.copyWith(
                                        status: value,
                                        completed: value == 'Done',
                                      );
                                      setState(() => _isLoading = true);
                                      try {
                                        await _taskService.updateTask(updatedTask);
                                        setState(() {
                                          _task = updatedTask;
                                          _status = value;
                                          _isLoading = false;
                                        });
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Cập nhật trạng thái thành công'),
                                            backgroundColor: Color(0xFF2ECC71),
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                        _loadNotifications();
                                      } catch (e) {
                                        setState(() => _isLoading = false);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Lỗi khi cập nhật trạng thái: $e'),
                                            backgroundColor: Color(0xFFE74C3C),
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                      }
                                    }
                                  },
                                ),
                              ),
                            ),
                            SizedBox(height: 25),
                            _buildSectionTitle('Mô tả', icon: Icons.description),
                            SizedBox(height: 10),
                            Container(
                              padding: EdgeInsets.all(15),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(color: Color(0xFFE0E0E0), width: 1.5),
                                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
                              ),
                              child: Text(
                                _htmlUnescape.convert(_task.description.isNotEmpty ? _task.description : 'Không có mô tả'),
                                style: TextStyle(fontSize: 16, color: Colors.black87, height: 1.6),
                              ),
                            ),
                            SizedBox(height: 25),
                            _buildDetailRow(
                              'Ưu tiên',
                              _task.priority == 1 ? 'Thấp' : _task.priority == 2 ? 'Trung bình' : 'Cao',
                              Icons.priority_high,
                            ),
                            _buildDetailRow(
                              'Hạn deadline',
                              _task.dueDate != null ? DateFormat.yMd().format(_task.dueDate!) : 'Không có',
                              Icons.calendar_today,
                            ),
                            _buildDetailRow(
                              'Nhắc nhở',
                              _task.reminderTime != null ? DateFormat.yMd().add_jm().format(_task.reminderTime!) : 'Không có',
                              Icons.alarm,
                            ),
                            _buildDetailRow(
                              'Tạo lúc',
                              _task.createdAt != null ? DateFormat.yMd().format(_task.createdAt) : 'Không có',
                              Icons.create,
                            ),
                            _buildDetailRow(
                              'Cập nhật lúc',
                              _task.updatedAt != null ? DateFormat.yMd().format(_task.updatedAt) : 'Không có',
                              Icons.update,
                            ),
                            _buildDetailRow(
                              'Giao cho',
                              _task.assignedTo ?? 'Chưa giao',
                              Icons.person,
                            ),
                            _buildDetailRow(
                              'Người tạo',
                              _task.createdBy.isNotEmpty ? _task.createdBy : 'Không xác định',
                              Icons.account_circle,
                            ),
                            _buildDetailRow(
                              'Danh mục',
                              _task.category ?? 'Không có',
                              Icons.category,
                            ),
                            SizedBox(height: 25),
                            _buildSectionTitle('Đính kèm', icon: Icons.attach_file),
                            SizedBox(height: 10),
                            _task.attachments.isNotEmpty
                                ? Column(
                              children: _task.attachments.map((url) {
                                return Container(
                                  margin: EdgeInsets.symmetric(vertical: 6),
                                  child: Card(
                                    elevation: 3,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    child: ListTile(
                                      leading: Icon(Icons.insert_drive_file, color: Color(0xFF4A90E2), size: 28),
                                      title: Text(
                                        url.isNotEmpty ? url.split('/').last : 'Tệp không hợp lệ',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.black87,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      trailing: Icon(Icons.download, color: Color(0xFF9B59B6), size: 22),
                                      onTap: () => _openAttachment(url),
                                    ),
                                  ),
                                );
                              }).toList(),
                            )
                                : Padding(
                              padding: EdgeInsets.all(12),
                              child: Text(
                                'Không có đính kèm',
                                style: TextStyle(fontSize: 16, color: Colors.grey[600], fontStyle: FontStyle.italic),
                              ),
                            ),
                            if (_notifications.isNotEmpty) ...[
                              SizedBox(height: 25),
                              _buildSectionTitle('Thông báo', icon: Icons.notifications),
                              SizedBox(height: 10),
                              ..._notifications.map((notification) => Container(
                                margin: EdgeInsets.symmetric(vertical: 6),
                                child: Card(
                                  elevation: 3,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  child: ListTile(
                                    leading: Icon(Icons.notification_important, color: Color(0xFF4A90E2), size: 28),
                                    title: Text(
                                      _htmlUnescape.convert(notification['title']),
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.black87,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    subtitle: Text(
                                      _htmlUnescape.convert(notification['body']),
                                      style: TextStyle(fontSize: 14, color: Colors.black54),
                                    ),
                                    trailing: Text(
                                      DateFormat.yMd().format(DateTime.parse(notification['createdAt'])),
                                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                    ),
                                  ),
                                ),
                              )),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black45,
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}