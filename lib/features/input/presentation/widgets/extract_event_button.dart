import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../parser/presentation/providers/parser_providers.dart';
import '../../../parser/services/gemini_service.dart';
import '../providers/input_providers.dart';

/// Primary CTA on the Home screen: "Extract Event".
///
/// Starts a fresh [parseEventProvider] request for each tap. While Gemini is
/// working, the button shows a spinner and the label changes to
/// "Understanding your message...". On success, the parsed event is pushed
/// onto `/preview`. On failure, a Material 3 AlertDialog explains that
/// Riimind couldn't extract the event and offers "Edit message" or
/// "Try again".
class ExtractEventButton extends ConsumerStatefulWidget {
  const ExtractEventButton({super.key});

  @override
  ConsumerState<ExtractEventButton> createState() => _ExtractEventButtonState();
}

class _ExtractEventButtonState extends ConsumerState<ExtractEventButton> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = ref.watch(inputTextProvider);
    final hasText = text.trim().isNotEmpty;

    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: (hasText && !_isLoading) ? () => _onPressed(text) : null,
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 18),
        ),
        child: _isLoading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        theme.colorScheme.onPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text('Understanding your message...'),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.auto_awesome_rounded, size: 18),
                  SizedBox(width: 10),
                  Text('Extract Event'),
                ],
              ),
      ),
    );
  }

  Future<void> _onPressed(String text) async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    Object? error;
    try {
      // A FutureProvider family caches completed values by its argument.
      // Invalidate this message's previous result so retries always invoke
      // Gemini instead of reusing a prior AsyncError or successful response.
      ref.invalidate(parseEventProvider(text));
      final event = await ref.read(parseEventProvider(text).future);

      if (mounted) {
        GoRouter.of(context).push('/preview', extra: event);
      }
    } catch (caughtError) {
      error = caughtError;
    } finally {
      // This must run for every success, Gemini failure, parse failure, or
      // unexpected exception so the CTA is never left disabled.
      if (mounted) setState(() => _isLoading = false);
    }

    if (mounted && error != null) {
      _showErrorDialog(error);
    }
  }

  void _showErrorDialog(Object error) {
    final message = _friendlyErrorMessage(error);

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Couldn't understand this message"),
          content: Text('$message\n\nYou can edit the message and try again.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Edit message'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                final text = ref.read(inputTextProvider);
                if (text.trim().isNotEmpty) {
                  _onPressed(text);
                }
              },
              child: const Text('Try again'),
            ),
          ],
        );
      },
    );
  }

  String _friendlyErrorMessage(Object error) {
    if (error is! GeminiParseException) {
      return 'We couldn\'t reach Gemini. Check your connection and try again.';
    }

    return switch (error.kind) {
      GeminiFailureKind.missingApiKey =>
        'Gemini is not configured yet. Add GEMINI_API_KEY to your .env file.',
      GeminiFailureKind.invalidApiKey =>
        'Your Gemini API key was rejected. Check GEMINI_API_KEY and try again.',
      GeminiFailureKind.network =>
        'No internet connection was found. Connect and try again.',
      GeminiFailureKind.rateLimit =>
        'Gemini API quota has been reached for this key. Wait a bit or replace the key and try again.',
      GeminiFailureKind.unavailable =>
        'Gemini is temporarily unavailable. Please try again shortly.',
      GeminiFailureKind.malformedResponse =>
        'Gemini returned an unreadable result. Please try again.',
      GeminiFailureKind.noEventDetected =>
        'We couldn\'t find an event in that message. Try adding what, when, or where.',
    };
  }
}
