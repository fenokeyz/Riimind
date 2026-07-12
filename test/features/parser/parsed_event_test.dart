import 'package:flutter_test/flutter_test.dart';
import 'package:riimind/features/parser/models/parsed_event.dart';

void main() {
  group('ParsedEvent.fromJson', () {
    test('reads all fields from a complete, well-formed JSON object', () {
      final e = ParsedEvent.fromJson({
        'title': 'Lunch with Alex',
        'description': 'Discuss Q3 roadmap',
        'date': '2026-07-13',
        'time': '13:00',
        'location': 'Cafe Milano',
      });

      expect(e.title, 'Lunch with Alex');
      expect(e.description, 'Discuss Q3 roadmap');
      expect(e.date, '2026-07-13');
      expect(e.time, '13:00');
      expect(e.location, 'Cafe Milano');
    });

    test('uses empty strings for missing keys', () {
      final e = ParsedEvent.fromJson({});
      expect(e.title, '');
      expect(e.description, '');
      expect(e.date, '');
      expect(e.time, '');
      expect(e.location, '');
    });

    test('stringifies non-string values', () {
      final e = ParsedEvent.fromJson({
        'title': 42,
        'description': true,
        'date': null,
        'time': 1300,
        'location': ['a', 'b'],
      });

      expect(e.title, '42');
      expect(e.description, 'true');
      expect(e.date, '');
      expect(e.time, '1300');
      expect(e.location, '[a, b]');
    });

    test('ignores extra keys', () {
      final e = ParsedEvent.fromJson({
        'title': 'Standup',
        'date': '2026-07-13',
        'time': '09:00',
        'attendees': ['Alex', 'Sam'],
        'priority': 'high',
      });

      expect(e.title, 'Standup');
      expect(e.date, '2026-07-13');
      expect(e.time, '09:00');
      expect(e.description, '');
      expect(e.location, '');
    });

    test('trims whitespace from string values', () {
      final e = ParsedEvent.fromJson({
        'title': '  Coffee  ',
        'description': '  with Sam  ',
        'date': ' 2026-07-13 ',
        'time': ' 09:00 ',
        'location': ' Cafe ',
      });

      expect(e.title, 'Coffee');
      expect(e.description, 'with Sam');
      expect(e.date, '2026-07-13');
      expect(e.time, '09:00');
      expect(e.location, 'Cafe');
    });
  });

  group('ParsedEvent.toJson', () {
    test('round-trips through fromJson', () {
      const original = ParsedEvent(
        title: 'Lunch',
        description: 'with Alex',
        date: '2026-07-13',
        time: '13:00',
        location: 'Cafe Milano',
      );

      final restored = ParsedEvent.fromJson(original.toJson());

      expect(restored.title, original.title);
      expect(restored.description, original.description);
      expect(restored.date, original.date);
      expect(restored.time, original.time);
      expect(restored.location, original.location);
    });
  });

  group('ParsedEvent.copyWith', () {
    test('overrides only the named fields', () {
      const original = ParsedEvent(
        title: 'Lunch',
        description: 'with Alex',
        date: '2026-07-13',
        time: '13:00',
        location: 'Cafe Milano',
      );

      final copy = original.copyWith(title: 'Dinner', time: '19:30');

      expect(copy.title, 'Dinner');
      expect(copy.time, '19:30');
      // Untouched fields pass through.
      expect(copy.description, original.description);
      expect(copy.date, original.date);
      expect(copy.location, original.location);
    });
  });
}
