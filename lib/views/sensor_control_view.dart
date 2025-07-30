import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:mi_app/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sensor y Actuador',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const SensorControlView(),
    );
  }
}

class SensorControlView extends StatefulWidget {
  const SensorControlView({super.key});

  @override
  State<SensorControlView> createState() => _SensorControlViewState();
}

class _SensorControlViewState extends State<SensorControlView> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  bool heaterState = false;

  @override
  void initState() {
    super.initState();
    _listenToHeater();
  }

  void _listenToHeater() {
    _dbRef.child('actuators/heater').onValue.listen((event) {
      final value = event.snapshot.value;
      if (value is bool) {
        setState(() {
          heaterState = value;
        });
      }
    });
  }

  void _toggleHeater(bool state) {
    _dbRef.child('actuators/heater').set(state);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Prueba realtime')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Text('Temperatura:', style: TextStyle(fontSize: 20)),
            const SizedBox(height: 10),
            StreamBuilder<DatabaseEvent>(
              stream: _dbRef.child('sensors/temperature').onValue,
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
                  final temp = snapshot.data!.snapshot.value;
                  return Text(
                    '$temp °C',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }
                return const CircularProgressIndicator();
              },
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Encender', style: TextStyle(fontSize: 18)),
                Switch(value: heaterState, onChanged: _toggleHeater),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
