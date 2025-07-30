import 'package:flutter/material.dart';

class Patient {
  final String id;
  final String name;
  final int? spo2;
  final DateTime? lastUpdate;

  Patient({
    required this.id,
    required this.name,
    this.spo2,
    this.lastUpdate,
  });

  // Convertir a Map para Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'spo2': spo2,
      'lastUpdate': lastUpdate?.millisecondsSinceEpoch,
      // Guardamos DateTime como timestamp numérico
    };
  }

  // Crear Patient desde Firestore
  factory Patient.fromMap(Map<String, dynamic> map, String id) {
    return Patient(
      id: id,
      name: map['name'] ?? 'Sin nombre',
      spo2: map['spo2']?.toInt(), // Asegurar que es int
      lastUpdate: map['lastUpdate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastUpdate'] as int)
          : null,
    );
  }

  String get status {
    if (spo2 == null) return 'Sin datos';
    if (spo2! >= 95) return 'Normal';
    if (spo2! >= 90) return 'Bajo';
    return 'Crítico';
  }

  Color get statusColor {
    if (spo2 == null) return Colors.grey;
    if (spo2! >= 95) return Colors.green;
    if (spo2! >= 90) return Colors.orange;
    return Colors.red;
  }

  // Método útil para debugging
  @override
  String toString() {
    return 'Patient{id: $id, name: $name, spo2: $spo2, lastUpdate: $lastUpdate}';
  }
}