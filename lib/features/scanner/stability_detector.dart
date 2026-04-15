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
  final gray = cv.cvtColor(src, cv.COLOR_BGR2GRAY);
  final blurred = cv.gaussianBlur(gray, (5, 5), 0);
  final edges = cv.canny(blurred, 30, 90);
  final (contours, _) =
      cv.findContours(edges, cv.RETR_LIST, cv.CHAIN_APPROX_SIMPLE);
  final frameArea = src.width * src.height.toDouble();
  RectCandidate? best;
  for (var i = 0; i < contours.length; i++) {
    final c = contours[i];
    final peri = cv.arcLength(c, true);
    if (peri < 50) continue;
    for (final eps in const [0.02, 0.035, 0.05]) {
      final approx = cv.approxPolyDP(c, eps * peri, true);
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
      break;
    }
  }
  return best;
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
    double maxDelta = 0;
    for (final getter in [
      (CardQuad q) => q.tl,
      (CardQuad q) => q.tr,
      (CardQuad q) => q.br,
      (CardQuad q) => q.bl,
    ]) {
      final xs = _history.map((q) => getter(q).x);
      final ys = _history.map((q) => getter(q).y);
      maxDelta = [
        maxDelta,
        xs.reduce((a, b) => a > b ? a : b) - xs.reduce((a, b) => a < b ? a : b),
        ys.reduce((a, b) => a > b ? a : b) - ys.reduce((a, b) => a < b ? a : b),
      ].reduce((a, b) => a > b ? a : b);
    }
    return maxDelta < maxPxJitter;
  }

  CardQuad? get latest => _history.isEmpty ? null : _history.last;
}

