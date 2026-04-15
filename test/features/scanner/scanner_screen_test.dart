import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mtg_scanner/features/scanner/scanner_state.dart';

class _Overlay extends StatelessWidget {
  const _Overlay({required this.state});
  final ScannerState state;
  @override
  Widget build(BuildContext context) {
    if (state.phase == ScannerPhase.done && state.lastCardLabel != null) {
      return Text('\u2713 ${state.lastCardLabel}');
    }
    return const SizedBox.shrink();
  }
}

void main() {
  testWidgets('overlay shows toast after toDone', (t) async {
    final n = ScannerStateNotifier();
    await t.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ValueListenableBuilder<ScannerState>(
          valueListenable: n,
          builder: (_, s, __) => _Overlay(state: s),
        ),
      ),
    ));
    expect(find.textContaining('\u2713'), findsNothing);
    n.toDone('Lightning Bolt', price: null, newInQueue: 1);
    await t.pump();
    expect(find.text('\u2713 Lightning Bolt'), findsOneWidget);
  });

  testWidgets('pause flag flips with togglePause', (t) async {
    final n = ScannerStateNotifier();
    expect(n.value.paused, isFalse);
    n.togglePause();
    expect(n.value.paused, isTrue);
    n.togglePause();
    expect(n.value.paused, isFalse);
  });

  test('toMatching sets phase to matching and clears label/price', () {
    final n = ScannerStateNotifier();
    n.toDone('Old', price: 1.0, newInQueue: 1);
    n.toMatching();
    expect(n.value.phase, ScannerPhase.matching);
    expect(n.value.lastCardLabel, isNull);
    expect(n.value.lastCardPrice, isNull);
  });

  test('toDone stores label and price', () {
    final n = ScannerStateNotifier();
    n.toDone('Lightning Bolt', price: 2.5, newInQueue: 3);
    expect(n.value.phase, ScannerPhase.done);
    expect(n.value.lastCardLabel, 'Lightning Bolt');
    expect(n.value.lastCardPrice, 2.5);
    expect(n.value.inQueue, 3);
  });

  test('toNoMatch sets phase to noMatch with no label', () {
    final n = ScannerStateNotifier();
    n.toNoMatch();
    expect(n.value.phase, ScannerPhase.noMatch);
    expect(n.value.lastCardLabel, isNull);
  });

  test('toOffline sets phase to offline', () {
    final n = ScannerStateNotifier();
    n.toOffline();
    expect(n.value.phase, ScannerPhase.offline);
  });
}
