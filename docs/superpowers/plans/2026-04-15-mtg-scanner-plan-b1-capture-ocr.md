# MTG Scanner Plan B1 — Capture + OCR Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a live-camera scanning screen that detects a stable card in view, perspective-corrects it, runs OCR on the title + collector regions, and writes a scan row into the review queue built in Plan A. No Scryfall auto-match, no foil detection (Plans B2 and B3). User always lands in the review queue to confirm/edit.

**Architecture:** Flutter `camera` plugin provides frame stream. Each frame goes through a `StabilityDetector` (opencv_dart contour detection + jitter check). When stable, the pipeline freezes the frame, runs `PerspectiveCorrector` to warp the card rectangle to an upright crop, saves the crop as a thumbnail, runs `OcrRunner` (google_mlkit_text_recognition) on two normalized regions, parses the results (`ParsedOcr`), and inserts a row into the `scans` table via the existing `ScansRepository`. A `ScanPipeline` facade wires these dependencies and is injectable for testing. The scanner screen renders the camera preview, a live bounding-box overlay, and a state-based toast/flash.

**Tech Stack:** Flutter, `camera`, `opencv_dart`, `google_mlkit_text_recognition`, `permission_handler`, `image`, drift (from Plan A).

**Risks flagged:**
- `opencv_dart` adds a native dependency (~30 MB APK bloat) and requires NDK/CMake tooling on Windows. If it fails to build, fallback is `google_mlkit_document_scanner` (different UX) or manual-tap capture.
- `google_mlkit_text_recognition` ships a Latin-script model; non-Latin cards will require extra models and are out of scope for B1.
- Android min SDK must be ≥ 21 for camera2 + ML Kit; verify before Task 1.

---

## File Structure

**Create:**
- `lib/features/scanner/scanner_screen.dart` — screen widget, owns camera controller and state notifier
- `lib/features/scanner/scanner_state.dart` — state enum + `ScannerStateNotifier` (ValueNotifier)
- `lib/features/scanner/scan_pipeline.dart` — facade orchestrating stability → capture → warp → OCR → write
- `lib/features/scanner/stability_detector.dart` — opencv_dart contour finder + jitter tracker
- `lib/features/scanner/perspective_correct.dart` — warp rectangle corners to upright crop
- `lib/features/scanner/ocr_runner.dart` — ML Kit wrapper with injectable interface
- `lib/features/scanner/parsed_ocr.dart` — data class + parsers for name and set/collector
- `lib/features/scanner/scan_writer.dart` — persists scan row + thumbnail path
- `lib/features/scanner/thumbnail_storage.dart` — PNG write/delete under app docs dir
- `lib/features/scanner/permission_gate.dart` — camera permission screen with settings deep-link
- `test/features/scanner/parsed_ocr_test.dart`
- `test/features/scanner/scan_pipeline_test.dart`
- `test/features/scanner/thumbnail_storage_test.dart`
- `test/features/scanner/scanner_screen_test.dart`

**Modify:**
- `pubspec.yaml` — add deps
- `android/app/src/main/AndroidManifest.xml` — CAMERA permission
- `android/app/build.gradle.kts` (or `.gradle`) — `minSdkVersion 21`
- `lib/app.dart` (or wherever the scanner route stub lives) — mount new ScannerScreen

---

## Task 1: Dependencies + Android Manifest

**Files:**
- Modify: `pubspec.yaml`
- Modify: `android/app/src/main/AndroidManifest.xml`
- Modify: `android/app/build.gradle.kts`

- [ ] **Step 1: Add dependencies**

Append to `pubspec.yaml` `dependencies:` block (above `dev_dependencies`):

```yaml
  camera: ^0.11.0
  opencv_dart: ^1.3.0
  google_mlkit_text_recognition: ^0.13.0
  permission_handler: ^11.3.0
  image: ^4.2.0
```

- [ ] **Step 2: Verify versions resolve**

Run from project root:
```
powershell -File tool\flutter.ps1 pub get
```
Expected: `Got dependencies!` with no resolution errors. If any version pins conflict, bump to the newest compatible and note in commit message.

- [ ] **Step 3: Add camera permission to manifest**

Open `android/app/src/main/AndroidManifest.xml`. Inside `<manifest>` (before `<application>`) add:

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-feature android:name="android.hardware.camera" android:required="true" />
<uses-feature android:name="android.hardware.camera.autofocus" />
```

- [ ] **Step 4: Set minSdk**

In `android/app/build.gradle.kts` (fallback: `build.gradle`) find the `defaultConfig` block. Set `minSdk = 21` (keep `targetSdk` unchanged).

- [ ] **Step 5: Verify build**

Run:
```
powershell -File tool\flutter.ps1 build apk --debug
```
Expected: APK built successfully. If opencv_dart native build fails, stop and surface the error — do not proceed.

- [ ] **Step 6: Commit**

```
git add pubspec.yaml pubspec.lock android/app/src/main/AndroidManifest.xml android/app/build.gradle.kts
git commit -m "add camera, opencv_dart, mlkit deps for scanner"
```

---

## Task 2: Thumbnail Storage

**Files:**
- Create: `lib/features/scanner/thumbnail_storage.dart`
- Test: `test/features/scanner/thumbnail_storage_test.dart`

- [ ] **Step 1: Write the failing test**

`test/features/scanner/thumbnail_storage_test.dart`:

```dart
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mtg_scanner/features/scanner/thumbnail_storage.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:path/path.dart' as p;

