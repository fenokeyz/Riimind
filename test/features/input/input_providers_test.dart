import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riimind/features/input/presentation/providers/input_providers.dart';

void main() {
  test('input text follows typed, imported, and cleared controller values', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final controller = container.read(textControllerProvider);

    expect(container.read(inputTextProvider), isEmpty);

    controller.text = 'Team standup tomorrow at 09:00';
    expect(container.read(inputTextProvider), isNotEmpty);

    controller.text = 'Imported event message';
    expect(container.read(inputTextProvider), 'Imported event message');

    controller.clear();
    expect(container.read(inputTextProvider), isEmpty);
  });
}
