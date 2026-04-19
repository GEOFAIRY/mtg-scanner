// Standalone Dart script: generates a 1024x1024 app icon PNG.
// Run from project root: dart run tool/generate_icon.dart
//
// Icon: deep-purple background with a tilted card silhouette in gold,
// suggestive of an MTG card without actually infringing any trademarks.

import 'dart:io';
import 'dart:math' as math;
import 'package:image/image.dart' as img;

void main() {
  const size = 1024;
  final canvas = img.Image(width: size, height: size);

  // Background: radial-ish gradient from deep purple (center) to near-black.
  final center = (size / 2).round();
  for (var y = 0; y < size; y++) {
    for (var x = 0; x < size; x++) {
      final dx = x - center;
      final dy = y - center;
      final d = math.sqrt(dx * dx + dy * dy) / (size * 0.7);
      final t = d.clamp(0.0, 1.0);
      final r = (60 * (1 - t) + 10 * t).round();
      final g = (20 * (1 - t) + 5 * t).round();
      final b = (90 * (1 - t) + 25 * t).round();
      canvas.setPixelRgb(x, y, r, g, b);
    }
  }

  // Tilted card: rotate a portrait rounded-rectangle ~15° clockwise.
  final cardW = (size * 0.48).round();
  final cardH = (size * 0.67).round();
  final card = img.Image(width: cardW, height: cardH);
  img.fill(card, color: img.ColorRgba8(0, 0, 0, 0));
  _drawRoundedRect(
    card,
    x: 0, y: 0, w: cardW, h: cardH, radius: 60,
    fill: img.ColorRgb8(236, 196, 96), // gold
  );
  _drawRoundedRect(
    card,
    x: 36, y: 36, w: cardW - 72, h: cardH - 72, radius: 40,
    fill: img.ColorRgb8(30, 15, 50), // inner frame
  );

  final rotated = img.copyRotate(card, angle: -15);
  final cx = (size - rotated.width) ~/ 2;
  final cy = (size - rotated.height) ~/ 2;
  img.compositeImage(canvas, rotated, dstX: cx, dstY: cy);

  File('assets/icon/app_icon.png').createSync(recursive: true);
  File('assets/icon/app_icon.png')
      .writeAsBytesSync(img.encodePng(canvas));
  stdout.writeln('wrote assets/icon/app_icon.png (${size}x$size)');
}

void _drawRoundedRect(
  img.Image dst, {
  required int x,
  required int y,
  required int w,
  required int h,
  required int radius,
  required img.Color fill,
}) {
  final r = radius;
  for (var py = 0; py < h; py++) {
    for (var px = 0; px < w; px++) {
      final insideX =
          px < r ? r - px : (px >= w - r ? px - (w - r - 1) : 0);
      final insideY =
          py < r ? r - py : (py >= h - r ? py - (h - r - 1) : 0);
      if (insideX > 0 && insideY > 0) {
        final d = math.sqrt(insideX * insideX + insideY * insideY);
        if (d > r) continue;
      }
      dst.setPixel(x + px, y + py, fill);
    }
  }
}

