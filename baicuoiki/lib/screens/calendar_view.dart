import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:baicuoiki/models/task.dart';
import 'package:baicuoiki/screens/task_detail_screen.dart';
import 'package:google_fonts/google_fonts.dart';

class CalendarView extends StatefulWidget {
  final List<Task> tasks;
  const CalendarView({super.key, required this.tasks});

  @override
  _CalendarViewState createState() => _CalendarViewState();
}

class _CalendarViewState extends State<CalendarView> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  Map<DateTime, List<Task>> _getEvents() {
    final events = <DateTime, List<Task>>{};
    for (var task in widget.tasks) {
      if (task.dueDate != null) {
        final date = DateTime(task.dueDate!.year, task.dueDate!.month, task.dueDate!.day);
        events[date] = events[date] ?? [];
        events[date]!.add(task);
      }
      // Add reminder events
      if (task.reminderTime != null) {
        final reminderDate = DateTime(task.reminderTime!.year, task.reminderTime!.month, task.reminderTime!.day);
        events[reminderDate] = events[reminderDate] ?? [];
        events[reminderDate]!.add(task);
      }
    }
    return events;
  }

  @override
  Widget build(BuildContext context) {
    final events = _getEvents();
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            eventLoader: (day) {
              return events[DateTime(day.year, day.month, day.day)] ?? [];
            },
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: const Color(0xFFFC5C7D),
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: const Color(0xFF6A82FB),
                shape: BoxShape.circle,
              ),
              markerDecoration: BoxDecoration(
                color: Colors.redAccent,
                shape: BoxShape.circle,
              ),
            ),
            headerStyle: HeaderStyle(
              titleTextStyle: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              formatButtonVisible: false,
            ),
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, tasks) {
                if (tasks.isNotEmpty) {
                  return Positioned(
                    right: 1,
                    bottom: 1,
                    child: _buildEventsMarker(tasks),
                  );
                }
                return null;
              },
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: events[_selectedDay ?? _focusedDay]?.map((task) {
                final isReminder = task.reminderTime != null &&
                    isSameDay(task.reminderTime!, _selectedDay ?? _focusedDay);
                return ListTile(
                  leading: isReminder
                      ? Icon(Icons.alarm, color: Colors.redAccent)
                      : Icon(Icons.task, color: Colors.blue),
                  title: Text(
                    task.title,
                    style: GoogleFonts.roboto(
                      fontWeight: isReminder ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text(
                    isReminder
                        ? 'Reminder: ${task.description}'
                        : task.description,
                    style: GoogleFonts.roboto(color: Colors.grey[600]),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TaskDetailScreen(task: task),
                      ),
                    );
                  },
                );
              })?.toList() ??
                  [
                    ListTile(
                      title: Text(
                        'Không có công việc hoặc nhắc nhở cho ngày này',
                        style: GoogleFonts.roboto(color: Colors.grey[600]),
                      ),
                    ),
                  ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsMarker(List<dynamic> tasks) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: tasks.any((task) => task.reminderTime != null) ? Colors.redAccent : Colors.blue,
      ),
      width: 16.0,
      height: 16.0,
      child: Center(
        child: Text(
          '${tasks.length}',
          style: const TextStyle().copyWith(
            color: Colors.white,
            fontSize: 12.0,
          ),
        ),
      ),
    );
  }
}