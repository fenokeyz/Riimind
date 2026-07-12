import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import '../models/parsed_event.dart';

/// Thrown when the parser can't produce a usable [ParsedEvent].
class GeminiParseException implements Exception {
  GeminiParseException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Wraps the Gemini SDK. The whole API surface is one method: extract a
/// [ParsedEvent] from a free-form string of text.
class GeminiService {
  GeminiService({String? apiKey})
    : _apiKey = apiKey ?? dotenv.env['GEMINI_API_KEY'] ?? '';

  static const String _modelName = 'gemini-3.5-flash';

  final String _apiKey;

  /// Prompt that locks Gemini into JSON-only output.
  ///
  /// Combined with `responseMimeType: application/json` this is the cleanest
  /// way to get strict JSON out of Gemini — no markdown, no code fences, no
  /// preamble. The system instruction is short and explicit.
  static const String _systemInstruction = '''
You are an event-extraction assistant.
Extract a calendar event from the user's message and respond with ONLY a JSON object.

Today's local date and the user's current local timezone are always provided
in the user message. Use them to resolve relative phrases like "tomorrow",
"next Friday", "tonight", "in 2 hours".

Return JSON with these exact keys and nothing else:
- "title": short event title (string, required)
- "description": supporting detail, never include the user's exact phrasing unless useful (string, may be empty)
- "date": event date in ISO 8601 (YYYY-MM-DD), resolved in the user's local timezone (string, may be empty if unknown)
- "time": event time in 24-hour HH:mm (string, may be empty if unknown)
- "location": venue, address, or place name (string, may be empty)

Rules:
- Never invent missing information. If you are uncertain, leave the field empty instead of guessing.
- "time" must be 24-hour HH:mm. Convert "1pm" -> "13:00", "11:59 PM" -> "23:59".
- Always return valid JSON only. Never return markdown. Never return explanations. Never return code fences.
''';

  Future<ParsedEvent> extractEvent(String text) async {
    if (_apiKey.isEmpty) {
      throw GeminiParseException(
        'Gemini API key missing. Add GEMINI_API_KEY to your .env file.',
      );
    }
    if (text.trim().isEmpty) {
      throw GeminiParseException('Input text is empty.');
    }

    final model = GenerativeModel(
      model: _modelName,
      apiKey: _apiKey,
      systemInstruction: Content.system(_systemInstruction),
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        temperature: 0.1,
        // The model will be told exactly how many keys we want; this is a
        // safety cap that keeps responses from being absurdly long.
        maxOutputTokens: 512,
      ),
    );

    final now = DateTime.now();
    final today = _formatDate(now);
    final timezone = _localTimezone();
    final userPrompt =
        'today: $today\ntimezone: $timezone\nmessage: ${text.trim()}';

    final response = await model.generateContent([Content.text(userPrompt)]);
    final raw = response.text;
    if (raw == null || raw.trim().isEmpty) {
      throw GeminiParseException('Gemini returned an empty response.');
    }

    return _parseJson(raw);
  }

  /// Parse a JSON string from Gemini into a [ParsedEvent].
  ///
  /// Gemini should already return pure JSON because we set
  /// `responseMimeType: 'application/json'`, but we still defend against:
  /// - accidental markdown fences (```json ... ```)
  /// - leading/trailing prose
  /// - shape mismatches (handled by [ParsedEvent.fromJson])
  ParsedEvent _parseJson(String raw) {
    var cleaned = raw.trim();

    // Strip code fences if Gemini wrapped the JSON anyway.
    final fenceMatch = RegExp(
      r'```(?:json)?\s*(.*?)\s*```',
      dotAll: true,
    ).firstMatch(cleaned);
    if (fenceMatch != null) {
      cleaned = fenceMatch.group(1)!.trim();
    }

    // If the model added prose around the JSON, grab the first {...} block.
    if (!cleaned.startsWith('{')) {
      // A pure JSON array (top-level `[`) is a real failure mode we want to
      // surface as an exception, not silently turn into the first object
      // inside the array.
      if (cleaned.startsWith('[')) {
        throw GeminiParseException(
          'Unexpected response shape: expected a JSON object.',
        );
      }
      final objMatch = RegExp(r'\{.*\}', dotAll: true).firstMatch(cleaned);
      if (objMatch != null) cleaned = objMatch.group(0)!;
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(cleaned);
    } on FormatException catch (e) {
      throw GeminiParseException(
        'Couldn\'t parse the response as JSON. ${e.message}',
      );
    }

    if (decoded is! Map<String, dynamic>) {
      throw GeminiParseException(
        'Unexpected response shape: expected a JSON object.',
      );
    }

    return ParsedEvent.fromJson(decoded);
  }

  static String _formatDate(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// Best-effort local timezone name. `DateTime.now().timeZoneName` returns
  /// abbreviations like "PDT" on some platforms; on Android the
  /// [Platform.localeName] gives "en_US" but not the IANA zone. We fall back
  /// to the abbreviation when the IANA name isn't available.
  static String _localTimezone() {
    final offset = DateTime.now().timeZoneOffset;
    final sign = offset.isNegative ? '-' : '+';
    final h = offset.inHours.abs().toString().padLeft(2, '0');
    final m = (offset.inMinutes.abs() % 60).toString().padLeft(2, '0');
    final abbrev = DateTime.now().timeZoneName;
    return '$abbrev (UTC$sign$h:$m)';
  }

  // --- Test seams. These expose the private helpers above so the unit tests
  // can exercise the JSON-cleaning and date-formatting logic without going
  // through a real network call. Each one is a one-line forwarder and the
  // production code path is unchanged.

  @visibleForTesting
  static String formatDateForTest(DateTime dt) => _formatDate(dt);

  @visibleForTesting
  static String localTimezoneForTest() => _localTimezone();

  @visibleForTesting
  ParsedEvent parseJsonForTest(String raw) => _parseJson(raw);
}
