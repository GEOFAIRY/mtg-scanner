# MTG Scanner Plan B3 — Lightweight Foil Heuristic Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Set `foil_guess` on each new scan row to 1 (probably foil) or 0 (probably non-foil) based on a specular-highlight color heuristic of the warped crop, falling back to 0 (not -1) when uncertain. The review queue's manual switch remains the authoritative control — this only pre-checks it.

**Architecture:** A pure-Dart `FoilDetector` takes the upright card PNG and returns `FoilSignal { isFoil, saturationScore }`. It converts the crop to HSV via opencv_dart, masks the artwork region (top 60%, skipping the name band), and counts pixels where both saturation and value exceed threshold. If the high-sat ratio exceeds `triggerRatio` (default 0.08), it votes foil. Wired between `warpToUpright` and `captureFromWarpedCrop` so the scan row persists with the guess.

**Tech Stack:** Flutter, opencv_dart 1.4.5 (`cvtColor` HSV, `inRange`, `countNonZero`), drift via existing ScanWriter.

**Explicit non-goals (deferred):**
- Foil stamp detection (oval / star) — needs reference templates we don't have.
- Multi-frame tilt analysis — scans are single-frame.
- Distinguishing foil-rare from foil-common or promo-star stamps.

**Signal quality expectation:** This fires on *clearly rainbow/high-saturation* highlights typical of Modern foils. It will miss subtle foils and will false-positive on brightly colored artwork (e.g. Hour of Devastation Nicol Bolas, Planeswalker full-arts). Accuracy target: ~70% correct + review-queue switch for the rest.

---

## File Structure

**Create:**
- `lib/features/scanner/foil_detector.dart` — pure function + `FoilSignal` record
- `test/features/scanner/foil_detector_test.dart`

**Modify:**
- `lib/features/scanner/scan_writer.dart` — accept `foilGuess` param (currently hardcoded `-1`)
- `lib/features/scanner/scan_pipeline.dart` — run `FoilDetector` on the upright crop and pass result to writer
- `test/features/scanner/scan_pipeline_test.dart` — assert the pipeline passes a real foilGuess (0 or 1)

---

## Task 1: FoilDetector

**Files:**
- Create: `lib/features/scanner/foil_detector.dart`
- Test: `test/features/scanner/foil_detector_test.dart`

- [ ] **Step 1: Write failing test**

`test/features/scanner/foil_detector_test.dart`:

```dart
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:mtg_scanner/features/scanner/foil_detector.dart';
import 'package:opencv_dart/opencv_dart.dart' as cv;

Uint8List _solidPng({
  required int width,
  required int height,
  required int b,
  required int g,
  required int r,
}) {
  final mat = cv.Mat.zeros(height, width, cv.MatType.CV_8UC3);
  mat.setTo(cv.Scalar(b.toDouble(), g.toDouble(), r.toDouble(), 0));
  final (_, bytes) = cv.imencode('.png', mat);
  mat.dispose();
  return bytes;
}

/// Vertical rainbow stripes — maxes out saturation across the frame.
Uint8List _rainbowPng(int width, int height) {
  final mat = cv.Mat.zeros(height, width, cv.MatType.CV_8UC3);
  for (var x = 0; x < width; x++) {
    final hue = ((x / width) * 180).toInt(); // OpenCV H is 0..179
    // Build HSV then convert one column by painting a rect.
    final col = cv.Mat.zeros(height, 1, cv.MatType.CV_8UC3);
    col.setTo(cv.Scalar(hue.toDouble(), 255, 255, 0));
    final rgb = cv.cvtColor(col, cv.COLOR_HSV2BGR);
    for (var y = 0; y < height; y++) {
      mat.set(y, x, [rgb.at<int>(y, 0), rgb.at<int>(y, 1), rgb.at<int>(y, 2)]);
    }
    col.dispose();
    rgb.dispose();
  }
  final (_, bytes) = cv.imencode('.png', mat);
  mat.dispose();
  return bytes;
}

void main() {
  test('flat neutral gray returns isFoil=false', () {
    final png = _solidPng(width: 200, height: 280, b: 128, g: 128, r: 128);
    final sig = detectFoil(png);
    expect(sig.isFoil, isFalse);
    expect(sig.saturationScore, lessThan(0.05));
  });

  test('rainbow saturation returns isFoil=true', () {
    final png = _rainbowPng(200, 280);
    final sig = detectFoil(png);
    expect(sig.isFoil, isTrue);
    expect(sig.saturationScore, greaterThan(0.5));
  });

  test('single saturated red patch under threshold stays non-foil', () {
    final png = _solidPng(width: 200, height: 280, b: 0, g: 0, r: 255);
    // One solid hue is saturated but has no hue variance; the detector masks
    // to the artwork region and counts high-sat/high-val pixels regardless of
    // hue, so a solid red still trips the simple detector. This test documents
    // that limitation — detectFoil(strict: true) must require hue variance
    // across the region to pass.
    final sig = detectFoil(png, strict: true);
    expect(sig.isFoil, isFalse);
  });
}
```

