import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:baicuoiki/models/task.dart';
import 'package:intl/intl.dart';

class TaskService {
  final String baseUrl = 'http://10.0.2.2:5000/api/tasks';

  Future<String?> _getToken() async {
    final user = firebase_auth.FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('No user logged in');
      return null;
    }
    final token = await user.getIdToken();
    print('Token retrieved: $token');
    return token;
  }

  Future<List<Task>> getTasks(String userId) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('User not authenticated');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/$userId'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
    print('GET /tasks/$userId - Response status: ${response.statusCode}');
    print('GET /tasks/$userId - Response body: ${response.body}');

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Task.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load tasks: ${response.statusCode} - ${response.body}');
    }
  }

  Future<List<Task>> getAllTasks() async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('User not authenticated');
    }

    try {
      final response = await http.get(
        Uri.parse(baseUrl),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      print('GET /tasks - Response status: ${response.statusCode}');
      print('GET /tasks - Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Task.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load all tasks: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching all tasks: $e');
    }
  }

  Future<Task?> addTask(Task task, {List<http.MultipartFile>? newAttachments}) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('User not authenticated');
    }

    // Stricter validation for title and createdBy
    if (task.title == null || task.title.trim().isEmpty) {
      throw Exception('Title is required and cannot be empty');
    }
    if (task.createdBy == null || task.createdBy.trim().isEmpty) {
      throw Exception('CreatedBy is required and cannot be empty');
    }

    final taskJson = task.toJson()..remove('id');
    print('POST /tasks - Sending task data to server: $taskJson');

    var request = http.MultipartRequest('POST', Uri.parse(baseUrl))
      ..headers['Authorization'] = 'Bearer $token'
      ..fields['task'] = jsonEncode(taskJson);

    if (newAttachments != null && newAttachments.isNotEmpty) {
      request.files.addAll(newAttachments);
    }

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    print('POST /tasks - Response status: ${response.statusCode}');
    print('POST /tasks - Response body: $responseBody');

    if (response.statusCode == 201) {
      try {
        final jsonData = jsonDecode(responseBody);
        final addedTask = Task.fromJson(jsonData);
        await sendTaskNotification(addedTask, 'created');
        if (addedTask.dueDate != null && addedTask.reminderTime != null) {
          await scheduleReminder(addedTask);
        }
        return addedTask;
      } catch (e) {
        throw Exception('Failed to parse response: $e');
      }
    } else {
      throw Exception('Failed to add task: $responseBody');
    }
  }

  Future<Task?> updateTask(Task task, {List<http.MultipartFile>? newAttachments}) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('User not authenticated');
    }

    if (task.id.isEmpty) {
      throw Exception('Task ID is required for update');
    }

    if (task.createdBy.isEmpty) {
      throw Exception('CreatedBy is required for update');
    }

    print('PUT /tasks/${task.id} - Task ID sent: ${task.id}');
    print('PUT /tasks/${task.id} - CreatedBy sent: ${task.createdBy}');
    print('PUT /tasks/${task.id} - Request body: ${jsonEncode(task.toJson())}');

    var request = http.MultipartRequest('PUT', Uri.parse('$baseUrl/${task.id}'))
      ..headers['Authorization'] = 'Bearer $token'
      ..fields['task'] = jsonEncode(task.toJson());

    if (newAttachments != null && newAttachments.isNotEmpty) {
      request.files.addAll(newAttachments);
    }

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    print('PUT /tasks/${task.id} - Response status: ${response.statusCode}');
    print('PUT /tasks/${task.id} - Response body: $responseBody');

    if (response.statusCode == 200) {
      final updatedTask = Task.fromJson(jsonDecode(responseBody));
      await sendTaskNotification(updatedTask, 'updated');
      if (updatedTask.dueDate != null && updatedTask.reminderTime != null) {
        await scheduleReminder(updatedTask);
      }
      return updatedTask;
    } else {
      throw Exception('Failed to update task: $responseBody');
    }
  }

  Future<bool> deleteTask(String taskId, String createdBy) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('User not authenticated');
    }

    if (taskId.isEmpty) {
      throw Exception('Task ID is required for deletion');
    }

    if (createdBy.isEmpty) {
      throw Exception('CreatedBy is required for deletion');
    }

    print('DELETE /tasks/$taskId - Task ID sent: $taskId');
    print('DELETE /tasks/$taskId - CreatedBy sent: $createdBy');

    final response = await http.delete(
      Uri.parse('$baseUrl/$taskId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'createdBy': createdBy}),
    );

    print('DELETE /tasks/$taskId - Response status: ${response.statusCode}');
    print('DELETE /tasks/$taskId - Response body: ${response.body}');

    if (response.statusCode == 200) {
      return true;
    } else {
      throw Exception('Failed to delete task: ${response.body}');
    }
  }

  Future<void> sendTaskNotification(Task task, String action) async {
    final token = await _getToken();
    if (token == null) {
      print('No token available for sending notification');
      return;
    }
    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:5000/api/notifications'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'taskId': task.id,
          'userId': task.createdBy,
          'action': action,
          'title': 'Công việc: ${task.title}',
          'body': action == 'created'
              ? 'Công việc "${task.title}" đã được tạo.'
              : 'Công việc "${task.title}" đã được cập nhật.',
        }),
      );
      if (response.statusCode != 200) {
        print('Failed to send notification: ${response.body}');
      }
    } catch (e) {
      print('Error sending notification: $e');
    }
  }

  Future<void> scheduleReminder(Task task) async {
    final token = await _getToken();
    if (token == null) {
      print('No token available for scheduling reminder');
      return;
    }
    if (task.reminderTime == null || task.dueDate == null) {
      print('No reminder time or due date set for task: ${task.id}');
      return;
    }
    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:5000/api/notifications/reminder'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'taskId': task.id,
          'userId': task.createdBy,
          'title': 'Nhắc nhở: ${task.title}',
          'body': 'Công việc "${task.title}" sẽ đến hạn vào ${DateFormat.yMd().format(task.dueDate!)}.',
          'scheduleTime': task.reminderTime!.toIso8601String(),
        }),
      );
      if (response.statusCode != 200) {
        print('Failed to schedule reminder: ${response.body}');
      }
    } catch (e) {
      print('Error scheduling reminder: $e');
    }
  }
}