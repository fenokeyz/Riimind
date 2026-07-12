import 'package:flutter_test/flutter_test.dart';
import 'package:riimind/features/parser/services/gemini_service.dart';

void main() {
  group('GeminiService.extractEvent', () {
    test('throws when the API key is empty (no network call)', () async {
      final service = GeminiService(apiKey: '');
      expect(
        () => service.extractEvent('Lunch with Alex'),
        throwsA(isA<GeminiParseException>()),
      );
    });

    test('throws when the input text is empty', () async {
      final service = GeminiService(apiKey: 'fake-key');
      expect(
        () => service.extractEvent('   '),
        throwsA(isA<GeminiParseException>()),
      );
    });
  });

  group('GeminiService._formatDate', () {
    test('zero-pads single-digit month and day', () {
      final formatted = GeminiService.formatDateForTest(
        DateTime(2026, 1, 5),
      );
      expect(formatted, '2026-01-05');
    });

    test('keeps two-digit components as-is', () {
      final formatted = GeminiService.formatDateForTest(
        DateTime(2026, 12, 31),
      );
      expect(formatted, '2026-12-31');
    });
  });

  group('GeminiService._localTimezone', () {
    test('returns a non-empty string with a UTC offset', () {
      final tz = GeminiService.localTimezoneForTest();
      expect(tz, isNotEmpty);
      expect(tz, contains('UTC'));
    });
  });

  group('GeminiService._parseJson', () {
    final service = GeminiService(apiKey: 'fake-key');

    test('parses a clean JSON object', () {
      final result = service.parseJsonForTest(
        '{"title":"Lunch","description":"","date":"2026-07-13","time":"13:00","location":"Cafe"}',
      );
      expect(result.title, 'Lunch');
      expect(result.date, '2026-07-13');
      expect(result.time, '13:00');
      expect(result.location, 'Cafe');
      expect(result.description, '');
    });

    test('strips ```json code fences', () {
      final result = service.parseJsonForTest('''
```json
{"title":"Lunch","description":"","date":"2026-07-13","time":"13:00","location":"Cafe"}
```
''');
      expect(result.title, 'Lunch');
      expect(result.location, 'Cafe');
    });

    test('strips plain ``` code fences (no language tag)', () {
      final result = service.parseJsonForTest('''
```
{"title":"Lunch","description":"","date":"2026-07-13","time":"13:00","location":"Cafe"}
```
''');
      expect(result.title, 'Lunch');
    });

    test('extracts the first {...} block when wrapped in prose', () {
      final result = service.parseJsonForTest(
        'Here you go: {"title":"Lunch","description":"with Alex","date":"2026-07-13","time":"13:00","location":"Cafe"} — enjoy!',
      );
      expect(result.title, 'Lunch');
      expect(result.description, 'with Alex');
    });

    test('throws GeminiParseException on non-JSON garbage', () {
      expect(
        () => service.parseJsonForTest('this is not json'),
        throwsA(isA<GeminiParseException>()),
      );
    });

    test('throws GeminiParseException when JSON is an array, not an object',
        () {
      expect(
        () => service.parseJsonForTest('[{"title":"Lunch"}]'),
        throwsA(isA<GeminiParseException>()),
      );
    });

    test('throws GeminiParseException on truncated JSON', () {
      expect(
        () => service.parseJsonForTest('{"title":"Lunch"'),
        throwsA(isA<GeminiParseException>()),
      );
    });
  });
}
