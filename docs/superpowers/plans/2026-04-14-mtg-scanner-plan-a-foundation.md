# MTG Scanner — Plan A: Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship a usable Flutter Android app that lets a user manually add MTG cards (via Scryfall search), view them in a local collection with live prices, and export the collection to Moxfield text / CSV. This is the foundation the scanner (Plan B) will layer onto.

**Architecture:** Flutter app, single process, layered — `data/` (Drift SQLite + Scryfall REST client + repositories), `features/` (one folder per screen), `shared/` (cross-cutting widgets). No backend. Scryfall is called live with a rate-limited single-flight HTTP client. Pure-function formatters for export are golden-file tested.

**Tech Stack:** Flutter (stable), Dart 3, `drift` (SQLite), `http`, `go_router`, `shared_preferences`, `path_provider`, `share_plus`, `intl` (currency formatting). Tests: `flutter_test`, `mocktail`.

**Spec reference:** `docs/superpowers/specs/2026-04-14-mtg-card-scanner-design.md`

---

## File Structure

```
lib/
  main.dart                              # bootstrap, DI wiring
  app.dart                               # MaterialApp + go_router
  data/
    db/
      database.dart                      # Drift DB class + generated code
      tables.dart                        # Scans, Collection table defs
      daos/
        scans_dao.dart
        collection_dao.dart
    scryfall/
      scryfall_client.dart               # rate-limited HTTP
      scryfall_models.dart               # ScryfallCard, Prices
    repositories/
      collection_repository.dart         # merge rule, price refresh
      scans_repository.dart              # queue CRUD
  features/
    shell/
      app_shell.dart                     # bottom nav
    scanner/
      scanner_placeholder_screen.dart    # "coming in plan B"
    review_queue/
      review_queue_screen.dart
      review_queue_item_tile.dart
      edit_match_modal.dart
    collection/
      collection_screen.dart
      collection_detail_screen.dart
      manual_add_screen.dart
    export/
      export_screen.dart
      formatters/
        moxfield_text_formatter.dart
        moxfield_csv_formatter.dart
    settings/
      settings_screen.dart
      backup_restore_service.dart
  shared/
    widgets/
      price_text.dart
      printing_picker.dart
test/
  data/
    repositories/
      collection_repository_test.dart
    scryfall/
      scryfall_client_test.dart
  features/
    export/
      moxfield_text_formatter_test.dart
      moxfield_csv_formatter_test.dart
    review_queue/
      review_queue_screen_test.dart
  fixtures/
    scryfall/
      lightning_bolt_2xm_137.json
      snapcaster_mage_mm3_58.json
```

---

### Task 1: Project Scaffold + Dependencies

**Files:**
- Create: `pubspec.yaml`, `analysis_options.yaml`, `.gitignore`
- Create: `lib/main.dart`, `lib/app.dart`

- [ ] **Step 1: Create the Flutter project**

Run:
```bash
cd /mnt/c/Users/Krs19/Dev/mtg-scanner
flutter create --platforms=android --org com.krs19.mtgscanner --project-name mtg_scanner .
```
Expected: Flutter project files scaffolded into current dir (preserves `docs/`).

- [ ] **Step 2: Add dependencies to `pubspec.yaml`**

Replace the `dependencies:` and `dev_dependencies:` blocks:

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  drift: ^2.18.0
  sqlite3_flutter_libs: ^0.5.24
  path_provider: ^2.1.4
  path: ^1.9.0
  http: ^1.2.2
  go_router: ^14.2.7
  shared_preferences: ^2.3.2
  share_plus: ^10.0.2
  intl: ^0.19.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0
  drift_dev: ^2.18.0
  build_runner: ^2.4.12
  mocktail: ^1.0.4
```

Run:
```bash
flutter pub get
```
Expected: resolves dependencies without error.

- [ ] **Step 3: Tighten analyzer**

Overwrite `analysis_options.yaml`:

```yaml
include: package:flutter_lints/flutter.yaml

analyzer:
  language:
    strict-casts: true
    strict-inference: true
    strict-raw-types: true
  errors:
    missing_required_param: error
    missing_return: error
    todo: ignore

linter:
  rules:
    - prefer_const_constructors
    - prefer_final_locals
    - avoid_print
    - unawaited_futures
```

- [ ] **Step 4: Minimal bootstrap**

Overwrite `lib/main.dart`:

```dart
import 'package:flutter/material.dart';
import 'app.dart';

void main() {
  runApp(const MtgScannerApp());
}
```

Create `lib/app.dart`:

```dart
import 'package:flutter/material.dart';

class MtgScannerApp extends StatelessWidget {
  const MtgScannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MTG Scanner',
      theme: ThemeData(colorSchemeSeed: Colors.deepPurple, useMaterial3: true),
      home: const Scaffold(body: Center(child: Text('MTG Scanner'))),
    );
  }
}
```

- [ ] **Step 5: Verify it builds**

Run:
```bash
flutter analyze
flutter test
```
Expected: analyze clean, no tests yet — "No tests ran" is acceptable.

- [ ] **Step 6: Commit**

```bash
git init
git add -A
git commit -m "scaffold flutter project with core deps"
```

---

### Task 2: Drift Tables

**Files:**
- Create: `lib/data/db/tables.dart`

- [ ] **Step 1: Define tables**

Create `lib/data/db/tables.dart`:

```dart
import 'package:drift/drift.dart';

class Scans extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get capturedAt => dateTime()();
  TextColumn get rawName => text()();
  TextColumn get rawSetCollector => text()();
  TextColumn get matchedScryfallId => text().nullable()();
  TextColumn get matchedName => text().nullable()();
  TextColumn get matchedSet => text().nullable()();
  TextColumn get matchedCollectorNumber => text().nullable()();
  RealColumn get confidence => real().withDefault(const Constant(0))();
  IntColumn get foilGuess => integer().withDefault(const Constant(-1))();
  TextColumn get cropImagePath => text().nullable()();
  RealColumn get priceUsd => real().nullable()();
  RealColumn get priceUsdFoil => real().nullable()();
  TextColumn get status =>
      text().withDefault(const Constant('pending'))();
}

class Collection extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get scryfallId => text()();
  TextColumn get name => text()();
  TextColumn get setCode => text()();
  TextColumn get collectorNumber => text()();
  IntColumn get count => integer().withDefault(const Constant(1))();
  IntColumn get foil => integer().withDefault(const Constant(0))();
  TextColumn get condition => text().withDefault(const Constant('NM'))();
  TextColumn get language => text().withDefault(const Constant('en'))();
  DateTimeColumn get addedAt => dateTime()();
  RealColumn get priceUsd => real().nullable()();
  RealColumn get priceUsdFoil => real().nullable()();
  DateTimeColumn get priceUpdatedAt => dateTime().nullable()();
  TextColumn get notes => text().nullable()();
}
```

- [ ] **Step 2: Verify analyzer**

Run:
```bash
flutter analyze
```
Expected: clean.

- [ ] **Step 3: Commit**

```bash
git add lib/data/db/tables.dart
git commit -m "add drift schema for scans and collection"
```

---

### Task 3: Drift Database + Codegen

**Files:**
- Create: `lib/data/db/database.dart`
- Modify: (generated) `lib/data/db/database.g.dart`

- [ ] **Step 1: Write database class**

Create `lib/data/db/database.dart`:

```dart
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'tables.dart';

part 'database.g.dart';

@DriftDatabase(tables: [Scans, Collection])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_open());
  AppDatabase.forTesting(QueryExecutor e) : super(e);

  @override
  int get schemaVersion => 1;
}

