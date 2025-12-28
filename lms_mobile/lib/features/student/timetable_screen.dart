import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'student_provider.dart';

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<dynamic>> _events = {};

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('vi_VN', null);
    _selectedDay = _focusedDay;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchTimetable();
    });
  }

  Future<void> _fetchTimetable() async {
    final studentProvider = Provider.of<StudentProvider>(context, listen: false);
    await studentProvider.fetchTimetable();
    
    final events = <DateTime, List<dynamic>>{};
    for (var item in studentProvider.timetable) {
      if (item['date'] != null) {
        final dateStr = item['date'] as String;
        final date = DateTime.parse(dateStr);
        final normalizedDate = DateTime.utc(date.year, date.month, date.day);
        
        if (events[normalizedDate] == null) {
          events[normalizedDate] = [];
        }
        events[normalizedDate]!.add(item);
      }
    }
    
    setState(() {
      _events = events;
    });
  }

  List<dynamic> _getEventsForDay(DateTime day) {
    final normalizedDay = DateTime.utc(day.year, day.month, day.day);
    return _events[normalizedDay] ?? [];
  }
  
  Future<void> _selectMonth() async {
     final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: _focusedDay,
        firstDate: DateTime(2020),
        lastDate: DateTime(2030),
        initialDatePickerMode: DatePickerMode.year,
        helpText: "CHỌN THÁNG/NĂM",
     );
     if (picked != null) {
        setState(() {
           _focusedDay = picked;
           _selectedDay = picked;
        });
        
        final events = _getEventsForDay(picked);
        if (events.isNotEmpty) {
             _showDayDetailsModal(context, picked, events);
        }
     }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Thời khóa biểu"),
        elevation: 0,
        actions: [
           IconButton(
              icon: const Icon(Icons.calendar_month),
              tooltip: "Chọn tháng",
              onPressed: _selectMonth,
           )
        ],
      ),
      body: Column(
        children: [
          TableCalendar(
            locale: 'vi_VN',
            firstDay: DateTime.utc(2020, 10, 16),
            lastDay: DateTime.utc(2030, 3, 14),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            headerStyle: const HeaderStyle(
                formatButtonVisible: false, 
                titleCentered: true,
                titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
            ),
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },
            onDaySelected: (selectedDay, focusedDay) {
              if (!isSameDay(_selectedDay, selectedDay)) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
                
                final events = _getEventsForDay(selectedDay);
                if (events.isNotEmpty) {
                    _showDayDetailsModal(context, selectedDay, events);
                }
              } else {
                 final events = _getEventsForDay(selectedDay);
                 if (events.isNotEmpty) {
                    _showDayDetailsModal(context, selectedDay, events);
                 }
              }
            },
            onFormatChanged: (format) {
              if (_calendarFormat != format) {
                setState(() {
                  _calendarFormat = format;
                });
              }
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
            eventLoader: _getEventsForDay,
            calendarStyle: CalendarStyle(
              markerDecoration: const BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              selectedDecoration: const BoxDecoration(
                color: Colors.orange,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
              child: Center(
                  child: Text(
                      "Chọn ngày để xem chi tiết lớp học",
                      style: TextStyle(color: Colors.grey[600]),
                  )
              )
          ),
        ],
      ),
    );
  }

  void _showDayDetailsModal(BuildContext context, DateTime date, List<dynamic> events) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          height: 400,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                  child: Container(
                      width: 40, height: 4, 
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))
                  )
              ),
              Text(
                "Lịch học ngày ${DateFormat('dd/MM/yyyy').format(date)}",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    final event = events[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                             Text(
                                event['course_name'] ?? 'Môn học',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue),
                             ),
                             const SizedBox(height: 8),
                             Row(
                               children: [
                                 const Icon(Icons.access_time, size: 16, color: Colors.grey),
                                 const SizedBox(width: 4),
                                 Text("Tiết ${event['start_period']} - ${event['end_period']}"),
                                 const SizedBox(width: 16),
                                 const Icon(Icons.room, size: 16, color: Colors.grey),
                                 const SizedBox(width: 4),
                                 Text("Phòng: ${event['room'] ?? 'N/A'}"),
                               ],
                             ),
                             const SizedBox(height: 4),
                             Row(
                               children: [
                                 const Icon(Icons.person, size: 16, color: Colors.grey),
                                 const SizedBox(width: 4),
                                 Text("GV: ${event['lecturer_name'] ?? 'Unknown'}"),
                               ],
                             )
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
