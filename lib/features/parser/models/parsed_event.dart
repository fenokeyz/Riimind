/// Parsed event extracted from a natural-language message by Gemini.
///
/// Simple immutable Dart class — no codegen. Fields are nullable-free on the
/// outside (empty string for missing) so call sites don't have to null-check.
class ParsedEvent {
  final String title;
  final String description;
  final String date; // ISO 8601: YYYY-MM-DD. Empty if unknown.
  final String time; // 24h HH:mm. Empty if unknown.
  final String location;

  const ParsedEvent({
    required this.title,
    required this.description,
    required this.date,
    required this.time,
    required this.location,
  });

  /// Whether Gemini could not identify any usable event detail.
  bool get isEmpty =>
      title.isEmpty &&
      description.isEmpty &&
      date.isEmpty &&
      time.isEmpty &&
      location.isEmpty;

  /// Build from the JSON returned by Gemini. Tolerant of:
  /// - missing keys (becomes empty string)
  /// - non-string values (stringified)
  /// - extra keys (ignored)
  ///
  factory ParsedEvent.fromJson(Map<String, dynamic> json) {
    String readString(String key) {
      final v = json[key];
      if (v == null) return '';
      if (v is String) return v;
      return v.toString();
    }

    return ParsedEvent(
      title: readString('title').trim(),
      description: readString('description').trim(),
      date: readString('date').trim(),
      time: readString('time').trim(),
      location: readString('location').trim(),
    );
  }

  /// Serialise to a plain map. Not currently used for storage, but exposed
  /// so the model is symmetric and tests can round-trip it.
  Map<String, dynamic> toJson() => {
    'title': title,
    'description': description,
    'date': date,
    'time': time,
    'location': location,
  };

  ParsedEvent copyWith({
    String? title,
    String? description,
    String? date,
    String? time,
    String? location,
  }) {
    return ParsedEvent(
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      time: time ?? this.time,
      location: location ?? this.location,
    );
  }
}
