import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mi_app/models/patient.dart';
import 'package:mi_app/services/database_service.dart';
import 'package:mi_app/widgets/spo2_gauge.dart';
import '../widgets/spo2_gauge.dart';
import '../models/patient.dart';
import '../services/database_service.dart';

class PatientDetailScreen extends StatelessWidget {
  final String patientId;

  const PatientDetailScreen({Key? key, required this.patientId}) : super(key: key);

  @override
Widget build(BuildContext context) {
  final patientStream = Provider.of<DatabaseService>(context).getPatient(patientId);

  return Scaffold(
    appBar: AppBar(
      title: StreamBuilder<Patient?>(
        stream: patientStream,
        builder: (context, snapshot) {
          return Text(snapshot.data?.name ?? 'Paciente');
        },
      ),
    ),
    body: Padding(
      padding: const EdgeInsets.all(16.0),
      child: StreamBuilder<Patient?>(
        stream: patientStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData) {
            return const Center(child: Text('No se encontraron datos'));
          }

          final patient = snapshot.data!;
          return buildPatientUI(patient);
        },
      ),
    ),
  );
}

Widget buildPatientUI(Patient patient) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Spo2Gauge(value: patient.spo2 ?? 0),
              const SizedBox(height: 20),
              Text(
                'Estado: ${patient.status}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: patient.statusColor,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Última actualización: ${patient.lastUpdate != null 
                    ? '${patient.lastUpdate!.hour}:${patient.lastUpdate!.minute.toString().padLeft(2, '0')}'
                    : '--'}',
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 20),
      ElevatedButton.icon(
        icon: const Icon(Icons.history),
        label: const Text('Ver histórico'),
        onPressed: () {
          // Navegar a pantalla de histórico
        },
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    ],
  );
}

}