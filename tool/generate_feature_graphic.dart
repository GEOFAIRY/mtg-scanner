// Standalone Dart script: generates the 1024x500 Play Store feature
// graphic PNG. Run from project root:
//   dart run tool/generate_feature_graphic.dart
//
// Composition: deep-purple radial background (same hue as the app icon), a
// fanned triple card silhouette on the left in gold/dark-gold, and the
// "MTG SCANNER" wordmark + tagline on the right.

import 'dart:io';
import 'dart:math' as math;
import 'package:image/image.dart' as img;

void main() {
  const width = 1024;
  const height = 500;
  final canvas = img.Image(width: width, height: height);

  _paintBackground(canvas, width, height);
  _paintFannedCards(canvas, width, height);
  _paintWordmark(canvas, width, height);

  File('assets/store/feature_graphic.png')
    ..createSync(recursive: true)
    ..writeAsBytesSync(img.encodePng(canvas));
  stdout.writeln('Wrote assets/store/feature_graphic.png (${width}x$height)');
}

void _paintBackground(img.Image canvas, int w, int h) {
  // Radial-ish gradient, off-center toward the upper-left so the fanned
  // cards sit in the brightest zone.
  final cx = (w * 0.30).round();
  final cy = (h * 0.50).round();
  final maxR = math.sqrt(w * w + h * h.toDouble());
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final dx = x - cx;
      final dy = y - cy;
      final d = math.sqrt(dx * dx + dy * dy) / maxR;
      final t = d.clamp(0.0, 1.0);
      final r = (70 * (1 - t) + 8 * t).round();
      final g = (25 * (1 - t) + 4 * t).round();
      final b = (105 * (1 - t) + 20 * t).round();
      canvas.setPixelRgb(x, y, r, g, b);
    }
  }
}

void _paintFannedCards(img.Image canvas, int w, int h) {
  // Three overlapping portrait cards, fanning out from a shared bottom
  // pivot so the composition reads as "a hand of cards".
  final pivotX = (w * 0.22).toDouble();
  final pivotY = (h * 0.95).toDouble();
  // Card dimensions roughly mirror an MTG aspect ratio at feature-graphic scale.
  const cardW = 180.0;
  const cardH = 250.0;
  final cards = [
    (angleDeg: -22.0, fill: (100, 60, 140), edge: (235, 200, 90)),
    (angleDeg: 0.0, fill: (150, 95, 200), edge: (255, 220, 120)),
    (angleDeg: 22.0, fill: (100, 60, 140), edge: (235, 200, 90)),
  ];
  for (final c in cards) {
    _paintRotatedCard(canvas,
        pivotX: pivotX,
        pivotY: pivotY,
        cardW: cardW,
        cardH: cardH,
        angleDeg: c.angleDeg,
        fillRgb: c.fill,
        edgeRgb: c.edge);
  }
}

void _paintRotatedCard(
  img.Image canvas, {
  required double pivotX,
  required double pivotY,
  required double cardW,
  required double cardH,
  required double angleDeg,
  required (int, int, int) fillRgb,
  required (int, int, int) edgeRgb,
}) {
  final rad = angleDeg * math.pi / 180;
  final cosA = math.cos(rad);
  final sinA = math.sin(rad);
  // The card's local coordinate system: x in [-cardW/2, cardW/2], y in
  // [-cardH, 0]. Its bottom-center sits on (pivotX, pivotY).
  // Iterate over an axis-aligned bounding box of the rotated rectangle and
  // shade pixels that fall inside the card's local bounds.
  final reach = math.sqrt(cardW * cardW / 4 + cardH * cardH) + 4;
  final minX = (pivotX - reach).floor().clamp(0, canvas.width - 1);
  final maxX = (pivotX + reach).ceil().clamp(0, canvas.width - 1);
  final minY = (pivotY - reach).floor().clamp(0, canvas.height - 1);
  final maxY = (pivotY + reach).ceil().clamp(0, canvas.height - 1);
  for (var y = minY; y <= maxY; y++) {
    for (var x = minX; x <= maxX; x++) {
      final dx = x - pivotX;
      final dy = y - pivotY;
      // Inverse-rotate to local space.
      final lx = dx * cosA + dy * sinA;
      final ly = -dx * sinA + dy * cosA;
      if (lx < -cardW / 2 || lx > cardW / 2) continue;
      if (ly < -cardH || ly > 0) continue;
      // Rounded corners: distance from nearest corner center.
      const corner = 14.0;
      final ex = cardW / 2 - corner;
      final ey = -cardH + corner;
      final interiorX = lx.abs() - ex;
      final interiorY = (ly + cardH / 2).abs() - (cardH / 2 - corner);
      if (interiorX > 0 && interiorY > 0) {
        final dist = math.sqrt(interiorX * interiorX + interiorY * interiorY);
        if (dist > corner) continue;
      }
      // Edge band vs interior fill.
      final edgeDistX = (cardW / 2) - lx.abs();
      final edgeDistY = math.min(ly + cardH, -ly);
      final edgeDist = math.min(edgeDistX, edgeDistY);
      final (r, g, b) = edgeDist < 6 ? edgeRgb : fillRgb;
      canvas.setPixelRgb(x, y, r, g, b);
    }
  }
}

