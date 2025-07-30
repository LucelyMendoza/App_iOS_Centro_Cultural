import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mi_app/services/database_service.dart';
import 'package:mi_app/models/patient.dart';
import 'package:mi_app/views/patient_detail_screen.dart';

class PatientListScreen extends StatelessWidget {
  const PatientListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pacientes'),
      ),
      body: StreamBuilder<List<Patient>>(
        stream: Provider.of<DatabaseService>(context).getPatients(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No hay pacientes registrados'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final patient = snapshot.data![index];
              return ListTile(
                title: Text(patient.name),
                subtitle: Text('SpO2: ${patient.spo2 ?? '--'}%'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PatientDetailScreen(patientId: patient.id),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}