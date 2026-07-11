import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/input_providers.dart';

/// Card shown above the input field when the device clipboard contains text.
///
/// Provides two actions:
/// - **Import**: copy the clipboard text into the input field.
/// - **Dismiss**: hide this banner for the rest of the session.
///
/// Animates in/out using [AnimatedSize] + [AnimatedSwitcher] so the layout
/// reflows smoothly when the banner appears or disappears.
class ClipboardBanner extends ConsumerWidget {
  const ClipboardBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final clipboardAsync = ref.watch(clipboardProvider);
    final dismissed = ref.watch(clipboardDismissedProvider);

    // Decide whether to show the banner.
    final showBanner = !dismissed &&
        clipboardAsync.maybeWhen(
          data: (text) => text != null && text.trim().isNotEmpty,
          orElse: () => false,
        );

    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      child: showBanner
          ? Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _BannerCard(
                text: clipboardAsync.value!,
                onImport: () =>
                    _onImport(ref, clipboardAsync.value!),
                onDismiss: () =>
                    ref.read(clipboardDismissedProvider.notifier).state = true,
                colorScheme: colorScheme,
                theme: theme,
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  void _onImport(WidgetRef ref, String text) {
    final controller = ref.read(textControllerProvider);
    controller.text = text;
    controller.selection = TextSelection.collapsed(offset: text.length);
    // Hide the banner after importing.
    ref.read(clipboardDismissedProvider.notifier).state = true;
  }
}

class _BannerCard extends StatelessWidget {
  const _BannerCard({
    required this.text,
    required this.onImport,
    required this.onDismiss,
    required this.colorScheme,
    required this.theme,
  });

  final String text;
  final VoidCallback onImport;
  final VoidCallback onDismiss;
  final ColorScheme colorScheme;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    // Show a short preview of the clipboard text.
    final preview = text.length > 80
        ? '${text.substring(0, 80).trimRight()}…'
        : text;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.content_paste_rounded,
                size: 20,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Clipboard detected',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text(
              preview,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.85),
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              TextButton(
                onPressed: onDismiss,
                style: TextButton.styleFrom(
                  foregroundColor: colorScheme.onSurfaceVariant,
                ),
                child: const Text('Dismiss'),
              ),
              const SizedBox(width: 4),
              FilledButton.tonal(
                onPressed: onImport,
                child: const Text('Import'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