void _paintWordmark(img.Image canvas, int w, int h) {
  // img.drawString can paint text but looks rough at this scale. We draw
  // "MTG" in large block letters via hand-placed rectangles so the graphic
  // doesn't depend on a bundled font, then use the built-in bitmap font
  // for the tagline underneath.
  const titleLeft = 480;
  const titleTop = 140;
  _drawBlockText(canvas, 'MTG', titleLeft, titleTop,
      letterH: 120, stroke: 18, rgb: (255, 220, 120));
  _drawBlockText(canvas, 'SCANNER', titleLeft, titleTop + 140,
      letterH: 70, stroke: 10, rgb: (235, 235, 245));
  final tagline = 'Camera · Collection · Moxfield';
  img.drawString(canvas, tagline,
      font: img.arial24,
      x: titleLeft,
      y: titleTop + 240,
      color: img.ColorRgb8(210, 195, 235));
}

/// Minimal 5x7 block-letter typography. Covers the letters we need.
void _drawBlockText(
  img.Image canvas,
  String text,
  int x,
  int y, {
  required int letterH,
  required int stroke,
  required (int, int, int) rgb,
}) {
  final letterW = (letterH * 0.6).round();
  final spacing = (letterW * 0.25).round();
  var cx = x;
  for (final ch in text.split('')) {
    _drawBlockGlyph(canvas, ch, cx, y, letterW, letterH, stroke, rgb);
    cx += letterW + spacing;
  }
}

/// Each glyph rendered from a 5x7 on/off matrix. On cells become filled
/// rectangles scaled to the requested size.
void _drawBlockGlyph(
  img.Image canvas,
  String ch,
  int x,
  int y,
  int w,
  int h,
  int stroke,
  (int, int, int) rgb,
) {
  final matrix = _glyphs[ch.toUpperCase()];
  if (matrix == null) return;
  final cellW = w / 5;
  final cellH = h / 7;
  for (var row = 0; row < 7; row++) {
    final line = matrix[row];
    for (var col = 0; col < 5; col++) {
      if (line[col] != '#') continue;
      final px0 = (x + col * cellW).round();
      final py0 = (y + row * cellH).round();
      final px1 = (x + (col + 1) * cellW).round();
      final py1 = (y + (row + 1) * cellH).round();
      _fillRect(canvas, px0, py0, px1, py1, rgb);
    }
  }
}

void _fillRect(img.Image canvas, int x0, int y0, int x1, int y1,
    (int, int, int) rgb) {
  for (var y = y0; y < y1; y++) {
    if (y < 0 || y >= canvas.height) continue;
    for (var x = x0; x < x1; x++) {
      if (x < 0 || x >= canvas.width) continue;
      canvas.setPixelRgb(x, y, rgb.$1, rgb.$2, rgb.$3);
    }
  }
}

const Map<String, List<String>> _glyphs = {
  'M': [
    '#...#',
    '##.##',
    '#.#.#',
    '#.#.#',
    '#...#',
    '#...#',
    '#...#',
  ],
  'T': [
    '#####',
    '..#..',
    '..#..',
    '..#..',
    '..#..',
    '..#..',
    '..#..',
  ],
  'G': [
    '.###.',
    '#...#',
    '#....',
    '#.###',
    '#...#',
    '#...#',
    '.###.',
  ],
  'S': [
    '.###.',
    '#...#',
    '#....',
    '.###.',
    '....#',
    '#...#',
    '.###.',
  ],
  'C': [
    '.###.',
    '#...#',
    '#....',
    '#....',
    '#....',
    '#...#',
    '.###.',
  ],
  'A': [
    '..#..',
    '.#.#.',
    '#...#',
    '#####',
    '#...#',
    '#...#',
    '#...#',
  ],
  'N': [
    '#...#',
    '##..#',
    '#.#.#',
    '#.#.#',
    '#.#.#',
    '#..##',
    '#...#',
  ],
  'E': [
    '#####',
    '#....',
    '#....',
    '####.',
    '#....',
    '#....',
    '#####',
  ],
  'R': [
    '####.',
    '#...#',
    '#...#',
    '####.',
    '#.#..',
    '#..#.',
    '#...#',
  ],
};
