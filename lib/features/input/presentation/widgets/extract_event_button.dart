import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/input_providers.dart';

/// Primary CTA on the Home screen: "Extract Event".
///
/// Disabled when the input is empty. On tap, currently shows a SnackBar to
/// indicate the wiring is coming in Feature 4 — no Gemini call yet.
class ExtractEventButton extends ConsumerWidget {
  const ExtractEventButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasText = ref.watch(inputTextProvider).trim().isNotEmpty;

    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: hasText ? () => _onPressed(context) : null,
        icon: const Icon(Icons.auto_awesome_rounded, size: 18),
        label: const Text('Extract Event'),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 18),
        ),
      ),
    );
  }

  void _onPressed(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Coming soon — Gemini wiring arrives in Feature 4.'),
          duration: Duration(seconds: 2),
        ),
      );
  }
}
