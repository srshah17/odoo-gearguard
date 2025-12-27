import 'package:cloud_firestore/cloud_firestore.dart';

class Equipment {
  final String? id;
  final String name;
  final String serialNumber;
  final String category;
  final String department;
  final String assignedEmployee;
  final String maintenanceTeamId;
  final String defaultTechnicianId;
  final DateTime purchaseDate;
  final DateTime? warrantyExpiry;
  final String location;
  final bool isScrapped;
  final DateTime createdAt;
  final DateTime updatedAt;

  Equipment({
    this.id,
    required this.name,
    required this.serialNumber,
    required this.category,
    required this.department,
    required this.assignedEmployee,
    required this.maintenanceTeamId,
    required this.defaultTechnicianId,
    required this.purchaseDate,
    this.warrantyExpiry,
    required this.location,
    this.isScrapped = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Equipment.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Equipment(
      id: doc.id,
      name: data['name'] ?? '',
      serialNumber: data['serialNumber'] ?? '',
      category: data['category'] ?? '',
      department: data['department'] ?? '',
      assignedEmployee: data['assignedEmployee'] ?? '',
      maintenanceTeamId: data['maintenanceTeamId'] ?? '',
      defaultTechnicianId: data['defaultTechnicianId'] ?? '',
      purchaseDate: (data['purchaseDate'] as Timestamp).toDate(),
      warrantyExpiry: data['warrantyExpiry'] != null 
          ? (data['warrantyExpiry'] as Timestamp).toDate() 
          : null,
      location: data['location'] ?? '',
      isScrapped: data['isScrapped'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'serialNumber': serialNumber,
      'category': category,
      'department': department,
      'assignedEmployee': assignedEmployee,
      'maintenanceTeamId': maintenanceTeamId,
      'defaultTechnicianId': defaultTechnicianId,
      'purchaseDate': Timestamp.fromDate(purchaseDate),
      'warrantyExpiry': warrantyExpiry != null 
          ? Timestamp.fromDate(warrantyExpiry!) 
          : null,
      'location': location,
      'isScrapped': isScrapped,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  Equipment copyWith({
    String? id,
    String? name,
    String? serialNumber,
    String? category,
    String? department,
    String? assignedEmployee,
    String? maintenanceTeamId,
    String? defaultTechnicianId,
    DateTime? purchaseDate,
    DateTime? warrantyExpiry,
    String? location,
    bool? isScrapped,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Equipment(
      id: id ?? this.id,
      name: name ?? this.name,
      serialNumber: serialNumber ?? this.serialNumber,
      category: category ?? this.category,
      department: department ?? this.department,
      assignedEmployee: assignedEmployee ?? this.assignedEmployee,
      maintenanceTeamId: maintenanceTeamId ?? this.maintenanceTeamId,
      defaultTechnicianId: defaultTechnicianId ?? this.defaultTechnicianId,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      warrantyExpiry: warrantyExpiry ?? this.warrantyExpiry,
      location: location ?? this.location,
      isScrapped: isScrapped ?? this.isScrapped,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
