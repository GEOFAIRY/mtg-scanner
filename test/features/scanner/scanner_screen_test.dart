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
    n.toDone('Lightning Bolt', 1);
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
}