LazyDatabase _open() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'mtg_scanner.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
```

- [ ] **Step 2: Run codegen**

Run:
```bash
dart run build_runner build --delete-conflicting-outputs
```
Expected: generates `lib/data/db/database.g.dart` without errors.

- [ ] **Step 3: Verify analyzer and build**

Run:
```bash
flutter analyze
```
Expected: clean.

- [ ] **Step 4: Commit**

```bash
git add lib/data/db/database.dart lib/data/db/database.g.dart
git commit -m "wire drift database and run codegen"
```

---

### Task 4: Collection DAO + Merge Rule (TDD)

**Files:**
- Create: `lib/data/db/daos/collection_dao.dart`
- Create: `test/data/repositories/collection_repository_test.dart`

- [ ] **Step 1: Write the failing merge test**

Create `test/data/repositories/collection_repository_test.dart`:

```dart
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mtg_scanner/data/db/database.dart';

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() async => db.close());

  test('upsertMerging increments count when same printing+foil+cond+lang', () async {
    final dao = db.collectionDao;
    final now = DateTime(2026, 1, 1);

    await dao.upsertMerging(
      scryfallId: 'sid', name: 'Lightning Bolt',
      setCode: '2xm', collectorNumber: '137',
      foil: false, condition: 'NM', language: 'en',
      priceUsd: 1.0, priceUsdFoil: null, addedAt: now,
    );
    await dao.upsertMerging(
      scryfallId: 'sid', name: 'Lightning Bolt',
      setCode: '2xm', collectorNumber: '137',
      foil: false, condition: 'NM', language: 'en',
      priceUsd: 1.5, priceUsdFoil: null, addedAt: now,
    );

    final rows = await db.select(db.collection).get();
    expect(rows, hasLength(1));
    expect(rows.single.count, 2);
    expect(rows.single.priceUsd, 1.5, reason: 'latest price wins');
  });

  test('upsertMerging inserts new row when foil differs', () async {
    final dao = db.collectionDao;
    final now = DateTime(2026, 1, 1);
    await dao.upsertMerging(
      scryfallId: 'sid', name: 'Lightning Bolt',
      setCode: '2xm', collectorNumber: '137',
      foil: false, condition: 'NM', language: 'en',
      priceUsd: 1.0, priceUsdFoil: null, addedAt: now,
    );
    await dao.upsertMerging(
      scryfallId: 'sid', name: 'Lightning Bolt',
      setCode: '2xm', collectorNumber: '137',
      foil: true, condition: 'NM', language: 'en',
      priceUsd: 1.0, priceUsdFoil: 10.0, addedAt: now,
    );
    final rows = await db.select(db.collection).get();
    expect(rows, hasLength(2));
  });
}
```

- [ ] **Step 2: Run test — expect failure**

Run:
```bash
flutter test test/data/repositories/collection_repository_test.dart
```
Expected: FAIL — `db.collectionDao` undefined, `upsertMerging` undefined.

- [ ] **Step 3: Create DAO**

Create `lib/data/db/daos/collection_dao.dart`:

```dart
import 'package:drift/drift.dart';
import '../database.dart';
import '../tables.dart';

part 'collection_dao.g.dart';

@DriftAccessor(tables: [Collection])
class CollectionDao extends DatabaseAccessor<AppDatabase>
    with _$CollectionDaoMixin {
  CollectionDao(super.db);

  Future<void> upsertMerging({
    required String scryfallId,
    required String name,
    required String setCode,
    required String collectorNumber,
    required bool foil,
    required String condition,
    required String language,
    required double? priceUsd,
    required double? priceUsdFoil,
    required DateTime addedAt,
  }) async {
    final foilInt = foil ? 1 : 0;
    final existing = await (select(collection)
          ..where((t) =>
              t.scryfallId.equals(scryfallId) &
              t.foil.equals(foilInt) &
              t.condition.equals(condition) &
              t.language.equals(language)))
        .getSingleOrNull();
    if (existing == null) {
      await into(collection).insert(CollectionCompanion.insert(
        scryfallId: scryfallId,
        name: name,
        setCode: setCode,
        collectorNumber: collectorNumber,
        foil: Value(foilInt),
        condition: Value(condition),
        language: Value(language),
        addedAt: addedAt,
        priceUsd: Value(priceUsd),
        priceUsdFoil: Value(priceUsdFoil),
        priceUpdatedAt: Value(addedAt),
      ));
    } else {
      await (update(collection)..whereSamePrimaryKey(existing)).write(
        CollectionCompanion(
          count: Value(existing.count + 1),
          priceUsd: Value(priceUsd),
          priceUsdFoil: Value(priceUsdFoil),
          priceUpdatedAt: Value(addedAt),
        ),
      );
    }
  }
}
```

- [ ] **Step 4: Register the DAO**

Modify `lib/data/db/database.dart` — change the annotation and add the accessor getter:

```dart
@DriftDatabase(tables: [Scans, Collection], daos: [CollectionDao])
```

Add import: `import 'daos/collection_dao.dart';`

- [ ] **Step 5: Run codegen**

Run:
```bash
dart run build_runner build --delete-conflicting-outputs
```
Expected: generates `collection_dao.g.dart` and updates `database.g.dart`.

- [ ] **Step 6: Run test — expect pass**

Run:
```bash
flutter test test/data/repositories/collection_repository_test.dart
```
Expected: 2 tests PASS.

- [ ] **Step 7: Commit**

```bash
git add -A
git commit -m "add collection dao with merge rule and tests"
```

---

### Task 5: Scans DAO (basic CRUD)

**Files:**
- Create: `lib/data/db/daos/scans_dao.dart`

- [ ] **Step 1: Create DAO**

Create `lib/data/db/daos/scans_dao.dart`:

```dart
import 'package:drift/drift.dart';
import '../database.dart';
import '../tables.dart';

part 'scans_dao.g.dart';

@DriftAccessor(tables: [Scans])
class ScansDao extends DatabaseAccessor<AppDatabase> with _$ScansDaoMixin {
  ScansDao(super.db);

  Stream<List<Scan>> watchPending() =>
      (select(scans)
            ..where((t) => t.status.equals('pending'))
            ..orderBy([(t) => OrderingTerm.desc(t.capturedAt)]))
          .watch();

  Future<int> insertScan(ScansCompanion row) => into(scans).insert(row);

  Future<void> markStatus(int id, String status) =>
      (update(scans)..where((t) => t.id.equals(id)))
          .write(ScansCompanion(status: Value(status)));

  Future<void> updateMatch(int id, {
    required String scryfallId,
    required String name,
    required String setCode,
    required String collectorNumber,
    required double confidence,
    double? priceUsd,
    double? priceUsdFoil,
  }) =>
      (update(scans)..where((t) => t.id.equals(id))).write(ScansCompanion(
        matchedScryfallId: Value(scryfallId),
        matchedName: Value(name),
        matchedSet: Value(setCode),
        matchedCollectorNumber: Value(collectorNumber),
        confidence: Value(confidence),
        priceUsd: Value(priceUsd),
        priceUsdFoil: Value(priceUsdFoil),
      ));
}
```

- [ ] **Step 2: Register DAO**

Modify `lib/data/db/database.dart`:

```dart
@DriftDatabase(tables: [Scans, Collection], daos: [CollectionDao, ScansDao])
```
Add: `import 'daos/scans_dao.dart';`

- [ ] **Step 3: Codegen**

Run:
```bash
dart run build_runner build --delete-conflicting-outputs
flutter analyze
```
Expected: clean.

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "add scans dao with watch and update helpers"
```

---

### Task 6: Scryfall Models

**Files:**
- Create: `lib/data/scryfall/scryfall_models.dart`

- [ ] **Step 1: Write models**

Create `lib/data/scryfall/scryfall_models.dart`:

```dart
class ScryfallPrices {
  ScryfallPrices({this.usd, this.usdFoil});
  final double? usd;
  final double? usdFoil;

  factory ScryfallPrices.fromJson(Map<String, dynamic> j) => ScryfallPrices(
        usd: _parseDouble(j['usd']),
        usdFoil: _parseDouble(j['usd_foil']),
      );

  static double? _parseDouble(Object? v) =>
      v is String ? double.tryParse(v) : (v is num ? v.toDouble() : null);
}

class ScryfallCard {
  ScryfallCard({
    required this.id,
    required this.name,
    required this.set,
    required this.collectorNumber,
    required this.prices,
    this.imageUriSmall,
    this.imageUriNormal,
  });

  final String id;
  final String name;
  final String set;
  final String collectorNumber;
  final ScryfallPrices prices;
  final String? imageUriSmall;
  final String? imageUriNormal;

  factory ScryfallCard.fromJson(Map<String, dynamic> j) {
    final imgs = (j['image_uris'] as Map<String, dynamic>?) ??
        ((j['card_faces'] as List?)?.first as Map<String, dynamic>?)
            ?['image_uris'] as Map<String, dynamic>?;
    return ScryfallCard(
      id: j['id'] as String,
      name: j['name'] as String,
      set: j['set'] as String,
      collectorNumber: j['collector_number'] as String,
      prices: ScryfallPrices.fromJson(
          (j['prices'] as Map<String, dynamic>?) ?? const {}),
      imageUriSmall: imgs?['small'] as String?,
      imageUriNormal: imgs?['normal'] as String?,
    );
  }
}
```

- [ ] **Step 2: Analyze**

Run:
```bash
flutter analyze
```
Expected: clean.

- [ ] **Step 3: Commit**

