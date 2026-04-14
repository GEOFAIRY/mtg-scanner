# MTG Scanner Plan B2 — Scryfall Auto-Match Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** After a scan row is inserted by Plan B1's pipeline, call Scryfall to populate the `matched_*` columns with the best-guess card identity, confidence, and live prices. If confidence ≥ 0.8, auto-move the scan into the collection. Below 0.8, leave it in the review queue for the user.

**Architecture:** A new `ScanMatcher` service, injected into `ScanPipeline`. After `writer.insertPending(...)`, the pipeline hands the row id + `ParsedOcr` to the matcher. The matcher tries `/cards/{set}/{number}` when the OCR has both a set and a collector number (→ confidence 1.0), else falls back to `/cards/named?fuzzy=...` (→ 0.6). On failure: confidence 0.0, row stays unmatched. When confidence ≥ 0.8, the matcher calls `CollectionRepository.addFromScryfall()` and `ScansRepository.confirm()` so the row leaves the queue. All Scryfall calls are already rate-limited by `ScryfallClient`'s single-flight chain (100 ms gap) — no extra throttling needed.

**Tech Stack:** Flutter, drift, existing `ScryfallClient` (has `cardBySetAndNumber` + `cardByFuzzyName`), `ScansDao.updateMatch`, `CollectionRepository.addFromScryfall`, mocktail for tests.

**Existing surfaces to reuse (do not re-create):**
- `lib/data/scryfall/scryfall_client.dart` — `cardBySetAndNumber(set, number)`, `cardByFuzzyName(name)`, throws `ScryfallNotFound` / `ScryfallException`.
- `lib/data/db/daos/scans_dao.dart` — `updateMatch(id, {scryfallId, name, setCode, collectorNumber, confidence, priceUsd, priceUsdFoil})`.
- `lib/data/repositories/scans_repository.dart` — `confirm(id)`.
- `lib/data/repositories/collection_repository.dart` — `addFromScryfall(card, foil:, condition:, language:)`.
- `lib/features/scanner/parsed_ocr.dart` — `ParsedOcr` with `setCode`, `collectorNumber`, `name` getters.
- `lib/features/scanner/scan_pipeline.dart` — `captureFromWarpedCrop` currently wires OCR → writer; we'll extend it.

---

## File Structure

**Create:**
- `lib/features/scanner/scan_matcher.dart` — the service.
- `test/features/scanner/scan_matcher_test.dart`

**Modify:**
- `lib/features/scanner/scan_pipeline.dart` — add `matcher` constructor dep and call `matcher.matchAfterInsert(...)` after `insertPending`. Keep `captureFromWarpedCrop`'s return contract unchanged.
- `test/features/scanner/scan_pipeline_test.dart` — pass a fake matcher; assert it's called.
- `lib/app.dart` — construct the matcher and inject it into the `ScanPipeline`.

---

## Task 1: ScanMatcher service

**Files:**
- Create: `lib/features/scanner/scan_matcher.dart`
- Test: `test/features/scanner/scan_matcher_test.dart`

- [ ] **Step 1: Write failing test**

`test/features/scanner/scan_matcher_test.dart`:

