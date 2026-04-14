import 'package:drift/drift.dart';
import '../db/database.dart';
import '../scryfall/scryfall_client.dart';
import '../scryfall/scryfall_models.dart';

class CollectionRepository {
  CollectionRepository(this._db, this._scry);
  final AppDatabase _db;
  final ScryfallClient _scry;

  AppDatabase get db => _db;

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
