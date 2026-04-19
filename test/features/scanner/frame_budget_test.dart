import 'package:flutter_test/flutter_test.dart';
import 'package:mtg_card_scanner/features/scanner/frame_budget.dart';

void main() {
  test('first call always runs', () {
    final b = FrameBudget(minInterval: const Duration(milliseconds: 100));
    expect(b.shouldRun(DateTime(2026, 1, 1, 12, 0, 0, 0)), isTrue);
  });

  test('second call within the interval is skipped', () {
    final b = FrameBudget(minInterval: const Duration(milliseconds: 100));
    final t0 = DateTime(2026, 1, 1, 12, 0, 0, 0);
    b.shouldRun(t0);
    expect(b.shouldRun(t0.add(const Duration(milliseconds: 50))), isFalse);
  });

  test('second call after the interval runs', () {
    final b = FrameBudget(minInterval: const Duration(milliseconds: 100));
    final t0 = DateTime(2026, 1, 1, 12, 0, 0, 0);
    b.shouldRun(t0);
    expect(b.shouldRun(t0.add(const Duration(milliseconds: 150))), isTrue);
  });

  test('reset() allows the next call to run immediately', () {
    final b = FrameBudget(minInterval: const Duration(milliseconds: 100));
    final t0 = DateTime(2026, 1, 1, 12, 0, 0, 0);
    b.shouldRun(t0);
    b.reset();
    expect(b.shouldRun(t0.add(const Duration(milliseconds: 10))), isTrue);
  });
}
