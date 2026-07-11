import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

/// App entry point.
///
/// 1. Loads environment variables from `.env` (e.g. Gemini API key).
/// 2. Wraps the app in a [ProviderScope] so Riverpod is available everywhere.
/// 3. Runs [RiimindApp].
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');

  runApp(
    const ProviderScope(
      child: RiimindApp(),
    ),
  );
}
