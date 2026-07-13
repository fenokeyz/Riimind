import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riimind/features/input/presentation/widgets/extract_event_button.dart';
import 'package:riimind/features/input/presentation/widgets/input_text_field.dart';
import 'package:riimind/features/parser/models/parsed_event.dart';
import 'package:riimind/features/parser/presentation/providers/parser_providers.dart';
import 'package:riimind/features/parser/services/gemini_service.dart';

void main() {
  testWidgets('retries Gemini after repeated failures', (tester) async {
    final service = _FailingGeminiService();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [geminiServiceProvider.overrideWithValue(service)],
        child: const MaterialApp(
          home: Scaffold(
            body: Column(children: [InputTextField(), ExtractEventButton()]),
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'Lunch tomorrow at 1pm');
    await tester.pump();
    await tester.tap(find.text('Extract Event'));
    await tester.pump();

    expect(service.calls, 1);
    expect(find.text("Couldn't understand this message"), findsOneWidget);
    expect(find.textContaining('Gemini returned an unreadable result.'), findsOneWidget);

    await tester.tap(find.text('Edit message'));
    await tester.pump();
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );

    await tester.tap(find.text('Extract Event'));
    await tester.pump();

    expect(service.calls, 2);
    expect(find.text("Couldn't understand this message"), findsOneWidget);
  });
}

class _FailingGeminiService extends GeminiService {
  _FailingGeminiService() : super(apiKey: 'test-key');

  int calls = 0;

  @override
  Future<ParsedEvent> extractEvent(String text) async {
    calls++;
    throw GeminiParseException('Simulated request failure.');
  }
}
