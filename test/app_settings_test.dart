import 'package:flutter_test/flutter_test.dart';
import 'package:mtg_card_scanner/app_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('defaults value alert threshold to 1.0 when unset', () async {
    final s = await AppSettings.load();
    expect(s.valueAlertThreshold, 1.0);
  });

  test('persists and reloads value alert threshold', () async {
    final s = await AppSettings.load();
    await s.setValueAlertThreshold(4.25);
    expect(s.valueAlertThreshold, 4.25);
    final reloaded = await AppSettings.load();
    expect(reloaded.valueAlertThreshold, 4.25);
  });

  test('notifies listeners on threshold change', () async {
    final s = await AppSettings.load();
    var notified = 0;
    s.addListener(() => notified++);
    await s.setValueAlertThreshold(2.5);
    expect(notified, 1);
  });

  test('ignores non-positive or non-finite thresholds', () async {
    final s = await AppSettings.load();
    await s.setValueAlertThreshold(-1);
    expect(s.valueAlertThreshold, 1.0);
    await s.setValueAlertThreshold(double.nan);
    expect(s.valueAlertThreshold, 1.0);
  });
}

