import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../input/presentation/providers/input_providers.dart';
import '../../input/presentation/widgets/clipboard_banner.dart';
import '../../input/presentation/widgets/extract_event_button.dart';
import '../../input/presentation/widgets/input_action_row.dart';
import '../../input/presentation/widgets/input_text_field.dart';
import '../../input/services/share_intent_service.dart';

/// Home screen — Feature 2.
///
/// Layout (top to bottom):
/// 1. AppBar
/// 2. SafeArea → scrollable column:
///    - Clipboard banner (only when clipboard has text and not dismissed)
///    - Large multiline input field
///    - Paste / Clear row
///    - Extract Event button
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _shareIntentService = const ShareIntentService();
  StreamSubscription<String>? _shareSubscription;

  @override
  void initState() {
    super.initState();
    _shareSubscription = _shareIntentService.sharedText.listen(
      _applySharedText,
    );
    _loadInitialSharedText();
  }

  Future<void> _loadInitialSharedText() async {
    try {
      final text = await _shareIntentService.initialSharedText();
      if (mounted && text != null) _applySharedText(text);
    } catch (_) {
      // Sharing is optional; the app remains usable if platform delivery fails.
    }
  }

  void _applySharedText(String text) {
    if (!mounted || text.trim().isEmpty) return;
    replaceInputText(ref, text);
    ref.read(clipboardDismissedProvider.notifier).state = true;
  }

  @override
  void dispose() {
    _shareSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Riimind')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipboardBanner(),
              InputTextField(),
              SizedBox(height: 16),
              InputActionRow(),
              SizedBox(height: 16),
              ExtractEventButton(),
            ],
          ),
        ),
      ),
    );
  }
}
