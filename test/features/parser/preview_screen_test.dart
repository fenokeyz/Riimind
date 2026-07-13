import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:riimind/features/parser/models/parsed_event.dart';
import 'package:riimind/features/parser/presentation/preview_screen.dart';

void main() {
  testWidgets('allows editing all extracted event fields', (tester) async {
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const PreviewScreen(
                event: ParsedEvent(
                  title: 'Lunch',
                  description: 'With Sam',
                  date: '2026-07-14',
                  time: '12:00',
                  location: 'Cafe',
                ),
              ),
            ),
          ],
        ),
      ),
    );

    expect(find.text('Lunch'), findsOneWidget);
    await tester.enterText(find.byType(TextField).at(0), 'Team lunch');
    await tester.enterText(find.byType(TextField).at(1), 'New cafe');
    await tester.enterText(find.byType(TextField).at(2), 'Planning session');

    expect(find.text('Team lunch'), findsOneWidget);
    expect(find.text('New cafe'), findsOneWidget);
    expect(find.text('Planning session'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Continue'), findsOneWidget);
  });
}
