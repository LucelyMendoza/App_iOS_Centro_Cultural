import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> subirGaleriasDesdeJson() async {
  final jsonStr = await rootBundle.loadString('assets/data/galerias.json');
  final data = json.decode(jsonStr);

  final db = FirebaseFirestore.instance;
  final galerias = data['galerias'] as Map<String, dynamic>;

  for (var entry in galerias.entries) {
    final galeriaId = entry.key;
    final galeriaData = entry.value;
    final pinturas = galeriaData.remove('pinturas');

    await db.collection('galerias').doc(galeriaId).set(galeriaData);

    if (pinturas != null) {
      for (var pintura in (pinturas as Map<String, dynamic>).entries) {
        await db
            .collection('galerias')
            .doc(galeriaId)
            .collection('pinturas')
            .doc(pintura.key)
            .set(pintura.value);
      }
    }
  }

  print("✅ Datos subidos correctamente a Firestore.");
}
