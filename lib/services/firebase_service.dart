import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/equipment.dart';
import '../models/maintenance_team.dart';
import '../models/maintenance_request.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  late FirebaseFirestore _firestore;
  late FirebaseAuth _auth;

  Future<void> initialize() async {
    await Firebase.initializeApp();
    _firestore = FirebaseFirestore.instance;
    _auth = FirebaseAuth.instance;
  }

  FirebaseFirestore get firestore => _firestore;
  FirebaseAuth get auth => _auth;

  // Equipment CRUD operations
  Future<String> createEquipment(Equipment equipment) async {
    DocumentReference doc = await _firestore.collection('equipment').add(equipment.toFirestore());
    return doc.id;
  }

  Future<List<Equipment>> getAllEquipment() async {
    QuerySnapshot snapshot = await _firestore.collection('equipment').get();
    return snapshot.docs.map((doc) => Equipment.fromFirestore(doc)).toList();
  }

  Future<Equipment?> getEquipment(String id) async {
    DocumentSnapshot doc = await _firestore.collection('equipment').doc(id).get();
    if (doc.exists) {
      return Equipment.fromFirestore(doc);
    }
    return null;
  }

  Future<void> updateEquipment(Equipment equipment) async {
    await _firestore.collection('equipment').doc(equipment.id).update(equipment.toFirestore());
  }

  Future<void> deleteEquipment(String id) async {
    await _firestore.collection('equipment').doc(id).delete();
  }

  Future<List<Equipment>> getEquipmentByDepartment(String department) async {
    QuerySnapshot snapshot = await _firestore
        .collection('equipment')
        .where('department', isEqualTo: department)
        .get();
    return snapshot.docs.map((doc) => Equipment.fromFirestore(doc)).toList();
  }

  Future<List<Equipment>> getEquipmentByEmployee(String employee) async {
    QuerySnapshot snapshot = await _firestore
        .collection('equipment')
        .where('assignedEmployee', isEqualTo: employee)
        .get();
    return snapshot.docs.map((doc) => Equipment.fromFirestore(doc)).toList();
  }

  // Maintenance Team CRUD operations
  Future<String> createMaintenanceTeam(MaintenanceTeam team) async {
    DocumentReference doc = await _firestore.collection('maintenanceTeams').add(team.toFirestore());
    return doc.id;
  }

  Future<List<MaintenanceTeam>> getAllMaintenanceTeams() async {
    QuerySnapshot snapshot = await _firestore.collection('maintenanceTeams').get();
    return snapshot.docs.map((doc) => MaintenanceTeam.fromFirestore(doc)).toList();
  }

  Future<MaintenanceTeam?> getMaintenanceTeam(String id) async {
    DocumentSnapshot doc = await _firestore.collection('maintenanceTeams').doc(id).get();
    if (doc.exists) {
      return MaintenanceTeam.fromFirestore(doc);
    }
    return null;
  }

  Future<void> updateMaintenanceTeam(MaintenanceTeam team) async {
    await _firestore.collection('maintenanceTeams').doc(team.id).update(team.toFirestore());
  }

  Future<void> deleteMaintenanceTeam(String id) async {
    await _firestore.collection('maintenanceTeams').doc(id).delete();
  }

  // Team Member CRUD operations
  Future<String> createTeamMember(TeamMember member) async {
    DocumentReference doc = await _firestore.collection('teamMembers').add(member.toFirestore());
    return doc.id;
  }

  Future<List<TeamMember>> getAllTeamMembers() async {
    QuerySnapshot snapshot = await _firestore.collection('teamMembers').get();
    return snapshot.docs.map((doc) => TeamMember.fromFirestore(doc)).toList();
  }

  Future<List<TeamMember>> getTeamMembersByTeam(String teamId) async {
    QuerySnapshot snapshot = await _firestore
        .collection('teamMembers')
        .where('teamId', isEqualTo: teamId)
        .get();
    return snapshot.docs.map((doc) => TeamMember.fromFirestore(doc)).toList();
  }

  Future<void> updateTeamMember(TeamMember member) async {
    await _firestore.collection('teamMembers').doc(member.id).update(member.toFirestore());
  }

  Future<void> deleteTeamMember(String id) async {
    await _firestore.collection('teamMembers').doc(id).delete();
  }

  // Maintenance Request CRUD operations
  Future<String> createMaintenanceRequest(MaintenanceRequest request) async {
    DocumentReference doc = await _firestore.collection('maintenanceRequests').add(request.toFirestore());
    return doc.id;
  }

  Future<List<MaintenanceRequest>> getAllMaintenanceRequests() async {
    QuerySnapshot snapshot = await _firestore.collection('maintenanceRequests').get();
    return snapshot.docs.map((doc) => MaintenanceRequest.fromFirestore(doc)).toList();
  }

  Future<List<MaintenanceRequest>> getMaintenanceRequestsByEquipment(String equipmentId) async {
    QuerySnapshot snapshot = await _firestore
        .collection('maintenanceRequests')
        .where('equipmentId', isEqualTo: equipmentId)
        .get();
    return snapshot.docs.map((doc) => MaintenanceRequest.fromFirestore(doc)).toList();
  }

  Future<List<MaintenanceRequest>> getMaintenanceRequestsByTeam(String teamId) async {
    QuerySnapshot snapshot = await _firestore
        .collection('maintenanceRequests')
        .where('maintenanceTeamId', isEqualTo: teamId)
        .get();
    return snapshot.docs.map((doc) => MaintenanceRequest.fromFirestore(doc)).toList();
  }

  Future<List<MaintenanceRequest>> getMaintenanceRequestsByStage(RequestStage stage) async {
    QuerySnapshot snapshot = await _firestore
        .collection('maintenanceRequests')
        .where('stage', isEqualTo: stage.toString())
        .get();
    return snapshot.docs.map((doc) => MaintenanceRequest.fromFirestore(doc)).toList();
  }

  Future<List<MaintenanceRequest>> getPreventiveMaintenanceRequestsByDateRange(DateTime start, DateTime end) async {
    QuerySnapshot snapshot = await _firestore
        .collection('maintenanceRequests')
        .where('type', isEqualTo: RequestType.preventive.toString())
        .where('scheduledDate', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('scheduledDate', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .get();
    return snapshot.docs.map((doc) => MaintenanceRequest.fromFirestore(doc)).toList();
  }

  Future<void> updateMaintenanceRequest(MaintenanceRequest request) async {
    await _firestore.collection('maintenanceRequests').doc(request.id).update(request.toFirestore());
  }

  Future<void> deleteMaintenanceRequest(String id) async {
    await _firestore.collection('maintenanceRequests').doc(id).delete();
  }

  // Authentication
  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    UserCredential result = await _auth.signInWithEmailAndPassword(email: email, password: password);
    return result.user;
  }

  Future<User?> registerWithEmailAndPassword(String email, String password) async {
    UserCredential result = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    return result.user;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<User?> getCurrentUser() async {
    return _auth.currentUser;
  }

  Stream<User?> authStateChanges() {
    return _auth.authStateChanges();
  }

  // Reports and Analytics
  Future<Map<String, int>> getRequestCountByTeam() async {
    QuerySnapshot snapshot = await _firestore.collection('maintenanceRequests').get();
    Map<String, int> teamCounts = {};
    
    for (var doc in snapshot.docs) {
      MaintenanceRequest request = MaintenanceRequest.fromFirestore(doc);
      teamCounts[request.maintenanceTeamName] = (teamCounts[request.maintenanceTeamName] ?? 0) + 1;
    }
    
    return teamCounts;
  }

  Future<Map<String, int>> getRequestCountByEquipmentCategory() async {
    QuerySnapshot snapshot = await _firestore.collection('maintenanceRequests').get();
    Map<String, int> categoryCounts = {};
    
    for (var doc in snapshot.docs) {
      MaintenanceRequest request = MaintenanceRequest.fromFirestore(doc);
      categoryCounts[request.equipmentCategory] = (categoryCounts[request.equipmentCategory] ?? 0) + 1;
    }
    
    return categoryCounts;
  }

  Future<int> getOpenRequestCount() async {
    QuerySnapshot snapshot = await _firestore
        .collection('maintenanceRequests')
        .where('stage', whereIn: [
          RequestStage.new_.toString(),
          RequestStage.inProgress.toString()
        ]).get();
    return snapshot.docs.length;
  }
}
