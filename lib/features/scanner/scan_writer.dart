import 'package:drift/drift.dart';

import '../../data/db/database.dart';
import 'parsed_ocr.dart';
import 'scan_matcher.dart';

class ScanWriter {
  ScanWriter(this._db);
  final AppDatabase _db;

  Future<int> insertMatched({
    required ParsedOcr parsed,
    required String thumbPath,
    required int foilGuess,
    required MatchResult match,
  }) =>
      _db.scansDao.insertScan(ScansCompanion.insert(
        capturedAt: DateTime.now(),
        rawName: parsed.rawName,
        rawSetCollector: parsed.rawSetCollector,
        cropImagePath: Value(thumbPath),
        matchedScryfallId: Value(match.card.id),
        matchedName: Value(match.card.name),
        matchedSet: Value(match.card.set),
        matchedCollectorNumber: Value(match.card.collectorNumber),
        confidence: Value(match.confidence),
        foilGuess: Value(foilGuess),
        priceUsd: Value(match.card.prices.usd),
        priceUsdFoil: Value(match.card.prices.usdFoil),
      ));

  Future<void> markConfirmed(int id) =>
      _db.scansDao.markStatus(id, 'confirmed');
}
