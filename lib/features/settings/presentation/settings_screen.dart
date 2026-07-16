import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/settings_providers.dart';

/// Minimal settings surface for the v1.0 release.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final TextEditingController _proxyController;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider);
    _proxyController = TextEditingController(text: settings.proxyUrl ?? '');
  }

  @override
  void dispose() {
    _proxyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Gemini configuration',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Text(
                'If your API key is rate-limited, point Riimind at a backend proxy endpoint that forwards Gemini requests securely.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _proxyController,
                decoration: const InputDecoration(
                  labelText: 'Proxy URL',
                  hintText: 'https://your-proxy.example/api/gemini',
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () async {
                  final messenger = ScaffoldMessenger.maybeOf(context);
                  await ref
                      .read(settingsProvider.notifier)
                      .saveProxyUrl(_proxyController.text);
                  if (!mounted) return;
                  messenger?.showSnackBar(
                    const SnackBar(
                      content: Text('Proxy setting saved.'),
                    ),
                  );
                },
                icon: const Icon(Icons.save_rounded),
                label: const Text('Save proxy URL'),
              ),
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current status',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        settings.proxyUrl == null
                            ? 'Using direct Gemini SDK access.'
                            : 'Using proxy: ${settings.proxyUrl}',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
