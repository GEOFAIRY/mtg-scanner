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
