import '../../data/scryfall/scryfall_client.dart';
import '../../data/scryfall/scryfall_models.dart';
import 'parsed_ocr.dart';

class ScanMatcher {
  ScanMatcher({required this.scry});
  final ScryfallClient scry;

  /// Resolves parsed OCR to a Scryfall card.
  ///
  /// Returns `null` when no card is found (exact AND fuzzy 404, or empty input).
  /// Throws [ScryfallException] on network/API errors — callers treat these
  /// as "offline" rather than "no match".
  Future<ScryfallCard?> match(ParsedOcr parsed) async {
    if (parsed.setCode != null && parsed.collectorNumber != null) {
      try {
        return await scry.cardBySetAndNumber(
            parsed.setCode!, parsed.collectorNumber!);
      } on ScryfallNotFound {
        // fall through to fuzzy
      }
    }
    if (parsed.name.isEmpty) return null;
    try {
      return await scry.cardByFuzzyName(parsed.name);
    } on ScryfallNotFound {
      return null;
    }
  }
}
