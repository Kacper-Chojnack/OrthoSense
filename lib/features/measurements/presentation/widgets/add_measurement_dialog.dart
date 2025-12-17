import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orthosense/features/measurements/presentation/providers/measurement_providers.dart';

/// Dialog for adding a new measurement.
/// Demonstrates SSOT pattern: saves to DB and closes immediately,
/// letting the Drift stream update the UI.
class AddMeasurementDialog extends ConsumerStatefulWidget {
  const AddMeasurementDialog({
    required this.userId,
    super.key,
  });

  final String userId;

  @override
  ConsumerState<AddMeasurementDialog> createState() =>
      _AddMeasurementDialogState();
}

class _AddMeasurementDialogState extends ConsumerState<AddMeasurementDialog> {
  final _formKey = GlobalKey<FormState>();
  String _selectedType = 'pose_analysis';
  final _dataController = TextEditingController();
  bool _isSaving = false;

  static const _measurementTypes = [
    ('pose_analysis', 'Pose Analysis'),
    ('rom_measurement', 'ROM Measurement'),
    ('exercise_session', 'Exercise Session'),
    ('balance_test', 'Balance Test'),
  ];

  @override
  void initState() {
    super.initState();
    _dataController.text = '{"angle": 45, "duration": 30}';
  }

  @override
  void dispose() {
    _dataController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Add Measurement'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Type',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                items: _measurementTypes
                    .map(
                      (type) => DropdownMenuItem(
                        value: type.$1,
                        child: Text(type.$2),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedType = value);
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _dataController,
                decoration: const InputDecoration(
                  labelText: 'JSON Data',
                  hintText: '{"angle": 45, "duration": 30}',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.data_object),
                ),
                maxLines: 4,
                validator: _validateJson,
              ),
              const SizedBox(height: 8),
              Text(
                'Enter valid JSON data for the measurement.\n'
                'Data is saved locally first, then synced.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _isSaving ? null : _handleSave,
          icon: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save),
          label: const Text('Save'),
        ),
      ],
    );
  }

  String? _validateJson(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter JSON data';
    }

    try {
      jsonDecode(value);
      return null;
    } catch (_) {
      return 'Invalid JSON format';
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final data = jsonDecode(_dataController.text) as Map<String, dynamic>;
      final repository = ref.read(measurementRepositoryProvider);

      // SSOT: Save to DB only - Stream will update UI automatically
      // NO waiting for API response. Just local DB insert.
      await repository.saveMeasurement(
        userId: widget.userId,
        type: _selectedType,
        data: data,
      );

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Measurement saved locally'),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'OK',
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() => _isSaving = false);
      }
    }
  }
}
