import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/input_providers.dart';

/// Row of secondary actions that sit between the text field and the primary
/// "Extract Event" button.
///
/// - **Paste**: reads the device clipboard and writes it into the input
///   controller. Disabled if the clipboard is empty.
/// - **Clear**: empties the input controller. Disabled if it is already empty.
class InputActionRow extends ConsumerWidget {
  const InputActionRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasText = ref.watch(inputTextProvider).isNotEmpty;

    final clipboardAsync = ref.watch(clipboardProvider);
    final hasClipboard = clipboardAsync.maybeWhen(
      data: (text) => text != null && text.trim().isNotEmpty,
      orElse: () => false,
    );

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: hasClipboard ? () => _onPaste(ref) : null,
            icon: const Icon(Icons.content_paste_rounded, size: 18),
            label: const Text('Paste from clipboard'),
            style: OutlinedButton.styleFrom(
              foregroundColor: colorScheme.onSurface,
              side: BorderSide(
                color: hasClipboard
                    ? colorScheme.outlineVariant
                    : colorScheme.outlineVariant.withValues(alpha: 0.4),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: hasText ? () => _onClear(ref) : null,
            icon: const Icon(Icons.delete_outline_rounded, size: 18),
            label: const Text('Clear'),
            style: OutlinedButton.styleFrom(
              foregroundColor: colorScheme.onSurface,
              side: BorderSide(
                color: hasText
                    ? colorScheme.outlineVariant
                    : colorScheme.outlineVariant.withValues(alpha: 0.4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _onPaste(WidgetRef ref) async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text == null || text.isEmpty) return;

    final controller = ref.read(textControllerProvider);
    controller.text = text;
    controller.selection = TextSelection.collapsed(offset: text.length);

    // Hide the clipboard banner if it was visible.
    ref.read(clipboardDismissedProvider.notifier).state = true;
  }

  void _onClear(WidgetRef ref) {
    final controller = ref.read(textControllerProvider);
    controller.clear();
    FocusScope.of(ref.context).unfocus();
  }
}
