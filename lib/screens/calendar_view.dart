import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../services/firebase_service.dart';
import '../models/maintenance_request.dart';

class CalendarView extends StatefulWidget {
  const CalendarView({super.key});

  @override
  State<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<CalendarView> {
  final FirebaseService _firebaseService = FirebaseService();
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<MaintenanceRequest>> _events = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);
    
    try {
      final startOfMonth = DateTime(_focusedDay.year, _focusedDay.month, 1);
      final endOfMonth = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);
      
      final requests = await _firebaseService.getPreventiveMaintenanceRequestsByDateRange(
        startOfMonth,
        endOfMonth,
      );

      Map<DateTime, List<MaintenanceRequest>> events = {};
      
      for (var request in requests) {
        if (request.scheduledDate != null) {
          final date = DateTime(
            request.scheduledDate!.year,
            request.scheduledDate!.month,
            request.scheduledDate!.day,
          );
          
          if (events[date] == null) {
            events[date] = [];
          }
          events[date]!.add(request);
        }
      }

      setState(() {
        _events = events;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading events: ${e.toString()}')),
      );
    }
  }

  List<MaintenanceRequest> _getEventsForDay(DateTime day) {
    final date = DateTime(day.year, day.month, day.day);
    return _events[date] ?? [];
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });
    }
  }

  void _onPageChanged(DateTime focusedDay) {
    _focusedDay = focusedDay;
    _loadEvents();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Maintenance Calendar'),
        backgroundColor: Colors.blue[700],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                TableCalendar<MaintenanceRequest>(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
                  eventLoader: _getEventsForDay,
                  onDaySelected: _onDaySelected,
                  onPageChanged: _onPageChanged,
                  calendarStyle: const CalendarStyle(
                    markersMaxCount: 3,
                    markerDecoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                  ),
                  headerStyle: HeaderStyle(
                    formatButtonVisible: true,
                    titleCentered: true,
                    formatButtonDecoration: BoxDecoration(
                      color: Colors.blue[700],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    formatButtonTextStyle: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: _buildEventList(),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_selectedDay != null) {
            _showScheduleDialog(_selectedDay!);
          }
        },
        backgroundColor: Colors.blue[700],
        child: const Icon(Icons.add),
        tooltip: 'Schedule Maintenance',
      ),
    );
  }

  Widget _buildEventList() {
    final events = _getEventsForDay(_selectedDay!);
    
    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No maintenance scheduled for this day',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the + button to schedule maintenance',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final request = events[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue[100],
              child: Icon(Icons.build, color: Colors.blue[700]),
            ),
            title: Text(request.subject),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Equipment: ${request.equipmentName}'),
                Text('Team: ${request.maintenanceTeamName}'),
                if (request.assignedTechnicianName != null)
                  Text('Technician: ${request.assignedTechnicianName}'),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () => _showRequestDetails(request),
            ),
          ),
        );
      },
    );
  }

  void _showRequestDetails(MaintenanceRequest request) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(request.subject),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Equipment: ${request.equipmentName}'),
            Text('Category: ${request.equipmentCategory}'),
            const SizedBox(height: 8),
            Text('Team: ${request.maintenanceTeamName}'),
            if (request.assignedTechnicianName != null)
              Text('Technician: ${request.assignedTechnicianName}'),
            const SizedBox(height: 8),
            Text('Type: ${request.typeDisplayName}'),
            Text('Stage: ${request.stageDisplayName}'),
            const SizedBox(height: 8),
            Text('Description: ${request.description}'),
            if (request.scheduledDate != null)
              Text('Scheduled: ${request.scheduledDate!.toLocal()}'.split(' ')[0]),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showScheduleDialog(DateTime date) {
    // This would open a dialog to schedule new maintenance
    // For now, we'll just show a message
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Schedule Maintenance'),
        content: Text('Schedule maintenance for ${date.toLocal()}'.split(' ')[0]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to create request form with pre-filled date
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Navigate to request form with pre-filled date')),
              );
            },
            child: const Text('Create Request'),
          ),
        ],
      ),
    );
  }
}
