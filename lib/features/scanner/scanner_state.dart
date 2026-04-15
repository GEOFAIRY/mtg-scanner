import 'package:flutter/foundation.dart';

enum ScannerPhase {
  searching,
  tracking,
  capturing,
  processing,
  matching,
  done,
  noMatch,
  offline,
}

class ScannerState {
  const ScannerState({
    required this.phase,
    this.lastCardLabel,
    this.lastCardPrice,
    this.inQueue = 0,
    this.confirmed = 0,
    this.paused = false,
    this.torchOn = false,
  });
  final ScannerPhase phase;
  final String? lastCardLabel;
  final double? lastCardPrice;
  final int inQueue;
  final int confirmed;
  final bool paused;
  final bool torchOn;

  ScannerState copyWith({
    ScannerPhase? phase,
    String? lastCardLabel,
    double? lastCardPrice,
    int? inQueue,
    int? confirmed,
    bool? paused,
    bool? torchOn,
    bool clearLabel = false,
    bool clearPrice = false,
  }) =>
      ScannerState(
        phase: phase ?? this.phase,
        lastCardLabel: clearLabel ? null : (lastCardLabel ?? this.lastCardLabel),
        lastCardPrice: clearPrice ? null : (lastCardPrice ?? this.lastCardPrice),
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
  void toMatching() => value = value.copyWith(
        phase: ScannerPhase.matching,
        clearLabel: true,
        clearPrice: true,
      );
  void toDone(String label, {required double? price, required int newInQueue}) =>
      value = ScannerState(
        phase: ScannerPhase.done,
        lastCardLabel: label,
        lastCardPrice: price,
        inQueue: newInQueue,
        confirmed: value.confirmed,
        paused: value.paused,
        torchOn: value.torchOn,
      );
  void toNoMatch() => value = value.copyWith(
        phase: ScannerPhase.noMatch,
        clearLabel: true,
        clearPrice: true,
      );
  void toOffline() => value = value.copyWith(
        phase: ScannerPhase.offline,
        clearLabel: true,
        clearPrice: true,
      );

  void togglePause() => value = value.copyWith(paused: !value.paused);
  void toggleTorch() => value = value.copyWith(torchOn: !value.torchOn);
}
