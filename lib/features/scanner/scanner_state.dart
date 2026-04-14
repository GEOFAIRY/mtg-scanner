import 'package:flutter/foundation.dart';

enum ScannerPhase { searching, tracking, capturing, processing, done }

class ScannerState {
  const ScannerState({
    required this.phase,
    this.lastCardLabel,
    this.inQueue = 0,
    this.confirmed = 0,
    this.paused = false,
    this.torchOn = false,
  });
  final ScannerPhase phase;
  final String? lastCardLabel;
  final int inQueue;
  final int confirmed;
  final bool paused;
  final bool torchOn;

  ScannerState copyWith({
    ScannerPhase? phase,
    String? lastCardLabel,
    int? inQueue,
    int? confirmed,
    bool? paused,
    bool? torchOn,
  }) =>
      ScannerState(
        phase: phase ?? this.phase,
        lastCardLabel: lastCardLabel ?? this.lastCardLabel,
        inQueue: inQueue ?? this.inQueue,
        confirmed: confirmed ?? this.confirmed,
        paused: paused ?? this.paused,
        torchOn: torchOn ?? this.torchOn,
      );
}

class ScannerStateNotifier extends ValueNotifier<ScannerState> {
  ScannerStateNotifier()
      : super(const ScannerState(phase: ScannerPhase.searching));

  void toSearching() =>
      value = value.copyWith(phase: ScannerPhase.searching);
  void toTracking() =>
      value = value.copyWith(phase: ScannerPhase.tracking);
  void toCapturing() =>
      value = value.copyWith(phase: ScannerPhase.capturing);
  void toProcessing() =>
      value = value.copyWith(phase: ScannerPhase.processing);
  void toDone(String label, int newInQueue) => value = value.copyWith(
      phase: ScannerPhase.done,
      lastCardLabel: label,
      inQueue: newInQueue);

  void togglePause() => value = value.copyWith(paused: !value.paused);
  void toggleTorch() => value = value.copyWith(torchOn: !value.torchOn);
}
