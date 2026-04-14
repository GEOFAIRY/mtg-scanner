import 'dart:typed_data';
import 'package:opencv_dart/opencv_dart.dart' as cv;

class CardQuad {
  const CardQuad(this.tl, this.tr, this.br, this.bl);
  final ({double x, double y}) tl, tr, br, bl;
}

Uint8List warpToUpright(
  Uint8List frameBytes, {
  required CardQuad quad,
  int targetWidth = 488,
  int targetHeight = 680,
}) {
  final src = cv.imdecode(frameBytes, cv.IMREAD_COLOR);
  final srcPts = cv.VecPoint2f.fromList([
    cv.Point2f(quad.tl.x, quad.tl.y),
    cv.Point2f(quad.tr.x, quad.tr.y),
    cv.Point2f(quad.br.x, quad.br.y),
    cv.Point2f(quad.bl.x, quad.bl.y),
  ]);
  final dstPts = cv.VecPoint2f.fromList([
    cv.Point2f(0, 0),
    cv.Point2f(targetWidth.toDouble(), 0),
    cv.Point2f(targetWidth.toDouble(), targetHeight.toDouble()),
    cv.Point2f(0, targetHeight.toDouble()),
  ]);
  final m = cv.getPerspectiveTransform2f(srcPts, dstPts);
  final out = cv.warpPerspective(src, m, (targetWidth, targetHeight));
  final (_, png) = cv.imencode('.png', out);
  return png;
}
