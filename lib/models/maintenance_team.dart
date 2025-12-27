import 'package:cloud_firestore/cloud_firestore.dart';

class MaintenanceTeam {
  final String? id;
  final String name;
  final String description;
  final List<String> memberIds;
  final DateTime createdAt;
  final DateTime updatedAt;

  MaintenanceTeam({
    this.id,
    required this.name,
    required this.description,
    required this.memberIds,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MaintenanceTeam.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return MaintenanceTeam(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      memberIds: List<String>.from(data['memberIds'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'memberIds': memberIds,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  MaintenanceTeam copyWith({
    String? id,
    String? name,
    String? description,
    List<String>? memberIds,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MaintenanceTeam(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      memberIds: memberIds ?? this.memberIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class TeamMember {
  final String? id;
  final String name;
  final String email;
  final String role;
  final String teamId;
  final bool isTechnician;
  final DateTime createdAt;
  final DateTime updatedAt;

  TeamMember({
    this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.teamId,
    this.isTechnician = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TeamMember.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return TeamMember(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? '',
      teamId: data['teamId'] ?? '',
      isTechnician: data['isTechnician'] ?? true,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'role': role,
      'teamId': teamId,
      'isTechnician': isTechnician,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  TeamMember copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
    String? teamId,
    bool? isTechnician,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TeamMember(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      teamId: teamId ?? this.teamId,
      isTechnician: isTechnician ?? this.isTechnician,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
