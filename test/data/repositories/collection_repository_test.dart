import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mtg_card_scanner/data/db/database.dart';
import 'package:mtg_card_scanner/data/repositories/collection_repository.dart';
import 'package:mtg_card_scanner/data/scryfall/scryfall_client.dart';
import 'package:mtg_card_scanner/data/scryfall/scryfall_models.dart';

class _FakeScry extends Mock implements ScryfallClient {}

ScryfallCard _card({
  String id = 'sid-1',
  String name = 'Lightning Bolt',
  String set = '2xm',
  String setName = 'Double Masters',
  String collector = '137',
  String? rarity = 'uncommon',
  double? usd = 1.80,
  double? usdFoil,
}) =>
    ScryfallCard(
      id: id,
      name: name,
      set: set,
      setName: setName,
      collectorNumber: collector,
      rarity: rarity,
      prices: ScryfallPrices(usd: usd, usdFoil: usdFoil),
    );

void main() {
  late AppDatabase db;
  late CollectionRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = CollectionRepository(db, _FakeScry());
  });
  tearDown(() => db.close());

  test('addFromScryfall inserts new row and reports wasInsertion=true', () async {
    final r = await repo.addFromScryfall(_card(), foil: false);
    expect(r.wasInsertion, isTrue);
    final rows = await db.select(db.collection).get();
    expect(rows, hasLength(1));
    expect(rows.single.id, r.id);
    expect(rows.single.count, 1);
    expect(rows.single.rarity, 'uncommon');
  });

  test('addFromScryfall increments existing row and reports wasInsertion=false',
      () async {
    final first = await repo.addFromScryfall(_card(), foil: false);
    final second = await repo.addFromScryfall(_card(), foil: false);
    expect(first.id, second.id);
    expect(second.wasInsertion, isFalse);
    final row = await (db.select(db.collection)
          ..where((t) => t.id.equals(second.id)))
        .getSingle();
    expect(row.count, 2);
  });

  test('undoAdd deletes the row when wasInsertion is true', () async {
    final r = await repo.addFromScryfall(_card(), foil: false);
    await repo.undoAdd(id: r.id, wasInsertion: true);
    final rows = await db.select(db.collection).get();
    expect(rows, isEmpty);
  });

  test('undoAdd decrements count when wasInsertion is false', () async {
    await repo.addFromScryfall(_card(), foil: false);
    final second = await repo.addFromScryfall(_card(), foil: false);
    await repo.undoAdd(id: second.id, wasInsertion: false);
    final row = await (db.select(db.collection)
          ..where((t) => t.id.equals(second.id)))
        .getSingle();
    expect(row.count, 1);
  });

  test('undoAdd deletes row if decrement would drop to zero', () async {
    final r = await repo.addFromScryfall(_card(), foil: false);
    // count is 1; wasInsertion=false path should delete not decrement below 1
    await repo.undoAdd(id: r.id, wasInsertion: false);
    final rows = await db.select(db.collection).get();
    expect(rows, isEmpty);
  });

  test('updateMatch swaps the row to a different card', () async {
    final r = await repo.addFromScryfall(_card(), foil: false);
    final newCard = _card(id: 'sid-2', name: 'Counterspell', set: 'tmp', collector: '50', rarity: 'common', usd: 0.25);
    await repo.updateMatch(id: r.id, card: newCard, foil: false, count: 1);
    final row = await (db.select(db.collection)..where((t) => t.id.equals(r.id))).getSingle();
    expect(row.scryfallId, 'sid-2');
    expect(row.name, 'Counterspell');
    expect(row.rarity, 'common');
    expect(row.count, 1);
  });

  test('updateMatch merges into an existing (scryfallId, foil) row', () async {
    final a = await repo.addFromScryfall(_card(id: 'A'), foil: false);
    final b = await repo.addFromScryfall(_card(id: 'B'), foil: false);
    // update row `b` to become card `A` non-foil — should merge counts into `a`
    await repo.updateMatch(id: b.id, card: _card(id: 'A'), foil: false, count: 3);
    final rows = await db.select(db.collection).get();
    expect(rows, hasLength(1));
    expect(rows.single.id, a.id);
    expect(rows.single.count, 1 + 3);
  });

  test('updateMatch adjusts count only', () async {
    final r = await repo.addFromScryfall(_card(), foil: false);
    await repo.updateMatch(id: r.id, card: _card(), foil: false, count: 5);
    final row = await (db.select(db.collection)..where((t) => t.id.equals(r.id))).getSingle();
    expect(row.count, 5);
  });
}

