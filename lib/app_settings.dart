import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings extends ChangeNotifier {
  AppSettings._(this._prefs, this._threshold);

  static const _thresholdKey = 'value_alert_threshold_usd';
  static const _defaultThreshold = 1.0;

  final SharedPreferences _prefs;
  double _threshold;

  double get valueAlertThreshold => _threshold;

  static Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getDouble(_thresholdKey);
    final t = (stored != null && stored.isFinite && stored > 0)
        ? stored
        : _defaultThreshold;
    return AppSettings._(prefs, t);
  }

  Future<void> setValueAlertThreshold(double value) async {
    if (!value.isFinite || value <= 0) return;
    _threshold = value;
    await _prefs.setDouble(_thresholdKey, value);
    notifyListeners();
  }
}

