import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import '../models/equipment.dart';
import '../models/maintenance_request.dart';

class EquipmentManagement extends StatefulWidget {
  const EquipmentManagement({super.key});

  @override
  State<EquipmentManagement> createState() => _EquipmentManagementState();
}

class _EquipmentManagementState extends State<EquipmentManagement> {
  final FirebaseService _firebaseService = FirebaseService();
  List<Equipment> _equipment = [];
  List<MaintenanceRequest> _allRequests = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _groupBy = 'none'; // 'none', 'department', 'employee'

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final equipment = await _firebaseService.getAllEquipment();
      final requests = await _firebaseService.getAllMaintenanceRequests();
      
      setState(() {
        _equipment = equipment;
        _allRequests = requests;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: ${e.toString()}')),
      );
    }
  }

  int _getOpenRequestCount(String equipmentId) {
    return _allRequests.where((r) => 
      r.equipmentId == equipmentId && 
      (r.stage == RequestStage.new_ || r.stage == RequestStage.inProgress)
    ).length;
  }

  List<Equipment> _getFilteredEquipment() {
    var filtered = _equipment.where((e) {
      final matchesSearch = e.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                          e.serialNumber.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                          e.category.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesSearch && !e.isScrapped;
    }).toList();

    if (_groupBy == 'department') {
      filtered.sort((a, b) => a.department.compareTo(b.department));
    } else if (_groupBy == 'employee') {
      filtered.sort((a, b) => a.assignedEmployee.compareTo(b.assignedEmployee));
    }

    return filtered;
  }

  Map<String, List<Equipment>> _getGroupedEquipment() {
    final grouped = <String, List<Equipment>>{};
    final filtered = _getFilteredEquipment();

    if (_groupBy == 'department') {
      for (var e in filtered) {
        if (!grouped.containsKey(e.department)) {
          grouped[e.department] = [];
        }
        grouped[e.department]!.add(e);
      }
    } else if (_groupBy == 'employee') {
      for (var e in filtered) {
        if (!grouped.containsKey(e.assignedEmployee)) {
          grouped[e.assignedEmployee] = [];
        }
        grouped[e.assignedEmployee]!.add(e);
      }
    }

    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          labelText: 'Search Equipment',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    DropdownButton<String>(
                      value: _groupBy,
                      items: const [
                        DropdownMenuItem(value: 'none', child: Text('No Grouping')),
                        DropdownMenuItem(value: 'department', child: Text('Group by Department')),
                        DropdownMenuItem(value: 'employee', child: Text('Group by Employee')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _groupBy = value!;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _groupBy == 'none' ? _buildEquipmentList() : _buildGroupedEquipmentList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEquipmentList() {
    final filtered = _getFilteredEquipment();
    
    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.precision_manufacturing, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No equipment found',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final equipment = filtered[index];
        final openRequests = _getOpenRequestCount(equipment.id!);
        
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue[100],
              child: Icon(Icons.precision_manufacturing, color: Colors.blue[700]),
            ),
            title: Text(equipment.name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Serial: ${equipment.serialNumber}'),
                Text('Category: ${equipment.category}'),
                Text('Department: ${equipment.department}'),
                Text('Location: ${equipment.location}'),
                Text('Assigned to: ${equipment.assignedEmployee}'),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (openRequests > 0)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '$openRequests',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'view_requests') {
                      _viewEquipmentRequests(equipment);
                    } else if (value == 'edit') {
                      _editEquipment(equipment);
                    } else if (value == 'scrap') {
                      _scrapEquipment(equipment);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'view_requests',
                      child: Row(
                        children: [
                          Icon(Icons.build),
                          SizedBox(width: 8),
                          Text('View Maintenance'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'scrap',
                      child: Row(
                        children: [
                          Icon(Icons.delete),
                          SizedBox(width: 8),
                          Text('Scrap'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            onTap: () => _viewEquipmentDetails(equipment),
          ),
        );
      },
    );
  }

  Widget _buildGroupedEquipmentList() {
    final grouped = _getGroupedEquipment();
    
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: grouped.keys.length,
      itemBuilder: (context, index) {
        final groupKey = grouped.keys.elementAt(index);
        final equipmentList = grouped[groupKey]!;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[700],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      groupKey,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${equipmentList.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ...equipmentList.map((equipment) {
                final openRequests = _getOpenRequestCount(equipment.id!);
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue[100],
                    child: Icon(Icons.precision_manufacturing, color: Colors.blue[700]),
                  ),
                  title: Text(equipment.name),
                  subtitle: Text('${equipment.category} • ${equipment.location}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (openRequests > 0)
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$openRequests',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.build),
                        onPressed: () => _viewEquipmentRequests(equipment),
                        tooltip: 'View Maintenance',
                      ),
                    ],
                  ),
                  onTap: () => _viewEquipmentDetails(equipment),
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  void _viewEquipmentDetails(Equipment equipment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(equipment.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Serial Number: ${equipment.serialNumber}'),
              Text('Category: ${equipment.category}'),
              Text('Department: ${equipment.department}'),
              Text('Location: ${equipment.location}'),
              Text('Assigned to: ${equipment.assignedEmployee}'),
              Text('Purchase Date: ${equipment.purchaseDate.toLocal()}'.split(' ')[0]),
              if (equipment.warrantyExpiry != null)
                Text('Warranty Expiry: ${equipment.warrantyExpiry!.toLocal()}'.split(' ')[0]),
              const SizedBox(height: 16),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _viewEquipmentRequests(equipment),
                    icon: const Icon(Icons.build),
                    label: const Text('View Maintenance'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _editEquipment(equipment),
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit'),
                  ),
                ],
              ),
            ],
          ),
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

  void _viewEquipmentRequests(Equipment equipment) {
    final requests = _allRequests.where((r) => r.equipmentId == equipment.id).toList();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Maintenance Requests - ${equipment.name}'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: requests.isEmpty
              ? const Center(child: Text('No maintenance requests found'))
              : ListView.builder(
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    final request = requests[index];
                    return Card(
                      child: ListTile(
                        title: Text(request.subject),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Type: ${request.typeDisplayName}'),
                            Text('Stage: ${request.stageDisplayName}'),
                            if (request.scheduledDate != null)
                              Text('Scheduled: ${request.scheduledDate!.toLocal()}'.split(' ')[0]),
                          ],
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: _getStageColor(request.stage),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            request.stageDisplayName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
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

  Color _getStageColor(RequestStage stage) {
    switch (stage) {
      case RequestStage.new_:
        return Colors.blue;
      case RequestStage.inProgress:
        return Colors.orange;
      case RequestStage.repaired:
        return Colors.green;
      case RequestStage.scrap:
        return Colors.red;
    }
  }

  void _editEquipment(Equipment equipment) {
    // Navigate to edit form
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit equipment functionality')),
    );
  }

  void _scrapEquipment(Equipment equipment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Scrap Equipment'),
        content: Text('Are you sure you want to scrap ${equipment.name}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                final updatedEquipment = equipment.copyWith(
                  isScrapped: true,
                  updatedAt: DateTime.now(),
                );
                await _firebaseService.updateEquipment(updatedEquipment);
                Navigator.pop(context);
                _loadData();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Equipment scrapped successfully')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error scrapping equipment: ${e.toString()}')),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Scrap'),
          ),
        ],
      ),
    );
  }
}

class EquipmentForm extends StatefulWidget {
  const EquipmentForm({super.key});

  @override
  State<EquipmentForm> createState() => _EquipmentFormState();
}

class _EquipmentFormState extends State<EquipmentForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _serialNumberController = TextEditingController();
  final _categoryController = TextEditingController();
  final _departmentController = TextEditingController();
  final _employeeController = TextEditingController();
  final _locationController = TextEditingController();
  final _firebaseService = FirebaseService();
  bool _isLoading = false;

  DateTime _purchaseDate = DateTime.now();
  DateTime? _warrantyExpiry;

  @override
  void dispose() {
    _nameController.dispose();
    _serialNumberController.dispose();
    _categoryController.dispose();
    _departmentController.dispose();
    _employeeController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final equipment = Equipment(
        name: _nameController.text,
        serialNumber: _serialNumberController.text,
        category: _categoryController.text,
        department: _departmentController.text,
        assignedEmployee: _employeeController.text,
        maintenanceTeamId: '', // Will be set when teams are created
        defaultTechnicianId: '', // Will be set when technicians are assigned
        purchaseDate: _purchaseDate,
        warrantyExpiry: _warrantyExpiry,
        location: _locationController.text,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firebaseService.createEquipment(equipment);
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Equipment'),
        backgroundColor: Colors.blue[700],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Equipment Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value?.isEmpty == true ? 'Please enter equipment name' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _serialNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Serial Number',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value?.isEmpty == true ? 'Please enter serial number' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _categoryController,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value?.isEmpty == true ? 'Please enter category' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _departmentController,
                  decoration: const InputDecoration(
                    labelText: 'Department',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value?.isEmpty == true ? 'Please enter department' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _employeeController,
                  decoration: const InputDecoration(
                    labelText: 'Assigned Employee',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value?.isEmpty == true ? 'Please enter assigned employee' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _locationController,
                  decoration: const InputDecoration(
                    labelText: 'Location',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value?.isEmpty == true ? 'Please enter location' : null,
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: Text('Purchase Date: ${_purchaseDate.toLocal()}'.split(' ')[0]),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _purchaseDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() {
                        _purchaseDate = date;
                      });
                    }
                  },
                ),
                ListTile(
                  title: Text(
                    _warrantyExpiry == null
                        ? 'Set Warranty Expiry (Optional)'
                        : 'Warranty Expiry: ${_warrantyExpiry!.toLocal()}'.split(' ')[0],
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _warrantyExpiry ?? DateTime.now().add(const Duration(days: 365)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 3650)),
                    );
                    if (date != null) {
                      setState(() {
                        _warrantyExpiry = date;
                      });
                    }
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Add Equipment'),
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
