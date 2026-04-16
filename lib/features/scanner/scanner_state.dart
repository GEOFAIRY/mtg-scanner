import 'package:flutter/foundation.dart';

enum ScannerPhase {
  searching,
  tracking,
  capturing,
  matching,
  noMatch,
  offline,
}

class ScannerState {
  const ScannerState({
    required this.phase,
    this.paused = false,
    this.torchOn = false,
  });
  final ScannerPhase phase;
  final bool paused;
  final bool torchOn;

  ScannerState copyWith({
    ScannerPhase? phase,
    bool? paused,
    bool? torchOn,
  }) =>
      ScannerState(
        phase: phase ?? this.phase,
        paused: paused ?? this.paused,
        torchOn: torchOn ?? this.torchOn,
      );
}

class ScannerStateNotifier extends ValueNotifier<ScannerState> {
  ScannerStateNotifier()
      : super(const ScannerState(phase: ScannerPhase.searching));

  void toSearching() => value = value.copyWith(phase: ScannerPhase.searching);
  void toTracking() => value = value.copyWith(phase: ScannerPhase.tracking);
  void toCapturing() => value = value.copyWith(phase: ScannerPhase.capturing);
  void toMatching() => value = value.copyWith(phase: ScannerPhase.matching);
  void toNoMatch() => value = value.copyWith(phase: ScannerPhase.noMatch);
  void toOffline() => value = value.copyWith(phase: ScannerPhase.offline);

  void togglePause() => value = value.copyWith(paused: !value.paused);
  void toggleTorch() => value = value.copyWith(torchOn: !value.torchOn);
}
