import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart' as model;
import '../views/success.dart';
import '../views/menu.dart';

final authViewModelProvider = ChangeNotifierProvider<AuthViewModel>((ref) => AuthViewModel());

class AuthViewModel extends ChangeNotifier {
  final _firestore = FirebaseFirestore.instance;

  bool loading = false;
  String? error;

  Future<void> register(BuildContext context, model.User user) async {
    try {
      loading = true;
      error = null;
      notifyListeners();

      await _firestore.collection('users').add(user.toMap());

      loading = false;
      notifyListeners();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const Success()),
      );
    } catch (e) {
      loading = false;
      error = e.toString();
      notifyListeners();
    }
  }

  Future<void> login(BuildContext context, String username, String password) async {
    try {
      loading = true;
      error = null;
      notifyListeners();

      final snapshot = await _firestore
          .collection('users')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        throw 'Usuario no encontrado';
      }

      final userData = snapshot.docs.first.data();
      if (userData['password'] != password) {
        throw 'Contraseña incorrecta';
      }

      loading = false;
      notifyListeners();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const Menu()),
      );
    } catch (e) {
      loading = false;
      error = e.toString();
      notifyListeners();
    }
  }
}


