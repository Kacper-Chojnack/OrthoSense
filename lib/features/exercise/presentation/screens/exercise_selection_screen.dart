import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:orthosense/features/exercise/presentation/screens/live_analysis_screen.dart';
import 'package:orthosense/features/exercise/presentation/widgets/exercise_demo_video_sheet.dart';

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
      // Demo video showing correct technique (stored locally in assets)
      demoVideo: DemoVideo(
        title: 'Proper Deep Squat Form',
        description:
            'Watch how to maintain proper form throughout the movement. '
            'Focus on keeping your heels down and chest up.',
        assetPath: 'assets/videos/deep_squat_demo.mp4',
        viewAngle: 'side',
      ),
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
      demoVideo: DemoVideo(
        title: 'Hurdle Step Technique',
        description:
            'Maintain balance and control while stepping over the hurdle. '
            'Keep your standing leg stable.',
        assetPath: 'assets/videos/hurdle_step_demo.mp4',
        viewAngle: 'front',
      ),
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
      demoVideo: DemoVideo(
        title: 'Shoulder Abduction Form',
        description:
            'Raise arms smoothly to shoulder height. '
            'Avoid shrugging or leaning.',
        assetPath: 'assets/videos/shoulder_abduction_demo.mp4',
        viewAngle: 'front',
      ),
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
    this.demoVideo,
  });

  final int id;
  final String name;
  final String description;
  final IconData icon;
  final List<String> instructions;
  final DemoVideo? demoVideo;
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
                child: Image.asset(
                  'assets/images/logo.png',
                  height: 32,
                  width: 32,
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
              Image.asset(
                'assets/images/logo.png',
                height: 24,
                width: 24,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExerciseDetailsSheet extends ConsumerWidget {
  const _ExerciseDetailsSheet({required this.exercise});

  final ExerciseInfo exercise;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                      child: Image.asset(
                        'assets/images/logo.png',
                        height: 40,
                        width: 40,
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
                            label: 'Front Camera',
                            onPressed: () => _startAnalysis(
                              context,
                              ref,
                              exercise,
                              useFrontCamera: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _CameraOptionButton(
                            label: 'Back Camera',
                            onPressed: () => _startAnalysis(
                              context,
                              ref,
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

  Future<void> _startAnalysis(
    BuildContext context,
    WidgetRef ref,
    ExerciseInfo exercise, {
    required bool useFrontCamera,
  }) async {
    // Close the exercise details sheet first
    Navigator.of(context).pop();

    // Show demo video if available and user hasn't opted to skip
    if (exercise.demoVideo != null) {
      final shouldProceed = await ExerciseDemoVideoSheet.showIfNeeded(
        context: context,
        ref: ref,
        exerciseId: exercise.id,
        exerciseName: exercise.name,
        demoVideo: exercise.demoVideo,
        onContinue: () {
          // This is called after user clicks "Start Exercise"
        },
      );

      if (!shouldProceed) {
        return; // User cancelled
      }
    }

    // Navigate to live analysis screen
    if (context.mounted) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => LiveAnalysisScreen(
            exerciseName: exercise.name,
            useFrontCamera: useFrontCamera,
          ),
        ),
      );
    }
  }
}

class _CameraOptionButton extends StatelessWidget {
  const _CameraOptionButton({
    required this.label,
    required this.onPressed,
  });

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
          Image.asset('assets/images/logo.png', height: 32),
          const SizedBox(height: 8),
          Text(label),
        ],
      ),
    );
  }
}
