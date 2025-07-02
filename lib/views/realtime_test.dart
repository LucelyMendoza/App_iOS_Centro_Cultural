import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class RealtimeTest extends StatefulWidget {
  const RealtimeTest({super.key});

  @override
  State<RealtimeTest> createState() => _RealtimeTestState();
}

class _RealtimeTestState extends State<RealtimeTest> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  String nombre = '';
  int edad = 0;
  String datos = '';

  void escribirDatos() {
    _dbRef.child("usuarios/usuario1").set({'nombre': nombre, 'edad': edad});
  }

  void leerDatos() async {
    final snapshot = await _dbRef.child("usuarios/usuario1").get();
    if (snapshot.exists) {
      final data = snapshot.value as Map;
      setState(() {
        datos = 'Nombre: ${data['nombre']}, Edad: ${data['edad']}';
      });
    } else {
      setState(() {
        datos = 'No se encontraron datos.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Firebase Realtime Test')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(labelText: 'Nombre'),
              onChanged: (value) => nombre = value,
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'Edad'),
              keyboardType: TextInputType.number,
              onChanged: (value) => edad = int.tryParse(value) ?? 0,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: escribirDatos,
              child: const Text('Guardar en Firebase'),
            ),
            ElevatedButton(
              onPressed: leerDatos,
              child: const Text('Leer desde Firebase'),
            ),
            const SizedBox(height: 20),
            Text(datos, style: const TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}
