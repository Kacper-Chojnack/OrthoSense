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
                    child: Image.asset(
                      'assets/images/logo.png',
                      height: 24,
                    ),
                  ),
                  title: Text(patient.fullName),
                  subtitle: Text(patient.email),
                  trailing: Image.asset(
                    'assets/images/logo.png',
                    height: 24,
                  ),
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
        child: Image.asset('assets/images/logo.png', height: 24),
      ),
    );
  }
}