```bash
git add lib/data/scryfall/scryfall_models.dart
git commit -m "add scryfall card + prices models"
```

---

### Task 7: Scryfall Client — Rate-Limited HTTP (TDD)

**Files:**
- Create: `lib/data/scryfall/scryfall_client.dart`
- Create: `test/data/scryfall/scryfall_client_test.dart`
- Create: `test/fixtures/scryfall/lightning_bolt_2xm_137.json`

- [ ] **Step 1: Add fixture**

Create `test/fixtures/scryfall/lightning_bolt_2xm_137.json` — paste a real response (download from `https://api.scryfall.com/cards/2xm/137`) OR this minimal stub:

```json
{
  "id": "e3285e6b-3e79-4d7c-bf96-d920f973b122",
  "name": "Lightning Bolt",
  "set": "2xm",
  "collector_number": "137",
  "prices": {"usd": "1.80", "usd_foil": "6.50"},
  "image_uris": {"small": "https://img/s.jpg", "normal": "https://img/n.jpg"}
}
```

- [ ] **Step 2: Write failing test**

Create `test/data/scryfall/scryfall_client_test.dart`:

```dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:mtg_scanner/data/scryfall/scryfall_client.dart';

class _MockHttp extends Mock implements http.Client {}

void main() {
  late _MockHttp http_;
  late ScryfallClient client;

  setUp(() {
    http_ = _MockHttp();
    client = ScryfallClient(http_, minGap: Duration.zero);
    registerFallbackValue(Uri.parse('https://example.com'));
  });

  test('cardBySetAndNumber returns parsed card', () async {
    final body = File('test/fixtures/scryfall/lightning_bolt_2xm_137.json')
        .readAsStringSync();
    when(() => http_.get(any(), headers: any(named: 'headers')))
        .thenAnswer((_) async => http.Response(body, 200));

    final card = await client.cardBySetAndNumber('2xm', '137');
    expect(card.name, 'Lightning Bolt');
    expect(card.set, '2xm');
    expect(card.prices.usd, 1.80);
  });

  test('throws ScryfallNotFound on 404', () async {
    when(() => http_.get(any(), headers: any(named: 'headers')))
        .thenAnswer((_) async => http.Response('{"status":404}', 404));
    expect(() => client.cardBySetAndNumber('xxx', '0'),
        throwsA(isA<ScryfallNotFound>()));
  });

  test('rate-limits to minGap between requests', () async {
    final times = <DateTime>[];
    when(() => http_.get(any(), headers: any(named: 'headers')))
        .thenAnswer((_) async {
      times.add(DateTime.now());
      return http.Response(
          jsonEncode({
            'id': 'x', 'name': 'X', 'set': 'xxx', 'collector_number': '1',
            'prices': {'usd': null, 'usd_foil': null},
          }),
          200);
    });
    final c = ScryfallClient(http_, minGap: const Duration(milliseconds: 100));
    await Future.wait([
      c.cardBySetAndNumber('xxx', '1'),
      c.cardBySetAndNumber('xxx', '1'),
    ]);
    expect(times, hasLength(2));
    expect(times[1].difference(times[0]).inMilliseconds, greaterThanOrEqualTo(95));
  });
}
```

- [ ] **Step 3: Run — expect failure**

Run:
```bash
flutter test test/data/scryfall/scryfall_client_test.dart
```
Expected: FAIL — `ScryfallClient` undefined.

- [ ] **Step 4: Implement client**

Create `lib/data/scryfall/scryfall_client.dart`:

```dart
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'scryfall_models.dart';

class ScryfallException implements Exception {
  ScryfallException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;
  @override
  String toString() => 'ScryfallException($statusCode): $message';
}

class ScryfallNotFound extends ScryfallException {
  ScryfallNotFound(super.message) : super(statusCode: 404);
}

class ScryfallClient {
  ScryfallClient(this._http, {Duration minGap = const Duration(milliseconds: 100)})
      : _minGap = minGap;

  static const _base = 'https://api.scryfall.com';
  static const _headers = {
    'User-Agent': 'mtg-scanner/0.1',
    'Accept': 'application/json',
  };

  final http.Client _http;
  final Duration _minGap;
  Future<void> _chain = Future.value();
  DateTime _last = DateTime.fromMillisecondsSinceEpoch(0);

  Future<T> _throttled<T>(Future<T> Function() fn) {
    final completer = Completer<T>();
    _chain = _chain.then((_) async {
      final now = DateTime.now();
      final wait = _minGap - now.difference(_last);
      if (wait > Duration.zero) await Future<void>.delayed(wait);
      _last = DateTime.now();
      try {
        completer.complete(await fn());
      } catch (e, s) {
        completer.completeError(e, s);
      }
    });
    return completer.future;
  }

  Future<ScryfallCard> cardBySetAndNumber(String set, String number) {
    return _throttled(() async {
      final uri = Uri.parse('$_base/cards/$set/$number');
      final r = await _http.get(uri, headers: _headers);
      if (r.statusCode == 404) throw ScryfallNotFound('$set/$number');
      if (r.statusCode >= 400) {
        throw ScryfallException(r.body, statusCode: r.statusCode);
      }
      return ScryfallCard.fromJson(
          jsonDecode(r.body) as Map<String, dynamic>);
    });
  }

  Future<ScryfallCard> cardByFuzzyName(String name) {
    return _throttled(() async {
      final uri = Uri.parse('$_base/cards/named?fuzzy=${Uri.encodeQueryComponent(name)}');
      final r = await _http.get(uri, headers: _headers);
      if (r.statusCode == 404) throw ScryfallNotFound(name);
      if (r.statusCode >= 400) {
        throw ScryfallException(r.body, statusCode: r.statusCode);
      }
      return ScryfallCard.fromJson(
          jsonDecode(r.body) as Map<String, dynamic>);
    });
  }

  Future<List<String>> autocomplete(String partial) {
    return _throttled(() async {
      final uri = Uri.parse(
          '$_base/cards/autocomplete?q=${Uri.encodeQueryComponent(partial)}');
      final r = await _http.get(uri, headers: _headers);
      if (r.statusCode >= 400) {
        throw ScryfallException(r.body, statusCode: r.statusCode);
      }
      final data = (jsonDecode(r.body) as Map<String, dynamic>)['data'];
      return (data as List).cast<String>();
    });
  }

  Future<List<ScryfallCard>> printingsOfName(String name) {
    return _throttled(() async {
      final q = Uri.encodeQueryComponent('!"$name" unique:prints');
      final uri = Uri.parse('$_base/cards/search?q=$q&order=released');
      final r = await _http.get(uri, headers: _headers);
      if (r.statusCode == 404) return <ScryfallCard>[];
      if (r.statusCode >= 400) {
        throw ScryfallException(r.body, statusCode: r.statusCode);
      }
      final data = (jsonDecode(r.body) as Map<String, dynamic>)['data'];
      return (data as List)
          .map((j) => ScryfallCard.fromJson(j as Map<String, dynamic>))
          .toList();
    });
  }
}
```

- [ ] **Step 5: Run — expect pass**

Run:
```bash
flutter test test/data/scryfall/scryfall_client_test.dart
```
Expected: 3 tests PASS.

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "add scryfall client with rate limiting and tests"
```

---

### Task 8: Collection Repository (adds, refresh prices)

**Files:**
- Create: `lib/data/repositories/collection_repository.dart`

- [ ] **Step 1: Write repository**

Create `lib/data/repositories/collection_repository.dart`:

```dart
import '../db/database.dart';
import '../scryfall/scryfall_client.dart';
import '../scryfall/scryfall_models.dart';

class CollectionRepository {
  CollectionRepository(this._db, this._scry);
  final AppDatabase _db;
  final ScryfallClient _scry;

  Future<void> addFromScryfall(
    ScryfallCard c, {
    bool foil = false,
    String condition = 'NM',
    String language = 'en',
  }) =>
      _db.collectionDao.upsertMerging(
        scryfallId: c.id,
        name: c.name,
        setCode: c.set,
        collectorNumber: c.collectorNumber,
        foil: foil,
        condition: condition,
        language: language,
        priceUsd: c.prices.usd,
        priceUsdFoil: c.prices.usdFoil,
        addedAt: DateTime.now(),
      );

  Stream<List<CollectionData>> watchAll() =>
      _db.select(_db.collection).watch();