```dart
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mtg_scanner/data/db/database.dart';
import 'package:mtg_scanner/data/repositories/collection_repository.dart';
import 'package:mtg_scanner/data/repositories/scans_repository.dart';
import 'package:mtg_scanner/data/scryfall/scryfall_client.dart';
import 'package:mtg_scanner/data/scryfall/scryfall_models.dart';
import 'package:mtg_scanner/features/scanner/parsed_ocr.dart';
import 'package:mtg_scanner/features/scanner/scan_matcher.dart';
import 'package:drift/drift.dart' show Value;

class _FakeScry extends Mock implements ScryfallClient {}

ScryfallCard _card({
  String id = 'sid-1',
  String name = 'Lightning Bolt',
  String set = '2xm',
  String collector = '137',
  double? usd = 1.80,
}) =>
    ScryfallCard(
      id: id,
      name: name,
      set: set,
      collectorNumber: collector,
      prices: ScryfallPrices(usd: usd, usdFoil: null),
    );

Future<int> _insertPendingScan(AppDatabase db, String rawName) =>
    db.into(db.scans).insert(ScansCompanion.insert(
          capturedAt: DateTime(2026, 4, 15),
          rawName: rawName,
          rawSetCollector: '',
          confidence: const Value(0.0),
          foilGuess: const Value(-1),
        ));

void main() {
  late AppDatabase db;
  late _FakeScry scry;
  late CollectionRepository collection;
  late ScansRepository scans;
  late ScanMatcher matcher;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    scry = _FakeScry();
    collection = CollectionRepository(db, scry);
    scans = ScansRepository(db);
    matcher = ScanMatcher(scry: scry, collection: collection, scans: scans, db: db);
  });
  tearDown(() => db.close());

  test('exact set+collector match populates row and auto-confirms', () async {
    final id = await _insertPendingScan(db, 'Lightning Bolt');
    final parsed = ParsedOcr.from(
        rawName: 'Lightning Bolt', rawSetCollector: '2xm 137');
    when(() => scry.cardBySetAndNumber('2XM', '137'))
        .thenAnswer((_) async => _card());

    await matcher.matchAfterInsert(scanId: id, parsed: parsed);

    final row = await (db.select(db.scans)..where((t) => t.id.equals(id)))
        .getSingle();
    expect(row.confidence, 1.0);
    expect(row.status, 'confirmed');
    final coll = await db.select(db.collection).get();
    expect(coll, hasLength(1));
    expect(coll.single.name, 'Lightning Bolt');
  });

  test('fuzzy fallback when set+collector 404 keeps row pending at 0.6', () async {
    final id = await _insertPendingScan(db, 'Lightning Bolt');
    final parsed = ParsedOcr.from(
        rawName: 'Lightning Bolt', rawSetCollector: '2xm 999');
    when(() => scry.cardBySetAndNumber('2XM', '999'))
        .thenThrow(const ScryfallNotFound('2xm/999'));
    when(() => scry.cardByFuzzyName('Lightning Bolt'))
        .thenAnswer((_) async => _card());

    await matcher.matchAfterInsert(scanId: id, parsed: parsed);

    final row = await (db.select(db.scans)..where((t) => t.id.equals(id)))
        .getSingle();
    expect(row.confidence, closeTo(0.6, 1e-9));
    expect(row.status, 'pending');
    expect(row.matchedName, 'Lightning Bolt');
    final coll = await db.select(db.collection).get();
    expect(coll, isEmpty);
  });

  test('no parsed set+collector goes straight to fuzzy', () async {
    final id = await _insertPendingScan(db, 'Lightning Bolt');
    final parsed = ParsedOcr.from(
        rawName: 'Lightning Bolt', rawSetCollector: 'garbage');
    when(() => scry.cardByFuzzyName('Lightning Bolt'))
        .thenAnswer((_) async => _card());

    await matcher.matchAfterInsert(scanId: id, parsed: parsed);

    final row = await (db.select(db.scans)..where((t) => t.id.equals(id)))
        .getSingle();
    expect(row.confidence, closeTo(0.6, 1e-9));
    verifyNever(() => scry.cardBySetAndNumber(any(), any()));
  });

  test('both lookups fail -> confidence 0.0, row untouched at pending', () async {
    final id = await _insertPendingScan(db, 'xxjj');
    final parsed =
        ParsedOcr.from(rawName: 'xxjj', rawSetCollector: 'garbage');
    when(() => scry.cardByFuzzyName('xxjj'))
        .thenThrow(const ScryfallNotFound('xxjj'));

    await matcher.matchAfterInsert(scanId: id, parsed: parsed);

    final row = await (db.select(db.scans)..where((t) => t.id.equals(id)))
        .getSingle();
    expect(row.confidence, 0.0);
    expect(row.matchedScryfallId, isNull);
    expect(row.status, 'pending');
  });

  test('empty parsed name and no set skips network and stays at 0.0', () async {
    final id = await _insertPendingScan(db, '');
    final parsed = ParsedOcr.from(rawName: '', rawSetCollector: '');
    await matcher.matchAfterInsert(scanId: id, parsed: parsed);
    verifyNever(() => scry.cardByFuzzyName(any()));
    verifyNever(() => scry.cardBySetAndNumber(any(), any()));
    final row = await (db.select(db.scans)..where((t) => t.id.equals(id)))
        .getSingle();
    expect(row.confidence, 0.0);
  });
}
```

- [ ] **Step 2: Run to verify it fails**

```
powershell -File tool\flutter.ps1 test test/features/scanner/scan_matcher_test.dart
```
Expected: FAIL — `ScanMatcher` not defined.

- [ ] **Step 3: Implement**

`lib/features/scanner/scan_matcher.dart`:

