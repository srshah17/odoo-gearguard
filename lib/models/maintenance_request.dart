import 'package:cloud_firestore/cloud_firestore.dart';

enum RequestType {
  corrective,
  preventive,
}

enum RequestStage {
  new_,
  inProgress,
  repaired,
  scrap,
}

class MaintenanceRequest {
  final String? id;
  final String subject;
  final String description;
  final String equipmentId;
  final String equipmentName;
  final String equipmentCategory;
  final String maintenanceTeamId;
  final String maintenanceTeamName;
  final RequestType type;
  final RequestStage stage;
  final String? assignedTechnicianId;
  final String? assignedTechnicianName;
  final DateTime? scheduledDate;
  final DateTime? completedDate;
  final Duration? duration;
  final String? createdBy;
  final String? createdByName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isOverdue;

  MaintenanceRequest({
    this.id,
    required this.subject,
    required this.description,
    required this.equipmentId,
    required this.equipmentName,
    required this.equipmentCategory,
    required this.maintenanceTeamId,
    required this.maintenanceTeamName,
    required this.type,
    required this.stage,
    this.assignedTechnicianId,
    this.assignedTechnicianName,
    this.scheduledDate,
    this.completedDate,
    this.duration,
    this.createdBy,
    this.createdByName,
    required this.createdAt,
    required this.updatedAt,
    this.isOverdue = false,
  });

  factory MaintenanceRequest.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return MaintenanceRequest(
      id: doc.id,
      subject: data['subject'] ?? '',
      description: data['description'] ?? '',
      equipmentId: data['equipmentId'] ?? '',
      equipmentName: data['equipmentName'] ?? '',
      equipmentCategory: data['equipmentCategory'] ?? '',
      maintenanceTeamId: data['maintenanceTeamId'] ?? '',
      maintenanceTeamName: data['maintenanceTeamName'] ?? '',
      type: RequestType.values.firstWhere(
        (e) => e.toString() == data['type'],
        orElse: () => RequestType.corrective,
      ),
      stage: RequestStage.values.firstWhere(
        (e) => e.toString() == data['stage'],
        orElse: () => RequestStage.new_,
      ),
      assignedTechnicianId: data['assignedTechnicianId'],
      assignedTechnicianName: data['assignedTechnicianName'],
      scheduledDate: data['scheduledDate'] != null 
          ? (data['scheduledDate'] as Timestamp).toDate() 
          : null,
      completedDate: data['completedDate'] != null 
          ? (data['completedDate'] as Timestamp).toDate() 
          : null,
      duration: data['duration'] != null 
          ? Duration(hours: data['duration']['hours'], minutes: data['duration']['minutes'])
          : null,
      createdBy: data['createdBy'],
      createdByName: data['createdByName'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      isOverdue: data['isOverdue'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'subject': subject,
      'description': description,
      'equipmentId': equipmentId,
      'equipmentName': equipmentName,
      'equipmentCategory': equipmentCategory,
      'maintenanceTeamId': maintenanceTeamId,
      'maintenanceTeamName': maintenanceTeamName,
      'type': type.toString(),
      'stage': stage.toString(),
      'assignedTechnicianId': assignedTechnicianId,
      'assignedTechnicianName': assignedTechnicianName,
      'scheduledDate': scheduledDate != null 
          ? Timestamp.fromDate(scheduledDate!) 
          : null,
      'completedDate': completedDate != null 
          ? Timestamp.fromDate(completedDate!) 
          : null,
      'duration': duration != null 
          ? {'hours': duration!.inHours, 'minutes': duration!.inMinutes % 60}
          : null,
      'createdBy': createdBy,
      'createdByName': createdByName,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isOverdue': isOverdue,
    };
  }

  MaintenanceRequest copyWith({
    String? id,
    String? subject,
    String? description,
    String? equipmentId,
    String? equipmentName,
    String? equipmentCategory,
    String? maintenanceTeamId,
    String? maintenanceTeamName,
    RequestType? type,
    RequestStage? stage,
    String? assignedTechnicianId,
    String? assignedTechnicianName,
    DateTime? scheduledDate,
    DateTime? completedDate,
    Duration? duration,
    String? createdBy,
    String? createdByName,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isOverdue,
  }) {
    return MaintenanceRequest(
      id: id ?? this.id,
      subject: subject ?? this.subject,
      description: description ?? this.description,
      equipmentId: equipmentId ?? this.equipmentId,
      equipmentName: equipmentName ?? this.equipmentName,
      equipmentCategory: equipmentCategory ?? this.equipmentCategory,
      maintenanceTeamId: maintenanceTeamId ?? this.maintenanceTeamId,
      maintenanceTeamName: maintenanceTeamName ?? this.maintenanceTeamName,
      type: type ?? this.type,
      stage: stage ?? this.stage,
      assignedTechnicianId: assignedTechnicianId ?? this.assignedTechnicianId,
      assignedTechnicianName: assignedTechnicianName ?? this.assignedTechnicianName,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      completedDate: completedDate ?? this.completedDate,
      duration: duration ?? this.duration,
      createdBy: createdBy ?? this.createdBy,
      createdByName: createdByName ?? this.createdByName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isOverdue: isOverdue ?? this.isOverdue,
    );
  }

  String get stageDisplayName {
    switch (stage) {
      case RequestStage.new_:
        return 'New';
      case RequestStage.inProgress:
        return 'In Progress';
      case RequestStage.repaired:
        return 'Repaired';
      case RequestStage.scrap:
        return 'Scrap';
    }
  }

  String get typeDisplayName {
    switch (type) {
      case RequestType.corrective:
        return 'Corrective';
      case RequestType.preventive:
        return 'Preventive';
    }
  }
}
