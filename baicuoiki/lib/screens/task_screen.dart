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
  String _filterStatus = 'All'; // Default filter status
  String? _filterCategory = null; // Default to no category filter
  TabController? _tabController;
  bool _showAllTasks = false;

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
      print('Khởi tạo người dùng với userId: ${_user!.id}, username: ${_user!.username}, role: ${_user!.role}');
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
      print('Đang tải công việc cho userId: ${_user!.id}, chế độ: ${_showAllTasks ? "Tất cả công việc" : "Công việc cá nhân"}');
      final tasks = _showAllTasks && _user!.role == 'Admin'
          ? await _taskService.getAllTasks()
          : await _taskService.getTasks(_user!.id);
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

  void _toggleTaskView() {
    setState(() {
      _showAllTasks = !_showAllTasks;
    });
    _loadTasks();
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
      builder: (context) => AddTaskDialog(userId: _user!.id, role: _user!.role),
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
      builder: (context) => AddTaskDialog(userId: _user!.id, role: _user!.role, task: task),
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

    if (_user!.role != 'Admin') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.warning, color: Colors.white),
              const SizedBox(width: 8),
              Text('Chỉ Admin mới có thể xóa công việc'),
            ],
          ),
          backgroundColor: Colors.orange[400],
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
              ? const CircularProgressIndicator(color: Color(0xFF7C4DFF))
              : Text(
            'Lỗi: Không tìm thấy người dùng. Vui lòng đăng nhập lại.',
            style: GoogleFonts.poppins(fontSize: 18, color: Colors.white),
          ),
        ),
        backgroundColor: const Color(0xFF3F51B5),
      );
    }

    print('Xây dựng TaskScreen với userId: ${_user!.id}, role: ${_user!.role}');

    final categories = ['All', ..._tasks.map((t) => t.category).whereType<String>().toSet()];
    final currentCategory = (_filterCategory == null || !categories.contains(_filterCategory)) ? 'All' : _filterCategory;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF3F51B5), Color(0xFF7C4DFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Xin chào, ${_user!.username}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                        shadows: const [
                                          Shadow(
                                            blurRadius: 10.0,
                                            color: Colors.black26,
                                            offset: Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (_user!.role == 'Admin')
                                      Padding(
                                        padding: const EdgeInsets.only(left: 10.0),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [Color(0xFFFFA726), Color(0xFFFF5722)],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            borderRadius: BorderRadius.circular(12),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black26,
                                                blurRadius: 6,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Text(
                                            'Admin',
                                            style: GoogleFonts.poppins(
                                              fontSize: 10,
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                Text(
                                  'Quản lý công việc của bạn',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    color: Colors.white.withOpacity(0.8),
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(30),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: TextField(
                                  decoration: InputDecoration(
                                    hintText: 'Tìm kiếm công việc...',
                                    hintStyle: GoogleFonts.poppins(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 16,
                                    ),
                                    prefixIcon: Icon(
                                      Icons.search,
                                      color: Colors.white.withOpacity(0.7),
                                      size: 24,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(30),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(vertical: 15),
                                  ),
                                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 16),
                                  onChanged: (value) {
                                    _searchQuery = value;
                                    _filterTasks();
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF7C4DFF), Color(0xFF3F51B5)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _filterStatus.isEmpty ? 'All' : _filterStatus,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  icon: Icon(
                                    Icons.filter_list,
                                    color: Colors.white.withOpacity(0.9),
                                    size: 24,
                                  ),
                                  dropdownColor: const Color(0xFF3F51B5),
                                  items: ['All', 'To do', 'In progress', 'Done', 'Canceled']
                                      .map((status) => DropdownMenuItem(
                                    value: status,
                                    child: Text(
                                      status,
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ))
                                      .toList(),
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() {
                                        _filterStatus = value;
                                        _filterTasks();
                                      });
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF7C4DFF), Color(0xFF3F51B5)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: currentCategory?.isEmpty ?? true ? 'All' : (categories.contains(currentCategory) ? currentCategory : 'All'),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  icon: Icon(
                                    Icons.category,
                                    color: Colors.white.withOpacity(0.9),
                                    size: 24,
                                  ),
                                  dropdownColor: const Color(0xFF3F51B5),
                                  items: categories
                                      .map((category) => DropdownMenuItem(
                                    value: category,
                                    child: Text(
                                      category,
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ))
                                      .toList(),
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() {
                                        _filterCategory = value == 'All' ? null : value;
                                        _filterTasks();
                                      });
                                    }
                                  },
                                ),
                              ),
                            ),
                            if (_user!.role == 'Admin')
                              GestureDetector(
                                onTap: _toggleTaskView,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFFFFA726), Color(0xFFFF5722)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black26,
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    _showAllTasks ? 'Xem công việc của tôi' : 'Xem tất cả công việc',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TabBar(
                      controller: _tabController,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white.withOpacity(0.6),
                      indicatorColor: const Color(0xFFFF5722),
                      labelStyle: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      unselectedLabelStyle: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                      tabs: const [
                        Tab(text: 'Danh sách'),
                        Tab(text: 'Lịch'),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(top: 10),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                      ),
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _isLoading
                              ? const Center(child: CircularProgressIndicator(color: Color(0xFF7C4DFF)))
                              : _filteredTasks.isEmpty
                              ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.task_alt,
                                  size: 70,
                                  color: Colors.grey[300],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Không tìm thấy công việc',
                                  style: GoogleFonts.poppins(
                                    fontSize: 20,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Nhấn nút + để thêm công việc mới!',
                                  style: GoogleFonts.poppins(
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
                                duration: const Duration(milliseconds: 500),
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
                          CalendarView(tasks: _filteredTasks),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.transparent,
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF3F51B5), Color(0xFF7C4DFF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (_user!.role == 'Admin')
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Material(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                    child: IconButton(
                      icon: const Icon(Icons.people, color: Colors.white, size: 32),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const UserManagementScreen(),
                          ),
                        );
                      },
                      tooltip: 'Quản lý người dùng',
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Material(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  child: IconButton(
                    icon: const Icon(Icons.settings, color: Colors.white, size: 32),
                    onPressed: () => Navigator.pushNamed(context, '/settings'),
                    tooltip: 'Cài đặt',
                  ),
                ),
              ),
              Material(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                child: IconButton(
                  icon: const Icon(Icons.logout, color: Colors.white, size: 32),
                  onPressed: _logout,
                  tooltip: 'Đăng xuất',
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTask,
        backgroundColor: const Color(0xFFFF5722),
        child: const Icon(Icons.add, color: Colors.white, size: 30),
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        heroTag: null,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

class TaskCard extends StatelessWidget {
  final Task task;
  final Function(bool) onToggle;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const TaskCard({
    super.key,
    required this.task,
    required this.onToggle,
    required this.onDelete,
    required this.onEdit,
  });

  Color _getStatusColor(String status) {
    switch (status) {
      case 'To do':
        return Colors.blue[100]!;
      case 'In progress':
        return Colors.orange[100]!;
      case 'Done':
        return Colors.green[100]!;
      case 'Canceled':
        return Colors.red[100]!;
      default:
        return Colors.grey[200]!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      color: _getStatusColor(task.status),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        title: Text(
          task.title,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          task.description,
          style: GoogleFonts.poppins(fontSize: 12),
          overflow: TextOverflow.ellipsis,
          maxLines: 2,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Checkbox(
              value: task.completed,
              onChanged: (value) => onToggle(value!),
            ),
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

class AddTaskDialog extends StatefulWidget {
  final String userId;
  final String role;
  final Task? task;

  const AddTaskDialog({super.key, required this.userId, required this.role, this.task});

  @override
  _AddTaskDialogState createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<AddTaskDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _categoryController;
  String? _assignedTo;
  String _status = '';
  int _priority = 1;
  DateTime? _dueDate;
  DateTime? _reminderTime;
  List<XFile> _newAttachments = [];
  final ImagePicker _picker = ImagePicker();
  List<User> _users = [];
  bool _isLoadingUsers = true;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _descriptionController = TextEditingController(text: widget.task?.description ?? '');
    _categoryController = TextEditingController(text: widget.task?.category ?? '');
    _assignedTo = widget.task?.assignedTo;
    _status = widget.task?.status ?? '';
    _priority = widget.task?.priority ?? 1;
    _dueDate = widget.task?.dueDate;
    _reminderTime = widget.task?.reminderTime;

    if (widget.role == 'Admin') {
      _loadUsers();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoadingUsers = true);
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:5000/api/users'),
        headers: {
          'Authorization': 'Bearer ${await firebase_auth.FirebaseAuth.instance.currentUser?.getIdToken()}',
        },
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _users = data.map((json) => User.fromJson(json)).toList();
          _isLoadingUsers = false;
        });
      } else {
        throw Exception('Failed to load users');
      }
    } catch (e) {
      setState(() => _isLoadingUsers = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Text('Lỗi khi tải danh sách người dùng: $e'),
            ],
          ),
          backgroundColor: Colors.red[400],
        ),
      );
    }
  }

  Future<void> _pickDueDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF7C4DFF),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black87,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
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
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF7C4DFF),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black87,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );
    if (pickedDate != null) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_reminderTime ?? DateTime.now()),
        builder: (context, child) {
          return Theme(
            data: ThemeData.light().copyWith(
              colorScheme: const ColorScheme.light(
                primary: Color(0xFF7C4DFF),
                onPrimary: Colors.white,
                surface: Colors.white,
                onSurface: Colors.black87,
              ),
              dialogBackgroundColor: Colors.white,
            ),
            child: child!,
          );
        },
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

    final assignedToValue = widget.role == 'Admin' ? _assignedTo : null;

    final newTask = Task(
      id: widget.task?.id ?? '',
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      status: _status,
      priority: _priority,
      dueDate: _dueDate,
      createdAt: widget.task?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
      assignedTo: assignedToValue,
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
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        widget.task == null ? 'Thêm công việc mới' : 'Chỉnh sửa công việc',
        style: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF3F51B5),
        ),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Tiêu đề',
                  labelStyle: GoogleFonts.poppins(color: Colors.grey[600]),
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF7C4DFF), width: 2),
                  ),
                ),
                style: GoogleFonts.poppins(fontSize: 16),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập tiêu đề';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Mô tả',
                  labelStyle: GoogleFonts.poppins(color: Colors.grey[600]),
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF7C4DFF), width: 2),
                  ),
                ),
                style: GoogleFonts.poppins(fontSize: 16),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _status.isEmpty ? null : _status,
                decoration: InputDecoration(
                  labelText: 'Trạng thái',
                  labelStyle: GoogleFonts.poppins(color: Colors.grey[600]),
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF7C4DFF), width: 2),
                  ),
                ),
                items: ['To do', 'In progress', 'Done', 'Canceled', 'Not Set']
                    .map((status) => DropdownMenuItem(
                  value: status == 'Not Set' ? '' : status,
                  child: Text(status, style: GoogleFonts.poppins(fontSize: 16)),
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
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: _priority,
                decoration: InputDecoration(
                  labelText: 'Ưu tiên',
                  labelStyle: GoogleFonts.poppins(color: Colors.grey[600]),
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF7C4DFF), width: 2),
                  ),
                ),
                items: [
                  DropdownMenuItem(value: 1, child: Text('Thấp', style: GoogleFonts.poppins(fontSize: 16))),
                  DropdownMenuItem(value: 2, child: Text('Trung bình', style: GoogleFonts.poppins(fontSize: 16))),
                  DropdownMenuItem(value: 3, child: Text('Cao', style: GoogleFonts.poppins(fontSize: 16))),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _priority = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 12),
              ListTile(
                title: Text(
                  _dueDate == null ? 'Chọn ngày hết hạn' : 'Hết hạn: ${DateFormat.yMd().format(_dueDate!)}',
                  style: GoogleFonts.poppins(fontSize: 16, color: Colors.black87),
                ),
                trailing: const Icon(Icons.calendar_today, color: Color(0xFF7C4DFF)),
                onTap: _pickDueDate,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                tileColor: Colors.grey[100],
              ),
              const SizedBox(height: 12),
              ListTile(
                title: Text(
                  _reminderTime == null
                      ? 'Chọn thời gian nhắc nhở'
                      : 'Nhắc nhở: ${DateFormat.yMd().add_jm().format(_reminderTime!)}',
                  style: GoogleFonts.poppins(fontSize: 16, color: Colors.black87),
                ),
                trailing: const Icon(Icons.alarm, color: Color(0xFF7C4DFF)),
                onTap: _pickReminderTime,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                tileColor: Colors.grey[100],
              ),
              if (widget.role == 'Admin') ...[
                const SizedBox(height: 12),
                _isLoadingUsers
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFF7C4DFF)))
                    : DropdownButtonFormField<String>(
                  value: _assignedTo,
                  decoration: InputDecoration(
                    labelText: 'Giao cho',
                    labelStyle: GoogleFonts.poppins(color: Colors.grey[600]),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF7C4DFF), width: 2),
                    ),
                  ),
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('Không giao cho ai', style: TextStyle(fontStyle: FontStyle.italic)),
                    ),
                    ..._users.map((user) => DropdownMenuItem<String>(
                      value: user.id,
                      child: Text(
                        user.username,
                        style: GoogleFonts.poppins(fontSize: 16),
                      ),
                    )),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _assignedTo = value;
                    });
                  },
                ),
              ],
              const SizedBox(height: 12),
              TextFormField(
                controller: _categoryController,
                decoration: InputDecoration(
                  labelText: 'Danh mục',
                  labelStyle: GoogleFonts.poppins(color: Colors.grey[600]),
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF7C4DFF), width: 2),
                  ),
                ),
                style: GoogleFonts.poppins(fontSize: 16),
              ),
              const SizedBox(height: 12),
              ListTile(
                title: Text(
                  'Đính kèm hình ảnh',
                  style: GoogleFonts.poppins(fontSize: 16, color: Colors.black87),
                ),
                trailing: const Icon(Icons.attach_file, color: Color(0xFF7C4DFF)),
                onTap: _pickImages,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                tileColor: Colors.grey[100],
              ),
              if (_newAttachments.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _newAttachments.map((file) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        io.File(file.path),
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Hủy',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF7C4DFF),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            elevation: 5,
          ),
          child: Text(
            widget.task == null ? 'Thêm' : 'Cập nhật',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  _UserManagementScreenState createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  List<User> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:5000/api/users'),
        headers: {
          'Authorization': 'Bearer ${await firebase_auth.FirebaseAuth.instance.currentUser?.getIdToken()}',
        },
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _users = data.map((json) => User.fromJson(json)).toList();
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load users');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Text('Lỗi khi tải danh sách người dùng: $e'),
            ],
          ),
          backgroundColor: Colors.red[400],
        ),
      );
    }
  }

  Future<void> _deleteUser(String userId) async {
    try {
      final response = await http.delete(
        Uri.parse('http://10.0.2.2:5000/api/users/$userId'),
        headers: {
          'Authorization': 'Bearer ${await firebase_auth.FirebaseAuth.instance.currentUser?.getIdToken()}',
        },
      );
      if (response.statusCode == 200) {
        setState(() {
          _users.removeWhere((user) => user.id == userId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('Xóa người dùng thành công'),
              ],
            ),
            backgroundColor: Colors.green[400],
          ),
        );
      } else {
        throw Exception('Failed to delete user');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Text('Lỗi khi xóa người dùng: $e'),
            ],
          ),
          backgroundColor: Colors.red[400],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Quản lý người dùng',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xFF3F51B5),
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF3F51B5), Color(0xFF7C4DFF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF3F51B5), Color(0xFF7C4DFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF5722)))
            : _users.isEmpty
            ? Center(
          child: Text(
            'Không có người dùng nào',
            style: GoogleFonts.poppins(
              fontSize: 20,
              color: Colors.white.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
        )
            : ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: _users.length,
          itemBuilder: (context, index) {
            final user = _users[index];
            return Card(
              elevation: 5,
              margin: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.white, Color(0xFFF5F5F5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF7C4DFF),
                    child: Text(
                      user.username[0].toUpperCase(),
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  title: Text(
                    user.username,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  subtitle: Text(
                    'Email: ${user.email}\nVai trò: ${user.role}',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Color(0xFFFF5722)),
                    onPressed: () => _deleteUser(user.id),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}