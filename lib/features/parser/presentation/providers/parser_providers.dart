import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/parsed_event.dart';
import '../../services/gemini_service.dart';

/// Singleton [GeminiService] for the app.
///
/// Reads the API key from the [dotenv] entry that `main.dart` loads at startup.
/// Tests can override this provider with a fake that returns canned
/// [ParsedEvent]s.
final geminiServiceProvider = Provider<GeminiService>((ref) {
  return GeminiService();
});

/// Extract a [ParsedEvent] from a free-form string of text.
///
/// Keyed by the input text. The Home button invalidates this provider before
/// each user-initiated extraction, so retries never reuse a cached response or
/// error from an earlier attempt.
final parseEventProvider = FutureProvider.family<ParsedEvent, String>((
  ref,
  text,
) {
  final service = ref.watch(geminiServiceProvider);
  return service.extractEvent(text);
});
