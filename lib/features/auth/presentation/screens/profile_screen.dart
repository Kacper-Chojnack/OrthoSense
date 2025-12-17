import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orthosense/features/auth/presentation/providers/auth_notifier.dart';
import 'package:orthosense/features/settings/presentation/screens/settings_screen.dart';

/// Profile screen showing user info and settings navigation.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // User Avatar
                Center(
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: colorScheme.primaryContainer,
                    child: Text(
                      user.email.substring(0, 1).toUpperCase(),
                      style:
                          Theme.of(context).textTheme.headlineLarge?.copyWith(
                                color: colorScheme.onPrimaryContainer,
                              ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // User Info Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Account Information',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const Divider(),
                        _ProfileInfoRow(
                          icon: Icons.email_outlined,
                          label: 'Email',
                          value: user.email,
                        ),
                        const SizedBox(height: 12),
                        _ProfileInfoRow(
                          icon: Icons.verified_outlined,
                          label: 'Status',
                          value: user.isVerified ? 'Verified' : 'Unverified',
                          valueColor: user.isVerified
                              ? Colors.green
                              : colorScheme.error,
                        ),
                        const SizedBox(height: 12),
                        _ProfileInfoRow(
                          icon: Icons.fingerprint,
                          label: 'User ID',
                          value: user.id.length > 8
                              ? '${user.id.substring(0, 8)}...'
                              : user.id,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Quick Settings Card
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.settings_outlined),
                        title: const Text('Settings'),
                        subtitle: const Text('Theme, account, and more'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const SettingsScreen(),
                          ),
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.notifications_outlined),
                        title: const Text('Notifications'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Coming soon!')),
                          );
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.help_outline),
                        title: const Text('Help & Support'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Coming soon!')),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // App Version
                Center(
                  child: Text(
                    'OrthoSense v1.0.0',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _ProfileInfoRow extends StatelessWidget {
  const _ProfileInfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: valueColor,
                    ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
