import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_service.dart';
import '../models/maintenance_request.dart';
import 'kanban_board.dart';
import 'calendar_view.dart';
import 'equipment_management.dart';
import 'team_management.dart';
import 'reports_screen.dart';

class MainDashboard extends StatefulWidget {
  const MainDashboard({super.key});

  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> {
  final FirebaseService _firebaseService = FirebaseService();
  int _selectedIndex = 0;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
  }

  Future<void> _getCurrentUser() async {
    User? user = await _firebaseService.getCurrentUser();
    setState(() {
      _currentUser = user;
    });
  }

  Future<void> _signOut() async {
    await _firebaseService.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _pages = [
      const KanbanBoard(),
      const CalendarView(),
      const EquipmentManagement(),
      const TeamManagement(),
      const ReportsScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.build, color: Colors.white),
            const SizedBox(width: 8),
            const Text('GearGuard'),
            const Spacer(),
            if (_currentUser != null)
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Row(
                  children: [
                    Icon(Icons.person, color: Colors.white70, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      _currentUser!.email ?? 'User',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
          ],
        ),
        backgroundColor: Colors.blue[700],
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _signOut,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.view_kanban),
            label: 'Kanban',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Calendar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.precision_manufacturing),
            label: 'Equipment',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group),
            label: 'Teams',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Reports',
          ),
        ],
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MaintenanceRequestForm(),
                  ),
                );
              },
              backgroundColor: Colors.blue[700],
              child: const Icon(Icons.add),
            )
          : _selectedIndex == 2
              ? FloatingActionButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EquipmentForm(),
                      ),
                    );
                  },
                  backgroundColor: Colors.blue[700],
                  child: const Icon(Icons.add),
                )
              : _selectedIndex == 3
                  ? FloatingActionButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const TeamForm(),
                          ),
                        );
                      },
                      backgroundColor: Colors.blue[700],
                      child: const Icon(Icons.add),
                    )
                  : null,
    );
  }
}

class MaintenanceRequestForm extends StatefulWidget {
  const MaintenanceRequestForm({super.key});

  @override
  State<MaintenanceRequestForm> createState() => _MaintenanceRequestFormState();
}

class _MaintenanceRequestFormState extends State<MaintenanceRequestForm> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _firebaseService = FirebaseService();
  bool _isLoadingForm = false;
  bool _isLoadingData = true;

  String? _selectedEquipmentId;
  String? _selectedTeamId;
  RequestType _requestType = RequestType.corrective;
  DateTime? _scheduledDate;

  List<Map<String, String>> _equipmentList = [];
  List<Map<String, String>> _teamList = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final equipment = await _firebaseService.getAllEquipment();
      final teams = await _firebaseService.getAllMaintenanceTeams();

      setState(() {
        _equipmentList = equipment.map((e) => {
          'id': e.id!,
          'name': e.name,
          'category': e.category,
          'teamId': e.maintenanceTeamId,
        }).toList();

        _teamList = teams.map((t) => {
          'id': t.id!,
          'name': t.name,
        }).toList();

        // Set default values if lists are not empty
        if (_equipmentList.isNotEmpty && _selectedEquipmentId == null) {
          _selectedEquipmentId = _equipmentList[0]['id'];
          final equipTeamId = _equipmentList[0]['teamId'];
          // Only set team ID if it exists in team list
          if (_teamList.any((t) => t['id'] == equipTeamId)) {
            _selectedTeamId = equipTeamId;
          }
        }
        if (_teamList.isNotEmpty && _selectedTeamId == null) {
          _selectedTeamId = _teamList[0]['id'];
        }

        _isLoadingData = false;
      });
    } catch (e) {
      setState(() => _isLoadingData = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedEquipmentId == null || _selectedTeamId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select equipment and team')),
      );
      return;
    }

    setState(() => _isLoadingForm = true);

    try {
      final equipment = _equipmentList.firstWhere((e) => e['id'] == _selectedEquipmentId);
      final team = _teamList.firstWhere((t) => t['id'] == _selectedTeamId);

      final request = MaintenanceRequest(
        subject: _subjectController.text,
        description: _descriptionController.text,
        equipmentId: equipment['id']!,
        equipmentName: equipment['name']!,
        equipmentCategory: equipment['category']!,
        maintenanceTeamId: team['id']!,
        maintenanceTeamName: team['name']!,
        type: _requestType,
        stage: RequestStage.new_,
        scheduledDate: _scheduledDate,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firebaseService.createMaintenanceRequest(request);
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoadingForm = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingData) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Create Maintenance Request'),
          backgroundColor: Colors.blue[700],
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Maintenance Request'),
        backgroundColor: Colors.blue[700],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Equipment',
                    border: OutlineInputBorder(),
                  ),
                  value: _selectedEquipmentId,
                  items: _equipmentList.map((equipment) {
                    return DropdownMenuItem(
                      value: equipment['id'],
                      child: Text('${equipment['name']} (${equipment['category']})'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedEquipmentId = value;
                      if (value != null) {
                        final equipment = _equipmentList.firstWhere((e) => e['id'] == value);
                        final equipTeamId = equipment['teamId'];
                        // Only set team ID if it exists in the team list
                        if (_teamList.any((t) => t['id'] == equipTeamId)) {
                          _selectedTeamId = equipTeamId;
                        } else if (_teamList.isNotEmpty) {
                          _selectedTeamId = _teamList[0]['id'];
                        }
                      }
                    });
                  },
                  validator: (value) => value == null ? 'Please select equipment' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Maintenance Team',
                    border: OutlineInputBorder(),
                  ),
                  value: _selectedTeamId,
                  items: _teamList.map((team) {
                    return DropdownMenuItem(
                      value: team['id'],
                      child: Text(team['name']!),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedTeamId = value;
                    });
                  },
                  validator: (value) => value == null ? 'Please select a team' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<RequestType>(
                  decoration: const InputDecoration(
                    labelText: 'Request Type',
                    border: OutlineInputBorder(),
                  ),
                  value: _requestType,
                  items: RequestType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type == RequestType.corrective ? 'Corrective' : 'Preventive'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _requestType = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                if (_requestType == RequestType.preventive)
                  ListTile(
                    title: Text(
                      _scheduledDate == null
                          ? 'Select Scheduled Date'
                          : 'Scheduled: ${_scheduledDate!.toLocal()}'.split(' ')[0],
                    ),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now().add(const Duration(days: 1)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        setState(() {
                          _scheduledDate = date;
                        });
                      }
                    },
                  ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _subjectController,
                  decoration: const InputDecoration(
                    labelText: 'Subject',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value?.isEmpty == true ? 'Please enter a subject' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  validator: (value) => value?.isEmpty == true ? 'Please enter a description' : null,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoadingForm ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoadingForm
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Create Request'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
