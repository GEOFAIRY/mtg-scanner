import '../../data/scryfall/scryfall_client.dart';
import '../../data/scryfall/scryfall_models.dart';
import 'parsed_ocr.dart';

class ScanMatcher {
  ScanMatcher({required this.scry, this.maxAutocompleteRetries = 5});
  final ScryfallClient scry;

  /// Cap on how many autocomplete suggestions the rescue path re-checks.
  /// Every suggestion costs one or more Scryfall calls (throttled at 100ms),
  /// so we limit this to keep failing scans from stalling the UI.
  final int maxAutocompleteRetries;

  /// Resolves parsed OCR to a Scryfall card.
  ///
  /// Lookup order:
  /// 1. name + each candidate collector number.
  /// 2. set code + primary collector number.
  /// 3. fuzzy name.
  /// 4. autocomplete rescue: when the OCR'd name is close-but-not-exact
  ///    (retro / showcase / full-art frames are notorious for this), retry
  ///    name+cn against each autocomplete suggestion.
  ///
  /// Returns `null` when every lookup comes up empty. Throws [ScryfallException]
  /// on network/API errors so callers can treat them as "offline".
  Future<ScryfallCard?> match(ParsedOcr parsed) async {
    final name = parsed.name;
    final candidates = parsed.collectorNumberCandidates;

    if (name.isNotEmpty) {
      for (final cn in candidates) {
        final hits = await scry.cardsByNameAndCollectorNumber(name, cn);
        if (hits.isNotEmpty) return hits.first;
      }
    }

    final primaryCn = parsed.collectorNumber;
    if (parsed.setCode != null && primaryCn != null) {
      try {
        final card =
            await scry.cardBySetAndNumber(parsed.setCode!, primaryCn);
        // The set code from OCR is often garbage (especially on old-border
        // and retro frames). If the returned card's name doesn't resemble
        // the OCR'd name at all, this is a false positive (e.g. OCR reads
        // "S99/103" → Goblin Hero when the user scanned Lavaborn Muse).
        // Drop it and let fuzzy sort things out.
        if (name.isEmpty || _namesSimilar(name, card.name)) {
          return card;
        }
      } on ScryfallNotFound {
        // fall through to fuzzy
      }
    }

    if (name.isEmpty) return null;
    ScryfallCard? fuzzy;
    try {
      fuzzy = await scry.cardByFuzzyName(name);
    } on ScryfallNotFound {
      fuzzy = null;
    }

    if (fuzzy != null && candidates.isEmpty) return fuzzy;

    // When fuzzy resolved the name but we have cn candidates that didn't
    // match via the name+cn search (OCR noise on retro/showcase cn), scan
    // all printings and pick the one whose collector number matches a
    // candidate. This finds the specific retro/showcase/promo printing
    // rather than Scryfall's default.
    if (fuzzy != null && candidates.isNotEmpty) {
      try {
        final printings = await scry.printingsOfName(fuzzy.name);
        for (final cn in candidates) {
          final match = printings
              .where((p) => p.collectorNumber.toLowerCase() == cn)
              .toList();
          if (match.isNotEmpty) return match.first;
        }
      } on ScryfallException {
        // Fall through — return fuzzy as-is.
      }
      return fuzzy;
    }

    // If fuzzy returned a card whose name exactly matches the OCR'd name
    // (case-insensitive), trust it and skip the autocomplete rescue.
    if (fuzzy != null &&
        fuzzy.name.toLowerCase() == name.toLowerCase()) {
      return fuzzy;
    }

    // Autocomplete rescue — only runs when no exact match landed. When we do
    // have candidate cn values, prefer a suggestion whose cn matches the OCR;
    // otherwise fall back to fuzzy on the best suggestion.
    try {
      final suggestions = await scry.autocomplete(name);
      final tried = <String>{name.toLowerCase()};
      var attempts = 0;
      for (final s in suggestions) {
        if (attempts >= maxAutocompleteRetries) break;
        final key = s.toLowerCase();
        if (!tried.add(key)) continue;
        attempts++;
        if (candidates.isNotEmpty) {
          for (final cn in candidates) {
            final hits = await scry.cardsByNameAndCollectorNumber(s, cn);
            if (hits.isNotEmpty) return hits.first;
          }
        } else {
          try {
            return await scry.cardByFuzzyName(s);
          } on ScryfallNotFound {
            // next suggestion
          }
        }
      }
    } on ScryfallException {
      // Autocomplete is a best-effort rescue; don't let its failure mask the
      // fuzzy result we already have.
    }

    return fuzzy;
  }

  /// Quick sanity check: do the OCR'd name and the card name share at least
  /// one meaningful word? Catches obvious mismatches like "Lavaborn Muse" vs
  /// "Goblin Hero" without requiring a full edit-distance computation.
  static bool _namesSimilar(String ocrName, String cardName) {
    final ocrWords = ocrName.toLowerCase().split(RegExp(r'[\s,]+'))
      ..removeWhere((w) => w.length < 3);
    final cardWords = cardName.toLowerCase().split(RegExp(r'[\s,]+'))
      ..removeWhere((w) => w.length < 3);
    return ocrWords.any(cardWords.contains);
  }
}
