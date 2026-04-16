import 'dart:typed_data';
import 'package:opencv_dart/opencv_dart.dart' as cv;

class CardQuad {
  const CardQuad(this.tl, this.tr, this.br, this.bl);
  final ({double x, double y}) tl, tr, br, bl;
}

double _dist(({double x, double y}) a, ({double x, double y}) b) {
  final dx = a.x - b.x;
  final dy = a.y - b.y;
  return (dx * dx + dy * dy);
}

Uint8List warpToUpright(
  Uint8List frameBytes, {
  required CardQuad quad,
  int targetWidth = 488,
  int targetHeight = 680,
}) {
  final src = cv.imdecode(frameBytes, cv.IMREAD_COLOR);
  try {
    return warpToUprightOnMat(src,
        quad: quad, targetWidth: targetWidth, targetHeight: targetHeight);
  } finally {
    src.dispose();
  }
}

/// Warp an already-decoded BGR [src] Mat into an upright card PNG. Caller
/// owns [src] and its lifecycle — lets the scanner skip the
/// imencode/imdecode round-trip from the frame loop.
Uint8List warpToUprightOnMat(
  cv.Mat src, {
  required CardQuad quad,
  int targetWidth = 488,
  int targetHeight = 680,
}) {
  // MTG cards are portrait. If the detected quad is landscape (top edge
  // longer than left edge), rotate the corner labels 90° CW so the warp
  // output is upright in portrait regardless of how the camera saw it.
  final topLen = _dist(quad.tl, quad.tr);
  final leftLen = _dist(quad.tl, quad.bl);
  final useLandscape = topLen > leftLen;
  final (p0, p1, p2, p3) = useLandscape
      ? (quad.bl, quad.tl, quad.tr, quad.br)
      : (quad.tl, quad.tr, quad.br, quad.bl);
  final srcPts = cv.VecPoint2f.fromList([
    cv.Point2f(p0.x, p0.y),
    cv.Point2f(p1.x, p1.y),
    cv.Point2f(p2.x, p2.y),
    cv.Point2f(p3.x, p3.y),
  ]);
  final dstPts = cv.VecPoint2f.fromList([
    cv.Point2f(0, 0),
    cv.Point2f(targetWidth.toDouble(), 0),
    cv.Point2f(targetWidth.toDouble(), targetHeight.toDouble()),
    cv.Point2f(0, targetHeight.toDouble()),
  ]);
  final m = cv.getPerspectiveTransform2f(srcPts, dstPts);
  final out = cv.warpPerspective(src, m, (targetWidth, targetHeight));
  try {
    final (_, png) = cv.imencode('.png', out);
    return png;
  } finally {
    srcPts.dispose();
    dstPts.dispose();
    m.dispose();
    out.dispose();
  }
}
