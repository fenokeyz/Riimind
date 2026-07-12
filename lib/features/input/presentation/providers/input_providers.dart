import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Current text in the input.
///
/// Updated by [textControllerProvider] whenever its controller changes, so
/// widgets that watch this provider rebuild for both typed and programmatic
/// edits (Import, Paste, and Clear).
final inputTextProvider = StateProvider<String>((ref) => '');

/// Holds the multiline text controller shared by the Home screen actions.
///
/// The controller is disposed automatically when the [ProviderContainer] that
/// created it is disposed. Keeping this instance in a provider ensures the
/// input field, Import, Paste, and Clear actions all use the same controller.
final textControllerProvider = Provider<TextEditingController>((ref) {
  final controller = TextEditingController();
  void syncInputText() {
    ref.read(inputTextProvider.notifier).state = controller.text;
  }

  controller.addListener(syncInputText);
  ref.onDispose(() {
    controller.removeListener(syncInputText);
    controller.dispose();
  });
  return controller;
});

/// Snapshot of the device clipboard, read once on app start.
///
/// Returns the clipboard text if it exists, or `null` if the clipboard is
/// empty / contains non-text data / the platform refused access.
///
/// Treated as immutable from the UI's perspective — re-reading the clipboard
/// is a user-initiated action (tapping Paste).
final clipboardProvider = FutureProvider<String?>((ref) async {
  final data = await Clipboard.getData(Clipboard.kTextPlain);
  return data?.text;
});

/// Tracks whether the user has dismissed the clipboard banner in this app
/// session. Resets to `false` whenever the app is cold-started.
///
/// We use this instead of persistent storage because the clipboard can change
/// between app launches — we only want to hide the banner for the lifetime
/// of this session once the user says "Dismiss".
final clipboardDismissedProvider = StateProvider<bool>((ref) => false);
