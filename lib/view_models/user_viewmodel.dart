import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';

class UserViewModel extends ChangeNotifier {
  final CollectionReference _col = FirebaseFirestore.instance.collection(
    'users',
  );

  List<User> _users = [];
  bool _isLoading = false;

  List<User> get users => _users;
  bool get isLoading => _isLoading;

  /// Carga inicial de todos los usuarios
  Future<void> loadUsers() async {
    _isLoading = true;
    notifyListeners();

    final snapshot = await _col.get();
    _users = snapshot.docs.map((doc) => User.fromDoc(doc)).toList();

    _isLoading = false;
    notifyListeners();
  }

  /// Crea un usuario nuevo (usa campo password si está presente)
  Future<void> createUser(User user) async {
    await _col.add(user.toMap());
    await loadUsers();
  }

  /// Actualiza datos de un usuario existente
  Future<void> updateUser(User user) async {
    await _col.doc(user.id).update(user.toMap());
    await loadUsers();
  }

  /// Elimina un usuario por ID
  Future<void> deleteUser(String id) async {
    await _col.doc(id).delete();
    await loadUsers();
  }
}
