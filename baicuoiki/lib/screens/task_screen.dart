import 'package:flutter/material.dart';
import 'package:baicuoiki/models/task.dart';
import 'package:baicuoiki/models/user.dart';
import 'package:baicuoiki/services/auth_service.dart';
import 'package:baicuoiki/services/task_service.dart';
import 'package:baicuoiki/widgets/task_card.dart';
import 'package:baicuoiki/screens/task_detail_screen.dart';
import 'package:baicuoiki/screens/calendar_view.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'dart:ui';
import 'package:image_picker/image_picker.dart';
import 'dart:io' as io; // Use alias to avoid conflicts

class TaskScreen extends StatefulWidget {
  const TaskScreen({super.key});

  @override
  _TaskScreenState createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> with SingleTickerProviderStateMixin {
  final TaskService _taskService = TaskService();
  final AuthService _authService = AuthService();
  List<Task> _tasks = [];
  List<Task> _filteredTasks = [];
  bool _isLoading = true;
  User? _user;
  String _searchQuery = '';
  String _filterStatus = 'All';
  String? _filterCategory;
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeUserAndLoadTasks();
    });
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  void _initializeUserAndLoadTasks() {
    final arguments = ModalRoute.of(context)?.settings.arguments;
    if (arguments is User) {
      _user = arguments;
      print('Khởi tạo người dùng với userId: ${_user!.id}, username: ${_user!.username}');
      _loadTasks();
    } else {
      print('Lỗi: Không tìm thấy đối tượng User hợp lệ');
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Text('Lỗi: Không tìm thấy người dùng. Vui lòng đăng nhập lại.'),
            ],
          ),
          backgroundColor: Colors.red[400],
        ),
      );
    }
  }

  void _loadTasks() async {
    if (_user == null) {
      print('Lỗi: Người dùng là null trong _loadTasks');
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Text('Lỗi: Không tìm thấy người dùng'),
            ],
          ),
          backgroundColor: Colors.red[400],
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      print('Đang tải công việc cho userId: ${_user!.id}');
      final tasks = await _taskService.getTasks(_user!.id);
      print('Đã tải: ${tasks.length} công việc');
      setState(() {
        _tasks = tasks;
        _filteredTasks = tasks;
        _isLoading = false;
        if (_filterCategory != null && _filterCategory != 'All') {
          final categories = _tasks.map((t) => t.category).whereType<String>().toSet();
          if (!categories.contains(_filterCategory)) {
            _filterCategory = null;
          }
        }
      });
      _filterTasks();
    } catch (e) {
      print('Lỗi khi tải công việc: $e');
      setState(() {
        _tasks = [];
        _filteredTasks = [];
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Text('Lỗi khi tải công việc: $e'),
            ],
          ),
          backgroundColor: Colors.red[400],
        ),
      );
    }
  }

  void _addTask() async {
    if (_user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Text('Lỗi: Không tìm thấy người dùng'),
            ],
          ),
          backgroundColor: Colors.red[400],
        ),
      );
      return;
    }

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AddTaskDialog(userId: _user!.id),
    );

    if (result != null) {
      final newTask = result['task'] as Task;
      final newAttachments = result['attachments'] as List<http.MultipartFile>;
      try {
        final addedTask = await _taskService.addTask(newTask, newAttachments: newAttachments);
        if (addedTask != null) {
          setState(() {
            _tasks.add(addedTask);
            _filteredTasks = List.from(_tasks);
          });
          _filterTasks();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Text('Thêm công việc thành công'),
                ],
              ),
              backgroundColor: Colors.green[400],
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Text('Lỗi khi thêm công việc: $e'),
              ],
            ),
            backgroundColor: Colors.red[400],
          ),
        );
      }
    }
  }

  void _updateTask(Task task) async {
    try {
      print('Calling updateTask with task ID: ${task.id}');
      final updatedTask = await _taskService.updateTask(task);
      if (updatedTask != null) {
        setState(() {
          final index = _tasks.indexWhere((t) => t.id == updatedTask.id);
          if (index != -1) {
            _tasks[index] = updatedTask;
            _filteredTasks = List.from(_tasks);
          }
        });
        _filterTasks();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('Cập nhật công việc thành công'),
              ],
            ),
            backgroundColor: Colors.green[400],
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Text('Lỗi khi cập nhật công việc: $e'),
            ],
          ),
          backgroundColor: Colors.red[400],
        ),
      );
    }
  }

  void _editTask(Task task) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AddTaskDialog(userId: _user!.id, task: task),
    );

    if (result != null) {
      final updatedTask = result['task'] as Task;
      _updateTask(updatedTask);
    }
  }

  void _deleteTask(String taskId) async {
    if (_user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Text('Lỗi: Không tìm thấy người dùng'),
            ],
          ),
          backgroundColor: Colors.red[400],
        ),
      );
      return;
    }

    try {
      final success = await _taskService.deleteTask(taskId, _user!.id);
      if (success) {
        setState(() {
          _tasks.removeWhere((task) => task.id == taskId);
          _filteredTasks = List.from(_tasks);
        });
        _filterTasks();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('Xóa công việc thành công'),
              ],
            ),
            backgroundColor: Colors.green[400],
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Text('Lỗi khi xóa công việc: $e'),
            ],
          ),
          backgroundColor: Colors.red[400],
        ),
      );
    }
  }

  void _logout() async {
    try {
      await _authService.signOut();
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Text('Lỗi khi đăng xuất: $e'),
            ],
          ),
          backgroundColor: Colors.red[400],
        ),
      );
    }
  }

  void _filterTasks() {
    setState(() {
      _filteredTasks = _tasks.where((task) {
        final matchesSearch = task.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            task.description.toLowerCase().contains(_searchQuery.toLowerCase());
        final matchesStatus = _filterStatus == 'All' || task.status == _filterStatus;
        final matchesCategory = _filterCategory == null || _filterCategory == 'All' || task.category == _filterCategory;
        return matchesSearch && matchesStatus && matchesCategory;
      }).toList();
      print('Filtered tasks: ${_filteredTasks.length}');
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      return Scaffold(
        body: Center(
          child: _isLoading
              ? const CircularProgressIndicator(color: Color(0xFFFC5C7D))
              : Text(
            'Lỗi: Không tìm thấy người dùng. Vui lòng đăng nhập lại.',
            style: GoogleFonts.roboto(fontSize: 18, color: Colors.white),
          ),
        ),
        backgroundColor: const Color(0xFF6A82FB),
      );
    }

    print('Xây dựng TaskScreen với userId: ${_user!.id}');

    final categories = ['All', ..._tasks.map((t) => t.category).whereType<String>().toSet()];
    final currentCategory = (_filterCategory == null || !categories.contains(_filterCategory)) ? 'All' : _filterCategory;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6A82FB), Color(0xFFFC5C7D)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Xin chào, ${_user!.username}',
                          style: GoogleFonts.montserrat(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: const [
                              Shadow(
                                blurRadius: 8.0,
                                color: Colors.black26,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          'Quản lý công việc của bạn',
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            color: Colors.white70,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.settings, color: Colors.white, size: 28),
                          onPressed: () => Navigator.pushNamed(context, '/settings'),
                        ),
                        IconButton(
                          icon: const Icon(Icons.logout, color: Colors.white, size: 28),
                          onPressed: _logout,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'Tìm kiếm công việc...',
                              hintStyle: GoogleFonts.montserrat(color: Colors.white70),
                              prefixIcon: const Icon(Icons.search, color: Colors.white70, size: 24
                              ),
                              filled: true,
                              fillColor: Colors.white24,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: const BorderSide(color: Colors.white70, width: 2),
                              ),
                            ),
                            style: GoogleFonts.montserrat(color: Colors.white),
                            onChanged: (value) {
                              _searchQuery = value;
                              _filterTasks();
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        DropdownButton<String>(
                          value: _filterStatus,
                          icon: const Icon(Icons.filter_list, color: Colors.white, size: 24),
                          dropdownColor: const Color(0xFF6A82FB),
                          items: ['All', 'To do', 'In progress', 'Done', 'Canceled']
                              .map((status) => DropdownMenuItem(
                            value: status,
                            child: Text(
                              status,
                              style: GoogleFonts.montserrat(color: Colors.white, fontSize: 16),
                            ),
                          ))
                              .toList(),
                          onChanged: (value) {
                            _filterStatus = value!;
                            _filterTasks();
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    DropdownButton<String>(
                      value: currentCategory,
                      icon: const Icon(Icons.category, color: Colors.white, size: 24),
                      dropdownColor: const Color(0xFF6A82FB),
                      items: categories
                          .map((category) => DropdownMenuItem(
                        value: category,
                        child: Text(
                          category,
                          style: GoogleFonts.montserrat(color: Colors.white, fontSize: 16),
                        ),
                      ))
                          .toList(),
                      onChanged: (value) {
                        _filterCategory = value == 'All' ? null : value;
                        _filterTasks();
                      },
                    ),
                  ],
                ),
              ),
              TabBar(
                controller: _tabController,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                indicatorColor: Colors.white,
                tabs: const [
                  Tab(text: 'Danh sách'),
                  Tab(text: 'Lịch'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                      ),
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFC5C7D)))
                          : _filteredTasks.isEmpty
                          ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.task_alt,
                              size: 60,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Không tìm thấy công việc',
                              style: GoogleFonts.roboto(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Nhấn nút + để thêm công việc mới!',
                              style: GoogleFonts.roboto(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      )
                          : ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: _filteredTasks.length,
                        itemBuilder: (context, index) {
                          final task = _filteredTasks[index];
                          return AnimationConfiguration.staggeredList(
                            position: index,
                            duration: const Duration(milliseconds: 375),
                            child: SlideAnimation(
                              verticalOffset: 50.0,
                              child: FadeInAnimation(
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => TaskDetailScreen(task: task),
                                      ),
                                    );
                                  },
                                  child: TaskCard(
                                    task: task,
                                    onToggle: (value) {
                                      _updateTask(task.copyWith(
                                        status: value ? 'Done' : 'To do',
                                        completed: value,
                                      ));
                                    },
                                    onDelete: () => _deleteTask(task.id),
                                    onEdit: () => _editTask(task),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    CalendarView(tasks: _filteredTasks),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTask,
        backgroundColor: const Color(0xFFFC5C7D),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
    );
  }
}



