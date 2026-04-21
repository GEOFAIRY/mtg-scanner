import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:shared_preferences/shared_preferences.dart';

enum PriceRegion {
  usd(symbol: r'$', label: 'USD (TCGplayer)'),
  eur(symbol: '€', label: 'EUR (Cardmarket)');

  const PriceRegion({required this.symbol, required this.label});
  final String symbol;
  final String label;
}

class AppSettings extends ChangeNotifier {
  AppSettings._(
    this._prefs,
    this._threshold,
    this._themeMode,
    this._debugOverlay,
    this._region,
  );

  static const _thresholdKey = 'value_alert_threshold_usd';
  static const _themeModeKey = 'theme_mode';
  static const _debugOverlayKey = 'debug_overlay_enabled';
  static const _regionKey = 'price_region';
  static const _defaultThreshold = 1.0;
  static const _defaultThemeMode = ThemeMode.dark;
  static const _defaultRegion = PriceRegion.usd;

  final SharedPreferences _prefs;
  double _threshold;
  ThemeMode _themeMode;
  bool _debugOverlay;
  PriceRegion _region;

  double get valueAlertThreshold => _threshold;
  ThemeMode get themeMode => _themeMode;
  bool get debugOverlayEnabled => _debugOverlay;
  PriceRegion get priceRegion => _region;

  static Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getDouble(_thresholdKey);
    final t = (stored != null && stored.isFinite && stored > 0)
        ? stored
        : _defaultThreshold;
    final mode = _decodeThemeMode(prefs.getString(_themeModeKey));
    final debug = prefs.getBool(_debugOverlayKey) ?? false;
    final region = _decodeRegion(prefs.getString(_regionKey));
    return AppSettings._(prefs, t, mode, debug, region);
  }

  Future<void> setValueAlertThreshold(double value) async {
    if (!value.isFinite || value <= 0) return;
    _threshold = value;
    await _prefs.setDouble(_thresholdKey, value);
    notifyListeners();
  }

  Future<void> setDebugOverlayEnabled(bool enabled) async {
    _debugOverlay = enabled;
    await _prefs.setBool(_debugOverlayKey, enabled);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _prefs.setString(_themeModeKey, _encodeThemeMode(mode));
    notifyListeners();
  }

  Future<void> setPriceRegion(PriceRegion region) async {
    _region = region;
    await _prefs.setString(_regionKey, region.name);
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

  static PriceRegion _decodeRegion(String? s) => switch (s) {
        'usd' => PriceRegion.usd,
        'eur' => PriceRegion.eur,
        _ => _defaultRegion,
      };
}
