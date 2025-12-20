import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orthosense/features/therapist_dashboard/domain/models/models.dart';
import 'package:orthosense/features/therapist_dashboard/presentation/providers/plans_provider.dart';

class PlanDetailsScreen extends ConsumerWidget {
  const PlanDetailsScreen({super.key, required this.planId});

  final String planId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planAsync = ref.watch(planProvider(planId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Plan Details'),
        actions: [
          planAsync.when(
            data: (plan) => PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'edit') {
                  // TODO: Navigate to edit plan
                } else if (value == 'activate') {
                  await ref.read(plansProvider.notifier).activatePlan(planId);
                } else if (value == 'pause') {
                  await ref.read(plansProvider.notifier).pausePlan(planId);
                } else if (value == 'complete') {
                  await ref.read(plansProvider.notifier).completePlan(planId);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit Plan')),
                if (plan.status == PlanStatus.pending)
                  const PopupMenuItem(
                    value: 'activate',
                    child: Text('Activate Plan'),
                  ),
                if (plan.status == PlanStatus.active)
                  const PopupMenuItem(
                    value: 'pause',
                    child: Text('Pause Plan'),
                  ),
                if (plan.status == PlanStatus.active)
                  const PopupMenuItem(
                    value: 'complete',
                    child: Text('Complete Plan'),
                  ),
              ],
            ),
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
          ),
        ],
      ),
      body: planAsync.when(
        data: (plan) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(plan),
              const SizedBox(height: 24),
              _buildDetails(plan),
              const SizedBox(height: 24),
              const Text(
                'Sessions History',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              // TODO: Add sessions list for this plan
              const Center(child: Text('Session history coming soon')),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildHeader(TreatmentPlanDetails plan) {
    Color statusColor;
    switch (plan.status) {
      case PlanStatus.active:
        statusColor = Colors.green;
        break;
      case PlanStatus.pending:
        statusColor = Colors.orange;
        break;
      case PlanStatus.completed:
        statusColor = Colors.blue;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    plan.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Chip(
                  label: Text(
                    plan.status.name.toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  ),
                  backgroundColor: statusColor,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Patient: ${plan.patientName}'),
            if (plan.protocolName != null)
              Text('Based on Protocol: ${plan.protocolName}'),
          ],
        ),
      ),
    );
  }

  Widget _buildDetails(TreatmentPlanDetails plan) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Configuration',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Start Date'),
              subtitle: Text(plan.startDate.toString().split(' ')[0]),
            ),
            ListTile(
              leading: const Icon(Icons.event_available),
              title: const Text('End Date'),
              subtitle: Text(
                plan.endDate?.toString().split(' ')[0] ?? 'Open-ended',
              ),
            ),
            ListTile(
              leading: const Icon(Icons.repeat),
              title: const Text('Frequency'),
              subtitle: Text('${plan.frequencyPerWeek} sessions per week'),
            ),
            if (plan.notes.isNotEmpty) ...[
              const Divider(),
              const Text(
                'Notes',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(plan.notes),
            ],
          ],
        ),
      ),
    );
  }
}