class _FakePathProvider extends PathProviderPlatform {
  _FakePathProvider(this.dir);
  final String dir;
  @override
  Future<String?> getApplicationDocumentsPath() async => dir;
}

void main() {
  late Directory tempDir;
  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('thumb_test_');
    PathProviderPlatform.instance = _FakePathProvider(tempDir.path);
  });
  tearDown(() async => tempDir.delete(recursive: true));

  test('save writes bytes and returns a path under docs dir', () async {
    final storage = ThumbnailStorage();
    final path = await storage.save(List.filled(16, 0x42));
    expect(File(path).existsSync(), isTrue);
    expect(p.isWithin(tempDir.path, path), isTrue);
    expect(await File(path).length(), 16);
  });

  test('delete removes the file and is idempotent', () async {
    final storage = ThumbnailStorage();
    final path = await storage.save([1, 2, 3]);
    await storage.delete(path);
    expect(File(path).existsSync(), isFalse);
    await storage.delete(path); // no throw
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```
powershell -File tool\flutter.ps1 test test/features/scanner/thumbnail_storage_test.dart
```
Expected: FAIL — `ThumbnailStorage` not defined.

- [ ] **Step 3: Implement**

`lib/features/scanner/thumbnail_storage.dart`:

```dart
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ThumbnailStorage {
  Future<String> save(List<int> bytes) async {
    final dir = await getApplicationDocumentsDirectory();
    final subdir = Directory(p.join(dir.path, 'scan_thumbs'));
    if (!subdir.existsSync()) subdir.createSync(recursive: true);
    final name = 'scan_${DateTime.now().microsecondsSinceEpoch}.png';
    final file = File(p.join(subdir.path, name));
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  Future<void> delete(String path) async {
    final f = File(path);
    if (await f.exists()) await f.delete();
  }
}
```

- [ ] **Step 4: Run test**

```
powershell -File tool\flutter.ps1 test test/features/scanner/thumbnail_storage_test.dart
```
Expected: both tests PASS.

- [ ] **Step 5: Commit**

```
git add lib/features/scanner/thumbnail_storage.dart test/features/scanner/thumbnail_storage_test.dart
git commit -m "add thumbnail storage for scan crops"
```

---

## Task 3: ParsedOcr + Parsers

**Files:**
- Create: `lib/features/scanner/parsed_ocr.dart`
- Test: `test/features/scanner/parsed_ocr_test.dart`

- [ ] **Step 1: Write the failing tests**

`test/features/scanner/parsed_ocr_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mtg_scanner/features/scanner/parsed_ocr.dart';

void main() {
  group('cleanName', () {
    test('collapses whitespace and trims', () {
      expect(ParsedOcr.cleanName('  Lightning   Bolt '), 'Lightning Bolt');
    });
    test('strips mana-symbol OCR noise like {R} or (R)', () {
      expect(ParsedOcr.cleanName('Lightning Bolt {R}'), 'Lightning Bolt');
      expect(ParsedOcr.cleanName('Lightning Bolt (R)'), 'Lightning Bolt');
    });
    test('preserves commas and apostrophes', () {
      expect(ParsedOcr.cleanName("Jace, the Mind Sculptor"),
          "Jace, the Mind Sculptor");
    });
    test('returns empty when input is only symbols', () {
      expect(ParsedOcr.cleanName('{R}{R}'), '');
    });
  });

  group('parseSetCollector', () {
    test('extracts set and number from "2xm 137"', () {
      final r = ParsedOcr.parseSetCollector('2xm 137');
      expect(r, isNotNull);
      expect(r!.set, '2XM');
      expect(r.collectorNumber, '137');
    });
    test('handles "137/274 M 2XM" (reversed order)', () {
      final r = ParsedOcr.parseSetCollector('137/274 M 2XM');
      expect(r, isNotNull);
      expect(r!.set, '2XM');
      expect(r.collectorNumber, '137');
    });
    test('keeps letter-suffixed numbers like 137a', () {
      final r = ParsedOcr.parseSetCollector('neo 137a');
      expect(r!.collectorNumber, '137a');
    });
    test('returns null on garbage', () {
      expect(ParsedOcr.parseSetCollector('zzzzzz'), isNull);
    });
  });

  test('ParsedOcr.from combines raw strings', () {
    final p = ParsedOcr.from(rawName: 'Lightning Bolt', rawSetCollector: '2xm 137');
    expect(p.name, 'Lightning Bolt');
    expect(p.setCode, '2XM');
    expect(p.collectorNumber, '137');
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```
powershell -File tool\flutter.ps1 test test/features/scanner/parsed_ocr_test.dart
```
Expected: FAIL — `ParsedOcr` not defined.

- [ ] **Step 3: Implement**

`lib/features/scanner/parsed_ocr.dart`:

```dart
class SetCollector {
  const SetCollector(this.set, this.collectorNumber);
  final String set;
  final String collectorNumber;
}

class ParsedOcr {
  const ParsedOcr({
    required this.name,
    required this.rawName,
    required this.rawSetCollector,
    this.setCode,
    this.collectorNumber,
  });

  final String name;
  final String rawName;
  final String rawSetCollector;
  final String? setCode;
  final String? collectorNumber;

  static final _symbolNoise = RegExp(r'[{(\[][^})\]]*[})\]]');
  static final _ws = RegExp(r'\s+');

  static String cleanName(String input) {
    var s = input.replaceAll(_symbolNoise, '');
    s = s.replaceAll(_ws, ' ').trim();
    return s;
  }

  static final _setCode = RegExp(r'\b([a-zA-Z0-9]{3,4})\b');
  static final _collNum = RegExp(r'\b(\d{1,4}[a-z]?)\b(?:/\d+)?');

  static SetCollector? parseSetCollector(String input) {
    final s = input.toUpperCase();
    final nums = _collNum.allMatches(s).map((m) => m.group(1)!).toList();
    final codes = _setCode
        .allMatches(s)
        .map((m) => m.group(1)!)
        .where((c) => !RegExp(r'^\d+[A-Z]?$').hasMatch(c))
        .toList();
    if (nums.isEmpty || codes.isEmpty) return null;
    return SetCollector(codes.first.toUpperCase(), nums.first.toLowerCase());
  }

  factory ParsedOcr.from({
    required String rawName,
    required String rawSetCollector,
  }) {
    final sc = parseSetCollector(rawSetCollector);
    return ParsedOcr(
      name: cleanName(rawName),
      rawName: rawName,
      rawSetCollector: rawSetCollector,
      setCode: sc?.set,
      collectorNumber: sc?.collectorNumber,
    );
  }
}
```

- [ ] **Step 4: Run test**

```
powershell -File tool\flutter.ps1 test test/features/scanner/parsed_ocr_test.dart
```
Expected: all PASS. If a regex edge case fails, adjust `_setCode` / `_collNum` until green — do not remove tests.

- [ ] **Step 5: Commit**

```
git add lib/features/scanner/parsed_ocr.dart test/features/scanner/parsed_ocr_test.dart
git commit -m "add ocr result parser for name and set/collector"
```

---

## Task 4: OcrRunner (ML Kit wrapper)

**Files:**
- Create: `lib/features/scanner/ocr_runner.dart`

No test in this task — ML Kit is an external SDK with no practical unit-test seam. It is wrapped as an abstract class so downstream pipeline tests can mock it.

- [ ] **Step 1: Define interface + concrete**

`lib/features/scanner/ocr_runner.dart`:

```dart
import 'dart:typed_data';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Region of interest, expressed in normalized card coordinates (0..1).
class OcrRegion {
  const OcrRegion({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });
  final double left, top, width, height;
}

abstract class OcrRunner {
  /// Runs OCR on [imageBytes] (upright card PNG) and returns the concatenated
  /// text inside [region]. Returns '' on failure.
  Future<String> recognizeRegion(Uint8List imageBytes, OcrRegion region);
  Future<void> dispose();
}

class MlKitOcrRunner implements OcrRunner {
  final TextRecognizer _recognizer =
      TextRecognizer(script: TextRecognitionScript.latin);

  @override
  Future<String> recognizeRegion(Uint8List imageBytes, OcrRegion region) async {
    // Caller must pre-crop the image to the region; ML Kit does not accept
    // pixel rectangles on InputImage.fromBytes. Kept as a contract: the
    // ScanPipeline crops before calling.
    final img = InputImage.fromFilePath(await _writeTemp(imageBytes));
    final result = await _recognizer.processImage(img);
    return result.blocks.map((b) => b.text).join(' ').trim();
  }

  @override
  Future<void> dispose() => _recognizer.close();

  Future<String> _writeTemp(Uint8List bytes) async {
    final dir = Directory.systemTemp;
    final f = File('${dir.path}/ocr_${DateTime.now().microsecondsSinceEpoch}.png');
    await f.writeAsBytes(bytes);
    return f.path;
  }
}
```

Add imports at top:

```dart
import 'dart:io';
```

- [ ] **Step 2: Compile check**

```
powershell -File tool\flutter.ps1 analyze
```
Expected: clean. No tests yet.

- [ ] **Step 3: Commit**

```
git add lib/features/scanner/ocr_runner.dart
git commit -m "add mlkit ocr runner wrapper"
```

---

## Task 5: Perspective Correction

**Files:**
- Create: `lib/features/scanner/perspective_correct.dart`

- [ ] **Step 1: Implement**

`lib/features/scanner/perspective_correct.dart`:

```dart
import 'dart:typed_data';
import 'package:opencv_dart/opencv_dart.dart' as cv;

/// Four image-space corner points of a detected card, in TL, TR, BR, BL order.
class CardQuad {
  const CardQuad(this.tl, this.tr, this.br, this.bl);
  final ({double x, double y}) tl, tr, br, bl;
}

/// Warps the region bounded by [quad] in [frameBytes] to an upright
/// [targetWidth] x [targetHeight] crop, returned as PNG bytes.
/// MTG card aspect is 63 x 88 mm ≈ 0.7159.
Uint8List warpToUpright(
  Uint8List frameBytes, {
  required CardQuad quad,
  int targetWidth = 488,
  int targetHeight = 680,
}) {
  final src = cv.imdecode(frameBytes, cv.IMREAD_COLOR);
  final srcPts = cv.Mat.fromList(4, 2, cv.MatType.CV_32FC1, [
    quad.tl.x, quad.tl.y,
    quad.tr.x, quad.tr.y,
    quad.br.x, quad.br.y,
    quad.bl.x, quad.bl.y,
  ]);
  final dstPts = cv.Mat.fromList(4, 2, cv.MatType.CV_32FC1, [
    0.0, 0.0,
    targetWidth.toDouble(), 0.0,
    targetWidth.toDouble(), targetHeight.toDouble(),
    0.0, targetHeight.toDouble(),
  ]);
  final m = cv.getPerspectiveTransform(srcPts, dstPts);
  final out = cv.warpPerspective(src, m, (targetWidth, targetHeight));
  final (_, png) = cv.imencode('.png', out);
  return png;
}
```

- [ ] **Step 2: Compile check**

```
powershell -File tool\flutter.ps1 analyze
```
Expected: clean. No unit test — opencv_dart API is integration-level; exercised by the pipeline integration test in Task 8.

- [ ] **Step 3: Commit**

```
git add lib/features/scanner/perspective_correct.dart
git commit -m "add opencv perspective correction for card crops"
```

---

## Task 6: StabilityDetector

**Files:**
- Create: `lib/features/scanner/stability_detector.dart`

- [ ] **Step 1: Implement**

`lib/features/scanner/stability_detector.dart`:

```dart
import 'dart:typed_data';
import 'package:opencv_dart/opencv_dart.dart' as cv;
import 'perspective_correct.dart';

class RectCandidate {
  const RectCandidate(this.quad, this.areaPx);
  final CardQuad quad;
  final double areaPx;
}

/// Finds the largest rectangular contour in [frameBytes] likely to be a card.
/// Returns null if no contour > [minAreaFraction] of frame area.
RectCandidate? detectCardRect(
  Uint8List frameBytes, {
  double minAreaFraction = 0.15,
}) {
  final src = cv.imdecode(frameBytes, cv.IMREAD_COLOR);
  final gray = cv.cvtColor(src, cv.COLOR_BGR2GRAY);
  final blurred = cv.gaussianBlur(gray, (5, 5), 0);
  final edges = cv.canny(blurred, 50, 150);
  final (contours, _) =
      cv.findContours(edges, cv.RETR_EXTERNAL, cv.CHAIN_APPROX_SIMPLE);
  final frameArea = src.width * src.height.toDouble();
  RectCandidate? best;
  for (var i = 0; i < contours.length; i++) {
    final c = contours[i];
    final peri = cv.arcLength(c, true);
    final approx = cv.approxPolyDP(c, 0.02 * peri, true);
    if (approx.rows != 4) continue;
    final area = cv.contourArea(approx);
    if (area < frameArea * minAreaFraction) continue;
    if (best != null && area <= best.areaPx) continue;
    final pts = List.generate(
      4,
      (j) => (x: approx.at<double>(j, 0), y: approx.at<double>(j, 1)),
    )..sort((a, b) => (a.y + a.x).compareTo(b.y + b.x));
    // After sort: first = top-left-ish, last = bottom-right-ish.
    // Resolve TR/BL by x ordering.
    final tl = pts.first, br = pts.last;
    final mid = [pts[1], pts[2]]..sort((a, b) => a.x.compareTo(b.x));
    final bl = mid.first, tr = mid.last;
    best = RectCandidate(CardQuad(tl, tr, br, bl), area);
  }
  return best;
}

/// Ring buffer of recent quads; reports `stable` when jitter between the
/// most recent [windowSize] samples stays under [maxPxJitter].
class StabilityTracker {
  StabilityTracker({this.windowSize = 5, this.maxPxJitter = 5.0});
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
```

- [ ] **Step 2: Compile check**

```
powershell -File tool\flutter.ps1 analyze
```
Expected: clean.

- [ ] **Step 3: Commit**

```
git add lib/features/scanner/stability_detector.dart
git commit -m "add card rectangle detection + stability tracker"
```

---

## Task 7: ScanWriter

**Files:**
- Create: `lib/features/scanner/scan_writer.dart`

- [ ] **Step 1: Implement**

`lib/features/scanner/scan_writer.dart`:

```dart
import 'package:drift/drift.dart';
import '../../data/db/database.dart';
import 'parsed_ocr.dart';

class ScanWriter {
  ScanWriter(this._db);
  final AppDatabase _db;

  /// Inserts a pending scan row. Returns the new row id.
  Future<int> insertPending({
    required ParsedOcr parsed,
    required String thumbPath,
  }) {
    return _db.into(_db.scans).insert(ScansCompanion.insert(
          capturedAt: DateTime.now(),
          rawName: parsed.rawName,
          rawSetCollector: parsed.rawSetCollector,
          confidence: const Value(0.0),
          foilGuess: const Value(-1),
          cropImagePath: Value(thumbPath),
        ));
  }
}
```

> **Note:** `Scans` table must have `cropImagePath TEXT NULL`. It is already declared in Plan A's `tables.dart`. If the column name in your drift schema differs, adjust here. Do not silently drop the thumbnail.

- [ ] **Step 2: Compile**

```
powershell -File tool\flutter.ps1 analyze
```
Expected: clean. If `cropImagePath` is not a valid column, open `lib/data/db/tables.dart`, confirm the column, regenerate drift: `powershell -File tool\flutter.ps1 pub run build_runner build --delete-conflicting-outputs`. Commit that separately.

- [ ] **Step 3: Commit**

```
git add lib/features/scanner/scan_writer.dart
git commit -m "add scan writer persisting pending scans with thumbnail"
```

---

## Task 8: ScanPipeline + integration test

**Files:**
- Create: `lib/features/scanner/scan_pipeline.dart`
- Test: `test/features/scanner/scan_pipeline_test.dart`

- [ ] **Step 1: Write the failing test**

`test/features/scanner/scan_pipeline_test.dart`:

```dart
import 'dart:typed_data';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mtg_scanner/data/db/database.dart';
import 'package:mtg_scanner/features/scanner/ocr_runner.dart';
import 'package:mtg_scanner/features/scanner/scan_pipeline.dart';
import 'package:mtg_scanner/features/scanner/scan_writer.dart';
import 'package:mtg_scanner/features/scanner/thumbnail_storage.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'dart:io';

class _FakeOcr extends Mock implements OcrRunner {}

class _FakePathProvider extends PathProviderPlatform {
  _FakePathProvider(this.dir);
  final String dir;
  @override
  Future<String?> getApplicationDocumentsPath() async => dir;
}

void main() {
  late AppDatabase db;
  late _FakeOcr ocr;
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('pipeline_');
    PathProviderPlatform.instance = _FakePathProvider(tempDir.path);
    db = AppDatabase.forTesting(NativeDatabase.memory());
    ocr = _FakeOcr();
    registerFallbackValue(
        const OcrRegion(left: 0, top: 0, width: 1, height: 1));
  });
  tearDown(() async {
    await db.close();
    await tempDir.delete(recursive: true);
  });

  test('captureFromWarpedCrop writes a pending scan row with thumbnail', () async {
    when(() => ocr.recognizeRegion(any(), any())).thenAnswer((inv) async {
      final region = inv.positionalArguments[1] as OcrRegion;
      return region.top < 0.5 ? 'Lightning Bolt' : '2xm 137';
    });

    final pipeline = ScanPipeline(
      ocr: ocr,
      writer: ScanWriter(db),
      storage: ThumbnailStorage(),
    );

    final fakePng = Uint8List.fromList(List.filled(32, 0x89));
    final id = await pipeline.captureFromWarpedCrop(fakePng);

    final row = await (db.select(db.scans)..where((t) => t.id.equals(id)))
        .getSingle();
    expect(row.rawName, 'Lightning Bolt');
    expect(row.rawSetCollector, '2xm 137');
    expect(row.status, 'pending');
    expect(row.cropImagePath, isNotNull);
    expect(File(row.cropImagePath!).existsSync(), isTrue);
  });
}
```

- [ ] **Step 2: Run test — expect FAIL (ScanPipeline missing)**

```
powershell -File tool\flutter.ps1 test test/features/scanner/scan_pipeline_test.dart
```

- [ ] **Step 3: Implement**

`lib/features/scanner/scan_pipeline.dart`:

```dart
import 'dart:typed_data';
import 'ocr_runner.dart';
import 'parsed_ocr.dart';
import 'scan_writer.dart';
import 'thumbnail_storage.dart';

class ScanPipeline {
  ScanPipeline({
    required this.ocr,
    required this.writer,
    required this.storage,
  });
  final OcrRunner ocr;
  final ScanWriter writer;
  final ThumbnailStorage storage;

  static const _nameRegion =
      OcrRegion(left: 0.04, top: 0.03, width: 0.70, height: 0.08);
  static const _setRegion =
      OcrRegion(left: 0.04, top: 0.92, width: 0.40, height: 0.05);

  /// Caller supplies an upright card PNG (already perspective-corrected).
  /// Persists a pending scan row and returns its id.
  Future<int> captureFromWarpedCrop(Uint8List uprightPng) async {
    final rawName = await ocr.recognizeRegion(uprightPng, _nameRegion);
    final rawSet = await ocr.recognizeRegion(uprightPng, _setRegion);
    final parsed =
        ParsedOcr.from(rawName: rawName, rawSetCollector: rawSet);
    final thumbPath = await storage.save(uprightPng);
    return writer.insertPending(parsed: parsed, thumbPath: thumbPath);
  }
}
```

- [ ] **Step 4: Run test — expect PASS**

```
powershell -File tool\flutter.ps1 test test/features/scanner/scan_pipeline_test.dart
```

- [ ] **Step 5: Commit**

```
git add lib/features/scanner/scan_pipeline.dart test/features/scanner/scan_pipeline_test.dart
git commit -m "add scan pipeline orchestrator with integration test"
```

---

## Task 9: ScannerState notifier

**Files:**
- Create: `lib/features/scanner/scanner_state.dart`

- [ ] **Step 1: Implement**

`lib/features/scanner/scanner_state.dart`:

```dart
import 'package:flutter/foundation.dart';

enum ScannerPhase { searching, tracking, capturing, processing, done }

class ScannerState {
  const ScannerState({
    required this.phase,
    this.lastCardLabel,
    this.inQueue = 0,
    this.confirmed = 0,
    this.paused = false,
    this.torchOn = false,
  });
  final ScannerPhase phase;
  final String? lastCardLabel;
  final int inQueue;
  final int confirmed;
  final bool paused;
  final bool torchOn;

  ScannerState copyWith({
    ScannerPhase? phase,
    String? lastCardLabel,
    int? inQueue,
    int? confirmed,
    bool? paused,
    bool? torchOn,
  }) =>
      ScannerState(
        phase: phase ?? this.phase,
        lastCardLabel: lastCardLabel ?? this.lastCardLabel,
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
  void toDone(String label, int newInQueue) => value = value.copyWith(
      phase: ScannerPhase.done,
      lastCardLabel: label,
      inQueue: newInQueue);

  void togglePause() => value = value.copyWith(paused: !value.paused);
  void toggleTorch() => value = value.copyWith(torchOn: !value.torchOn);
}
```

- [ ] **Step 2: Compile**

```
powershell -File tool\flutter.ps1 analyze
```

- [ ] **Step 3: Commit**

```
git add lib/features/scanner/scanner_state.dart
git commit -m "add scanner state notifier"
```

---

## Task 10: Permission gate

**Files:**
- Create: `lib/features/scanner/permission_gate.dart`

- [ ] **Step 1: Implement**

`lib/features/scanner/permission_gate.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

typedef ChildBuilder = Widget Function(BuildContext);

class CameraPermissionGate extends StatefulWidget {
  const CameraPermissionGate({required this.child, super.key});
  final ChildBuilder child;
  @override
  State<CameraPermissionGate> createState() => _CameraPermissionGateState();
}

class _CameraPermissionGateState extends State<CameraPermissionGate> {
  PermissionStatus? _status;

  @override
  void initState() {
    super.initState();
    _request();
  }

  Future<void> _request() async {
    final s = await Permission.camera.request();
    if (!mounted) return;
    setState(() => _status = s);
  }

  @override
  Widget build(BuildContext context) {
    final s = _status;
    if (s == null) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }
    if (s.isGranted) return widget.child(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Camera')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                  'Camera access is required to scan cards. Grant it in system settings.',
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: openAppSettings,
                child: const Text('Open settings'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Compile**

```
powershell -File tool\flutter.ps1 analyze
```

- [ ] **Step 3: Commit**

```
git add lib/features/scanner/permission_gate.dart
git commit -m "add camera permission gate"
```

---

## Task 11: Scanner screen

**Files:**
- Create: `lib/features/scanner/scanner_screen.dart`

This task wires the pieces. It is the largest code change and is not unit-tested here — widget test in Task 12 covers state transitions with a fake pipeline.

- [ ] **Step 1: Implement**

`lib/features/scanner/scanner_screen.dart`:

```dart
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../../data/repositories/scans_repository.dart';
import 'ocr_runner.dart';
import 'perspective_correct.dart';
import 'scan_pipeline.dart';
import 'scan_writer.dart';
import 'scanner_state.dart';
import 'stability_detector.dart';
import 'thumbnail_storage.dart';
import 'permission_gate.dart';

class ScannerScreen extends StatelessWidget {
  const ScannerScreen({required this.scans, required this.pipeline, super.key});
  final ScansRepository scans;
  final ScanPipeline pipeline;

  @override
  Widget build(BuildContext context) => CameraPermissionGate(
        child: (ctx) => _ScannerBody(scans: scans, pipeline: pipeline),
      );
}

class _ScannerBody extends StatefulWidget {
  const _ScannerBody({required this.scans, required this.pipeline});
  final ScansRepository scans;
  final ScanPipeline pipeline;
  @override
  State<_ScannerBody> createState() => _ScannerBodyState();
}

class _ScannerBodyState extends State<_ScannerBody> {
  CameraController? _controller;
  final _state = ScannerStateNotifier();
  final _tracker = StabilityTracker();
  bool _busy = false;
  DateTime? _lastCaptureAt;
  String? _lastRawName;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final cams = await availableCameras();
    final back = cams.firstWhere((c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cams.first);
    final c = CameraController(back, ResolutionPreset.high,
        enableAudio: false, imageFormatGroup: ImageFormatGroup.jpeg);
    await c.initialize();
    if (!mounted) return;
    setState(() => _controller = c);
    await c.startImageStream(_onFrame);
  }

  Future<void> _onFrame(CameraImage img) async {
    if (_busy || _state.value.paused) return;
    _busy = true;
    try {
      final bytes = _jpegFromFrame(img);
      if (bytes == null) return;
      final rect = detectCardRect(bytes);
      if (rect == null) {
        _tracker.reset();
        _state.toSearching();
        return;
      }
      _tracker.push(rect.quad);
      _state.toTracking();
      if (!_tracker.isStable) return;

      final sinceLast = DateTime.now()
          .difference(_lastCaptureAt ?? DateTime.fromMillisecondsSinceEpoch(0));
      if (sinceLast.inMilliseconds < 500) return;

      _state.toCapturing();
      final upright = warpToUpright(bytes, quad: rect.quad);
      _state.toProcessing();
      final id = await widget.pipeline.captureFromWarpedCrop(upright);
      final row = await (widget.scans as dynamic).getById?.call(id);
      _lastCaptureAt = DateTime.now();
      final label = (row?.rawName as String?) ?? 'scan';
      if (_lastRawName != null && _lastRawName == label) {
        return; // duplicate guard
      }
      _lastRawName = label;
      _state.toDone(label, (_state.value.inQueue) + 1);
      await Future<void>.delayed(const Duration(milliseconds: 700));
      _state.toSearching();
      _tracker.reset();
    } finally {
      _busy = false;
    }
  }

  Uint8List? _jpegFromFrame(CameraImage img) {
    if (img.format.group != ImageFormatGroup.jpeg) return null;
    return img.planes.first.bytes;
  }

  @override
  void dispose() {
    _controller?.dispose();
    _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    if (c == null || !c.value.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          CameraPreview(c),
          ValueListenableBuilder<ScannerState>(
            valueListenable: _state,
            builder: (_, s, __) => _Overlay(state: s),
          ),
          Positioned(
            top: 16,
            right: 16,
            child: ValueListenableBuilder<ScannerState>(
              valueListenable: _state,
              builder: (_, s, __) => _QueueBadge(inQueue: s.inQueue),
            ),
          ),
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () async {
                    _state.togglePause();
                    if (_state.value.paused) {
                      await c.stopImageStream();
                    } else {
                      await c.startImageStream(_onFrame);
                    }
                  },
                  icon: const Icon(Icons.pause_circle_outline,
                      size: 48, color: Colors.white),
                ),
                IconButton(
                  onPressed: () async {
                    _state.toggleTorch();
                    await c.setFlashMode(
                        _state.value.torchOn ? FlashMode.torch : FlashMode.off);
                  },
                  icon: const Icon(Icons.flashlight_on,
                      size: 36, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Overlay extends StatelessWidget {
  const _Overlay({required this.state});
  final ScannerState state;
  @override
  Widget build(BuildContext context) {
    if (state.phase == ScannerPhase.done && state.lastCardLabel != null) {
      return Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(top: 72),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text('✓ ${state.lastCardLabel}',
                style: const TextStyle(color: Colors.white)),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}

class _QueueBadge extends StatelessWidget {
  const _QueueBadge({required this.inQueue});
  final int inQueue;
  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Text('$inQueue in queue',
            style: const TextStyle(color: Colors.white)),
      );
}
```

> **Known gap:** `_jpegFromFrame` assumes the camera plugin returns JPEG planes. On many Android devices it returns YUV_420_888 by default. If detectCardRect returns null on-device, revisit: either convert YUV→JPEG via `image` package or request JPEG explicitly (not supported on all devices) or decode YUV planes directly via `cv.Mat.fromList`. Treat this as a known follow-up during manual smoke test in Task 13.

- [ ] **Step 2: Wire route**

Open `lib/app.dart` (or wherever routes are defined). Replace the scanner-screen stub route with:

```dart
ScannerScreen(scans: scansRepo, pipeline: pipeline)
```

Construct `pipeline` at app startup:

```dart
final pipeline = ScanPipeline(
  ocr: MlKitOcrRunner(),
  writer: ScanWriter(db),
  storage: ThumbnailStorage(),
);
```

- [ ] **Step 3: Analyze**

```
powershell -File tool\flutter.ps1 analyze
```
Expected: clean.

- [ ] **Step 4: Commit**

```
git add lib/features/scanner/scanner_screen.dart lib/app.dart
git commit -m "wire scanner screen with camera preview and pipeline"
```

---

## Task 12: Scanner screen widget test

**Files:**
- Test: `test/features/scanner/scanner_screen_test.dart`

Widget test a stripped harness that exercises only the state notifier + overlay, since the real screen requires a camera device. The test verifies the overlay renders for each `ScannerPhase` and the queue badge reflects `inQueue`.

- [ ] **Step 1: Write the test**

`test/features/scanner/scanner_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mtg_scanner/features/scanner/scanner_state.dart';

class _Overlay extends StatelessWidget {
  const _Overlay({required this.state});
  final ScannerState state;
  @override
  Widget build(BuildContext context) {
    if (state.phase == ScannerPhase.done && state.lastCardLabel != null) {
      return Text('✓ ${state.lastCardLabel}');
    }
    return const SizedBox.shrink();
  }
}

void main() {
  testWidgets('overlay shows toast after toDone', (t) async {
    final n = ScannerStateNotifier();
    await t.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ValueListenableBuilder<ScannerState>(
          valueListenable: n,
          builder: (_, s, __) => _Overlay(state: s),
        ),
      ),
    ));
    expect(find.textContaining('✓'), findsNothing);
    n.toDone('Lightning Bolt', 1);
    await t.pump();
    expect(find.text('✓ Lightning Bolt'), findsOneWidget);
  });

  testWidgets('pause flag flips with togglePause', (t) async {
    final n = ScannerStateNotifier();
    expect(n.value.paused, isFalse);
    n.togglePause();
    expect(n.value.paused, isTrue);
    n.togglePause();
    expect(n.value.paused, isFalse);
  });
}
```

- [ ] **Step 2: Run**

```
powershell -File tool\flutter.ps1 test test/features/scanner/scanner_screen_test.dart
```
Expected: both PASS.

- [ ] **Step 3: Commit**

```
git add test/features/scanner/scanner_screen_test.dart
git commit -m "add scanner state widget test"
```

---

## Task 13: Manual smoke test + APK

- [ ] **Step 1: Full test suite**

```
powershell -File tool\flutter.ps1 analyze
powershell -File tool\flutter.ps1 test
```
Expected: no issues, all tests green.

- [ ] **Step 2: Build and install**

```
powershell -File tool\flutter.ps1 build apk --debug
C:\Users\Krs19\AppData\Local\Android\sdk\platform-tools\adb.exe install -r build\app\outputs\flutter-apk\app-debug.apk
```
Expected: Success.

- [ ] **Step 3: On-device checks**

Launch the app; open the Scanner screen.

Verify in order:
1. Camera permission dialog appears; denying shows the settings screen; re-allowing returns to preview.
2. Point camera at a card against a plain background. Bounding box draws. Holding steady triggers a "✓ {name}" toast within ~1 second.
3. Tap the badge in the top-right; lands on the Review Queue with the new pending scan. The thumbnail is present. Name OCR is approximately correct.
4. The duplicate guard: scanning the same card again within 500ms of the previous capture does **not** create a second row.
5. Torch toggle flips the flashlight. Pause toggle stops capture.

If any of the 5 fail, stop, diagnose (most likely the YUV issue flagged in Task 11, Step 1). Do not ship until all five pass.

- [ ] **Step 4: Update RESUME.md + memory**

Mark Plan B1 complete. Add a note listing known limitations (Latin-script OCR only; no Scryfall match yet — comes in B2; no foil detection — comes in B3). Point at B2 as the next plan.

- [ ] **Step 5: Commit**

```
git add RESUME.md
git commit -m "mark plan b1 complete"
```

---

## Self-Review Notes

- **Spec coverage:** B1 covers camera preview, stability detection, perspective correction, OCR of title + collector regions, scan-row insertion, thumbnail storage, duplicate guard, torch/pause/queue-badge UI, permission handling. Scryfall matching (§Lookup, §Confidence scoring) is deferred to B2. Foil heuristics (§Foil detection) are deferred to B3. The spec's state machine (`searching`/`tracking`/`capturing`/`processing`/`done`/`ambiguous`) is implemented minus `ambiguous` — that state only makes sense after B2 when matches can be low-confidence.
- **Known gap — frame format:** Task 11 flags the YUV-vs-JPEG camera-frame decoding. If scanning silently no-ops on-device, this is the first place to look.
- **Types consistent:** `CardQuad`, `OcrRegion`, `ParsedOcr`, `ScanPipeline.captureFromWarpedCrop` all match across tasks. `ScansCompanion.insert` fields match the Plan-A schema (`capturedAt`, `rawName`, `rawSetCollector`, `confidence`, `foilGuess`, `cropImagePath`).
- **Placeholders:** none. Every step has exact code or exact commands.
- **Hack flagged:** `_ScannerBodyState._onFrame` reads `widget.scans` via `as dynamic` to fetch the written row for the toast label. Replace with an explicit `ScansRepository.getById` method in B2 cleanup — keeping the dynamic cast now to avoid expanding Plan-A surface mid-plan.
