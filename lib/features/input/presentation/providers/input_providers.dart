import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Holds the multiline text the user is composing on the Home screen.
///
/// This provider owns the [TextEditingController] for the input field. The
/// controller is disposed automatically when the [ProviderContainer] that
/// created it is disposed, which happens when the app shuts down. We do not
/// keep the controller in widget state because [TextEditingController] is not
/// a value type — multiple widget rebuilds would create duplicate listeners.
final textControllerProvider = Provider<TextEditingController>((ref) {
  final controller = TextEditingController();
  ref.onDispose(controller.dispose);
  return controller;
});

/// Read-only convenience for the current text in the input.
///
/// Listens to the controller and rebuilds dependents (e.g. the Extract button
/// and the Clear button) whenever the text changes.
final inputTextProvider = Provider<String>((ref) {
  final controller = ref.watch(textControllerProvider);
  return controller.text;
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
