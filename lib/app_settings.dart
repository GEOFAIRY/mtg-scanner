import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings extends ChangeNotifier {
  AppSettings._(this._prefs, this._threshold, this._themeMode);

  static const _thresholdKey = 'value_alert_threshold_usd';
  static const _themeModeKey = 'theme_mode';
  static const _defaultThreshold = 1.0;
  static const _defaultThemeMode = ThemeMode.dark;

  final SharedPreferences _prefs;
  double _threshold;
  ThemeMode _themeMode;

  double get valueAlertThreshold => _threshold;
  ThemeMode get themeMode => _themeMode;

  static Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getDouble(_thresholdKey);
    final t = (stored != null && stored.isFinite && stored > 0)
        ? stored
        : _defaultThreshold;
    final mode = _decodeThemeMode(prefs.getString(_themeModeKey));
    return AppSettings._(prefs, t, mode);
  }

  Future<void> setValueAlertThreshold(double value) async {
    if (!value.isFinite || value <= 0) return;
    _threshold = value;
    await _prefs.setDouble(_thresholdKey, value);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _prefs.setString(_themeModeKey, _encodeThemeMode(mode));
    notifyListeners();
  }

  static String _encodeThemeMode(ThemeMode mode) => switch (mode) {
        ThemeMode.system => 'system',
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
      };

  static ThemeMode _decodeThemeMode(String? s) => switch (s) {
        'system' => ThemeMode.system,
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => _defaultThemeMode,
      };
}
