# Scan Price Feedback Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Show the matched card's price in the scan confirmation overlay and play a cash-register sound when the price exceeds a user-configured threshold, saving only Scryfall-matched scans.

**Architecture:** The capture pipeline runs the Scryfall match synchronously and only writes a scan row when a match succeeds. The scanner state machine gains a `matching` phase for the "⋯ matching…" hint and a nullable `lastCardPrice` for the post-match display. A new `AppSettings` service wraps `shared_preferences` to persist the value-alert threshold and notify listeners. A preloaded `AudioPlayer` (from `audioplayers`) plays a bundled cash-register MP3 on the value trigger.

**Tech Stack:** Flutter, Drift (SQLite), `shared_preferences`, `audioplayers`, `mocktail` + `flutter_test` for unit tests, `go_router`, `path_provider`.

---

## File Structure

**New files:**
- `lib/app_settings.dart` — `ChangeNotifier` wrapper over `shared_preferences` for the value-alert threshold.
- `assets/sounds/cash_register.mp3` — cash-register sound bundled as an asset.
- `test/app_settings_test.dart` — unit tests for `AppSettings`.

**Modified files:**
- `pubspec.yaml` — add `audioplayers` dep, register `assets/sounds/` directory.
- `lib/features/scanner/scan_matcher.dart` — drop DB side effects; return `MatchResult?`; classify errors.
- `lib/features/scanner/scan_pipeline.dart` — match-before-save; return `CaptureResult` with outcome enum.
- `lib/features/scanner/scanner_state.dart` — add `matching` phase + `lastCardPrice` field + helpers.
- `lib/features/scanner/scanner_screen.dart` — new overlay states, sound trigger, settings read; remove `scans.reject` rollback (pipeline no longer inserts unmatched rows).
- `lib/features/settings/settings_screen.dart` — new "Value alert threshold ($)" list tile + dialog.
- `lib/app.dart` — construct `AppSettings` and preloaded `AudioPlayer` in `Deps`; pass through to `SettingsScreen` and `ScannerScreen`.
- `test/features/scanner/scan_matcher_test.dart` — rewrite for new `match()` signature.
- `test/features/scanner/scan_pipeline_test.dart` — rewrite for `CaptureResult` and match-before-save.
- `test/features/scanner/scanner_screen_test.dart` — extend overlay test to cover matching/done-with-price.

---

### Task 1: Bundle sound asset and add audioplayers dependency

