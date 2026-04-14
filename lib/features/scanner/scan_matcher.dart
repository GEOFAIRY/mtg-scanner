import '../../data/db/database.dart';
import '../../data/repositories/collection_repository.dart';
import '../../data/repositories/scans_repository.dart';
import '../../data/scryfall/scryfall_client.dart';
import '../../data/scryfall/scryfall_models.dart';
import 'parsed_ocr.dart';

class ScanMatcher {
  ScanMatcher({
    required this.scry,
    required this.collection,
    required this.scans,
    required this.db,
    this.autoConfirmThreshold = 0.8,
  });

  final ScryfallClient scry;
  final CollectionRepository collection;
  final ScansRepository scans;
  final AppDatabase db;
  final double autoConfirmThreshold;

  Future<void> matchAfterInsert({
    required int scanId,
    required ParsedOcr parsed,
  }) async {
    final match = await _findMatch(parsed);
    if (match == null) return;
    await db.scansDao.updateMatch(
      scanId,
      scryfallId: match.card.id,
      name: match.card.name,
      setCode: match.card.set,
      collectorNumber: match.card.collectorNumber,
      confidence: match.confidence,
      priceUsd: match.card.prices.usd,
      priceUsdFoil: match.card.prices.usdFoil,
    );
    if (match.confidence >= autoConfirmThreshold) {
      await collection.addFromScryfall(match.card);
      await scans.confirm(scanId);
    }
  }

  Future<_MatchResult?> _findMatch(ParsedOcr parsed) async {
    if (parsed.setCode != null && parsed.collectorNumber != null) {
      try {
        final c = await scry.cardBySetAndNumber(
            parsed.setCode!, parsed.collectorNumber!);
        return _MatchResult(c, 1.0);
      } on ScryfallNotFound {
        // fall through to fuzzy
      } on ScryfallException {
        return null;
      }
    }
    if (parsed.name.isEmpty) return null;
    try {
      final c = await scry.cardByFuzzyName(parsed.name);
      return _MatchResult(c, 0.6);
    } on ScryfallNotFound {
      return null;
    } on ScryfallException {
      return null;
    }
  }
}

class _MatchResult {
  _MatchResult(this.card, this.confidence);
  final ScryfallCard card;
  final double confidence;
}
