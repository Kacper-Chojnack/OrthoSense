import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orthosense/core/providers/notification_provider.dart';
import 'package:orthosense/core/providers/preferences_provider.dart';
import 'package:orthosense/features/auth/domain/models/models.dart';
import 'package:orthosense/features/auth/presentation/providers/auth_notifier.dart';
import 'package:orthosense/features/onboarding/presentation/screens/voice_selection_screen.dart';
import 'package:orthosense/features/settings/data/account_service.dart';
import 'package:orthosense/features/settings/presentation/providers/theme_mode_provider.dart';
import 'package:orthosense/features/settings/presentation/screens/edit_profile_screen.dart';

/// Settings screen with appearance, account, and about sections.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // Appearance Section
          const _SectionHeader(title: 'Appearance'),
          _AppearanceSection(),
          const SizedBox(height: 16),

          // Notifications Section
          const _SectionHeader(title: 'Notifications'),
          const _NotificationSection(),
          const SizedBox(height: 16),

          // Voice Assistant Section
          const _SectionHeader(title: 'Voice Assistant'),
          const _VoiceSection(),
          const SizedBox(height: 16),

          // Account Section
          const _SectionHeader(title: 'Account'),
          _AccountSection(),
          const SizedBox(height: 16),

          // About Section
          const _SectionHeader(title: 'About'),
          _AboutSection(),
          const SizedBox(height: 32),

          // App Info
          Center(
            child: Column(
              children: [
                Image.asset(
                  'assets/images/logo.png',
                  height: 64,
                  color: colorScheme.primary.withValues(alpha: 0.8),
                ),
                const SizedBox(height: 8),
                Text(
                  'OrthoSense',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  'Digital Telerehabilitation',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _AppearanceSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(currentThemeModeProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.palette_outlined,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Text(
                  'Theme',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment(
                    value: ThemeMode.system,
                    icon: Icon(Icons.brightness_auto),
                    label: Text('System'),
                  ),
                  ButtonSegment(
                    value: ThemeMode.light,
                    icon: Icon(Icons.light_mode),
                    label: Text('Light'),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    icon: Icon(Icons.dark_mode),
                    label: Text('Dark'),
                  ),
                ],
                selected: {themeMode},
                onSelectionChanged: (Set<ThemeMode> selection) {
                  ref
                      .read(themeModeProvider.notifier)
                      .setThemeMode(selection.first);
                },
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _getThemeDescription(themeMode),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getThemeDescription(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.system => 'Follows your device settings',
      ThemeMode.light => 'Always use light theme',
      ThemeMode.dark => 'Always use dark theme',
    };
  }
}

class _AccountSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final authState = ref.watch(authProvider);
    final accountOpState = ref.watch(accountOperationProvider);
    final isLoading =
        authState is AuthStateLoading ||
        accountOpState is AccountOperationLoading;
    final colorScheme = Theme.of(context).colorScheme;

    // Listen for account operation results
    ref.listen<AccountOperationState>(
      accountOperationProvider,
      (previous, next) {
        if (next is AccountOperationSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(next.message),
              backgroundColor: Colors.green,
            ),
          );
          ref.read(accountOperationProvider.notifier).reset();
        } else if (next is AccountOperationError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(next.message),
              backgroundColor: colorScheme.error,
            ),
          );
          ref.read(accountOperationProvider.notifier).reset();
        }
      },
    );

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          if (user != null) ...[
            ListTile(
              leading: CircleAvatar(
                backgroundColor: colorScheme.primaryContainer,
                child: Text(
                  user.email.substring(0, 1).toUpperCase(),
                  style: TextStyle(color: colorScheme.onPrimaryContainer),
                ),
              ),
              title: Text(user.email),
            ),
            const Divider(height: 1),
          ],
          // Edit Profile
          ListTile(
            leading: Icon(
              Icons.edit,
              color: colorScheme.onSurfaceVariant,
            ),
            title: const Text('Edit Profile'),
            trailing: const Icon(Icons.chevron_right),
            onTap: isLoading
                ? null
                : () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (context) => const EditProfileScreen(),
                      ),
                    );
                  },
          ),
          const Divider(height: 1),
          // Download My Data (GDPR)
          ListTile(
            leading: Icon(
              Icons.download,
              color: colorScheme.primary,
            ),
            title: const Text('Download My Data'),
            subtitle: const Text('GDPR: Right to Data Portability'),
            trailing: accountOpState is AccountOperationLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.chevron_right),
            onTap: isLoading ? null : () => _handleDownloadData(context, ref),
          ),
          const Divider(height: 1),
          // Sign Out
          ListTile(
            leading: Icon(
              Icons.logout,
              color: colorScheme.error,
            ),
            title: Text(
              'Sign Out',
              style: TextStyle(color: colorScheme.error),
            ),
            trailing: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    Icons.chevron_right,
                    color: colorScheme.error,
                  ),
            onTap: isLoading ? null : () => _handleLogout(context, ref),
          ),
          const Divider(height: 1),
          // Delete Account (GDPR)
          ListTile(
            leading: const Icon(
              Icons.delete_forever,
              color: Colors.red,
            ),
            title: const Text(
              'Delete Account',
              style: TextStyle(color: Colors.red),
            ),
            subtitle: const Text('GDPR: Right to be Forgotten'),
            trailing: const Icon(
              Icons.chevron_right,
              color: Colors.red,
            ),
            onTap: isLoading ? null : () => _handleDeleteAccount(context, ref),
          ),
        ],
      ),
    );
  }

  Future<void> _handleDownloadData(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Download Your Data'),
        content: const Text(
          'This will export all your data including:\n\n'
          '• Account information\n'
          '• Treatment plans\n'
          '• Exercise sessions & results\n'
          '• Protocols you created\n\n'
          'The data will be saved as a JSON file.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(Icons.download),
            label: const Text('Download'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      await ref.read(accountOperationProvider.notifier).exportData();
    }
  }

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text(
          'Are you sure you want to sign out? '
          'Any unsynced data will be preserved locally.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      await ref.read(authProvider.notifier).logout();
      if (context.mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }
  }

  Future<void> _handleDeleteAccount(BuildContext context, WidgetRef ref) async {
    // First confirmation
    final firstConfirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.warning, color: Colors.red, size: 48),
        title: const Text('Delete Account?'),
        content: const Text(
          'This will permanently delete:\n\n'
          '• Your account and profile\n'
          '• All treatment plans (as patient)\n'
          '• All exercise sessions and results\n'
          '• All protocols you created\n\n'
          'This action CANNOT be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Continue'),
          ),
        ],
      ),
    );

    if (!(firstConfirm ?? false) || !context.mounted) return;

    // Second confirmation with typing
    final textController = TextEditingController();
    final finalConfirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Final Confirmation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Type "DELETE" to confirm:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: textController,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'DELETE',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ListenableBuilder(
            listenable: textController,
            builder: (context, _) {
              final isValid = textController.text.toUpperCase() == 'DELETE';
              return FilledButton(
                onPressed: isValid
                    ? () => Navigator.of(context).pop(true)
                    : null,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                child: const Text('Delete Forever'),
              );
            },
          ),
        ],
      ),
    );

    if (!(finalConfirm ?? false) || !context.mounted) return;

    // Perform deletion
    final success = await ref
        .read(accountOperationProvider.notifier)
        .deleteAccount();

    if (success && context.mounted) {
      // Clear local preferences
      await ref.read(preferencesServiceProvider).clearAll();
      // Logout to reset auth state
      await ref.read(authProvider.notifier).logout();
      if (context.mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }
}

