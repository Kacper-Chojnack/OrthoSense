import 'package:flutter/material.dart';

/// A dialog showing tips for best analysis results.
///
/// Displays guidelines about lighting, body visibility, and clothing.
/// Includes a checkbox to dismiss permanently.
class AnalysisTipsDialog extends StatefulWidget {
  const AnalysisTipsDialog({
    required this.onContinue,
    super.key,
  });

  /// Called when user taps Continue. Returns true if "Don't show again" was checked.
  final void Function({required bool dontShowAgain}) onContinue;

  /// Shows the dialog and returns whether the user checked "Don't show again".
  static Future<bool?> show(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AnalysisTipsDialog(
        onContinue: ({required bool dontShowAgain}) {
          Navigator.of(ctx).pop(dontShowAgain);
        },
      ),
    );
  }

  @override
  State<AnalysisTipsDialog> createState() => _AnalysisTipsDialogState();
}

class _AnalysisTipsDialogState extends State<AnalysisTipsDialog> {
  bool _dontShowAgain = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.tips_and_updates_outlined,
                    size: 40,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Tips for Best Results',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Follow these guidelines for accurate movement analysis',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          // Tips list
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  _TipCard(
                    icon: Icons.wb_sunny_outlined,
                    iconColor: Colors.amber,
                    title: 'Good Lighting',
                    description:
                        'Ensure the room is well-lit. Avoid backlighting (bright windows behind you). Natural or bright artificial light works best.',
                    theme: theme,
                  ),
                  const SizedBox(height: 12),
                  _TipCard(
                    icon: Icons.accessibility_new,
                    iconColor: Colors.blue,
                    title: 'Full Body Visibility',
                    description:
                        'Position yourself so your entire body is visible on screen. Step back if needed. The camera should capture you from head to toe.',
                    theme: theme,
                  ),
                  const SizedBox(height: 12),
                  _TipCard(
                    icon: Icons.checkroom_outlined,
                    iconColor: Colors.teal,
                    title: 'Fitted Clothing',
                    description:
                        'Wear fitted (not loose or baggy) clothes that contrast with your background. Avoid clothing that matches your wall or floor color.',
                    theme: theme,
                  ),
                ],
              ),
            ),
          ),

          // Don't show again checkbox and Continue button
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Checkbox row
                InkWell(
                  onTap: () {
                    setState(() {
                      _dontShowAgain = !_dontShowAgain;
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: Checkbox(
                            value: _dontShowAgain,
                            onChanged: (value) {
                              setState(() {
                                _dontShowAgain = value ?? false;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "Don't show this again",
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Continue button
                FilledButton.icon(
                  onPressed: () =>
                      widget.onContinue(dontShowAgain: _dontShowAgain),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Continue'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  const _TipCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.theme,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
