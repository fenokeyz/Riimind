import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _proxyUrlKey = 'gemini_proxy_url';

class GeminiSettings {
  const GeminiSettings({this.proxyUrl});

  final String? proxyUrl;

  GeminiSettings copyWith({String? proxyUrl}) {
    return GeminiSettings(proxyUrl: proxyUrl ?? this.proxyUrl);
  }
}

class SettingsNotifier extends StateNotifier<GeminiSettings> {
  SettingsNotifier() : super(const GeminiSettings()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final proxyUrl = prefs.getString(_proxyUrlKey)?.trim();
    state = GeminiSettings(proxyUrl: proxyUrl?.isEmpty ?? true ? null : proxyUrl);
  }

  Future<void> saveProxyUrl(String value) async {
    final prefs = await SharedPreferences.getInstance();
    final normalized = value.trim();

    if (normalized.isEmpty) {
      await prefs.remove(_proxyUrlKey);
      state = const GeminiSettings();
      return;
    }

    await prefs.setString(_proxyUrlKey, normalized);
    state = GeminiSettings(proxyUrl: normalized);
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, GeminiSettings>(
  (ref) => SettingsNotifier(),
);
