import '../../data/scryfall/scryfall_client.dart';
import '../../data/scryfall/scryfall_models.dart';
import 'parsed_ocr.dart';

class ScanMatcher {
  ScanMatcher({required this.scry});
  final ScryfallClient scry;

  /// Resolves parsed OCR to a Scryfall card.
  ///
  /// Lookup order:
  /// 1. name + each candidate collector number (set-code OCR is noisy and
  ///    cards without an `N/M` fraction tend to produce multiple digit
  ///    candidates — try them until one hits).
  /// 2. set code + best collector number.
  /// 3. fuzzy name.
  ///
  /// Returns `null` when every lookup comes up empty. Throws [ScryfallException]
  /// on network/API errors so callers can treat them as "offline".
  Future<ScryfallCard?> match(ParsedOcr parsed) async {
    final name = parsed.name;

    if (name.isNotEmpty) {
      for (final cn in parsed.collectorNumberCandidates) {
        final hits = await scry.cardsByNameAndCollectorNumber(name, cn);
        if (hits.isNotEmpty) return hits.first;
      }
    }

    final primaryCn = parsed.collectorNumber;
    if (parsed.setCode != null && primaryCn != null) {
      try {
        return await scry.cardBySetAndNumber(parsed.setCode!, primaryCn);
      } on ScryfallNotFound {
        // fall through to fuzzy
      }
    }

    if (name.isEmpty) return null;
    try {
      return await scry.cardByFuzzyName(name);
    } on ScryfallNotFound {
      return null;
    }
  }
}