class AddTaskDialog extends StatefulWidget {
  final String userId;
  final Task? task;

  const AddTaskDialog({super.key, required this.userId, this.task});

  @override
  _AddTaskDialogState createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<AddTaskDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _assignedToController;
  late TextEditingController _categoryController;
  String _status = 'To do';
  int _priority = 1;
  DateTime? _dueDate;
  DateTime? _reminderTime;
  List<XFile> _newAttachments = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _descriptionController = TextEditingController(text: widget.task?.description ?? '');
    _assignedToController = TextEditingController(text: widget.task?.assignedTo ?? '');
    _categoryController = TextEditingController(text: widget.task?.category ?? '');
    _status = widget.task?.status ?? 'To do';
    _priority = widget.task?.priority ?? 1;
    _dueDate = widget.task?.dueDate;
    _reminderTime = widget.task?.reminderTime;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _assignedToController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null) {
      setState(() {
        _dueDate = pickedDate;
      });
    }
  }

  Future<void> _pickReminderTime() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _reminderTime ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_reminderTime ?? DateTime.now()),
      );
      if (pickedTime != null) {
        setState(() {
          _reminderTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  Future<void> _pickImages() async {
    final pickedFiles = await _picker.pickMultiImage();
    if (pickedFiles != null) {
      setState(() {
        _newAttachments.addAll(pickedFiles);
      });
    }
  }

  Future<List<http.MultipartFile>> _convertToMultipartFiles(List<XFile> files) async {
    List<http.MultipartFile> multipartFiles = [];
    for (var file in files) {
      final bytes = await file.readAsBytes();
      multipartFiles.add(
        http.MultipartFile.fromBytes(
          'attachments',
          bytes,
          filename: file.name,
        ),
      );
    }
    return multipartFiles;
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final currentUser = firebase_auth.FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User not authenticated')),
      );
      return;
    }

    final newTask = Task(
      id: widget.task?.id ?? '',
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      status: _status,
      priority: _priority,
      dueDate: _dueDate,
      createdAt: widget.task?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
      assignedTo: _assignedToController.text.trim(),
      createdBy: currentUser.uid,
      category: _categoryController.text.trim(),
      attachments: widget.task?.attachments ?? [],
      completed: _status == 'Done',
      reminderTime: _reminderTime,
    );

    final newAttachments = await _convertToMultipartFiles(_newAttachments);

    Navigator.of(context).pop({
      'task': newTask,
      'attachments': newAttachments,
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.task == null ? 'Thêm công việc mới' : 'Chỉnh sửa công việc'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(labelText: 'Tiêu đề'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập tiêu đề';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: 'Mô tả'),
              ),
              DropdownButtonFormField<String>(
                value: _status,
                decoration: InputDecoration(labelText: 'Trạng thái'),
                items: ['To do', 'In progress', 'Done', 'Canceled']
                    .map((status) => DropdownMenuItem(
                  value: status,
                  child: Text(status),
                ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _status = value;
                    });
                  }
                },
              ),
              DropdownButtonFormField<int>(
                value: _priority,
                decoration: InputDecoration(labelText: 'Ưu tiên'),
                items: [
                  DropdownMenuItem(value: 1, child: Text('Thấp')),
                  DropdownMenuItem(value: 2, child: Text('Trung bình')),
                  DropdownMenuItem(value: 3, child: Text('Cao')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _priority = value;
                    });
                  }
                },
              ),
              ListTile(
                title: Text(_dueDate == null
                    ? 'Chọn ngày hết hạn'
                    : 'Hết hạn: ${DateFormat.yMd().format(_dueDate!)}'),
                trailing: Icon(Icons.calendar_today),
                onTap: _pickDueDate,
              ),
              ListTile(
                title: Text(_reminderTime == null
                    ? 'Chọn thời gian nhắc nhở'
                    : 'Nhắc nhở: ${DateFormat.yMd().add_jm().format(_reminderTime!)}'),
                trailing: Icon(Icons.alarm),
                onTap: _pickReminderTime,
              ),
              TextFormField(
                controller: _assignedToController,
                decoration: InputDecoration(labelText: 'Giao cho'),
              ),
              TextFormField(
                controller: _categoryController,
                decoration: InputDecoration(labelText: 'Danh mục'),
              ),
              ListTile(
                title: Text('Đính kèm hình ảnh'),
                trailing: Icon(Icons.attach_file),
                onTap: _pickImages,
              ),
              if (_newAttachments.isNotEmpty)
                Wrap(
                  children: _newAttachments.map((file) {
                    return Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Image.file(
                        io.File(file.path), // Use fully qualified name to avoid conflicts
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: Text(widget.task == null ? 'Thêm' : 'Cập nhật'),
        ),
      ],
    );
  }
}