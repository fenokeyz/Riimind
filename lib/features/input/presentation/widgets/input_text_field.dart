import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/input_providers.dart';

/// The large multiline text field on the Home screen.
///
/// Reads its [TextEditingController] from [textControllerProvider] so the
/// controller is shared across the banner's Import action, the Paste button,
/// and the Clear button — they all read/write the same instance.
class InputTextField extends ConsumerWidget {
  const InputTextField({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final controller = ref.watch(textControllerProvider);
    final hasText = ref.watch(inputTextProvider).isNotEmpty;

    return Stack(
      children: [
        TextField(
          controller: controller,
          minLines: 6,
          maxLines: 12,
          textInputAction: TextInputAction.newline,
          keyboardType: TextInputType.multiline,
          style: theme.textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText:
                'Paste a message like “Lunch with Alex tomorrow at 1pm at Cafe Milano”',
            hintStyle: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            ),
            // Reserve room for the clear button so the caret doesn't overlap it.
            contentPadding: const EdgeInsets.fromLTRB(20, 20, 48, 20),
          ),
        ),
        // Clear button — only rendered when there is text.
        Positioned(
          top: 12,
          right: 12,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 180),
            opacity: hasText ? 1.0 : 0.0,
            child: IgnorePointer(
              ignoring: !hasText,
              child: Material(
                color: colorScheme.surfaceContainerHighest,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () {
                    controller.clear();
                    // Move focus out so the keyboard closes if it was open.
                    FocusScope.of(context).unfocus();
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
