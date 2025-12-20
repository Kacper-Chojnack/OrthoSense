import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orthosense/features/auth/presentation/providers/auth_notifier.dart';
import 'package:orthosense/features/settings/data/account_service.dart';

/// Screen for editing user profile (name, email).
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;

  String? _originalName;
  String? _originalEmail;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();

    // Initialize with current user data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(currentUserProvider);
      if (user != null) {
        _nameController.text = user.fullName ?? '';
        _emailController.text = user.email;
        _originalName = user.fullName ?? '';
        _originalEmail = user.email;
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  bool get _hasChanges =>
      _nameController.text != _originalName ||
      _emailController.text != _originalEmail;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final user = ref.watch(currentUserProvider);
    final accountOpState = ref.watch(accountOperationProvider);
    final isLoading = accountOpState is AccountOperationLoading;

    // Listen for operation results
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
          // Refresh auth to get updated user info
          ref.read(authProvider.notifier).refreshAuthStatus();
          Navigator.of(context).pop();
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          if (_hasChanges)
            TextButton(
              onPressed: isLoading ? null : _saveChanges,
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
        ],
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Profile Avatar
                  Center(
                    child: CircleAvatar(
                      radius: 48,
                      backgroundColor: colorScheme.primaryContainer,
                      child: Text(
                        user.email.substring(0, 1).toUpperCase(),
                        style: TextStyle(
                          fontSize: 32,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Full Name Field
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      hintText: 'Enter your full name',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.words,
                    onChanged: (_) => setState(() {}),
                    validator: (value) {
                      if (value != null && value.length > 255) {
                        return 'Name must be less than 255 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Email Field
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      hintText: 'Enter your email',
                      prefixIcon: const Icon(Icons.email),
                      border: const OutlineInputBorder(),
                      helperText: _emailController.text != _originalEmail
                          ? 'Changing email will require re-verification'
                          : null,
                      helperStyle: TextStyle(color: colorScheme.error),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (_) => setState(() {}),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Email is required';
                      }
                      if (!RegExp(
                        r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                      ).hasMatch(value)) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Account Info Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Account Information',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            context,
                            'Role',
                            user.role?.toString().split('.').last ?? 'Patient',
                          ),
                          _buildInfoRow(
                            context,
                            'Email Verified',
                            user.isVerified == true ? 'Yes' : 'No',
                          ),
                          if (user.createdAt != null)
                            _buildInfoRow(
                              context,
                              'Member Since',
                              _formatDate(user.createdAt!),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Email change warning
                  if (_emailController.text != _originalEmail) ...[
                    Card(
                      color: colorScheme.errorContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(
                              Icons.warning,
                              color: colorScheme.onErrorContainer,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Changing your email will require you to verify '
                                'the new email address before accessing all features.',
                                style: TextStyle(
                                  color: colorScheme.onErrorContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    String? newName;
    String? newEmail;

    if (_nameController.text != _originalName) {
      newName = _nameController.text;
    }
    if (_emailController.text != _originalEmail) {
      newEmail = _emailController.text;
    }

    await ref
        .read(accountOperationProvider.notifier)
        .updateProfile(
          fullName: newName,
          email: newEmail,
        );
  }
}
