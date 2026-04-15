import '../../data/scryfall/scryfall_client.dart';
import '../../data/scryfall/scryfall_models.dart';
import 'parsed_ocr.dart';

class ScanMatcher {
  ScanMatcher({required this.scry});

  final ScryfallClient scry;

  /// Resolves a parsed OCR result to a Scryfall card.
  ///
  /// Returns `null` when no card is found (exact lookup 404s AND fuzzy 404s,
  /// or there isn't enough input to try a fuzzy lookup).
  ///
  /// Throws [ScryfallException] on network/API errors — callers should treat
  /// these as "offline" rather than "no match".
  Future<MatchResult?> match(ParsedOcr parsed) async {
    if (parsed.setCode != null && parsed.collectorNumber != null) {
      try {
        final card = await scry.cardBySetAndNumber(
            parsed.setCode!, parsed.collectorNumber!);
        return MatchResult(card, 1.0);
      } on ScryfallNotFound {
        // fall through to fuzzy
      }
    }
    if (parsed.name.isEmpty) return null;
    try {
      final card = await scry.cardByFuzzyName(parsed.name);
      return MatchResult(card, 0.6);
    } on ScryfallNotFound {
      return null;
    }
  }
}

class MatchResult {
  MatchResult(this.card, this.confidence);
  final ScryfallCard card;
  final double confidence;
}
