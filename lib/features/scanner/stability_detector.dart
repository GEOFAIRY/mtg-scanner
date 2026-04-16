import 'dart:typed_data';
import 'package:opencv_dart/opencv_dart.dart' as cv;
import 'perspective_correct.dart';

class RectCandidate {
  const RectCandidate(this.quad, this.areaPx);
  final CardQuad quad;
  final double areaPx;
}

RectCandidate? detectCardRect(
  Uint8List frameBytes, {
  double minAreaFraction = 0.06,
}) {
  final src = cv.imdecode(frameBytes, cv.IMREAD_COLOR);
  try {
    return _detect(src, minAreaFraction: minAreaFraction);
  } finally {
    src.dispose();
  }
}

/// Detect on an already-decoded Mat. Caller owns [src] and its lifecycle —
/// used by the scanner screen to skip the JPEG round-trip when it already
/// has a BGR Mat in hand.
RectCandidate? detectCardRectOnMat(
  cv.Mat src, {
  double minAreaFraction = 0.06,
}) =>
    _detect(src, minAreaFraction: minAreaFraction);

RectCandidate? _detect(cv.Mat src, {required double minAreaFraction}) {
  final gray = cv.cvtColor(src, cv.COLOR_BGR2GRAY);
  final blurred = cv.gaussianBlur(gray, (5, 5), 0);
  final edges = cv.canny(blurred, 30, 90);
  final (contours, _) =
      cv.findContours(edges, cv.RETR_LIST, cv.CHAIN_APPROX_SIMPLE);
  try {
    final frameArea = src.width * src.height.toDouble();
    RectCandidate? best;
    for (var i = 0; i < contours.length; i++) {
      final c = contours[i];
      final peri = cv.arcLength(c, true);
      if (peri < 50) continue;
      for (final eps in const [0.02, 0.035, 0.05]) {
        final approx = cv.approxPolyDP(c, eps * peri, true);
        try {
          if (approx.length != 4) continue;
          final area = cv.contourArea(approx);
          if (area < frameArea * minAreaFraction) continue;
          if (best != null && area <= best.areaPx) continue;
          final points = <({double x, double y})>[
            for (var j = 0; j < 4; j++)
              (x: approx[j].x.toDouble(), y: approx[j].y.toDouble()),
          ];
          points.sort((a, b) => (a.y + a.x).compareTo(b.y + b.x));
          final tl = points.first, br = points.last;
          final mid = [points[1], points[2]]..sort((a, b) => a.x.compareTo(b.x));
          final bl = mid.first, tr = mid.last;
          best = RectCandidate(CardQuad(tl, tr, br, bl), area);
        } finally {
          approx.dispose();
        }
        break;
      }
    }
    return best;
  } finally {
    gray.dispose();
    blurred.dispose();
    edges.dispose();
    contours.dispose();
  }
}

class StabilityTracker {
  StabilityTracker({this.windowSize = 3, this.maxPxJitter = 25.0});
  final int windowSize;
  final double maxPxJitter;
  final List<CardQuad> _history = [];

  void push(CardQuad q) {
    _history.add(q);
    if (_history.length > windowSize) _history.removeAt(0);
  }

  void reset() => _history.clear();

  bool get isStable {
    if (_history.length < windowSize) return false;
    // Hot path — inline the four corners instead of allocating closures.
    double maxDelta = 0;
    maxDelta = _cornerSpan(maxDelta, (q) => q.tl.x, (q) => q.tl.y);
    maxDelta = _cornerSpan(maxDelta, (q) => q.tr.x, (q) => q.tr.y);
    maxDelta = _cornerSpan(maxDelta, (q) => q.br.x, (q) => q.br.y);
    maxDelta = _cornerSpan(maxDelta, (q) => q.bl.x, (q) => q.bl.y);
    return maxDelta < maxPxJitter;
  }

  double _cornerSpan(double acc, double Function(CardQuad) getX,
      double Function(CardQuad) getY) {
    var minX = double.infinity, maxX = double.negativeInfinity;
    var minY = double.infinity, maxY = double.negativeInfinity;
    for (final q in _history) {
      final x = getX(q), y = getY(q);
      if (x < minX) minX = x;
      if (x > maxX) maxX = x;
      if (y < minY) minY = y;
      if (y > maxY) maxY = y;
    }
    final dx = maxX - minX;
    final dy = maxY - minY;
    var m = acc;
    if (dx > m) m = dx;
    if (dy > m) m = dy;
    return m;
  }

  CardQuad? get latest => _history.isEmpty ? null : _history.last;
}
