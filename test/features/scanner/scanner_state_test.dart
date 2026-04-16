import 'package:flutter_test/flutter_test.dart';
import 'package:mtg_card_scanner/features/scanner/scanner_state.dart';

void main() {
  test('starts in searching phase with flags off', () {
    final n = ScannerStateNotifier();
    expect(n.value.phase, ScannerPhase.searching);
    expect(n.value.paused, isFalse);
    expect(n.value.torchOn, isFalse);
  });

  test('phase transitions do not touch torch or paused', () {
    final n = ScannerStateNotifier();
    n.togglePause();
    n.toggleTorch();
    n.toMatching();
    expect(n.value.phase, ScannerPhase.matching);
    expect(n.value.paused, isTrue);
    expect(n.value.torchOn, isTrue);
  });

  test('togglePause and toggleTorch flip independently', () {
    final n = ScannerStateNotifier();
    n.togglePause();
    expect(n.value.paused, isTrue);
    expect(n.value.torchOn, isFalse);
    n.toggleTorch();
    expect(n.value.torchOn, isTrue);
    n.togglePause();
    expect(n.value.paused, isFalse);
    expect(n.value.torchOn, isTrue);
  });

  test('each phase helper sets the corresponding phase', () {
    final n = ScannerStateNotifier();
    n.toTracking();
    expect(n.value.phase, ScannerPhase.tracking);
    n.toCapturing();
    expect(n.value.phase, ScannerPhase.capturing);
    n.toMatching();
    expect(n.value.phase, ScannerPhase.matching);
    n.toNoMatch();
    expect(n.value.phase, ScannerPhase.noMatch);
    n.toOffline();
    expect(n.value.phase, ScannerPhase.offline);
    n.toSearching();
    expect(n.value.phase, ScannerPhase.searching);
  });
}
