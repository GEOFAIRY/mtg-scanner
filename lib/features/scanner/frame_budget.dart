/// Tiny time-based throttle. Each call to [tryConsume] returns true if at
/// least [minInterval] has passed since the last true return, in which case
/// the call is "consumed" and the internal clock advances. Calling
/// [tryConsume] with false return does not advance the clock.
///
/// Injecting `now` lets callers (and tests) use a deterministic clock
/// without reaching for `FakeAsync`.
class FrameBudget {
  FrameBudget({required this.minInterval});

  final Duration minInterval;
  DateTime? _lastRun;

  bool tryConsume(DateTime now) {
    final last = _lastRun;
    if (last == null || now.difference(last) >= minInterval) {
      _lastRun = now;
      return true;
    }
    return false;
  }

  void reset() {
    _lastRun = null;
  }
}
