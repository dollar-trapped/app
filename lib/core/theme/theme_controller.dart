import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ThemeController extends ChangeNotifier {
  ThemeController({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const storageKey = 'preferences.theme_mode';
  final FlutterSecureStorage _storage;
  ThemeMode _mode = ThemeMode.light;
  bool _saving = false;
  bool _disposed = false;

  ThemeMode get mode => _mode;
  bool get isDark => _mode == ThemeMode.dark;
  bool get saving => _saving;

  Future<void> load() async {
    try {
      final saved = await _storage.read(key: storageKey);
      if (_disposed) return;
      _mode = saved == 'dark' ? ThemeMode.dark : ThemeMode.light;
      notifyListeners();
    } catch (_) {
      // Storage failure must not prevent opening the app.
    }
  }

  Future<void> setDarkMode(bool enabled) async {
    if (_saving || _disposed || enabled == isDark) return;
    final previous = _mode;
    _mode = enabled ? ThemeMode.dark : ThemeMode.light;
    _saving = true;
    notifyListeners();
    try {
      await _storage.write(key: storageKey, value: enabled ? 'dark' : 'light');
    } catch (_) {
      _mode = previous;
      rethrow;
    } finally {
      _saving = false;
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