**Files:**
- Create: `assets/sounds/cash_register.mp3` (copy from user's Downloads)
- Modify: `pubspec.yaml`

- [ ] **Step 1: Create the assets directory and copy the MP3**

```bash
mkdir -p assets/sounds
cp "/mnt/c/Users/Krs19/Downloads/cash-register-sound-fx_HgrEcyp.mp3" assets/sounds/cash_register.mp3
```

- [ ] **Step 2: Add `audioplayers` to pubspec.yaml under `dependencies:`**

In `pubspec.yaml`, under `dependencies:` (alphabetically after `path`, before `permission_handler`):

```yaml
  audioplayers: ^6.1.0
```

- [ ] **Step 3: Register the asset directory in pubspec.yaml**

In `pubspec.yaml`, find the `flutter:` section (bottom of file). Under `flutter:` there is usually a `uses-material-design: true` line. Add (or extend existing `assets:` block if present):

```yaml
flutter:
  uses-material-design: true
  assets:
    - assets/sounds/
```

- [ ] **Step 4: Fetch dependencies**

Run: `cmd.exe /c "powershell -File tool\\flutter.ps1 pub get"`
Expected: `Got dependencies!` without errors.

- [ ] **Step 5: Commit**

```bash
git add pubspec.yaml pubspec.lock assets/sounds/cash_register.mp3
git commit -m "add cash-register sound asset and audioplayers dep"
```

---

### Task 2: AppSettings service with shared_preferences

**Files:**
- Create: `lib/app_settings.dart`
- Create: `test/app_settings_test.dart`

- [ ] **Step 1: Write the failing tests**

Create `test/app_settings_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mtg_scanner/app_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('defaults value alert threshold to 1.0 when unset', () async {
    final s = await AppSettings.load();
    expect(s.valueAlertThreshold, 1.0);
  });

  test('persists and reloads value alert threshold', () async {
    final s = await AppSettings.load();
    await s.setValueAlertThreshold(4.25);
    expect(s.valueAlertThreshold, 4.25);
    final reloaded = await AppSettings.load();
    expect(reloaded.valueAlertThreshold, 4.25);
  });

  test('notifies listeners on threshold change', () async {
    final s = await AppSettings.load();
    var notified = 0;
    s.addListener(() => notified++);
    await s.setValueAlertThreshold(2.5);
    expect(notified, 1);
  });

  test('ignores non-positive or non-finite thresholds', () async {
    final s = await AppSettings.load();
    await s.setValueAlertThreshold(-1);
    expect(s.valueAlertThreshold, 1.0);
    await s.setValueAlertThreshold(double.nan);
    expect(s.valueAlertThreshold, 1.0);
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `cmd.exe /c "powershell -File tool\\flutter.ps1 test test/app_settings_test.dart"`
Expected: compile error on `package:mtg_scanner/app_settings.dart` (file does not exist).

- [ ] **Step 3: Create the service**

Create `lib/app_settings.dart`:

```dart
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings extends ChangeNotifier {
  AppSettings._(this._prefs, this._threshold);

  static const _thresholdKey = 'value_alert_threshold_usd';
  static const _defaultThreshold = 1.0;

  final SharedPreferences _prefs;
  double _threshold;

  double get valueAlertThreshold => _threshold;

  static Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getDouble(_thresholdKey);
    final t = (stored != null && stored.isFinite && stored > 0)
        ? stored
        : _defaultThreshold;
    return AppSettings._(prefs, t);
  }

  Future<void> setValueAlertThreshold(double value) async {
    if (!value.isFinite || value <= 0) return;
    _threshold = value;
    await _prefs.setDouble(_thresholdKey, value);
    notifyListeners();
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `cmd.exe /c "powershell -File tool\\flutter.ps1 test test/app_settings_test.dart"`
Expected: all 4 tests pass.

- [ ] **Step 5: Commit**

```bash
git add lib/app_settings.dart test/app_settings_test.dart
git commit -m "add AppSettings service for value-alert threshold"
```

---

### Task 3: Refactor ScanMatcher to pure match() + error classification

**Files:**
- Modify: `lib/features/scanner/scan_matcher.dart` (whole file)
- Modify: `test/features/scanner/scan_matcher_test.dart` (whole file)

- [ ] **Step 1: Rewrite the matcher tests**

Replace the entire contents of `test/features/scanner/scan_matcher_test.dart` with:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mtg_scanner/data/scryfall/scryfall_client.dart';
import 'package:mtg_scanner/data/scryfall/scryfall_models.dart';
import 'package:mtg_scanner/features/scanner/parsed_ocr.dart';
import 'package:mtg_scanner/features/scanner/scan_matcher.dart';

class _FakeScry extends Mock implements ScryfallClient {}

ScryfallCard _card({
  String id = 'sid-1',
  String name = 'Lightning Bolt',
  String set = '2xm',
  String collector = '137',
  double? usd = 1.80,
  double? usdFoil,
}) =>
    ScryfallCard(
      id: id,
      name: name,
      set: set,
      collectorNumber: collector,
      prices: ScryfallPrices(usd: usd, usdFoil: usdFoil),
    );

void main() {
  late _FakeScry scry;
  late ScanMatcher matcher;

  setUp(() {
    scry = _FakeScry();
    matcher = ScanMatcher(scry: scry);
  });

  test('exact set+collector match returns confidence 1.0', () async {
    when(() => scry.cardBySetAndNumber('2XM', '137'))
        .thenAnswer((_) async => _card());

    final result = await matcher.match(ParsedOcr.from(
        rawName: 'Lightning Bolt', rawSetCollector: '2xm 137'));

    expect(result, isNotNull);
    expect(result!.confidence, 1.0);
    expect(result.card.name, 'Lightning Bolt');
  });

  test('fuzzy fallback when exact 404s returns confidence 0.6', () async {
    when(() => scry.cardBySetAndNumber('2XM', '999'))
        .thenThrow(ScryfallNotFound('2xm/999'));
    when(() => scry.cardByFuzzyName('Lightning Bolt'))
        .thenAnswer((_) async => _card());

    final result = await matcher.match(ParsedOcr.from(
        rawName: 'Lightning Bolt', rawSetCollector: '2xm 999'));

    expect(result!.confidence, 0.6);
  });

  test('fuzzy-only search when no set+collector present', () async {
    when(() => scry.cardByFuzzyName('Lightning Bolt'))
        .thenAnswer((_) async => _card());

    final result = await matcher
        .match(ParsedOcr.from(rawName: 'Lightning Bolt', rawSetCollector: ''));

    expect(result!.confidence, 0.6);
  });

  test('returns null when fuzzy 404s (no match found)', () async {
    when(() => scry.cardByFuzzyName('Gibberish'))
        .thenThrow(ScryfallNotFound('fuzzy'));

    final result = await matcher
        .match(ParsedOcr.from(rawName: 'Gibberish', rawSetCollector: ''));

    expect(result, isNull);
  });

  test('returns null when parsed name is empty and no set+collector', () async {
    final result =
        await matcher.match(ParsedOcr.from(rawName: '', rawSetCollector: ''));

    expect(result, isNull);
    verifyNever(() => scry.cardByFuzzyName(any()));
  });

  test('rethrows ScryfallException from exact lookup (network error)', () async {
    when(() => scry.cardBySetAndNumber('2XM', '137'))
        .thenThrow(ScryfallException('network down'));

    expect(
      () => matcher.match(
          ParsedOcr.from(rawName: 'Lightning Bolt', rawSetCollector: '2xm 137')),
      throwsA(isA<ScryfallException>()),
    );
  });

  test('rethrows ScryfallException from fuzzy lookup (network error)', () async {
    when(() => scry.cardByFuzzyName('Lightning Bolt'))
        .thenThrow(ScryfallException('network down'));

    expect(
      () => matcher
          .match(ParsedOcr.from(rawName: 'Lightning Bolt', rawSetCollector: '')),
      throwsA(isA<ScryfallException>()),
    );
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `cmd.exe /c "powershell -File tool\\flutter.ps1 test test/features/scanner/scan_matcher_test.dart"`
Expected: compile errors (`match` not defined, extra constructor params, `MatchResult` visibility).

- [ ] **Step 3: Rewrite the matcher**

Replace the entire contents of `lib/features/scanner/scan_matcher.dart` with:

```dart
import '../../data/scryfall/scryfall_client.dart';
import '../../data/scryfall/scryfall_models.dart';
import 'parsed_ocr.dart';

class ScanMatcher {
  ScanMatcher({required this.scry});

  final ScryfallClient scry;

  /// Resolves a parsed OCR result to a Scryfall card.
  ///
  /// Returns `null` when no card is found (exact lookup 404s AND fuzzy 404s,
  /// or there isn't enough input to try a fuzzy lookup).
  ///
  /// Throws [ScryfallException] on network/API errors — callers should treat
  /// these as "offline" rather than "no match".
  Future<MatchResult?> match(ParsedOcr parsed) async {
    if (parsed.setCode != null && parsed.collectorNumber != null) {
      try {
        final card = await scry.cardBySetAndNumber(
            parsed.setCode!, parsed.collectorNumber!);
        return MatchResult(card, 1.0);
      } on ScryfallNotFound {
        // fall through to fuzzy
      }
    }
    if (parsed.name.isEmpty) return null;
    try {
      final card = await scry.cardByFuzzyName(parsed.name);
      return MatchResult(card, 0.6);
    } on ScryfallNotFound {
      return null;
    }
  }
}

class MatchResult {
  MatchResult(this.card, this.confidence);
  final ScryfallCard card;
  final double confidence;
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `cmd.exe /c "powershell -File tool\\flutter.ps1 test test/features/scanner/scan_matcher_test.dart"`
Expected: all 7 tests pass.

- [ ] **Step 5: Commit**

```bash
git add lib/features/scanner/scan_matcher.dart test/features/scanner/scan_matcher_test.dart
git commit -m "refactor: ScanMatcher returns MatchResult, no DB side effects"
```

---

### Task 4: Refactor ScanPipeline to match-before-save with CaptureResult

**Files:**
- Modify: `lib/features/scanner/scan_pipeline.dart` (whole file)
- Modify: `test/features/scanner/scan_pipeline_test.dart` (whole file)

- [ ] **Step 1: Rewrite the pipeline tests**

Replace the entire contents of `test/features/scanner/scan_pipeline_test.dart` with:

```dart
import 'dart:io';
import 'dart:typed_data';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mtg_scanner/data/db/database.dart';
import 'package:mtg_scanner/data/repositories/collection_repository.dart';
import 'package:mtg_scanner/data/scryfall/scryfall_client.dart';
import 'package:mtg_scanner/data/scryfall/scryfall_models.dart';
import 'package:mtg_scanner/features/scanner/ocr_runner.dart';
import 'package:mtg_scanner/features/scanner/parsed_ocr.dart';
import 'package:mtg_scanner/features/scanner/scan_matcher.dart';
import 'package:mtg_scanner/features/scanner/scan_pipeline.dart';
import 'package:mtg_scanner/features/scanner/scan_writer.dart';
import 'package:mtg_scanner/features/scanner/thumbnail_storage.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

class _FakeOcr extends Mock implements OcrRunner {}

class _FakeMatcher extends Mock implements ScanMatcher {}

class _FakeScry extends Mock implements ScryfallClient {}

class _FakePathProvider extends PathProviderPlatform {
  _FakePathProvider(this.dir);
  final String dir;
  @override
  Future<String?> getApplicationDocumentsPath() async => dir;
}

ScryfallCard _card({double? usd = 1.80, double? usdFoil}) => ScryfallCard(
      id: 'sid-1',
      name: 'Lightning Bolt',
      set: '2xm',
      collectorNumber: '137',
      prices: ScryfallPrices(usd: usd, usdFoil: usdFoil),
    );

void main() {
  late AppDatabase db;
  late _FakeOcr ocr;
  late _FakeMatcher matcher;
  late _FakeScry scry;
  late CollectionRepository collection;
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('pipeline_');
    PathProviderPlatform.instance = _FakePathProvider(tempDir.path);
    db = AppDatabase.forTesting(NativeDatabase.memory());
    ocr = _FakeOcr();
    matcher = _FakeMatcher();
    scry = _FakeScry();
    collection = CollectionRepository(db, scry);
    registerFallbackValue(
        const OcrRegion(left: 0, top: 0, width: 1, height: 1));
    registerFallbackValue(Uint8List(0));
    registerFallbackValue(
        ParsedOcr.from(rawName: '', rawSetCollector: ''));
  });
  tearDown(() async {
    await db.close();
    await tempDir.delete(recursive: true);
  });

  ScanPipeline _pipeline() => ScanPipeline(
        ocr: ocr,
        writer: ScanWriter(db),
        storage: ThumbnailStorage(),
        matcher: matcher,
        collection: collection,
      );

  void _stubOcr({String name = 'Lightning Bolt', String setCol = '2xm 137'}) {
    when(() => ocr.recognizeRegion(any(), any())).thenAnswer((inv) async {
      final region = inv.positionalArguments[1] as OcrRegion;
      return region.top < 0.5 ? name : setCol;
    });
  }

  test('matched outcome inserts scan, auto-confirms, returns price (non-foil)',
      () async {
    _stubOcr();
    when(() => matcher.match(any()))
        .thenAnswer((_) async => MatchResult(_card(), 1.0));

    final res =
        await _pipeline().captureFromWarpedCrop(Uint8List(4), forceFoil: false);

    expect(res.outcome, CaptureOutcome.matched);
    expect(res.matchedName, 'Lightning Bolt');
    expect(res.price, 1.80);
    final rows = await db.select(db.scans).get();
    expect(rows, hasLength(1));
    expect(rows.single.status, 'confirmed');
    expect(rows.single.matchedName, 'Lightning Bolt');
    expect(rows.single.priceUsd, 1.80);
    final coll = await db.select(db.collection).get();
    expect(coll, hasLength(1));
  });

  test('matched outcome picks foil price when forceFoil is true', () async {
    _stubOcr();
    when(() => matcher.match(any())).thenAnswer(
        (_) async => MatchResult(_card(usd: 1.80, usdFoil: 5.50), 1.0));

    final res =
        await _pipeline().captureFromWarpedCrop(Uint8List(4), forceFoil: true);

    expect(res.price, 5.50);
  });

  test('matched outcome falls back to non-foil when foil price is null',
      () async {
    _stubOcr();
    when(() => matcher.match(any())).thenAnswer(
        (_) async => MatchResult(_card(usd: 1.80, usdFoil: null), 1.0));

    final res =
        await _pipeline().captureFromWarpedCrop(Uint8List(4), forceFoil: true);

    expect(res.price, 1.80);
  });

  test('low-confidence match inserts but does not auto-confirm', () async {
    _stubOcr();
    when(() => matcher.match(any()))
        .thenAnswer((_) async => MatchResult(_card(), 0.6));

    final res =
        await _pipeline().captureFromWarpedCrop(Uint8List(4), forceFoil: false);

    expect(res.outcome, CaptureOutcome.matched);
    final rows = await db.select(db.scans).get();
    expect(rows.single.status, 'pending');
    final coll = await db.select(db.collection).get();
    expect(coll, isEmpty);
  });

  test('no-match outcome: matcher returns null, nothing inserted', () async {
    _stubOcr(name: 'Gibberish', setCol: '');
    when(() => matcher.match(any())).thenAnswer((_) async => null);

    final res =
        await _pipeline().captureFromWarpedCrop(Uint8List(4), forceFoil: false);

    expect(res.outcome, CaptureOutcome.noMatch);
    expect(res.price, isNull);
    final rows = await db.select(db.scans).get();
    expect(rows, isEmpty);
  });

  test('offline outcome: ScryfallException becomes offline, nothing inserted',
      () async {
    _stubOcr();
    when(() => matcher.match(any()))
        .thenThrow(ScryfallException('network down'));

    final res =
        await _pipeline().captureFromWarpedCrop(Uint8List(4), forceFoil: false);

    expect(res.outcome, CaptureOutcome.offline);
    final rows = await db.select(db.scans).get();
    expect(rows, isEmpty);
  });

  test('offline outcome: timeout beyond 4s becomes offline', () async {
    _stubOcr();
    when(() => matcher.match(any())).thenAnswer((_) async {
      await Future<void>.delayed(const Duration(seconds: 5));
      return null;
    });

    final res = await _pipeline()
        .captureFromWarpedCrop(Uint8List(4), forceFoil: false);

    expect(res.outcome, CaptureOutcome.offline);
    final rows = await db.select(db.scans).get();
    expect(rows, isEmpty);
  }, timeout: const Timeout(Duration(seconds: 10)));
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `cmd.exe /c "powershell -File tool\\flutter.ps1 test test/features/scanner/scan_pipeline_test.dart"`
Expected: compile errors on `CaptureOutcome`, `CaptureResult` fields, `collection:` constructor param, `matcher.match`.

- [ ] **Step 3: Rewrite the pipeline**

Replace the entire contents of `lib/features/scanner/scan_pipeline.dart` with:

```dart
import 'dart:async';
import 'dart:typed_data';

import '../../data/repositories/collection_repository.dart';
import '../../data/scryfall/scryfall_client.dart';
import 'foil_detector.dart';
import 'ocr_runner.dart';
import 'parsed_ocr.dart';
import 'scan_matcher.dart';
import 'scan_writer.dart';
import 'thumbnail_storage.dart';

enum CaptureOutcome { matched, noMatch, offline }

class CaptureResult {
  CaptureResult.matched({
    required this.id,
    required this.matchedName,
    required this.price,
  }) : outcome = CaptureOutcome.matched;

  CaptureResult.noMatch()
      : outcome = CaptureOutcome.noMatch,
        id = null,
        matchedName = null,
        price = null;

  CaptureResult.offline()
      : outcome = CaptureOutcome.offline,
        id = null,
        matchedName = null,
        price = null;

  final CaptureOutcome outcome;
  final int? id;
  final String? matchedName;
  final double? price;
}

class ScanPipeline {
  ScanPipeline({
    required this.ocr,
    required this.writer,
    required this.storage,
    required this.matcher,
    required this.collection,
    this.autoConfirmThreshold = 0.8,
    this.matchTimeout = const Duration(seconds: 4),
  });

  final OcrRunner ocr;
  final ScanWriter writer;
  final ThumbnailStorage storage;
  final ScanMatcher matcher;
  final CollectionRepository collection;
  final double autoConfirmThreshold;
  final Duration matchTimeout;

  static const _nameRegion =
      OcrRegion(left: 0.02, top: 0.02, width: 0.96, height: 0.14);
  static const _setRegion =
      OcrRegion(left: 0.02, top: 0.86, width: 0.60, height: 0.12);

  Future<CaptureResult> captureFromWarpedCrop(
    Uint8List uprightPng, {
    bool forceFoil = false,
  }) async {
    final rawName = await ocr.recognizeRegion(uprightPng, _nameRegion);
    final rawSet = await ocr.recognizeRegion(uprightPng, _setRegion);
    final parsed = ParsedOcr.from(rawName: rawName, rawSetCollector: rawSet);

    final MatchResult? match;
    try {
      match = await matcher.match(parsed).timeout(matchTimeout);
    } on TimeoutException {
      return CaptureResult.offline();
    } on ScryfallException {
      return CaptureResult.offline();
    }

    if (match == null) return CaptureResult.noMatch();

    var foilGuess = 0;
    if (forceFoil) {
      foilGuess = 1;
    } else {
      try {
        final sig = detectFoil(uprightPng);
        foilGuess = sig.isFoil ? 1 : 0;
      } catch (_) {
        foilGuess = 0;
      }
    }

    final thumbPath = await storage.save(uprightPng);
    final id = await writer.insertMatched(
      parsed: parsed,
      thumbPath: thumbPath,
      foilGuess: foilGuess,
      match: match,
    );

    if (match.confidence >= autoConfirmThreshold) {
      await collection.addFromScryfall(match.card, foil: foilGuess == 1);
      await writer.markConfirmed(id);
    }

    final price = _selectPrice(match.card, forceFoil || foilGuess == 1);
    return CaptureResult.matched(
      id: id,
      matchedName: match.card.name,
      price: price,
    );
  }

  static double? _selectPrice(dynamic card, bool foil) {
    final usd = card.prices.usd as double?;
    final usdFoil = card.prices.usdFoil as double?;
    if (foil) return usdFoil ?? usd;
    return usd ?? usdFoil;
  }
}
```

- [ ] **Step 4: Update ScanWriter to expose the two writer methods used by the pipeline**

Read the current `lib/features/scanner/scan_writer.dart`:

```bash
cat lib/features/scanner/scan_writer.dart
```

Replace its contents with:

```dart
import 'package:drift/drift.dart';

import '../../data/db/database.dart';
import 'parsed_ocr.dart';
import 'scan_matcher.dart';

class ScanWriter {
  ScanWriter(this._db);
  final AppDatabase _db;

  Future<int> insertMatched({
    required ParsedOcr parsed,
    required String thumbPath,
    required int foilGuess,
    required MatchResult match,
  }) =>
      _db.scansDao.insertScan(ScansCompanion.insert(
        capturedAt: DateTime.now(),
        rawName: parsed.name,
        rawSetCollector:
            '${parsed.setCode ?? ''} ${parsed.collectorNumber ?? ''}'.trim(),
        thumbnailPath: Value(thumbPath),
        matchedScryfallId: Value(match.card.id),
        matchedName: Value(match.card.name),
        matchedSet: Value(match.card.set),
        matchedCollectorNumber: Value(match.card.collectorNumber),
        confidence: Value(match.confidence),
        foilGuess: Value(foilGuess),
        priceUsd: Value(match.card.prices.usd),
        priceUsdFoil: Value(match.card.prices.usdFoil),
      ));

  Future<void> markConfirmed(int id) => _db.scansDao.markStatus(id, 'confirmed');
}
```

- [ ] **Step 5: Run tests to verify they pass**

Run: `cmd.exe /c "powershell -File tool\\flutter.ps1 test test/features/scanner/scan_pipeline_test.dart"`
Expected: all 7 tests pass.

- [ ] **Step 6: Commit**

```bash
git add lib/features/scanner/scan_pipeline.dart lib/features/scanner/scan_writer.dart test/features/scanner/scan_pipeline_test.dart
git commit -m "refactor: ScanPipeline matches before save, returns CaptureResult"
```

---

### Task 5: Update ScannerState for matching phase and price

**Files:**
- Modify: `lib/features/scanner/scanner_state.dart`
- Modify: `test/features/scanner/scanner_screen_test.dart`

- [ ] **Step 1: Extend the scanner-state tests**

Read `test/features/scanner/scanner_screen_test.dart`. After the existing `pause flag flips with togglePause` test, add (inside the same `main()`):

```dart
  test('toMatching sets phase to matching and clears label/price', () {
    final n = ScannerStateNotifier();
    n.toDone('Old', price: 1.0, newInQueue: 1);
    n.toMatching();
    expect(n.value.phase, ScannerPhase.matching);
    expect(n.value.lastCardLabel, isNull);
    expect(n.value.lastCardPrice, isNull);
  });

  test('toDone stores label and price', () {
    final n = ScannerStateNotifier();
    n.toDone('Lightning Bolt', price: 2.5, newInQueue: 3);
    expect(n.value.phase, ScannerPhase.done);
    expect(n.value.lastCardLabel, 'Lightning Bolt');
    expect(n.value.lastCardPrice, 2.5);
    expect(n.value.inQueue, 3);
  });

  test('toNoMatch sets phase to noMatch with no label', () {
    final n = ScannerStateNotifier();
    n.toNoMatch();
    expect(n.value.phase, ScannerPhase.noMatch);
    expect(n.value.lastCardLabel, isNull);
  });

  test('toOffline sets phase to offline', () {
    final n = ScannerStateNotifier();
    n.toOffline();
    expect(n.value.phase, ScannerPhase.offline);
  });
```

Also update the existing `overlay shows toast after toDone` test's call from `n.toDone('Lightning Bolt', 1);` to `n.toDone('Lightning Bolt', price: null, newInQueue: 1);`.

- [ ] **Step 2: Run tests to verify they fail**

Run: `cmd.exe /c "powershell -File tool\\flutter.ps1 test test/features/scanner/scanner_screen_test.dart"`
Expected: compile errors on `ScannerPhase.matching`, `lastCardPrice`, `toMatching`, `toNoMatch`, `toOffline`, new `toDone` signature.

- [ ] **Step 3: Update ScannerState**

Replace the entire contents of `lib/features/scanner/scanner_state.dart` with:

```dart
import 'package:flutter/foundation.dart';

enum ScannerPhase {
  searching,
  tracking,
  capturing,
  processing,
  matching,
  done,
  noMatch,
  offline,
}

class ScannerState {
  const ScannerState({
    required this.phase,
    this.lastCardLabel,
    this.lastCardPrice,
    this.inQueue = 0,
    this.confirmed = 0,
    this.paused = false,
    this.torchOn = false,
  });
  final ScannerPhase phase;
  final String? lastCardLabel;
  final double? lastCardPrice;
  final int inQueue;
  final int confirmed;
  final bool paused;
  final bool torchOn;

  ScannerState copyWith({
    ScannerPhase? phase,
    String? lastCardLabel,
    double? lastCardPrice,
    int? inQueue,
    int? confirmed,
    bool? paused,
    bool? torchOn,
    bool clearLabel = false,
    bool clearPrice = false,
  }) =>
      ScannerState(
        phase: phase ?? this.phase,
        lastCardLabel: clearLabel ? null : (lastCardLabel ?? this.lastCardLabel),
        lastCardPrice: clearPrice ? null : (lastCardPrice ?? this.lastCardPrice),
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
  void toMatching() => value = value.copyWith(
        phase: ScannerPhase.matching,
        clearLabel: true,
        clearPrice: true,
      );
  void toDone(String label, {required double? price, required int newInQueue}) =>
      value = ScannerState(
        phase: ScannerPhase.done,
        lastCardLabel: label,
        lastCardPrice: price,
        inQueue: newInQueue,
        confirmed: value.confirmed,
        paused: value.paused,
        torchOn: value.torchOn,
      );
  void toNoMatch() => value = value.copyWith(
        phase: ScannerPhase.noMatch,
        clearLabel: true,
        clearPrice: true,
      );
  void toOffline() => value = value.copyWith(
        phase: ScannerPhase.offline,
        clearLabel: true,
        clearPrice: true,
      );

  void togglePause() => value = value.copyWith(paused: !value.paused);
  void toggleTorch() => value = value.copyWith(torchOn: !value.torchOn);
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `cmd.exe /c "powershell -File tool\\flutter.ps1 test test/features/scanner/scanner_screen_test.dart"`
Expected: all tests pass.

- [ ] **Step 5: Commit**

```bash
git add lib/features/scanner/scanner_state.dart test/features/scanner/scanner_screen_test.dart
git commit -m "scanner state: add matching/noMatch/offline phases and price"
```

---

### Task 6: Wire AppSettings and preloaded AudioPlayer into Deps

**Files:**
- Modify: `lib/app.dart`

- [ ] **Step 1: Read the current `Deps` class**

Run: `grep -n "class Deps" lib/app.dart`
Then: `sed -n '23,50p' lib/app.dart` to read the section.

- [ ] **Step 2: Add AppSettings + AudioPlayer to Deps**

In `lib/app.dart`, replace the existing `Deps` class block with:

```dart
class Deps {
  Deps._(this.db, this.scry, this.collection, this.scans, this.pipeline,
      this.settings, this.valuePlayer);
  final AppDatabase db;
  final ScryfallClient scry;
  final CollectionRepository collection;
  final ScansRepository scans;
  final ScanPipeline pipeline;
  final AppSettings settings;
  final AudioPlayer valuePlayer;

  static Future<Deps> create() async {
    final db = AppDatabase();
    final scry = ScryfallClient(http.Client());
    final collection = CollectionRepository(db, scry);
    final scans = ScansRepository(db);
    final pipeline = ScanPipeline(
      ocr: MlKitOcrRunner(),
      writer: ScanWriter(db),
      storage: ThumbnailStorage(),
      matcher: ScanMatcher(scry: scry),
      collection: collection,
    );
    final settings = await AppSettings.load();
    final valuePlayer = AudioPlayer();
    await valuePlayer.setSource(AssetSource('sounds/cash_register.mp3'));
    await valuePlayer.setReleaseMode(ReleaseMode.stop);
    return Deps._(db, scry, collection, scans, pipeline, settings, valuePlayer);
  }
}
```

Add these imports near the top of `lib/app.dart` (alphabetically):

```dart
import 'package:audioplayers/audioplayers.dart';
import 'app_settings.dart';
```

- [ ] **Step 3: Make the app await Deps.create()**

Find the existing state field `late final Deps deps = Deps.create();`. Replace the `_MtgScannerAppState` class with:

```dart
class _MtgScannerAppState extends State<MtgScannerApp> {
  Deps? _deps;
  GoRouter? _router;

  @override
  void initState() {
    super.initState();
    Deps.create().then((d) {
      if (!mounted) return;
      setState(() {
        _deps = d;
        _router = _buildRouter(d);
      });
    });
  }

  GoRouter _buildRouter(Deps deps) => GoRouter(
        initialLocation: '/collection',
        routes: [
          ShellRoute(
            observers: [appRouteObserver],
            builder: (ctx, state, child) =>
                AppShell(location: state.matchedLocation, child: child),
            routes: [
              GoRoute(
                  path: '/scan',
                  builder: (_, __) => ScannerScreen(
                      scans: deps.scans,
                      pipeline: deps.pipeline,
                      settings: deps.settings,
                      valuePlayer: deps.valuePlayer)),
              GoRoute(
                  path: '/queue',
                  builder: (_, __) => ReviewQueueScreen(
                      scans: deps.scans,
                      collection: deps.collection,
                      scry: deps.scry)),
              GoRoute(path: '/collection', routes: [
                GoRoute(
                    path: 'add',
                    builder: (_, __) => ManualAddScreen(
                        scry: deps.scry, collection: deps.collection)),
                GoRoute(
                    path: ':id',
                    builder: (ctx, st) => CollectionDetailScreen(
                        id: int.parse(st.pathParameters['id']!),
                        repo: deps.collection)),
              ], builder: (_, __) => CollectionScreen(repo: deps.collection)),
              GoRoute(
                  path: '/export',
                  builder: (_, __) =>
                      ExportScreen(repo: deps.collection)),
              GoRoute(
                  path: '/settings',
                  builder: (_, __) => SettingsScreen(
                      repo: deps.collection, settings: deps.settings)),
            ],
          ),
        ],
      );

  @override
  void dispose() {
    _deps?.db.close();
    _deps?.valuePlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = _router;
    if (router == null) {
      return const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }
    return MaterialApp.router(
      title: 'MTG Scanner',
      theme: ThemeData(colorSchemeSeed: Colors.deepPurple, useMaterial3: true),
      routerConfig: router,
    );
  }
}
```

- [ ] **Step 4: Verify the file compiles**

Run: `cmd.exe /c "powershell -File tool\\flutter.ps1 analyze lib/app.dart"`
Expected: "No issues found!" (or pre-existing unrelated infos). If there are errors about `ScannerScreen`, `SettingsScreen` — those are introduced in later tasks, verify by temporarily commenting out the `settings:`/`valuePlayer:` args until Task 7 and Task 8 land. **Do not commit with failing analysis.** The simpler path: complete Task 7 and Task 8 first if needed, or compile once all three are ready.

- [ ] **Step 5: Commit (only after Tasks 7+8 land if analyzer fails)**

```bash
git add lib/app.dart
git commit -m "deps: load AppSettings and preload value-alert sound"
```

---

### Task 7: Settings screen — value alert threshold

**Files:**
- Modify: `lib/features/settings/settings_screen.dart`

- [ ] **Step 1: Replace SettingsScreen with a version that takes AppSettings and shows the threshold tile**

Replace the entire contents of `lib/features/settings/settings_screen.dart` with:

```dart
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../app_settings.dart';
import '../../data/repositories/collection_repository.dart';
import 'backup_restore_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    required this.repo,
    required this.settings,
    super.key,
  });
  final CollectionRepository repo;
  final AppSettings settings;
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int? _refreshDone;
  int? _refreshTotal;

  @override
  void initState() {
    super.initState();
    widget.settings.addListener(_onSettingsChanged);
  }

  @override
  void dispose() {
    widget.settings.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _refreshAll() async {
    setState(() {
      _refreshDone = 0;
      _refreshTotal = null;
    });
    await widget.repo.refreshAllPrices(onProgress: (done, total) {
      if (!mounted) return;
      setState(() {
        _refreshDone = done;
        _refreshTotal = total;
      });
    });
    if (!mounted) return;
    setState(() {
      _refreshDone = null;
      _refreshTotal = null;
    });
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Prices refreshed')));
  }

  Future<void> _editThreshold() async {
    final ctrl = TextEditingController(
        text: widget.settings.valueAlertThreshold.toStringAsFixed(2));
    final result = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Value alert threshold'),
        content: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          decoration: const InputDecoration(
            prefixText: r'$ ',
            helperText: 'Sound plays when scanned card is above this USD value',
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final v = double.tryParse(ctrl.text.trim());
              if (v != null && v.isFinite && v > 0) Navigator.of(ctx).pop(v);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result != null) await widget.settings.setValueAlertThreshold(result);
  }

  @override
  Widget build(BuildContext context) {
    final backup = BackupRestoreService(widget.repo.db);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Value alert threshold'),
            subtitle: Text(
                r'$' '${widget.settings.valueAlertThreshold.toStringAsFixed(2)}'),
            leading: const Icon(Icons.notifications_active),
            onTap: _editThreshold,
          ),
          const Divider(),
          ListTile(
            title: const Text('Refresh all prices'),
            subtitle: _refreshDone == null
                ? const Text('Re-fetches every card from Scryfall (rate-limited)')
                : Text('Refreshing… $_refreshDone / ${_refreshTotal ?? "?"}'),
            trailing: _refreshDone == null
                ? const Icon(Icons.refresh)
                : const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2)),
            onTap: _refreshDone == null ? _refreshAll : null,
          ),
          const Divider(),
          ListTile(
            title: const Text('Export JSON backup'),
            leading: const Icon(Icons.save_alt),
            onTap: () async {
              final f = await backup.exportJson();
              await Share.shareXFiles([XFile(f.path)]);
            },
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Verify compile**

Run: `cmd.exe /c "powershell -File tool\\flutter.ps1 analyze lib/features/settings/settings_screen.dart"`
Expected: "No issues found!"

- [ ] **Step 3: Commit**

```bash
git add lib/features/settings/settings_screen.dart
git commit -m "settings: add value alert threshold editor"
```

---

### Task 8: Scanner screen — matching overlay, price display, sound trigger

**Files:**
- Modify: `lib/features/scanner/scanner_screen.dart`

- [ ] **Step 1: Update ScannerScreen constructor and _ScannerBody to accept AppSettings and AudioPlayer**

In `lib/features/scanner/scanner_screen.dart`:

Near the top, add imports:

```dart
import 'package:audioplayers/audioplayers.dart';

import '../../app_settings.dart';
```

Replace the `ScannerScreen` class with:

```dart
class ScannerScreen extends StatelessWidget {
  const ScannerScreen({
    required this.scans,
    required this.pipeline,
    required this.settings,
    required this.valuePlayer,
    super.key,
  });
  final ScansRepository scans;
  final ScanPipeline pipeline;
  final AppSettings settings;
  final AudioPlayer valuePlayer;

  @override
  Widget build(BuildContext context) => CameraPermissionGate(
        child: (ctx) => _ScannerBody(
          scans: scans,
          pipeline: pipeline,
          settings: settings,
          valuePlayer: valuePlayer,
        ),
      );
}
```

Replace the `_ScannerBody` class declaration with:

```dart
class _ScannerBody extends StatefulWidget {
  const _ScannerBody({
    required this.scans,
    required this.pipeline,
    required this.settings,
    required this.valuePlayer,
  });
  final ScansRepository scans;
  final ScanPipeline pipeline;
  final AppSettings settings;
  final AudioPlayer valuePlayer;
  @override
  State<_ScannerBody> createState() => _ScannerBodyState();
}
```

- [ ] **Step 2: Rewrite `_onFrame` to use the new pipeline and state transitions**

Locate `_onFrame` and replace its body with:

```dart
  Future<void> _onFrame(CameraImage img) async {
    if (_busy || _state.value.paused || _externallyPaused) return;
    _busy = true;
    try {
      final bytes = _bgrJpegFromFrame(img);
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

      final sinceLast = DateTime.now().difference(
          _lastCaptureAt ?? DateTime.fromMillisecondsSinceEpoch(0));
      if (sinceLast.inMilliseconds < 500) return;

      if (_externallyPaused || _state.value.paused) return;
      _state.toCapturing();
      final upright = warpToUpright(bytes, quad: rect.quad);
      _state.toMatching();
      final res = await widget.pipeline
          .captureFromWarpedCrop(upright, forceFoil: _forceFoil.value);
      _lastCaptureAt = DateTime.now();

      if (_externallyPaused || _state.value.paused) {
        _state.toSearching();
        _tracker.reset();
        return;
      }

      switch (res.outcome) {
        case CaptureOutcome.matched:
          final name = res.matchedName ?? 'scan';
          if (_lastLabel != null && _lastLabel == name) {
            _state.toSearching();
            _tracker.reset();
            return;
          }
          _lastLabel = name;
          _state.toDone(
            name,
            price: res.price,
            newInQueue: _state.value.inQueue + 1,
          );
          if (res.price != null &&
              res.price! > widget.settings.valueAlertThreshold) {
            unawaited(_playValueAlert());
          }
          break;
        case CaptureOutcome.noMatch:
          _state.toNoMatch();
          break;
        case CaptureOutcome.offline:
          _state.toOffline();
          break;
      }
      await Future<void>.delayed(const Duration(milliseconds: 700));
      _state.toSearching();
      _tracker.reset();
    } finally {
      _busy = false;
    }
  }

  Future<void> _playValueAlert() async {
    try {
      await widget.valuePlayer.stop();
      await widget.valuePlayer.resume();
    } catch (_) {}
  }
```

Add at the top of the file (next to existing `import 'dart:typed_data';`):

```dart
import 'dart:async';
```

This gives you `unawaited`.

- [ ] **Step 3: Remove the old `scans.reject` rollback import usage if unused**

Search the file:

```bash
grep -n "scans.reject\|widget.scans.reject" lib/features/scanner/scanner_screen.dart
```

If nothing matches, no change needed. If any leftover line references `scans.reject` inside `_onFrame`, delete it.

- [ ] **Step 4: Update the Overlay widget to render matching/done/noMatch/offline states**

Find the `_Overlay` class near the bottom. Replace its `build` method with:

```dart
  @override
  Widget build(BuildContext context) {
    final (text, color) = switch (state.phase) {
      ScannerPhase.matching => ('\u22EF matching…', Colors.white70),
      ScannerPhase.done when state.lastCardLabel != null => (
          state.lastCardPrice != null
              ? '\u2713 ${state.lastCardLabel} — \$${state.lastCardPrice!.toStringAsFixed(2)}'
              : '\u2713 ${state.lastCardLabel}',
          Colors.white,
        ),
      ScannerPhase.noMatch => ('\u2717 no match', Colors.redAccent),
      ScannerPhase.offline => ('\u26A0 offline', Colors.orangeAccent),
      _ => (null, Colors.white),
    };
    if (text == null) return const SizedBox.shrink();
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
          child: Text(text, style: TextStyle(color: color)),
        ),
      ),
    );
  }
```

- [ ] **Step 5: Verify compile + all tests still pass**

Run: `cmd.exe /c "powershell -File tool\\flutter.ps1 analyze lib/"`
Expected: "No issues found!" (or pre-existing unrelated infos).

Run: `cmd.exe /c "powershell -File tool\\flutter.ps1 test"`
Expected: all tests pass.

- [ ] **Step 6: Build release APK**

Run: `cmd.exe /c "powershell -File tool\\flutter.ps1 build apk --release --split-per-abi --target-platform=android-arm64"`
Expected: `✓ Built build\\app\\outputs\\flutter-apk\\app-arm64-v8a-release.apk`.

- [ ] **Step 7: Install and manual-test on the device**

Run: `cmd.exe /c "C:\\Users\\Krs19\\AppData\\Local\\Android\\Sdk\\platform-tools\\adb.exe -s R5CX63G9RAA install -r build\\app\\outputs\\flutter-apk\\app-arm64-v8a-release.apk"`
Expected: `Performing Streamed Install` followed by `Success`.

Manually on the phone:
- Scan a known low-value card → overlay should show `⋯ matching…` then `✓ <name> — $<price>` (no sound if below threshold).
- Scan a card worth more than the threshold → sound plays on the `✓` transition.
- Put a blank page in front of the camera that yields unmatched OCR → overlay shows `✗ no match`, nothing added to the review queue.
- Toggle airplane mode, scan a card → overlay shows `⚠ offline`, nothing added to the queue.
- Open Settings → Value alert threshold → change it → rescan a card in between → new threshold takes effect without app restart.

- [ ] **Step 8: Commit**

```bash
git add lib/features/scanner/scanner_screen.dart
git commit -m "scanner: matching overlay, price display, value alert sound"
```

---

### Task 9: Finalise Deps commit and push

**Files:**
- (no code changes)

- [ ] **Step 1: Confirm `lib/app.dart` commit from Task 6 is in**

Run: `git log --oneline -1 -- lib/app.dart`
Expected: shows the "deps: load AppSettings and preload value-alert sound" commit.

If Task 6 was deferred because the analyzer failed at that point, commit it now:

```bash
git add lib/app.dart
git commit -m "deps: load AppSettings and preload value-alert sound"
```

- [ ] **Step 2: Run the full test suite once more**

Run: `cmd.exe /c "powershell -File tool\\flutter.ps1 test"`
Expected: all tests pass.

- [ ] **Step 3: Build and install one last time**

Run: `cmd.exe /c "powershell -File tool\\flutter.ps1 build apk --release --split-per-abi --target-platform=android-arm64"`
Then: `cmd.exe /c "C:\\Users\\Krs19\\AppData\\Local\\Android\\Sdk\\platform-tools\\adb.exe -s R5CX63G9RAA install -r build\\app\\outputs\\flutter-apk\\app-arm64-v8a-release.apk"`
Expected: Success.