```dart
import '../../data/db/database.dart';
import '../../data/repositories/collection_repository.dart';
import '../../data/repositories/scans_repository.dart';
import '../../data/scryfall/scryfall_client.dart';
import '../../data/scryfall/scryfall_models.dart';
import 'parsed_ocr.dart';

class ScanMatcher {
  ScanMatcher({
    required this.scry,
    required this.collection,
    required this.scans,
    required this.db,
    this.autoConfirmThreshold = 0.8,
  });

  final ScryfallClient scry;
  final CollectionRepository collection;
  final ScansRepository scans;
  final AppDatabase db;
  final double autoConfirmThreshold;

  Future<void> matchAfterInsert({
    required int scanId,
    required ParsedOcr parsed,
  }) async {
    final match = await _findMatch(parsed);
    if (match == null) return;
    await db.scansDao.updateMatch(
      scanId,
      scryfallId: match.card.id,
      name: match.card.name,
      setCode: match.card.set,
      collectorNumber: match.card.collectorNumber,
      confidence: match.confidence,
      priceUsd: match.card.prices.usd,
      priceUsdFoil: match.card.prices.usdFoil,
    );
    if (match.confidence >= autoConfirmThreshold) {
      await collection.addFromScryfall(match.card);
      await scans.confirm(scanId);
    }
  }

  Future<_MatchResult?> _findMatch(ParsedOcr parsed) async {
    if (parsed.setCode != null && parsed.collectorNumber != null) {
      try {
        final c = await scry.cardBySetAndNumber(
            parsed.setCode!, parsed.collectorNumber!);
        return _MatchResult(c, 1.0);
      } on ScryfallNotFound {
        // fall through to fuzzy
      } on ScryfallException {
        return null;
      }
    }
    if (parsed.name.isEmpty) return null;
    try {
      final c = await scry.cardByFuzzyName(parsed.name);
      return _MatchResult(c, 0.6);
    } on ScryfallNotFound {
      return null;
    } on ScryfallException {
      return null;
    }
  }
}

class _MatchResult {
  _MatchResult(this.card, this.confidence);
  final ScryfallCard card;
  final double confidence;
}
```

- [ ] **Step 4: Run test to verify PASS**

```
powershell -File tool\flutter.ps1 test test/features/scanner/scan_matcher_test.dart
```
Expected: all 5 tests PASS.

- [ ] **Step 5: Commit**

```
git add lib/features/scanner/scan_matcher.dart test/features/scanner/scan_matcher_test.dart
git commit -m "add scryfall scan matcher with auto-confirm threshold"
```

---

## Task 2: Wire matcher into ScanPipeline

**Files:**
- Modify: `lib/features/scanner/scan_pipeline.dart`
- Test: `test/features/scanner/scan_pipeline_test.dart`

- [ ] **Step 1: Update pipeline test to pass a fake matcher**

Edit `test/features/scanner/scan_pipeline_test.dart`. At the top of `setUp`, add a fake matcher and pass it to `ScanPipeline`. Also add one assertion that `matchAfterInsert` was called with the returned id.

Add imports:
```dart
import 'package:mtg_scanner/features/scanner/scan_matcher.dart';
import 'package:mtg_scanner/features/scanner/parsed_ocr.dart';
```

Add fake class near `_FakeOcr`:
```dart
class _FakeMatcher extends Mock implements ScanMatcher {}
```

In `setUp`, add:
```dart
registerFallbackValue(
    ParsedOcr.from(rawName: '', rawSetCollector: ''));
```

Update the pipeline construction and add a stub + assertion inside the test:
```dart
final matcher = _FakeMatcher();
when(() => matcher.matchAfterInsert(
        scanId: any(named: 'scanId'), parsed: any(named: 'parsed')))
    .thenAnswer((_) async {});

final pipeline = ScanPipeline(
  ocr: ocr,
  writer: ScanWriter(db),
  storage: ThumbnailStorage(),
  matcher: matcher,
);

// ... after awaiting captureFromWarpedCrop:
verify(() => matcher.matchAfterInsert(
    scanId: res.id, parsed: any(named: 'parsed'))).called(1);
```

- [ ] **Step 2: Run to see new failure**

```
powershell -File tool\flutter.ps1 test test/features/scanner/scan_pipeline_test.dart
```
Expected: FAIL — `ScanPipeline` constructor does not accept `matcher`.

- [ ] **Step 3: Update pipeline**

Edit `lib/features/scanner/scan_pipeline.dart`:

```dart
import 'dart:typed_data';
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
    final id = await writer.insertPending(parsed: parsed, thumbPath: thumbPath);
    // Fire-and-forget so the scanner loop isn't blocked by Scryfall latency.
    unawaited(matcher.matchAfterInsert(scanId: id, parsed: parsed));
    final label = parsed.name.isNotEmpty ? parsed.name : 'scan';
    return (id: id, label: label);
  }
}
```

Add at the top of the file:
```dart
import 'dart:async';
```

- [ ] **Step 4: Run test**

```
powershell -File tool\flutter.ps1 test test/features/scanner/scan_pipeline_test.dart
```
Expected: PASS. The `verify(...)` call works because `unawaited` returns immediately but still dispatches to the stub; the fake completes synchronously.

