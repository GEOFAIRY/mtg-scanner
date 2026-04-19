import 'package:drift/drift.dart';
import '../database.dart';
import '../tables.dart';

part 'collection_dao.g.dart';

@DriftAccessor(tables: [Collection])
class CollectionDao extends DatabaseAccessor<AppDatabase>
    with _$CollectionDaoMixin {
  CollectionDao(super.db);

  Future<({int id, bool wasInsertion})> upsertMerging({
    required String scryfallId,
    required String name,
    required String setCode,
    required String collectorNumber,
    required String? rarity,
    required bool foil,
    required String condition,
    required String language,
    required double? priceUsd,
    required double? priceUsdFoil,
    required DateTime addedAt,
    String? imageSmall,
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
      final id = await into(collection).insert(CollectionCompanion.insert(
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
        rarity: Value(rarity),
        imageSmall: Value(imageSmall),
      ));
      return (id: id, wasInsertion: true);
    }
    await (update(collection)..whereSamePrimaryKey(existing)).write(
      CollectionCompanion(
        count: Value(existing.count + 1),
        priceUsd: Value(priceUsd),
        priceUsdFoil: Value(priceUsdFoil),
        priceUpdatedAt: Value(addedAt),
        rarity: Value(rarity ?? existing.rarity),
        imageSmall: Value(imageSmall ?? existing.imageSmall),
      ),
    );
    return (id: existing.id, wasInsertion: false);
  }
}

