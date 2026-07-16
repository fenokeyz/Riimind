import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/parsed_event.dart';

enum GeminiFailureKind {
  missingApiKey,
  invalidApiKey,
  network,
  rateLimit,
  unavailable,
  malformedResponse,
  noEventDetected,
}

/// A parser failure that can be rendered as a friendly user-facing message.
class GeminiParseException implements Exception {
  GeminiParseException(
    this.message, {
    this.kind = GeminiFailureKind.malformedResponse,
  });

  final String message;
  final GeminiFailureKind kind;

  @override
  String toString() => message;
}

/// Wraps Gemini natural-language event extraction.
class GeminiService {
  GeminiService({String? apiKey})
    : _apiKey = apiKey ?? dotenv.env['GEMINI_API_KEY'] ?? '';

  static const List<String> _modelCandidates = [
    'gemini-1.5-flash',
    'gemini-2.0-flash',
  ];
  final String _apiKey;

  static const String _systemInstruction = '''
You are an event-extraction assistant. Extract one calendar event from the
user's message and respond with ONLY a JSON object.

Today's local date and the user's current local timezone are always provided
in the user message. Use them to resolve relative phrases.

Return JSON with these exact keys and nothing else:
- "title": short event title (string, required)
- "description": supporting detail, including recurring intent when present (string, may be empty)
- "date": event date in ISO 8601 (YYYY-MM-DD), resolved in the user's local timezone (string, may be empty if unknown)
- "time": event time in 24-hour HH:mm (string, may be empty; an empty time means an all-day event)
- "location": venue, address, or place name (string, may be empty)

Rules:
- Never invent missing information. If uncertain, leave the field empty.
- Resolve "tomorrow" to the next local calendar day and "tonight" to today's date. Do not invent a clock time for "tonight".
- Resolve weekday references such as "next Monday" and "next Friday" to their next matching local date. For "every Monday", use the next Monday as the date and preserve the recurring intent in description.
- "time" must be 24-hour HH:mm. Convert "noon" to "12:00", "midnight" to "00:00", and "3pm" to "15:00". Retain an explicit "15:00".
- "evening", "morning", and similar vague parts of day do not specify a time; leave time empty unless a clock time is provided.
- If the message explicitly says all-day or supplies no time, leave time empty.
- Always return valid JSON only. Never return markdown, explanations, or code fences.
''';

  Future<ParsedEvent> extractEvent(String text) async {
    if (text.trim().isEmpty) {
      throw GeminiParseException(
        'Input text is empty.',
        kind: GeminiFailureKind.noEventDetected,
      );
    }

    final proxyUrl = await _loadProxyUrl();
    if (proxyUrl != null) {
      return _extractEventWithProxy(text, proxyUrl);
    }

    if (_apiKey.isEmpty) {
      throw GeminiParseException(
        'Gemini API key missing.',
        kind: GeminiFailureKind.missingApiKey,
      );
    }

    final now = DateTime.now();
    final prompt =
        'today: ${_formatDate(now)}\ntimezone: ${_localTimezone()}\nmessage: ${text.trim()}';

    GenerateContentResponse? response;
    Object? lastError;
    for (final modelName in _modelCandidates) {
      try {
        final model = GenerativeModel(
          model: modelName,
          apiKey: _apiKey,
          systemInstruction: Content.system(_systemInstruction),
          generationConfig: GenerationConfig(
            responseMimeType: 'application/json',
            temperature: 0.0,
            maxOutputTokens: 192,
          ),
        );
        response = await model
            .generateContent([Content.text(prompt)])
            .timeout(const Duration(seconds: 12));
        lastError = null;
        break;
      } on InvalidApiKey {
        throw GeminiParseException(
          'The Gemini API key was rejected.',
          kind: GeminiFailureKind.invalidApiKey,
        );
      } on SocketException {
        lastError = GeminiParseException(
          'No network connection is available.',
          kind: GeminiFailureKind.network,
        );
      } on TimeoutException {
        lastError = GeminiParseException(
          'Gemini timed out.',
          kind: GeminiFailureKind.unavailable,
        );
      } on GenerativeAIException catch (error) {
        final details = error.toString().toLowerCase();
        final isRateLimit = details.contains('429') ||
            details.contains('quota') ||
            details.contains('rate limit') ||
            details.contains('resource exhausted');
        lastError = GeminiParseException(
          isRateLimit
              ? 'Gemini API quota was exceeded for this key.'
              : 'Gemini is unavailable.',
          kind: isRateLimit
              ? GeminiFailureKind.rateLimit
              : GeminiFailureKind.unavailable,
        );
      }
    }

    if (lastError != null || response == null) {
      throw lastError ?? GeminiParseException(
        'Gemini is unavailable.',
        kind: GeminiFailureKind.unavailable,
      );
    }

    final raw = response.text;
    if (raw == null || raw.trim().isEmpty) {
      throw GeminiParseException(
        'Gemini returned an empty response.',
        kind: GeminiFailureKind.noEventDetected,
      );
    }

    final event = _parseJson(raw);
    if (event.isEmpty) {
      throw GeminiParseException(
        'No event details were found.',
        kind: GeminiFailureKind.noEventDetected,
      );
    }
    return event;
  }

