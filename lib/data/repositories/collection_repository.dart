import 'package:drift/drift.dart';
import '../db/database.dart';
import '../scryfall/scryfall_client.dart';
import '../scryfall/scryfall_models.dart';

class CollectionRepository {
  CollectionRepository(this._db, this._scry);
  final AppDatabase _db;
  final ScryfallClient _scry;

  AppDatabase get db => _db;

  Future<({int id, bool wasInsertion})> addFromScryfall(
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
        rarity: c.rarity,
        foil: foil,
        condition: condition,
        language: language,
        priceUsd: c.prices.usd,
        priceUsdFoil: c.prices.usdFoil,
        addedAt: DateTime.now(),
        imageSmall: c.imageUriSmall,
      );

  Future<void> undoAdd({required int id, required bool wasInsertion}) async {
    if (wasInsertion) {
      await (_db.delete(_db.collection)..where((t) => t.id.equals(id))).go();
      return;
    }
    final row = await (_db.select(_db.collection)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    if (row == null) return;
    if (row.count <= 1) {
      await (_db.delete(_db.collection)..where((t) => t.id.equals(id))).go();
    } else {
      await (_db.update(_db.collection)..whereSamePrimaryKey(row))
          .write(CollectionCompanion(count: Value(row.count - 1)));
    }
  }

  Future<void> updateMatch({
    required int id,
    required ScryfallCard card,
    required bool foil,
    required int count,
  }) async {
    final foilInt = foil ? 1 : 0;
    final target = await (_db.select(_db.collection)
          ..where((t) =>
              t.scryfallId.equals(card.id) &
              t.foil.equals(foilInt) &
              t.id.equals(id).not()))
        .getSingleOrNull();
    if (target != null) {
      await (_db.update(_db.collection)..whereSamePrimaryKey(target)).write(
        CollectionCompanion(
          count: Value(target.count + count),
          priceUsd: Value(card.prices.usd),
          priceUsdFoil: Value(card.prices.usdFoil),
          priceUpdatedAt: Value(DateTime.now()),
          rarity: Value(card.rarity ?? target.rarity),
          imageSmall: Value(card.imageUriSmall ?? target.imageSmall),
        ),
      );
      await (_db.delete(_db.collection)..where((t) => t.id.equals(id))).go();
      return;
    }
    await (_db.update(_db.collection)..where((t) => t.id.equals(id))).write(
      CollectionCompanion(
        scryfallId: Value(card.id),
        name: Value(card.name),
        setCode: Value(card.set),
        collectorNumber: Value(card.collectorNumber),
        rarity: Value(card.rarity),
        foil: Value(foilInt),
        count: Value(count),
        priceUsd: Value(card.prices.usd),
        priceUsdFoil: Value(card.prices.usdFoil),
        priceUpdatedAt: Value(DateTime.now()),
        imageSmall: Value(card.imageUriSmall),
      ),
    );
  }

  Stream<List<CollectionData>> watchAll() =>
      _db.select(_db.collection).watch();

  Future<CollectionData> getById(int id) =>
      (_db.select(_db.collection)..where((t) => t.id.equals(id))).getSingle();

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
            rarity: Value(card.rarity ?? row.rarity),
            imageSmall: Value(card.imageUriSmall ?? row.imageSmall),
          ),
        );
      } on ScryfallException {
        // skip
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
        rarity: Value(card.rarity ?? row.rarity),
        imageSmall: Value(card.imageUriSmall ?? row.imageSmall),
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