class _AboutSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Version'),
            trailing: Text(
              '1.0.0',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Licenses'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => showLicensePage(
              context: context,
              applicationName: 'OrthoSense',
              applicationVersion: '1.0.0',
              applicationIcon: Padding(
                padding: const EdgeInsets.all(8),
                child: Image.asset(
                  'assets/images/logo.png',
                  height: 64,
                  width: 64,
                  color: colorScheme.primary,
                ),
              ),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy Policy'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Privacy policy coming soon')),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.article_outlined),
            title: const Text('Terms of Service'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Terms of service coming soon')),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _NotificationSection extends ConsumerStatefulWidget {
  const _NotificationSection();

  @override
  ConsumerState<_NotificationSection> createState() =>
      _NotificationSectionState();
}

class _NotificationSectionState extends ConsumerState<_NotificationSection> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(preferencesServiceProvider);
    final enabled = prefs.areNotificationsEnabled;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: SwitchListTile(
        secondary: Icon(
          enabled
              ? Icons.notifications_active_outlined
              : Icons.notifications_off_outlined,
          color: colorScheme.primary,
        ),
        title: const Text('Session Reminders'),
        subtitle: const Text('Get notified 15 min before sessions'),
        value: enabled,
        onChanged: _isLoading ? null : _handleToggle,
      ),
    );
  }

  Future<void> _handleToggle(bool value) async {
    setState(() => _isLoading = true);

    try {
      if (value) {
        // Request permissions when enabling
        final granted = await ref
            .read(notificationServiceProvider)
            .requestPermissions();

        if (!granted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Notification permission denied. '
                  'Please enable in system settings.',
                ),
              ),
            );
          }
          return;
        }
      } else {
        // Cancel all notifications when disabling
        await ref.read(notificationServiceProvider).cancelAll();
      }

      await ref.read(preferencesServiceProvider).setNotificationsEnabled(value: value);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

class _VoiceSection extends StatelessWidget {
  const _VoiceSection();

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ListTile(
        leading: const Icon(Icons.record_voice_over),
        title: const Text('Assistant Voice'),
        subtitle: const Text('Change the voice of your exercise assistant'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (context) =>
                  const VoiceSelectionScreen(isSettingsMode: true),
            ),
          );
        },
      ),
    );
  }
}