> **If verify fires before the stub runs:** the fake `matchAfterInsert` call happens synchronously when invoked. If the test flakes, `await Future<void>.delayed(Duration.zero)` once before the `verify`.

- [ ] **Step 5: Commit**

```
git add lib/features/scanner/scan_pipeline.dart test/features/scanner/scan_pipeline_test.dart
git commit -m "wire scan matcher into pipeline with fire-and-forget"
```

---

## Task 3: Wire matcher into app startup

**Files:**
- Modify: `lib/app.dart` (specifically the `Deps` / `Deps.create` area where `ScanPipeline` is constructed — see B1's Task 11 wiring).

- [ ] **Step 1: Construct matcher + pass to pipeline**

Open `lib/app.dart`. Find where `ScanPipeline` is built (near the collection repo). Replace the pipeline construction with:

```dart
final matcher = ScanMatcher(
  scry: scry,
  collection: collectionRepo,
  scans: scansRepo,
  db: db,
);
final pipeline = ScanPipeline(
  ocr: MlKitOcrRunner(),
  writer: ScanWriter(db),
  storage: ThumbnailStorage(),
  matcher: matcher,
);
```

Adjust the identifier names (`scry`, `collectionRepo`, `scansRepo`, `db`) to match what's already in the file. If a reference doesn't exist — for instance `scry` is constructed with a different name — use the existing name; do not add a new one.

- [ ] **Step 2: Compile + test**

```
powershell -File tool\flutter.ps1 analyze
powershell -File tool\flutter.ps1 test
```
Expected: clean, all tests pass.

- [ ] **Step 3: Commit**

```
git add lib/app.dart
git commit -m "inject scan matcher at app startup"
```

---

## Task 4: On-device smoke test + ship

- [ ] **Step 1: Build + install**

```
powershell -File tool\flutter.ps1 build apk --debug
C:\Users\Krs19\AppData\Local\Android\sdk\platform-tools\adb.exe install -r build\app\outputs\flutter-apk\app-debug.apk
```

- [ ] **Step 2: Verify**

On-device:
1. Scan a card. Within ~2 s after the capture toast, the new review-queue row should flip from "OCR: {raw}" to the matched card name (e.g. "Lightning Bolt"). If OCR produced a good-enough set/collector, the row should auto-disappear (moved to collection). If OCR only got a rough name, the row stays pending at 60% confidence.
2. Open the collection screen — confirmed scans appear with live prices.
3. Airplane-mode test: enable airplane mode, scan a card, re-enable network. The row stays pending and Scryfall lookup fails silently; the row remains editable in the review queue. Re-running lookup manually is outside B2 scope (lives in the spec's §Error Handling, deferred).

If any of those fail, stop and diagnose rather than pushing forward.

- [ ] **Step 3: Mark complete**

Update `RESUME.md`: B2 done, B3 (foil detection) is the remaining unstarted plan.

- [ ] **Step 4: Commit**

```
git add RESUME.md
git commit -m "mark plan b2 complete"
```

---

## Self-Review Notes

- **Spec coverage:** §Lookup layer (set+collector → fuzzy fallback, confidence 1.0 / 0.6 / 0.3) and §Confidence scoring (≥ 0.8 auto-move) are implemented in Task 1. The "0.3 for low-quality OCR" tier from the spec is subsumed by 0.0 fall-through here — the review queue already shows the raw OCR so users can fix it via Edit. That's a small simplification vs the spec; surface in commit message.
- **Fire-and-forget:** Scryfall matching is intentionally not awaited inside `captureFromWarpedCrop` so the scanner loop isn't blocked by 200–800 ms round-trips. The scan row is visible immediately at `confidence=0`, then updated in place when Scryfall responds. Because `watchPending()` streams, the review queue row updates live.
- **Auto-confirm path:** Uses existing `CollectionRepository.addFromScryfall` + `ScansRepository.confirm`. Merge rule (spec §Data Model) is already handled by `upsertMerging`.
- **Types consistent:** `ScanMatcher.matchAfterInsert({scanId, parsed})` matches the call site in `ScanPipeline`. `_MatchResult` is file-private. Signatures of `updateMatch`, `cardBySetAndNumber`, `cardByFuzzyName` copied verbatim from the existing source.
- **No placeholders.** Every step has complete code or exact commands.
- **Deferred to B3:** foil detection still leaves `foilGuess = -1` on inserted rows. Matcher does not toggle foil. Manual foil switch in the review queue remains the user's escape hatch.
- **Deferred to a follow-up:** "retry failed lookups when back online" bulk action (spec §Error Handling). Out of B2.