  Future<void> refreshAllPrices({
    void Function(int done, int total)? onProgress,
  }) async {
    final rows = await _db.select(_db.collection).get();
    var done = 0;
    for (final row in rows) {
      try {
        final card =
            await _scry.cardBySetAndNumber(row.setCode, row.collectorNumber);
        await (_db.update(_db.collection)..whereSamePrimaryKey(row)).write(
          CollectionCompanion(
            priceUsd: Value(card.prices.usd),
            priceUsdFoil: Value(card.prices.usdFoil),
            priceUpdatedAt: Value(DateTime.now()),
          ),
        );
      } on ScryfallException {
        // skip this row; continue
      }
      done++;
      onProgress?.call(done, rows.length);
    }
  }

  Future<void> refreshOne(int id) async {
    final row = await (_db.select(_db.collection)
          ..where((t) => t.id.equals(id)))
        .getSingle();
    final card =
        await _scry.cardBySetAndNumber(row.setCode, row.collectorNumber);
    await (_db.update(_db.collection)..whereSamePrimaryKey(row)).write(
      CollectionCompanion(
        priceUsd: Value(card.prices.usd),
        priceUsdFoil: Value(card.prices.usdFoil),
        priceUpdatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> updateQuantity(int id, int count) =>
      (_db.update(_db.collection)..where((t) => t.id.equals(id)))
          .write(CollectionCompanion(count: Value(count)));

  Future<void> delete(int id) =>
      (_db.delete(_db.collection)..where((t) => t.id.equals(id))).go();

  Future<void> setNotes(int id, String? notes) =>
      (_db.update(_db.collection)..where((t) => t.id.equals(id)))
          .write(CollectionCompanion(notes: Value(notes)));
}

typedef CollectionData = CollectionEntry;
```

Note: Drift generates a class per table; the row class for `Collection` table is named `CollectionEntry` — confirm after codegen; if named differently, adjust the typedef. (In drift 2.x, the default row class is the singular form of the table class name.)

- [ ] **Step 2: Verify codegen + analyze**

Run:
```bash
dart run build_runner build --delete-conflicting-outputs
flutter analyze
```
If analyzer reports `CollectionEntry` not found, open `lib/data/db/database.g.dart`, find the data class (search for `class ... extends DataClass implements Insertable<... >`), and update the typedef.

Expected: analyze clean.

- [ ] **Step 3: Commit**

```bash
git add -A
git commit -m "add collection repository with add, refresh, edit"
```

---

### Task 9: Scans Repository

**Files:**
- Create: `lib/data/repositories/scans_repository.dart`

- [ ] **Step 1: Create**

Create `lib/data/repositories/scans_repository.dart`:

```dart
import 'package:drift/drift.dart';
import '../db/database.dart';
import '../scryfall/scryfall_models.dart';

class ScansRepository {
  ScansRepository(this._db);
  final AppDatabase _db;

  Stream<List<Scan>> watchPending() => _db.scansDao.watchPending();

  Future<int> addManual({
    required ScryfallCard card,
    required bool foilGuess,
  }) =>
      _db.scansDao.insertScan(ScansCompanion.insert(
        capturedAt: DateTime.now(),
        rawName: card.name,
        rawSetCollector: '${card.set} ${card.collectorNumber}',
        matchedScryfallId: Value(card.id),
        matchedName: Value(card.name),
        matchedSet: Value(card.set),
        matchedCollectorNumber: Value(card.collectorNumber),
        confidence: const Value(1.0),
        foilGuess: Value(foilGuess ? 1 : 0),
        priceUsd: Value(card.prices.usd),
        priceUsdFoil: Value(card.prices.usdFoil),
      ));

  Future<void> confirm(int id) =>
      _db.scansDao.markStatus(id, 'confirmed');

  Future<void> reject(int id) =>
      _db.scansDao.markStatus(id, 'rejected');
}
```

- [ ] **Step 2: Analyze**

Run:
```bash
flutter analyze
```
Expected: clean.

- [ ] **Step 3: Commit**

```bash
git add -A
git commit -m "add scans repository"
```

---

### Task 10: App Shell + Router + DI

**Files:**
- Create: `lib/features/shell/app_shell.dart`
- Create: `lib/features/scanner/scanner_placeholder_screen.dart`
- Modify: `lib/main.dart`, `lib/app.dart`

- [ ] **Step 1: Placeholder scanner screen**

Create `lib/features/scanner/scanner_placeholder_screen.dart`:

```dart
import 'package:flutter/material.dart';

class ScannerPlaceholderScreen extends StatelessWidget {
  const ScannerPlaceholderScreen({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(
        body: Center(child: Text('Scanner — coming in Plan B')),
      );
}
```

- [ ] **Step 2: Shell with bottom nav**

Create `lib/features/shell/app_shell.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppShell extends StatelessWidget {
  const AppShell({required this.child, required this.location, super.key});
  final Widget child;
  final String location;

  static const _tabs = [
    ('Scan', Icons.camera_alt, '/scan'),
    ('Queue', Icons.inbox, '/queue'),
    ('Collection', Icons.style, '/collection'),
    ('Export', Icons.ios_share, '/export'),
    ('Settings', Icons.settings, '/settings'),
  ];

  int get _index =>
      _tabs.indexWhere((t) => location.startsWith(t.$3)).clamp(0, 4);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => context.go(_tabs[i].$3),
        destinations: [
          for (final t in _tabs)
            NavigationDestination(icon: Icon(t.$2), label: t.$1),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: Wire router with DI**

Overwrite `lib/app.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;

import 'data/db/database.dart';
import 'data/scryfall/scryfall_client.dart';
import 'data/repositories/collection_repository.dart';
import 'data/repositories/scans_repository.dart';
import 'features/shell/app_shell.dart';
import 'features/scanner/scanner_placeholder_screen.dart';
import 'features/review_queue/review_queue_screen.dart';
import 'features/collection/collection_screen.dart';
import 'features/collection/manual_add_screen.dart';
import 'features/collection/collection_detail_screen.dart';
import 'features/export/export_screen.dart';
import 'features/settings/settings_screen.dart';

class Deps {
  Deps._(this.db, this.scry, this.collection, this.scans);
  final AppDatabase db;
  final ScryfallClient scry;
  final CollectionRepository collection;
  final ScansRepository scans;

  factory Deps.create() {
    final db = AppDatabase();
    final scry = ScryfallClient(http.Client());
    return Deps._(db, scry, CollectionRepository(db, scry), ScansRepository(db));
  }
}

class MtgScannerApp extends StatefulWidget {
  const MtgScannerApp({super.key});
  @override
  State<MtgScannerApp> createState() => _MtgScannerAppState();
}

class _MtgScannerAppState extends State<MtgScannerApp> {
  late final Deps deps = Deps.create();
  late final GoRouter _router = GoRouter(
    initialLocation: '/collection',
    routes: [
      ShellRoute(
        builder: (ctx, state, child) =>
            AppShell(location: state.matchedLocation, child: child),
        routes: [
          GoRoute(path: '/scan', builder: (_, __) => const ScannerPlaceholderScreen()),
          GoRoute(
              path: '/queue',
              builder: (_, __) => ReviewQueueScreen(
                  scans: deps.scans, collection: deps.collection, scry: deps.scry)),
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
          GoRoute(path: '/export', builder: (_, __) => ExportScreen(repo: deps.collection)),
          GoRoute(path: '/settings', builder: (_, __) => SettingsScreen(repo: deps.collection)),
        ],
      ),
    ],
  );

  @override
  void dispose() {
    deps.db.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp.router(
        title: 'MTG Scanner',
        theme: ThemeData(colorSchemeSeed: Colors.deepPurple, useMaterial3: true),
        routerConfig: _router,
      );
}
```

Note: this references several screens we haven't created yet. To keep the build green between tasks, **also create empty stub files now** for each of the screens referenced above (single-line placeholder widgets). Replace them in later tasks.

- [ ] **Step 4: Create screen stubs**

Create these files, each containing a placeholder widget with the matching constructor arguments:

`lib/features/review_queue/review_queue_screen.dart`:
```dart
import 'package:flutter/material.dart';
import '../../data/repositories/scans_repository.dart';
import '../../data/repositories/collection_repository.dart';
import '../../data/scryfall/scryfall_client.dart';

class ReviewQueueScreen extends StatelessWidget {
  const ReviewQueueScreen({required this.scans, required this.collection, required this.scry, super.key});
  final ScansRepository scans;
  final CollectionRepository collection;
  final ScryfallClient scry;
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('Queue')));
}
```

`lib/features/collection/collection_screen.dart`:
```dart
import 'package:flutter/material.dart';
import '../../data/repositories/collection_repository.dart';

class CollectionScreen extends StatelessWidget {
  const CollectionScreen({required this.repo, super.key});
  final CollectionRepository repo;
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('Collection')));
}
```

`lib/features/collection/manual_add_screen.dart`:
```dart
import 'package:flutter/material.dart';
import '../../data/scryfall/scryfall_client.dart';
import '../../data/repositories/collection_repository.dart';

class ManualAddScreen extends StatelessWidget {
  const ManualAddScreen({required this.scry, required this.collection, super.key});
  final ScryfallClient scry;
  final CollectionRepository collection;
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('Manual Add')));
}
```

`lib/features/collection/collection_detail_screen.dart`:
```dart
import 'package:flutter/material.dart';
import '../../data/repositories/collection_repository.dart';

class CollectionDetailScreen extends StatelessWidget {
  const CollectionDetailScreen({required this.id, required this.repo, super.key});
  final int id;
  final CollectionRepository repo;
  @override
  Widget build(BuildContext context) =>
      Scaffold(body: Center(child: Text('Card $id')));
}
```

`lib/features/export/export_screen.dart`:
```dart
import 'package:flutter/material.dart';
import '../../data/repositories/collection_repository.dart';

class ExportScreen extends StatelessWidget {
  const ExportScreen({required this.repo, super.key});
  final CollectionRepository repo;
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('Export')));
}
```

`lib/features/settings/settings_screen.dart`:
```dart
import 'package:flutter/material.dart';
import '../../data/repositories/collection_repository.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({required this.repo, super.key});
  final CollectionRepository repo;
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('Settings')));
}
```

- [ ] **Step 5: Run**

Run:
```bash
flutter analyze
flutter test
```
Expected: analyze clean, existing tests still pass.

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "add app shell, router, and screen stubs"
```

---

### Task 11: Printing Picker + Manual Add Screen

**Files:**
- Create: `lib/shared/widgets/printing_picker.dart`
- Modify: `lib/features/collection/manual_add_screen.dart`

- [ ] **Step 1: Printing picker widget**

Create `lib/shared/widgets/printing_picker.dart`:

```dart
import 'package:flutter/material.dart';
import '../../data/scryfall/scryfall_client.dart';
import '../../data/scryfall/scryfall_models.dart';

class PrintingPicker extends StatefulWidget {
  const PrintingPicker({
    required this.name,
    required this.scry,
    required this.onPick,
    super.key,
  });
  final String name;
  final ScryfallClient scry;
  final void Function(ScryfallCard) onPick;

  @override
  State<PrintingPicker> createState() => _PrintingPickerState();
}

class _PrintingPickerState extends State<PrintingPicker> {
  late Future<List<ScryfallCard>> _future = widget.scry.printingsOfName(widget.name);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ScryfallCard>>(
      future: _future,
      builder: (ctx, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(child: Text('Error: ${snap.error}'));
        }
        final printings = snap.data!;
        if (printings.isEmpty) {
          return const Center(child: Text('No printings found'));
        }
        return ListView.separated(
          itemCount: printings.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (_, i) {
            final p = printings[i];
            final price = p.prices.usd == null
                ? '—'
                : '\$${p.prices.usd!.toStringAsFixed(2)}';
            return ListTile(
              leading: p.imageUriSmall == null
                  ? const SizedBox(width: 40)
                  : Image.network(p.imageUriSmall!, width: 40),
              title: Text('${p.set.toUpperCase()} · ${p.collectorNumber}'),
              subtitle: Text(price),
              onTap: () => widget.onPick(p),
            );
          },
        );
      },
    );
  }
}
```

- [ ] **Step 2: Manual add screen**

Overwrite `lib/features/collection/manual_add_screen.dart`:

```dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/scryfall/scryfall_client.dart';
import '../../data/repositories/collection_repository.dart';
import '../../shared/widgets/printing_picker.dart';

class ManualAddScreen extends StatefulWidget {
  const ManualAddScreen({required this.scry, required this.collection, super.key});
  final ScryfallClient scry;
  final CollectionRepository collection;
  @override
  State<ManualAddScreen> createState() => _ManualAddScreenState();
}

class _ManualAddScreenState extends State<ManualAddScreen> {
  final _ctrl = TextEditingController();
  Timer? _debounce;
  List<String> _suggestions = const [];
  String? _pickedName;
  bool _foil = false;

  void _onQueryChanged(String q) {
    _debounce?.cancel();
    if (q.trim().length < 2) {
      setState(() => _suggestions = const []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 200), () async {
      final list = await widget.scry.autocomplete(q);
      if (!mounted) return;
      setState(() => _suggestions = list);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add card')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _ctrl,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Card name',
                border: OutlineInputBorder(),
              ),
              onChanged: _onQueryChanged,
            ),
          ),
          SwitchListTile(
            title: const Text('Foil'),
            value: _foil,
            onChanged: (v) => setState(() => _foil = v),
          ),
          const Divider(height: 1),
          Expanded(
            child: _pickedName == null
                ? ListView(
                    children: [
                      for (final s in _suggestions)
                        ListTile(
                          title: Text(s),
                          onTap: () => setState(() => _pickedName = s),
                        ),
                    ],
                  )
                : PrintingPicker(
                    name: _pickedName!,
                    scry: widget.scry,
                    onPick: (card) async {
                      await widget.collection.addFromScryfall(card, foil: _foil);
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Added ${card.name} (${card.set.toUpperCase()})')),
                      );
                      context.pop();
                    },
                  ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    super.dispose();
  }
}
```

- [ ] **Step 3: Analyze**

Run:
```bash
flutter analyze
```
Expected: clean.

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "add printing picker and manual-add flow"
```

---

### Task 12: Collection Screen + Detail + PriceText

**Files:**
- Create: `lib/shared/widgets/price_text.dart`
- Modify: `lib/features/collection/collection_screen.dart`
- Modify: `lib/features/collection/collection_detail_screen.dart`

- [ ] **Step 1: Price widget**

Create `lib/shared/widgets/price_text.dart`:

```dart
import 'package:flutter/material.dart';

class PriceText extends StatelessWidget {
  const PriceText({required this.usd, required this.updatedAt, super.key});
  final double? usd;
  final DateTime? updatedAt;

  @override
  Widget build(BuildContext context) {
    final stale = updatedAt == null ||
        DateTime.now().difference(updatedAt!).inDays >= 7;
    final text = usd == null ? '—' : '\$${usd!.toStringAsFixed(2)}';
    return Text(
      text,
      style: stale
          ? TextStyle(color: Theme.of(context).disabledColor)
          : null,
    );
  }
}
```

- [ ] **Step 2: Collection screen**

Overwrite `lib/features/collection/collection_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/db/database.dart';
import '../../data/repositories/collection_repository.dart';
import '../../shared/widgets/price_text.dart';

enum _Sort { set, nameAsc, priceDesc, dateDesc }

class CollectionScreen extends StatefulWidget {
  const CollectionScreen({required this.repo, super.key});
  final CollectionRepository repo;
  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> {
  String _query = '';
  _Sort _sort = _Sort.set;

  double _rowPrice(CollectionData r) => r.foil == 1
      ? (r.priceUsdFoil ?? r.priceUsd ?? 0)
      : (r.priceUsd ?? 0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Collection'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.go('/collection/add'),
          ),
          PopupMenuButton<_Sort>(
            icon: const Icon(Icons.sort),
            onSelected: (v) => setState(() => _sort = v),
            itemBuilder: (_) => const [
              PopupMenuItem(value: _Sort.set, child: Text('By set')),
              PopupMenuItem(value: _Sort.nameAsc, child: Text('Name A–Z')),
              PopupMenuItem(value: _Sort.priceDesc, child: Text('Price (high → low)')),
              PopupMenuItem(value: _Sort.dateDesc, child: Text('Recently added')),
            ],
          ),
        ],
      ),
      body: StreamBuilder<List<CollectionData>>(
        stream: widget.repo.watchAll(),
        builder: (ctx, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          var rows = snap.data!;
          if (_query.isNotEmpty) {
            final q = _query.toLowerCase();
            rows = rows.where((r) =>
                r.name.toLowerCase().contains(q) ||
                r.setCode.toLowerCase().contains(q)).toList();
          }
          rows.sort((a, b) {
            switch (_sort) {
              case _Sort.set:
                return a.setCode.compareTo(b.setCode);
              case _Sort.nameAsc:
                return a.name.compareTo(b.name);
              case _Sort.priceDesc:
                return _rowPrice(b).compareTo(_rowPrice(a));
              case _Sort.dateDesc:
                return b.addedAt.compareTo(a.addedAt);
            }
          });
          final total = rows.fold<double>(0, (s, r) => s + _rowPrice(r) * r.count);
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search name or set code',
                    prefixIcon: Icon(Icons.search),
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Showing ${rows.length} cards · \$${total.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
              Expanded(
                child: ListView.separated(
                  itemCount: rows.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final r = rows[i];
                    return ListTile(
                      title: Text('${r.count}× ${r.name}${r.foil == 1 ? " ✦" : ""}'),
                      subtitle: Text('${r.setCode.toUpperCase()} · ${r.collectorNumber}'),
                      trailing: PriceText(
                        usd: r.foil == 1 ? (r.priceUsdFoil ?? r.priceUsd) : r.priceUsd,
                        updatedAt: r.priceUpdatedAt,
                      ),
                      onTap: () => context.go('/collection/${r.id}'),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
```

- [ ] **Step 3: Detail screen**

Overwrite `lib/features/collection/collection_detail_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/db/database.dart';
import '../../data/repositories/collection_repository.dart';
import '../../shared/widgets/price_text.dart';

class CollectionDetailScreen extends StatefulWidget {
  const CollectionDetailScreen({required this.id, required this.repo, super.key});
  final int id;
  final CollectionRepository repo;
  @override
  State<CollectionDetailScreen> createState() => _CollectionDetailScreenState();
}

class _CollectionDetailScreenState extends State<CollectionDetailScreen> {
  late Future<CollectionData> _future = _load();

  Future<CollectionData> _load() => (widget.repo as dynamic).watchAll().first;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Card')),
      body: FutureBuilder<CollectionData>(
        future: _future,
        builder: (ctx, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final r = snap.data!;
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(r.name, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text('${r.setCode.toUpperCase()} · ${r.collectorNumber}'),
              const SizedBox(height: 8),
              PriceText(
                usd: r.foil == 1 ? (r.priceUsdFoil ?? r.priceUsd) : r.priceUsd,
                updatedAt: r.priceUpdatedAt,
              ),
              const Spacer(),
              Row(children: [
                FilledButton.tonal(
                  onPressed: () async {
                    await widget.repo.refreshOne(r.id);
                    if (!mounted) return;
                    setState(() => _future = _load());
                  },
                  child: const Text('Refresh price'),
                ),
                const Spacer(),
                OutlinedButton(
                  onPressed: () async {
                    await widget.repo.delete(r.id);
                    if (!mounted) return;
                    context.pop();
                  },
                  child: const Text('Delete'),
                ),
              ]),
            ]),
          );
        },
      ),
    );
  }
}
```

Note: the `_load()` above is simplified — replace with a proper lookup. Add a `Future<CollectionData> getById(int id)` method to `CollectionRepository`:

```dart
Future<CollectionData> getById(int id) =>
    (_db.select(_db.collection)..where((t) => t.id.equals(id))).getSingle();
```

Then change `_load()` to `widget.repo.getById(widget.id)`.

- [ ] **Step 4: Analyze + run**

Run:
```bash
flutter analyze
flutter test
```
Expected: clean.

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "add collection list, detail screen, and price widget"
```

---

### Task 13: Moxfield Text Formatter (TDD)

**Files:**
- Create: `lib/features/export/formatters/moxfield_text_formatter.dart`
- Create: `test/features/export/moxfield_text_formatter_test.dart`

- [ ] **Step 1: Write failing test**

Create `test/features/export/moxfield_text_formatter_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mtg_scanner/features/export/formatters/moxfield_text_formatter.dart';

void main() {
  test('formats basic rows', () {
    final lines = formatMoxfieldText([
      const MoxRow(count: 4, name: 'Lightning Bolt', set: '2xm', collector: '137', foil: false),
      const MoxRow(count: 1, name: 'Lightning Bolt', set: '2xm', collector: '137', foil: true),
      const MoxRow(count: 2, name: 'Snapcaster Mage', set: 'mm3', collector: '58', foil: false),
    ]);
    expect(lines, [
      '4 Lightning Bolt (2XM) 137',
      '1 Lightning Bolt (2XM) 137 *F*',
      '2 Snapcaster Mage (MM3) 58',
    ]);
  });

  test('uppercases set code', () {
    final lines = formatMoxfieldText([
      const MoxRow(count: 1, name: 'Island', set: 'neo', collector: '1', foil: false),
    ]);
    expect(lines.single, '1 Island (NEO) 1');
  });
}
```

- [ ] **Step 2: Run — expect failure**

Run:
```bash
flutter test test/features/export/moxfield_text_formatter_test.dart
```
Expected: FAIL — undefined.

- [ ] **Step 3: Implement**

Create `lib/features/export/formatters/moxfield_text_formatter.dart`:

```dart
class MoxRow {
  const MoxRow({
    required this.count,
    required this.name,
    required this.set,
    required this.collector,
    required this.foil,
    this.condition = 'NM',
    this.language = 'en',
  });
  final int count;
  final String name;
  final String set;
  final String collector;
  final bool foil;
  final String condition;
  final String language;
}

List<String> formatMoxfieldText(List<MoxRow> rows) {
  return rows
      .map((r) =>
          '${r.count} ${r.name} (${r.set.toUpperCase()}) ${r.collector}${r.foil ? ' *F*' : ''}')
      .toList();
}
```

- [ ] **Step 4: Run — expect pass**

Run:
```bash
flutter test test/features/export/moxfield_text_formatter_test.dart
```
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "add moxfield text formatter with tests"
```

---

### Task 14: Moxfield CSV Formatter (TDD)

**Files:**
- Create: `lib/features/export/formatters/moxfield_csv_formatter.dart`
- Create: `test/features/export/moxfield_csv_formatter_test.dart`

- [ ] **Step 1: Write failing test**

Create `test/features/export/moxfield_csv_formatter_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mtg_scanner/features/export/formatters/moxfield_text_formatter.dart';
import 'package:mtg_scanner/features/export/formatters/moxfield_csv_formatter.dart';

void main() {
  test('emits header + rows in Moxfield CSV format', () {
    final csv = formatMoxfieldCsv(
      [
        const MoxRow(count: 4, name: 'Lightning Bolt', set: '2xm', collector: '137', foil: false),
        const MoxRow(count: 1, name: 'Lightning Bolt', set: '2xm', collector: '137', foil: true, condition: 'LP', language: 'ja'),
      ],
      now: DateTime.utc(2026, 4, 14, 12, 0, 0),
    );
    final lines = csv.split('\n');
    expect(lines[0],
        'Count,Tradelist Count,Name,Edition,Condition,Language,Foil,Tags,Last Modified,Collector Number');
    expect(lines[1],
        '4,0,Lightning Bolt,2xm,NM,English,,,2026-04-14 12:00:00,137');
    expect(lines[2],
        '1,0,Lightning Bolt,2xm,LP,Japanese,foil,,2026-04-14 12:00:00,137');
  });

  test('quotes fields containing commas', () {
    final csv = formatMoxfieldCsv(
      [const MoxRow(count: 1, name: 'Aetherworks, Inc.', set: 'xyz', collector: '1', foil: false)],
      now: DateTime.utc(2026, 4, 14),
    );
    expect(csv.split('\n')[1].contains('"Aetherworks, Inc."'), isTrue);
  });
}
```

- [ ] **Step 2: Run — expect failure**

Run:
```bash
flutter test test/features/export/moxfield_csv_formatter_test.dart
```
Expected: FAIL.

- [ ] **Step 3: Implement**

Create `lib/features/export/formatters/moxfield_csv_formatter.dart`:

```dart
import 'moxfield_text_formatter.dart';

const _languages = {
  'en': 'English', 'ja': 'Japanese', 'de': 'German', 'fr': 'French',
  'it': 'Italian', 'es': 'Spanish', 'pt': 'Portuguese', 'ru': 'Russian',
  'ko': 'Korean', 'zhs': 'Chinese Simplified', 'zht': 'Chinese Traditional',
};

String _q(String v) {
  if (v.contains(',') || v.contains('"') || v.contains('\n')) {
    return '"${v.replaceAll('"', '""')}"';
  }
  return v;
}

String _ts(DateTime t) {
  String p2(int n) => n.toString().padLeft(2, '0');
  return '${t.year}-${p2(t.month)}-${p2(t.day)} '
      '${p2(t.hour)}:${p2(t.minute)}:${p2(t.second)}';
}

String formatMoxfieldCsv(List<MoxRow> rows, {DateTime? now}) {
  final ts = _ts(now ?? DateTime.now());
  final buf = StringBuffer()
    ..write('Count,Tradelist Count,Name,Edition,Condition,Language,Foil,Tags,Last Modified,Collector Number');
  for (final r in rows) {
    final lang = _languages[r.language] ?? r.language;
    buf
      ..write('\n')
      ..write('${r.count},0,${_q(r.name)},${r.set},${r.condition},$lang,${r.foil ? 'foil' : ''},,$ts,${r.collector}');
  }
  return buf.toString();
}
```

- [ ] **Step 4: Run — expect pass**

Run:
```bash
flutter test test/features/export/moxfield_csv_formatter_test.dart
```
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "add moxfield csv formatter with tests"
```

---

### Task 15: Export Screen

**Files:**
- Modify: `lib/features/export/export_screen.dart`

- [ ] **Step 1: Implement**

Overwrite `lib/features/export/export_screen.dart`:

```dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../data/db/database.dart';
import '../../data/repositories/collection_repository.dart';
import 'formatters/moxfield_text_formatter.dart';
import 'formatters/moxfield_csv_formatter.dart';

enum _Format { text, csv }
enum _Scope { all }

class ExportScreen extends StatefulWidget {
  const ExportScreen({required this.repo, super.key});
  final CollectionRepository repo;
  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  _Format _format = _Format.text;
  _Scope _scope = _Scope.all;

  List<MoxRow> _toRows(List<CollectionData> rows) => rows
      .map((r) => MoxRow(
            count: r.count,
            name: r.name,
            set: r.setCode,
            collector: r.collectorNumber,
            foil: r.foil == 1,
            condition: r.condition,
            language: r.language,
          ))
      .toList();

  String _render(List<MoxRow> rows) =>
      _format == _Format.text ? formatMoxfieldText(rows).join('\n')
                              : formatMoxfieldCsv(rows);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Export')),
      body: StreamBuilder<List<CollectionData>>(
        stream: widget.repo.watchAll(),
        builder: (ctx, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final rows = _toRows(snap.data!);
          final text = _render(rows);
          final preview = text.split('\n').take(20).join('\n');
          return Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(children: [
                  const Text('Format: '),
                  DropdownButton<_Format>(
                    value: _format,
                    items: const [
                      DropdownMenuItem(value: _Format.text, child: Text('Moxfield text')),
                      DropdownMenuItem(value: _Format.csv, child: Text('CSV')),
                    ],
                    onChanged: (v) => setState(() => _format = v!),
                  ),
                ]),
                const SizedBox(height: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Theme.of(context).dividerColor),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: SingleChildScrollView(child: SelectableText(preview)),
                  ),
                ),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(
                    child: FilledButton.tonal(
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: text));
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Copied')));
                      },
                      child: const Text('Copy'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.tonal(
                      onPressed: () async {
                        final ext = _format == _Format.csv ? 'csv' : 'txt';
                        final dir = await getTemporaryDirectory();
                        final f = File(p.join(dir.path, 'collection.$ext'));
                        await f.writeAsString(text);
                        await Share.shareXFiles([XFile(f.path)]);
                      },
                      child: const Text('Share'),
                    ),
                  ),
                ]),
              ],
            ),
          );
        },
      ),
    );
  }
}
```

- [ ] **Step 2: Analyze**

Run:
```bash
flutter analyze
```
Expected: clean.

- [ ] **Step 3: Commit**

```bash
git add -A
git commit -m "add export screen with preview, copy, share"
```

---

### Task 16: Review Queue Screen (widget-tested)

**Files:**
- Create: `lib/features/review_queue/review_queue_item_tile.dart`
- Create: `lib/features/review_queue/edit_match_modal.dart`
- Modify: `lib/features/review_queue/review_queue_screen.dart`
- Create: `test/features/review_queue/review_queue_screen_test.dart`

- [ ] **Step 1: Item tile widget**

Create `lib/features/review_queue/review_queue_item_tile.dart`:

```dart
import 'package:flutter/material.dart';
import '../../data/db/database.dart';