  Future<ParsedEvent> _extractEventWithProxy(String text, String proxyUrl) async {
    final response = await http
        .post(
          Uri.parse(proxyUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'text': text.trim()}),
        )
        .timeout(const Duration(seconds: 12));

    if (response.statusCode == 429) {
      throw GeminiParseException(
        'Gemini API quota has been reached for this key. Wait a bit or replace the key and try again.',
        kind: GeminiFailureKind.rateLimit,
      );
    }

    if (response.statusCode != 200) {
      throw GeminiParseException(
        'Gemini is temporarily unavailable.',
        kind: GeminiFailureKind.unavailable,
      );
    }

    final raw = response.body.trim();
    if (raw.isEmpty) {
      throw GeminiParseException(
        'Gemini returned an empty response.',
        kind: GeminiFailureKind.noEventDetected,
      );
    }

    return _parseJson(raw);
  }

  Future<String?> _loadProxyUrl() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final value = prefs.getString('gemini_proxy_url')?.trim();
      return (value == null || value.isEmpty) ? null : value;
    } on FlutterError {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  ParsedEvent _parseJson(String raw) {
    var cleaned = raw.trim();
    final fenceMatch = RegExp(
      r'```(?:json)?\s*(.*?)\s*```',
      dotAll: true,
    ).firstMatch(cleaned);
    if (fenceMatch != null) cleaned = fenceMatch.group(1)!.trim();

    if (!cleaned.startsWith('{')) {
      if (cleaned.startsWith('[')) {
        throw GeminiParseException(
          'Expected a JSON object.',
          kind: GeminiFailureKind.malformedResponse,
        );
      }
      final objectMatch = RegExp(r'\{.*\}', dotAll: true).firstMatch(cleaned);
      if (objectMatch != null) cleaned = objectMatch.group(0)!;
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(cleaned);
    } on FormatException {
      throw GeminiParseException(
        'Could not parse Gemini JSON.',
        kind: GeminiFailureKind.malformedResponse,
      );
    }
    if (decoded is! Map<String, dynamic>) {
      throw GeminiParseException(
        'Expected a JSON object.',
        kind: GeminiFailureKind.malformedResponse,
      );
    }
    return ParsedEvent.fromJson(decoded);
  }

  static String _formatDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  static String _localTimezone() {
    final now = DateTime.now();
    final offset = now.timeZoneOffset;
    final sign = offset.isNegative ? '-' : '+';
    final hours = offset.inHours.abs().toString().padLeft(2, '0');
    final minutes = (offset.inMinutes.abs() % 60).toString().padLeft(2, '0');
    return '${now.timeZoneName} (UTC$sign$hours:$minutes)';
  }

  @visibleForTesting
  static String formatDateForTest(DateTime date) => _formatDate(date);

  @visibleForTesting
  static String localTimezoneForTest() => _localTimezone();

  @visibleForTesting
  ParsedEvent parseJsonForTest(String raw) => _parseJson(raw);
}
