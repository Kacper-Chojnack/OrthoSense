import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orthosense/features/therapist_dashboard/domain/models/models.dart';
import 'package:orthosense/features/therapist_dashboard/presentation/providers/patients_provider.dart';
import 'package:orthosense/features/therapist_dashboard/presentation/screens/plan_details_screen.dart';

class PatientDetailsScreen extends ConsumerWidget {
  const PatientDetailsScreen({required this.patientId, super.key});

  final String patientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patientAsync = ref.watch(patientProvider(patientId));
    final plansAsync = ref.watch(patientPlansProvider(patientId));
    final statsAsync = ref.watch(patientStatsProvider(patientId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Patient Info
            patientAsync.when(
              data: _buildPatientHeader,
              loading: () => const LinearProgressIndicator(),
              error: (err, _) => Text('Error loading patient: $err'),
            ),
            const SizedBox(height: 24),

            // Stats Overview
            const Text(
              'Overview',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            statsAsync.when(
              data: _buildStatsGrid,
              loading: () => const SizedBox(
                height: 100,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, _) => Text('No stats available: $err'),
            ),
            const SizedBox(height: 24),

            // Treatment Plans
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Treatment Plans',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    // TODO(user): Navigate to create plan screen
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('New Plan'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            plansAsync.when(
              data: (plans) => _buildPlansList(context, plans),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Text('Error loading plans: $err'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientHeader(PatientModel patient) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              child: Text(
                patient.fullName.isNotEmpty
                    ? patient.fullName[0].toUpperCase()
                    : '?',
                style: const TextStyle(fontSize: 24),
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  patient.fullName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(patient.email),
                const SizedBox(height: 4),
                Chip(
                  label: Text(patient.isActive ? 'Active' : 'Inactive'),
                  backgroundColor: patient.isActive
                      ? Colors.green[100]
                      : Colors.grey[300],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(PatientStats stats) {
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.5,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: [
        _buildStatCard(
          'Compliance',
          '${stats.complianceRate.toStringAsFixed(1)}%',
          Icons.check_circle_outline,
          Colors.blue,
        ),
        _buildStatCard(
          'Sessions',
          '${stats.completedSessions} / ${stats.totalSessions}',
          Icons.fitness_center,
          Colors.orange,
        ),
        _buildStatCard(
          'Streak',
          '${stats.streakDays} days',
          Icons.local_fire_department,
          Colors.red,
        ),
        _buildStatCard(
          'Avg Score',
          stats.averageScore != null
              ? '${stats.averageScore!.toStringAsFixed(1)}%'
              : 'N/A',
          Icons.star_border,
          Colors.purple,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(title, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildPlansList(
    BuildContext context,
    List<TreatmentPlanDetails> plans,
  ) {
    if (plans.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: Text('No treatment plans assigned.')),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: plans.length,
      itemBuilder: (context, index) {
        final plan = plans[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(plan.name),
            subtitle: Text(
              '${plan.status.name.toUpperCase()} • ${plan.frequencyPerWeek}x / week',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => PlanDetailsScreen(planId: plan.id),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
