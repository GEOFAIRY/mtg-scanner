import 'dart:typed_data';
import 'package:opencv_dart/opencv_dart.dart' as cv;

class FoilSignal {
  const FoilSignal({required this.isFoil, required this.saturationScore});
  final bool isFoil;
  final double saturationScore;
}

FoilSignal detectFoil(
  Uint8List uprightPng, {
  double triggerRatio = 0.04,
  int saturationThreshold = 160,
  int valueThreshold = 180,
  bool strict = false,
}) {
  final src = cv.imdecode(uprightPng, cv.IMREAD_COLOR);
  if (src.isEmpty) {
    src.dispose();
    return const FoilSignal(isFoil: false, saturationScore: 0);
  }
  final h = src.rows;
  final w = src.cols;
  final top = (h * 0.14).round();
  final bottom = (h * 0.90).round();
  final roi = src.region(cv.Rect(0, top, w, bottom - top));
  final hsv = cv.cvtColor(roi, cv.COLOR_BGR2HSV);
  final mask = cv.inRangebyScalar(
    hsv,
    cv.Scalar(0, saturationThreshold.toDouble(), valueThreshold.toDouble(), 0),
    cv.Scalar(179, 255, 255, 0),
  );
  final hot = cv.countNonZero(mask);
  final total = mask.rows * mask.cols;
  final ratio = total == 0 ? 0.0 : hot / total;

  var isFoil = ratio > triggerRatio;
  if (strict && isFoil) {
    final hueBuckets = <int, int>{};
    for (var y = 0; y < mask.rows; y += 4) {
      for (var x = 0; x < mask.cols; x += 4) {
        if (mask.at<int>(y, x) == 0) continue;
        final hue = hsv.at<cv.Vec3b>(y, x).val1;
        final bucket = hue ~/ 30;
        hueBuckets[bucket] = (hueBuckets[bucket] ?? 0) + 1;
      }
    }
    final distinct = hueBuckets.values.where((c) => c >= 3).length;
    if (distinct < 3) isFoil = false;
  }

  src.dispose();
  roi.dispose();
  hsv.dispose();
  mask.dispose();

  return FoilSignal(isFoil: isFoil, saturationScore: ratio);
}
