import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/input_providers.dart';

/// The large multiline text field on the Home screen.
///
/// Reads its [TextEditingController] from [textControllerProvider] so the
/// controller is shared across the banner's Import action, the Paste button,
/// and the Clear button — they all read/write the same instance.
class InputTextField extends ConsumerStatefulWidget {
  const InputTextField({super.key});

  @override
  ConsumerState<InputTextField> createState() => _InputTextFieldState();
}

class _InputTextFieldState extends ConsumerState<InputTextField> {
  late final TextEditingController _controller;
  late final VoidCallback _listener;

  @override
  void initState() {
    super.initState();
    _controller = ref.read(textControllerProvider);

    // Re-render this widget when the controller's text changes so the
    // Clear button can animate in/out. We do not call setState inside
    // the listener — instead we listen to Riverpod's inputTextProvider
    // via ref.listen in build.
    _listener = () {
      if (mounted) setState(() {});
    };
    _controller.addListener(_listener);
  }

  @override
  void dispose() {
    _controller.removeListener(_listener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasText = _controller.text.isNotEmpty;

    return Stack(
      children: [
        TextField(
          controller: _controller,
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
                    _controller.clear();
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