- [ ] **Step 2: Run to verify fail**

```
powershell -File tool\flutter.ps1 test test/features/scanner/foil_detector_test.dart
```
Expected: FAIL — `detectFoil` undefined.

- [ ] **Step 3: Implement**

`lib/features/scanner/foil_detector.dart`:

```dart
import 'dart:typed_data';
import 'package:opencv_dart/opencv_dart.dart' as cv;

class FoilSignal {
  const FoilSignal({required this.isFoil, required this.saturationScore});
  final bool isFoil;
  final double saturationScore;
}

/// Heuristic foil detection from a single upright card crop.
///
/// [triggerRatio]: fraction of artwork-region pixels that must be
/// high-saturation + high-value to vote "foil".
/// [strict]: when true, also require hue variance across the region
/// (real foils have rainbow highlights spanning hues; solid-color
/// artwork does not).
FoilSignal detectFoil(
  Uint8List uprightPng, {
  double triggerRatio = 0.08,
  int saturationThreshold = 200,
  int valueThreshold = 200,
  bool strict = false,
}) {
  final src = cv.imdecode(uprightPng, cv.IMREAD_COLOR);
  final h = src.height;
  final w = src.width;
  // Artwork region: skip top 14% (name band) and bottom 10% (text/stamp),
  // keep middle 76%.
  final top = (h * 0.14).round();
  final bottom = (h * 0.90).round();
  final roi = src.region(cv.Rect(0, top, w, bottom - top));
  final hsv = cv.cvtColor(roi, cv.COLOR_BGR2HSV);
  final mask = cv.inRange(
    hsv,
    cv.Mat.fromList(1, 3, cv.MatType.CV_8UC1,
        Uint8List.fromList([0, saturationThreshold, valueThreshold])),
    cv.Mat.fromList(1, 3, cv.MatType.CV_8UC1,
        Uint8List.fromList([179, 255, 255])),
  );
  final hot = cv.countNonZero(mask);
  final total = mask.rows * mask.cols;
  final ratio = total == 0 ? 0.0 : hot / total;

  var isFoil = ratio > triggerRatio;
  if (strict && isFoil) {
    // Require at least 3 distinct hue buckets present among hot pixels.
    final hueHist = <int, int>{};
    for (var y = 0; y < mask.rows; y += 4) {
      for (var x = 0; x < mask.cols; x += 4) {
        if (mask.at<int>(y, x) == 0) continue;
        final hue = (hsv.at<int>(y, x * 3)) ~/ 30; // 6 buckets of 30
        hueHist[hue] = (hueHist[hue] ?? 0) + 1;
      }
    }
    final distinct =
        hueHist.values.where((c) => c >= 3).length;
    if (distinct < 3) isFoil = false;
  }

  src.dispose();
  roi.dispose();
  hsv.dispose();
  mask.dispose();

  return FoilSignal(isFoil: isFoil, saturationScore: ratio);
}
```

- [ ] **Step 4: Run test**

