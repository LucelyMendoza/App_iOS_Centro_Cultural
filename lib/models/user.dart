import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  String id;
  String firstName;
  String lastName;
  String email;
  String phoneNumber;
  String username;
  String? password; // solo usado en creación, no se suele guardar en cliente

  User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    required this.username,
    this.password,
  });

  factory User.fromDoc(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return User(
      id: doc.id,
      firstName: data['firstName'] as String,
      lastName: data['lastName'] as String,
      email: data['email'] as String,
      phoneNumber: data['phoneNumber'] as String,
      username: data['username'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phoneNumber': phoneNumber,
      'username': username,
    };
    if (password != null) {
      map['password'] = password; // opcional: enrutar a función de creación
    }
    return map;
  }
}
