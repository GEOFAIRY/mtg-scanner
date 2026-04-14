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

  Future<void> confirm(int id) => _db.scansDao.markStatus(id, 'confirmed');
  Future<void> reject(int id) => _db.scansDao.markStatus(id, 'rejected');
}