```
powershell -File tool\flutter.ps1 test test/features/scanner/foil_detector_test.dart
```
Expected: all PASS. If the opencv_dart API for `inRange`/`Mat.region`/`cvtColor` differs in 1.4.5, check `/mnt/c/Users/Krs19/AppData/Local/Pub/Cache/hosted/pub.dev/opencv_dart-1.4.5/lib/` for correct signatures.

### Known opencv_dart quirks to watch for

- `cv.Rect` — may be `cv.Rect.fromLTWH` or take a positional `(int x, int y, int w, int h)` record. If compile fails, check the package's `src/core/rect.dart`.
- `cv.inRange` in 1.4.5 may accept raw `Scalar` bounds instead of 3-channel Mats. If so, use `cv.Scalar(0, sat, val)` / `cv.Scalar(179, 255, 255)`.
- `Mat.region(rect)` vs `Mat.submat(rect)` — adapt to whichever exists.
- `Mat.at<int>(row, col)` / `Mat.at<int>(row, col*channels)` — multi-channel access may be `Mat.at<cv.Vec3b>(y, x)` instead. If so, read the Vec3b and unpack.

If any of these cause more than 3 adjustment cycles, report BLOCKED with the compile errors.

- [ ] **Step 5: Commit**

```
git add lib/features/scanner/foil_detector.dart test/features/scanner/foil_detector_test.dart
git commit -m "add specular-saturation foil heuristic"
```

---

## Task 2: Wire into pipeline + scan writer

**Files:**
- Modify: `lib/features/scanner/scan_writer.dart`
- Modify: `lib/features/scanner/scan_pipeline.dart`
- Modify: `test/features/scanner/scan_pipeline_test.dart`

- [ ] **Step 1: Update ScanWriter to accept foilGuess**

`lib/features/scanner/scan_writer.dart`:

```dart
import 'package:drift/drift.dart';
import '../../data/db/database.dart';
import 'parsed_ocr.dart';

class ScanWriter {
  ScanWriter(this._db);
  final AppDatabase _db;

  Future<int> insertPending({
    required ParsedOcr parsed,
    required String thumbPath,
    required int foilGuess,
  }) {
    return _db.into(_db.scans).insert(ScansCompanion.insert(
          capturedAt: DateTime.now(),
          rawName: parsed.rawName,
          rawSetCollector: parsed.rawSetCollector,
          confidence: const Value(0.0),
          foilGuess: Value(foilGuess),
          cropImagePath: Value(thumbPath),
        ));
  }
}
```

- [ ] **Step 2: Update pipeline test to assert foilGuess is written**

Edit `test/features/scanner/scan_pipeline_test.dart`. In the one existing test, after the `db.select(db.scans)` assertion block, add:

```dart
expect(row.foilGuess, anyOf(equals(0), equals(1)));
```

This is a smoke assertion — the fake PNG fed into the pipeline is 32 bytes of 0x89, which will fail to decode in opencv_dart. To avoid the pipeline blowing up on bad bytes, the pipeline must catch detector errors and fall back to `foilGuess = 0`. The test thus also verifies the fallback is wired.

- [ ] **Step 3: Run — expect FAIL**

```
powershell -File tool\flutter.ps1 test test/features/scanner/scan_pipeline_test.dart
```
Expected: compile error — `insertPending` missing `foilGuess`.

- [ ] **Step 4: Update pipeline**

Replace `lib/features/scanner/scan_pipeline.dart` with:

