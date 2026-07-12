import 'package:flutter/material.dart';

/// A single labelled row on the event preview screen.
///
/// Renders a small icon tile, a label, and the value. Empty values are shown
/// as "Not detected" in a lighter style so the user can see which fields the
/// model missed.
class PreviewField {
  const PreviewField({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  /// Placeholder shown when [value] is empty.
  static const String notDetected = 'Not detected';

  bool get isEmpty => value.trim().isEmpty;
}

/// Card row that renders a [PreviewField].
class PreviewFieldCard extends StatelessWidget {
  const PreviewFieldCard({required this.field, super.key});

  final PreviewField field;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isEmpty = field.isEmpty;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              field.icon,
              size: 18,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  field.label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isEmpty ? PreviewField.notDetected : field.value,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: isEmpty
                        ? colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.55)
                        : colorScheme.onSurface,
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

/// Material 3 warning card shown at the top of the preview when one of the
/// time-anchored fields (date or time) couldn't be determined.
class PreviewMissingInfoCard extends StatelessWidget {
  const PreviewMissingInfoCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            size: 22,
            color: colorScheme.onErrorContainer,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "Some information couldn't be determined. Please edit your message and try again.",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onErrorContainer,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
