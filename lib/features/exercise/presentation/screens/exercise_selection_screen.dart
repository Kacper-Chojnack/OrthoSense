import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orthosense/features/exercise/presentation/screens/live_analysis_screen.dart';

/// Screen for selecting an exercise to perform with real-time analysis.
class ExerciseSelectionScreen extends ConsumerWidget {
  const ExerciseSelectionScreen({super.key});

  static const List<ExerciseInfo> _exercises = [
    ExerciseInfo(
      id: 0,
      name: 'Deep Squat',
      description: 'Lower body mobility and strength assessment',
      icon: Icons.fitness_center,
      instructions: [
        'Stand with feet shoulder-width apart',
        'Keep your arms extended forward',
        'Lower your hips as deep as possible',
        'Keep heels on the ground',
        'Maintain upright torso',
      ],
    ),
    ExerciseInfo(
      id: 1,
      name: 'Hurdle Step',
      description: 'Hip and leg stability assessment',
      icon: Icons.directions_walk,
      instructions: [
        'Stand on one leg',
        'Lift the other knee to hip height',
        'Step over an imaginary hurdle',
        'Keep pelvis stable and level',
        'Avoid torso lean',
      ],
    ),
    ExerciseInfo(
      id: 2,
      name: 'Standing Shoulder Abduction',
      description: 'Shoulder mobility and stability assessment',
      icon: Icons.accessibility_new,
      instructions: [
        'Stand with arms at your sides',
        'Raise both arms out to the sides',
        'Lift until arms are parallel to floor',
        'Keep arms symmetrical',
        'Avoid shrugging shoulders',
      ],
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Exercise'),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _exercises.length,
        itemBuilder: (context, index) {
          final exercise = _exercises[index];
          return _ExerciseCard(
            exercise: exercise,
            onTap: () => _showExerciseDetails(context, exercise),
          );
        },
      ),
    );
  }

  void _showExerciseDetails(BuildContext context, ExerciseInfo exercise) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _ExerciseDetailsSheet(exercise: exercise),
    );
  }
}

class ExerciseInfo {
  const ExerciseInfo({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.instructions,
  });

  final int id;
  final String name;
  final String description;
  final IconData icon;
  final List<String> instructions;
}

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({
    required this.exercise,
    required this.onTap,
  });

  final ExerciseInfo exercise;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  exercise.icon,
                  size: 32,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      exercise.description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExerciseDetailsSheet extends StatelessWidget {
  const _ExerciseDetailsSheet({required this.exercise});

  final ExerciseInfo exercise;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(24),
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        exercise.icon,
                        size: 40,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      exercise.name,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      exercise.description,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Instructions',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...exercise.instructions.asMap().entries.map((entry) {
                      final index = entry.key + 1;
                      final instruction = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: colorScheme.secondaryContainer,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '$index',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSecondaryContainer,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  instruction,
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 24),
                    Text(
                      'Camera Position',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _CameraOptionButton(
                            icon: Icons.camera_front,
                            label: 'Front Camera',
                            onPressed: () => _startAnalysis(
                              context,
                              exercise,
                              useFrontCamera: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _CameraOptionButton(
                            icon: Icons.camera_rear,
                            label: 'Back Camera',
                            onPressed: () => _startAnalysis(
                              context,
                              exercise,
                              useFrontCamera: false,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _startAnalysis(
    BuildContext context,
    ExerciseInfo exercise, {
    required bool useFrontCamera,
  }) {
    Navigator.of(context).pop();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LiveAnalysisScreen(
          exerciseName: exercise.name,
          useFrontCamera: useFrontCamera,
        ),
      ),
    );
  }
}

class _CameraOptionButton extends StatelessWidget {
  const _CameraOptionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32),
          const SizedBox(height: 8),
          Text(label),
        ],
      ),
    );
  }
}