class ReviewQueueItemTile extends StatelessWidget {
  const ReviewQueueItemTile({
    required this.scan,
    required this.onConfirm,
    required this.onReject,
    required this.onEdit,
    required this.onToggleFoil,
    super.key,
  });
  final Scan scan;
  final VoidCallback onConfirm;
  final VoidCallback onReject;
  final VoidCallback onEdit;
  final ValueChanged<bool> onToggleFoil;

  @override
  Widget build(BuildContext context) {
    final name = scan.matchedName ?? '(unmatched)';
    final setNum = scan.matchedSet == null
        ? scan.rawSetCollector
        : '${scan.matchedSet!.toUpperCase()} · ${scan.matchedCollectorNumber ?? '?'}';
    final price = scan.foilGuess == 1
        ? scan.priceUsdFoil
        : scan.priceUsd;
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            title: Text(name),
            subtitle: Text('$setNum · ${(scan.confidence * 100).toStringAsFixed(0)}%'
                '${price == null ? "" : "  ·  \$${price.toStringAsFixed(2)}"}'),
            trailing: Switch(
              value: scan.foilGuess == 1,
              onChanged: onToggleFoil,
            ),
          ),
          OverflowBar(
            spacing: 8,
            alignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(onPressed: onReject, child: const Text('Reject')),
              OutlinedButton(onPressed: onEdit, child: const Text('Edit')),
              FilledButton(onPressed: onConfirm, child: const Text('Confirm')),
            ],
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Edit modal**

Create `lib/features/review_queue/edit_match_modal.dart`:

```dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../../data/scryfall/scryfall_client.dart';
import '../../data/scryfall/scryfall_models.dart';
import '../../shared/widgets/printing_picker.dart';

class EditMatchModal extends StatefulWidget {
  const EditMatchModal({required this.scry, super.key});
  final ScryfallClient scry;
  @override
  State<EditMatchModal> createState() => _EditMatchModalState();
}

class _EditMatchModalState extends State<EditMatchModal> {
  final _ctrl = TextEditingController();
  Timer? _debounce;
  List<String> _suggestions = const [];
  String? _picked;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit match')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _ctrl,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Card name',
                border: OutlineInputBorder(),
              ),
              onChanged: (q) {
                _debounce?.cancel();
                if (q.trim().length < 2) {
                  setState(() => _suggestions = const []);
                  return;
                }
                _debounce = Timer(const Duration(milliseconds: 200), () async {
                  final list = await widget.scry.autocomplete(q);
                  if (!mounted) return;
                  setState(() => _suggestions = list);
                });
              },
            ),
          ),
          Expanded(
            child: _picked == null
                ? ListView(
                    children: [
                      for (final s in _suggestions)
                        ListTile(
                          title: Text(s),
                          onTap: () => setState(() => _picked = s),
                        ),
                    ],
                  )
                : PrintingPicker(
                    name: _picked!,
                    scry: widget.scry,
                    onPick: (card) => Navigator.of(context).pop<ScryfallCard>(card),
                  ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    super.dispose();
  }
}
```

- [ ] **Step 3: Review Queue screen**

Overwrite `lib/features/review_queue/review_queue_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:drift/drift.dart' as d;
import '../../data/db/database.dart';
import '../../data/repositories/collection_repository.dart';
import '../../data/repositories/scans_repository.dart';
import '../../data/scryfall/scryfall_client.dart';
import '../../data/scryfall/scryfall_models.dart';
import 'review_queue_item_tile.dart';
import 'edit_match_modal.dart';

class ReviewQueueScreen extends StatelessWidget {
  const ReviewQueueScreen({
    required this.scans,
    required this.collection,
    required this.scry,
    super.key,
  });
  final ScansRepository scans;
  final CollectionRepository collection;
  final ScryfallClient scry;

  Future<void> _confirm(BuildContext ctx, AppDatabase db, Scan s) async {
    if (s.matchedScryfallId == null) return;
    final foil = s.foilGuess == 1;
    final card = ScryfallCard(
      id: s.matchedScryfallId!,
      name: s.matchedName!,
      set: s.matchedSet!,
      collectorNumber: s.matchedCollectorNumber!,
      prices: ScryfallPrices(usd: s.priceUsd, usdFoil: s.priceUsdFoil),
    );
    await collection.addFromScryfall(card, foil: foil);
    await scans.confirm(s.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Review queue')),
      body: StreamBuilder<List<Scan>>(
        stream: scans.watchPending(),
        builder: (ctx, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snap.data!;
          if (items.isEmpty) {
            return const Center(child: Text('Nothing to review'));
          }
          final db = (collection as dynamic)._db as AppDatabase;
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final s = items[i];
              return ReviewQueueItemTile(
                scan: s,
                onConfirm: () => _confirm(ctx, db, s),
                onReject: () => scans.reject(s.id),
                onToggleFoil: (v) async {
                  await db.update(db.scans).replace(
                      s.copyWith(foilGuess: d.Value(v ? 1 : 0)));
                },
                onEdit: () async {
                  final picked = await Navigator.of(ctx).push<ScryfallCard>(
                    MaterialPageRoute(
                        builder: (_) => EditMatchModal(scry: scry)),
                  );
                  if (picked == null) return;
                  await db.scansDao.updateMatch(
                    s.id,
                    scryfallId: picked.id,
                    name: picked.name,
                    setCode: picked.set,
                    collectorNumber: picked.collectorNumber,
                    confidence: 1.0,
                    priceUsd: picked.prices.usd,
                    priceUsdFoil: picked.prices.usdFoil,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
```

Note: the `collection as dynamic`._db hack above is ugly — add a public `AppDatabase get db => _db;` to `CollectionRepository` and use `collection.db` instead. Make that change now.

- [ ] **Step 4: Widget test — confirm flow**

Create `test/features/review_queue/review_queue_screen_test.dart`:

```dart
import 'package:drift/native.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:mtg_scanner/data/db/database.dart';
import 'package:mtg_scanner/data/repositories/collection_repository.dart';
import 'package:mtg_scanner/data/repositories/scans_repository.dart';
import 'package:mtg_scanner/data/scryfall/scryfall_client.dart';
import 'package:mtg_scanner/features/review_queue/review_queue_screen.dart';

class _Http extends Mock implements http.Client {}

void main() {
  late AppDatabase db;
  late CollectionRepository collection;
  late ScansRepository scansRepo;
  late ScryfallClient scry;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    scry = ScryfallClient(_Http(), minGap: Duration.zero);
    collection = CollectionRepository(db, scry);
    scansRepo = ScansRepository(db);
    await db.into(db.scans).insert(ScansCompanion.insert(
          capturedAt: DateTime(2026, 4, 14),
          rawName: 'Lightning Bolt',
          rawSetCollector: '2xm 137',
          matchedScryfallId: const Value('sid-1'),
          matchedName: const Value('Lightning Bolt'),
          matchedSet: const Value('2xm'),
          matchedCollectorNumber: const Value('137'),
          confidence: const Value(0.95),
          foilGuess: const Value(0),
          priceUsd: const Value(1.80),
        ));
  });
  tearDown(() => db.close());

  testWidgets('confirm moves scan from queue to collection', (t) async {
    await t.pumpWidget(MaterialApp(
        home: ReviewQueueScreen(
            scans: scansRepo, collection: collection, scry: scry)));
    await t.pumpAndSettle();
    expect(find.text('Lightning Bolt'), findsOneWidget);
    await t.tap(find.text('Confirm'));
    await t.pumpAndSettle();
    expect(find.text('Nothing to review'), findsOneWidget);
    final inCollection = await db.select(db.collection).get();
    expect(inCollection, hasLength(1));
    expect(inCollection.single.name, 'Lightning Bolt');
  });
}
```

- [ ] **Step 5: Run tests**

Run:
```bash
flutter test test/features/review_queue/review_queue_screen_test.dart
```
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "add review queue screen with confirm/reject/edit flow"
```

---

### Task 17: Settings Screen + Refresh All Prices + Backup/Restore

**Files:**
- Create: `lib/features/settings/backup_restore_service.dart`
- Modify: `lib/features/settings/settings_screen.dart`

- [ ] **Step 1: Backup/restore service**

Create `lib/features/settings/backup_restore_service.dart`:

```dart
import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../data/db/database.dart';

class BackupRestoreService {
  BackupRestoreService(this._db);
  final AppDatabase _db;

