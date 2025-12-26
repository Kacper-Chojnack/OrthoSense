import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orthosense/features/therapist_dashboard/presentation/providers/patients_provider.dart';
import 'package:orthosense/features/therapist_dashboard/presentation/screens/patient_details_screen.dart';

class PatientsScreen extends ConsumerWidget {
  const PatientsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patientsAsync = ref.watch(patientsListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Patients'),
        automaticallyImplyLeading: false,
      ),
      body: patientsAsync.when(
        data: (patients) {
          if (patients.isEmpty) {
            return const Center(
              child: Text('No active patients found.'),
            );
          }
          return ListView.builder(
            itemCount: patients.length,
            itemBuilder: (context, index) {
              final patient = patients[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(
                      patient.fullName.isNotEmpty
                          ? patient.fullName[0].toUpperCase()
                          : '?',
                    ),
                  ),
                  title: Text(patient.fullName),
                  subtitle: Text(patient.email),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (context) =>
                            PatientDetailsScreen(patientId: patient.id),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO(user): Implement invite patient dialog
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invite Patient feature coming soon')),
          );
        },
        child: const Icon(Icons.person_add_rounded),
      ),
    );
  }
}
