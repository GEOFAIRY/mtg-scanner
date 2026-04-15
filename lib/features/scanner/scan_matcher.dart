import '../../data/scryfall/scryfall_client.dart';
import '../../data/scryfall/scryfall_models.dart';
import 'parsed_ocr.dart';

class ScanMatcher {
  ScanMatcher({required this.scry});
  final ScryfallClient scry;

  /// Resolves parsed OCR to a Scryfall card.
  ///
  /// Lookup order:
  /// 1. name + collector number (set-code OCR is noisy, name + cn is usually unique)
  /// 2. set code + collector number (kept as a fallback when name OCR is empty)
  /// 3. fuzzy name
  ///
  /// Returns `null` when every lookup comes up empty. Throws [ScryfallException]
  /// on network/API errors so callers can treat them as "offline".
  Future<ScryfallCard?> match(ParsedOcr parsed) async {
    final name = parsed.name;
    final cn = parsed.collectorNumber;

    if (name.isNotEmpty && cn != null) {
      final hits = await scry.cardsByNameAndCollectorNumber(name, cn);
      if (hits.isNotEmpty) return hits.first;
    }

    if (parsed.setCode != null && cn != null) {
      try {
        return await scry.cardBySetAndNumber(parsed.setCode!, cn);
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
