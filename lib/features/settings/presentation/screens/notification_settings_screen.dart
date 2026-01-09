import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orthosense/core/providers/notification_provider.dart';
import 'package:orthosense/core/providers/preferences_provider.dart';
import 'package:orthosense/features/settings/presentation/providers/notification_schedule_provider.dart';

/// Screen for configuring training reminder notifications.
class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final prefs = ref.watch(preferencesServiceProvider);
    final notificationsEnabled = prefs.areNotificationsEnabled;
    final scheduleAsync = ref.watch(notificationScheduleProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Training Reminders'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Master toggle
          Card(
            child: SwitchListTile(
              secondary: Icon(
                Icons.notifications_active,
                color: colorScheme.primary,
              ),
              title: const Text('Enable Reminders'),
              subtitle: const Text('Get notified about your training sessions'),
              value: notificationsEnabled,
              onChanged: (value) async {
                if (value) {
                  final granted = await ref
                      .read(notificationServiceProvider)
                      .requestPermissions();
                  if (!granted && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Notification permission denied. '
                          'Please enable in system settings.',
                        ),
                      ),
                    );
                    return;
                  }
                }
                await ref
                    .read(preferencesServiceProvider)
                    .setNotificationsEnabled(value: value);
                // Force UI refresh
                ref.invalidate(preferencesServiceProvider);
                if (!value) {
                  await ref.read(notificationServiceProvider).cancelAll();
                } else {
                  // Re-schedule notifications with current settings
                  await ref
                      .read(notificationScheduleProvider.notifier)
                      .applySchedule();
                }
              },
            ),
          ),
          const SizedBox(height: 24),

          // Schedule section
          if (notificationsEnabled) ...[
            Text(
              'Reminder Schedule',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose which days and time you want to be reminded',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),

            // Time picker
            scheduleAsync.when(
              data: (schedule) => Column(
                children: [
                  // Time selection
                  Card(
                    child: ListTile(
                      leading: Icon(
                        Icons.access_time,
                        color: colorScheme.primary,
                      ),
                      title: const Text('Reminder Time'),
                      subtitle: Text(
                        _formatTime(schedule.hour, schedule.minute),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay(
                            hour: schedule.hour,
                            minute: schedule.minute,
                          ),
                        );
                        if (time != null) {
                          await ref
                              .read(notificationScheduleProvider.notifier)
                              .setTime(time.hour, time.minute);
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Day selection
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                color: colorScheme.primary,
                              ),
                              const SizedBox(width: 12),
                              const Text('Training Days'),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _DaySelector(
                            selectedDays: schedule.days,
                            onChanged: (days) {
                              ref
                                  .read(notificationScheduleProvider.notifier)
                                  .setDays(days);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Preview
                  Card(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _getScheduleSummary(schedule),
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(int hour, int minute) {
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _getScheduleSummary(NotificationSchedule schedule) {
    if (schedule.days.isEmpty) {
      return 'No days selected. Please select at least one day.';
    }

    final dayNames = <String>[];
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    for (var i = 0; i < 7; i++) {
      if (schedule.days.contains(i + 1)) {
        dayNames.add(names[i]);
      }
    }

    return 'You will be reminded at ${_formatTime(schedule.hour, schedule.minute)} '
        'on ${dayNames.join(", ")}.';
  }
}

class _DaySelector extends StatelessWidget {
  const _DaySelector({
    required this.selectedDays,
    required this.onChanged,
  });

  final Set<int> selectedDays;
  final ValueChanged<Set<int>> onChanged;

  @override
  Widget build(BuildContext context) {
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(7, (index) {
        final dayNumber = index + 1; // 1 = Monday, 7 = Sunday
        final isSelected = selectedDays.contains(dayNumber);

        return GestureDetector(
          onTap: () {
            final newDays = Set<int>.from(selectedDays);
            if (isSelected) {
              newDays.remove(dayNumber);
            } else {
              newDays.add(dayNumber);
            }
            onChanged(newDays);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.outlineVariant,
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                days[index],
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? colorScheme.onPrimary
                      : colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
