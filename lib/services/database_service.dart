// services/database_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mi_app/models/patient.dart';

class DatabaseService {
  final FirebaseFirestore _firestore;

  DatabaseService() : _firestore = FirebaseFirestore.instance;

  Stream<List<Patient>> getPatients() {
    return _firestore.collection('pacientes').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Patient.fromMap(doc.data()!, doc.id);
      }).toList();
    });
  }

  Stream<Patient?> getPatient(String patientId) {
    return _firestore
        .collection('pacientes')
        .doc(patientId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return Patient.fromMap(doc.data()!, doc.id);
    });
  }

  Future<void> addPatient(Patient patient) async {
    await _firestore.collection('pacientes').add(patient.toMap());
  }

  Future<void> updatePatient(String id, Patient patient) async {
    await _firestore.collection('pacientes').doc(id).update(patient.toMap());
  }

  Future<void> deletePatient(String id) async {
    await _firestore.collection('pacientes').doc(id).delete();
  }
}