  Future<File> exportJson() async {
    final rows = await _db.select(_db.collection).get();
    final json = rows
        .map((r) => {
              'scryfall_id': r.scryfallId,
              'name': r.name,
              'set_code': r.setCode,
              'collector_number': r.collectorNumber,
              'count': r.count,
              'foil': r.foil,
              'condition': r.condition,
              'language': r.language,
              'added_at': r.addedAt.toIso8601String(),
              'price_usd': r.priceUsd,
              'price_usd_foil': r.priceUsdFoil,
              'price_updated_at': r.priceUpdatedAt?.toIso8601String(),
              'notes': r.notes,
            })
        .toList();
    final dir = await getApplicationDocumentsDirectory();
    final f = File(p.join(dir.path,
        'mtg-collection-${DateTime.now().toIso8601String().split('T').first}.json'));
    await f.writeAsString(jsonEncode({'version': 1, 'cards': json}));
    return f;
  }

  Future<int> importJson(String jsonText) async {
    final data = jsonDecode(jsonText) as Map<String, dynamic>;
    final cards = (data['cards'] as List).cast<Map<String, dynamic>>();
    var imported = 0;
    for (final c in cards) {
      await _db.into(_db.collection).insert(CollectionCompanion.insert(
            scryfallId: c['scryfall_id'] as String,
            name: c['name'] as String,
            setCode: c['set_code'] as String,
            collectorNumber: c['collector_number'] as String,
            count: Value(c['count'] as int),
            foil: Value(c['foil'] as int),
            condition: Value(c['condition'] as String),
            language: Value(c['language'] as String),
            addedAt: DateTime.parse(c['added_at'] as String),
            priceUsd: Value(c['price_usd'] as double?),
            priceUsdFoil: Value(c['price_usd_foil'] as double?),
            priceUpdatedAt: Value(c['price_updated_at'] == null
                ? null
                : DateTime.parse(c['price_updated_at'] as String)),
            notes: Value(c['notes'] as String?),
          ));
      imported++;
    }
    return imported;
  }
}
```

- [ ] **Step 2: Settings screen**

Overwrite `lib/features/settings/settings_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../data/repositories/collection_repository.dart';
import 'backup_restore_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({required this.repo, super.key});
  final CollectionRepository repo;
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int? _refreshDone;
  int? _refreshTotal;

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
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Prices refreshed')));
  }

  @override
  Widget build(BuildContext context) {
    final backup = BackupRestoreService(widget.repo.db);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Refresh all prices'),
            subtitle: _refreshDone == null
                ? const Text('Re-fetches every card from Scryfall (rate-limited)')
                : Text('Refreshing… $_refreshDone / ${_refreshTotal ?? "?"}'),
            trailing: _refreshDone == null
                ? const Icon(Icons.refresh)
                : const SizedBox(
                    width: 24, height: 24,
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

- [ ] **Step 3: Analyze**

Run:
```bash
flutter analyze
```
Expected: clean.

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "add settings screen with refresh-all and json backup"
```

---

### Task 18: Final Smoke Test + README

**Files:**
- Create: `README.md`

- [ ] **Step 1: Build APK**

Run:
```bash
flutter build apk --debug
```
Expected: builds successfully.

- [ ] **Step 2: Full test run**

Run:
```bash
flutter analyze
flutter test
```
Expected: all green.

- [ ] **Step 3: Minimal README**

Create `README.md`:

```markdown
# MTG Scanner

Free, login-free Android app for cataloging Magic: The Gathering cards and exporting to Moxfield.

## Plan A (current): manual add + collection + export

- Search by name (Scryfall autocomplete)
- Pick exact printing
- View collection with live prices and totals
- Export to Moxfield text or CSV
- JSON backup

## Plan B (upcoming)

- Camera scanning with OCR + foil detection

## Dev

    flutter pub get
    dart run build_runner build --delete-conflicting-outputs
    flutter test
    flutter run
```

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "add readme and finalize plan a"
```

---

## Self-Review Notes

- **Spec coverage:** All Plan-A-relevant spec sections are covered — data model (Task 2), Scryfall client with rate limit (Task 7), collection merge rule (Task 4), price capture at match time (Task 6/8), stale-price display (Task 12), export formats (Tasks 13–15), review queue with confirm/edit/reject (Task 16), settings with refresh-all + backup (Task 17). Scanning pipeline and foil detection are deferred to Plan B as agreed.
- **Scryfall rate limit:** client uses a 100ms minimum gap (10 req/s cap from spec).
- **Types:** `CollectionData` is typedef'd to the drift-generated row class; actual name confirmed after codegen and adjusted if needed.
- **Hack flagged:** Task 16's `(collection as dynamic)._db` replaced with a public `db` getter on `CollectionRepository` in Step 3.
