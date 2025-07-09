import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class RealtimeTest extends StatefulWidget {
  const RealtimeTest({super.key});

  @override
  State<RealtimeTest> createState() => _RealtimeTestState();
}

class _RealtimeTestState extends State<RealtimeTest> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  int contador = 0;

  @override
  void initState() {
    super.initState();

    // Escuchar en tiempo real el cambio en "sala/personas"
    _dbRef.child("sala/personas").onValue.listen((event) {
      final data = event.snapshot.value;
      if (data != null && mounted) {
        setState(() {
          contador = int.parse(data.toString());
        });
      }
    });
  }

  void simularEntradaPersona() async {
    final snapshot = await _dbRef.child("sala/personas").get();
    int current = 0;
    if (snapshot.exists) {
      current = int.parse(snapshot.value.toString());
    }

    final nuevoValor = current + 1;
    await _dbRef.child("sala").update({'personas': nuevoValor});

    setState(() {
      contador = nuevoValor;
    });
  }

  void resetearContador() async {
    await _dbRef.child("sala").update({'personas': 0});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Contador de Personas')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Personas dentro de la sala:',
              style: TextStyle(fontSize: 20),
            ),
            Text(
              '$contador',
              style: const TextStyle(fontSize: 50, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              icon: const Icon(Icons.door_front_door),
              label: const Text('Simular Entrada'),
              onPressed: simularEntradaPersona,
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Resetear contador'),
              onPressed: resetearContador,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            ),
          ],
        ),
      ),
    );
  }
}
