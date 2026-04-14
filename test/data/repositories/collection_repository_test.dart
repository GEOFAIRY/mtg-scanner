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
