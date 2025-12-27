import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import '../models/maintenance_request.dart';

class KanbanBoard extends StatefulWidget {
  const KanbanBoard({super.key});

  @override
  State<KanbanBoard> createState() => _KanbanBoardState();
}

class _KanbanBoardState extends State<KanbanBoard> {
  final FirebaseService _firebaseService = FirebaseService();
  List<MaintenanceRequest> _allRequests = [];
  Map<RequestStage, List<MaintenanceRequest>> _requestsByStage = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() => _isLoading = true);
    
    try {
      final requests = await _firebaseService.getAllMaintenanceRequests();
      setState(() {
        _allRequests = requests;
        _organizeRequestsByStage();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading requests: ${e.toString()}')),
      );
    }
  }

  void _organizeRequestsByStage() {
    _requestsByStage = {
      RequestStage.new_: _allRequests.where((r) => r.stage == RequestStage.new_).toList(),
      RequestStage.inProgress: _allRequests.where((r) => r.stage == RequestStage.inProgress).toList(),
      RequestStage.repaired: _allRequests.where((r) => r.stage == RequestStage.repaired).toList(),
      RequestStage.scrap: _allRequests.where((r) => r.stage == RequestStage.scrap).toList(),
    };
  }

  Future<void> _updateRequestStage(MaintenanceRequest request, RequestStage newStage) async {
    try {
      final updatedRequest = request.copyWith(
        stage: newStage,
        updatedAt: DateTime.now(),
        completedDate: newStage == RequestStage.repaired || newStage == RequestStage.scrap
            ? DateTime.now()
            : null,
      );

      await _firebaseService.updateMaintenanceRequest(updatedRequest);
      await _loadRequests();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating request: ${e.toString()}')),
      );
    }
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

  Widget _buildRequestCard(MaintenanceRequest request) {
    final isOverdue = request.scheduledDate != null &&
        request.scheduledDate!.isBefore(DateTime.now()) &&
        request.stage != RequestStage.repaired &&
        request.stage != RequestStage.scrap;

    return Card(
      margin: const EdgeInsets.all(4),
      elevation: 2,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: isOverdue ? Border.all(color: Colors.red, width: 2) : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      request.subject,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isOverdue)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'OVERDUE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                request.equipmentName,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                request.typeDisplayName,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (request.assignedTechnicianName != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: Colors.blue[100],
                      child: Text(
                        request.assignedTechnicianName![0].toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.blue[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        request.assignedTechnicianName!,
                        style: const TextStyle(fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              if (request.scheduledDate != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.schedule, size: 12, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(
                      '${request.scheduledDate!.day}/${request.scheduledDate!.month}/${request.scheduledDate!.year}',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStageColumn(RequestStage stage) {
    final requests = _requestsByStage[stage] ?? [];
    
    return Container(
      margin: const EdgeInsets.all(8),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _getStageColor(stage),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Text(
                  stage == RequestStage.new_ ? 'New' :
                  stage == RequestStage.inProgress ? 'In Progress' :
                  stage == RequestStage.repaired ? 'Repaired' : 'Scrap',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
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
                    '${requests.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 400,
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(8),
                bottomRight: Radius.circular(8),
              ),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: requests.isEmpty
                ? Center(
                    child: Text(
                      'No requests',
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: requests.length,
                    itemBuilder: (context, index) {
                      final request = requests[index];
                      return Dismissible(
                        key: Key(request.id!),
                        direction: DismissDirection.horizontal,
                        onDismissed: (direction) {
                          RequestStage newStage;
                          if (direction == DismissDirection.startToEnd) {
                            // Move to next stage
                            switch (stage) {
                              case RequestStage.new_:
                                newStage = RequestStage.inProgress;
                                break;
                              case RequestStage.inProgress:
                                newStage = RequestStage.repaired;
                                break;
                              case RequestStage.repaired:
                              case RequestStage.scrap:
                                return;
                            }
                          } else {
                            // Move to previous stage
                            switch (stage) {
                              case RequestStage.inProgress:
                                newStage = RequestStage.new_;
                                break;
                              case RequestStage.repaired:
                                newStage = RequestStage.inProgress;
                                break;
                              case RequestStage.new_:
                              case RequestStage.scrap:
                                return;
                            }
                          }
                          _updateRequestStage(request, newStage);
                        },
                        background: Container(
                          color: Colors.green,
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.only(left: 20),
                          child: const Icon(Icons.arrow_forward, color: Colors.white),
                        ),
                        secondaryBackground: Container(
                          color: Colors.orange,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(Icons.arrow_back, color: Colors.white),
                        ),
                        child: _buildRequestCard(request),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: RequestStage.values.map((stage) {
            return SizedBox(
              width: 300,
              child: _buildStageColumn(stage),
            );
          }).toList(),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadRequests,
        backgroundColor: Colors.blue[700],
        child: const Icon(Icons.refresh),
        tooltip: 'Refresh',
      ),
    );
  }
}