```dart
import 'dart:async';
import 'dart:typed_data';
import 'foil_detector.dart';
import 'ocr_runner.dart';
import 'parsed_ocr.dart';
import 'scan_matcher.dart';
import 'scan_writer.dart';
import 'thumbnail_storage.dart';

class ScanPipeline {
  ScanPipeline({
    required this.ocr,
    required this.writer,
    required this.storage,
    required this.matcher,
  });
  final OcrRunner ocr;
  final ScanWriter writer;
  final ThumbnailStorage storage;
  final ScanMatcher matcher;

  static const _nameRegion =
      OcrRegion(left: 0.02, top: 0.02, width: 0.96, height: 0.14);
  static const _setRegion =
      OcrRegion(left: 0.02, top: 0.86, width: 0.60, height: 0.12);

  Future<({int id, String label})> captureFromWarpedCrop(
      Uint8List uprightPng) async {
    final rawName = await ocr.recognizeRegion(uprightPng, _nameRegion);
    final rawSet = await ocr.recognizeRegion(uprightPng, _setRegion);
    final parsed =
        ParsedOcr.from(rawName: rawName, rawSetCollector: rawSet);
    final thumbPath = await storage.save(uprightPng);
    var foilGuess = 0;
    try {
      final sig = detectFoil(uprightPng);
      foilGuess = sig.isFoil ? 1 : 0;
    } catch (_) {
      foilGuess = 0;
    }
    final id = await writer.insertPending(
        parsed: parsed, thumbPath: thumbPath, foilGuess: foilGuess);
    unawaited(matcher.matchAfterInsert(scanId: id, parsed: parsed));
    final label = parsed.name.isNotEmpty ? parsed.name : 'scan';
    return (id: id, label: label);
  }
}
```

- [ ] **Step 5: Run tests — expect PASS**

```
powershell -File tool\flutter.ps1 test test/features/scanner/scan_pipeline_test.dart
powershell -File tool\flutter.ps1 test
```
Expected: all green, including the full suite.

- [ ] **Step 6: Commit**

```
git add lib/features/scanner/scan_writer.dart lib/features/scanner/scan_pipeline.dart test/features/scanner/scan_pipeline_test.dart
git commit -m "wire foil heuristic into pipeline and scan writer"
```

---

## Task 3: On-device smoke + ship

- [ ] **Step 1: Build + install**

```
powershell -File tool\flutter.ps1 build apk --debug
C:\Users\Krs19\AppData\Local\Android\sdk\platform-tools\adb.exe install -r build\app\outputs\flutter-apk\app-debug.apk
```

- [ ] **Step 2: On-device check**

Scan a mix of foil and non-foil cards. For each scan that lands in the review queue at <80% confidence, check the foil switch:
- Obvious rainbow foil: switch should be pre-flipped ON.
- Matte non-foil: switch should stay OFF.

If the detector is firing on non-foils (false positives), the top-level `triggerRatio` in `detectFoil` is too low — bump from 0.08 to 0.12 and rebuild.

If it's missing obvious foils, lower `saturationThreshold` from 200 to 180.

Calibration is an expected iterative step; one or two rebuild cycles is normal.

- [ ] **Step 3: Update RESUME + merge**

Mark B3 complete in `RESUME.md`. Checkout master, merge `plan-b3` with `--no-ff`, commit.

```
git add RESUME.md
git commit -m "mark plan b3 complete"
git checkout master
git merge --no-ff plan-b3 -m "merge plan b3: foil heuristic"
```

---

## Self-Review Notes

- **Spec coverage:** This is the deliberately-lightweight B3 the user picked (option 2). It covers the specular-saturation signal from spec §Foil heuristics. Stamp detection (oval + star) is explicitly out of scope — documented in the plan header. The spec's "both signals agree" confidence bump therefore doesn't apply; foilGuess is binary 0/1.
- **Fallback from -1 to 0:** Plan A's schema allowed -1 (unknown). B3 always writes 0 or 1, so the "-1 unknown" path is effectively dead after this plan. It remains valid (not a breaking change) for any rows written before B3.
- **Pipeline robustness:** If opencv decoding fails on the warped PNG, the pipeline falls back to 0 rather than crashing. Verified by the existing pipeline test which feeds a garbage 32-byte PNG.
- **No placeholders.** Every step has complete code or exact commands.
- **Type consistency:** `FoilSignal { isFoil, saturationScore }` used consistently. `insertPending` now takes `{parsed, thumbPath, foilGuess}` — every call site updated in Task 2 Step 4.
- **Calibration expected:** `triggerRatio` 0.08 and thresholds 200 are best-guess starts. Task 3 Step 2 documents how to adjust.
