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
        .thenThrow(ScryfallNotFound('2xm/999'));
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
        .thenThrow(ScryfallNotFound('xxjj'));

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
