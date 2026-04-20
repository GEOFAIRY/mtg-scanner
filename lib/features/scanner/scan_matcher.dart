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

  static const double _shortCircuitScore = 0.95;
  static const double _acceptThreshold = 0.5;

  /// Resolves parsed OCR to a Scryfall card by gathering candidates across
  /// lookup paths and returning the highest-scoring one.
  ///
  /// Scoring weights: 0.5 * name similarity + 0.3 * cn match + 0.2 * set match.
  /// A candidate scoring >= 0.95 short-circuits the remaining paths.
  /// Final result must clear 0.5 or `null` is returned.
  ///
  /// Lookup order (same as before, just feeds into a scored pool now):
  /// 1. name + each candidate collector number.
  /// 2. plst / set + primary collector number.
  /// 3. fuzzy name.
  /// 4. printings-of-name walk.
  /// 5. autocomplete rescue.
  ///
  /// Throws [ScryfallException] on network/API errors so callers can treat
  /// them as "offline".
  Future<ScryfallCard?> match(
    ParsedOcr parsed, {
    bool isListCard = false,
    Future<ScryfallCard?>? speculativeFuzzy,
  }) async {
    final name = parsed.name;
    final candidates = parsed.collectorNumberCandidates;
    ScryfallCard? best;
    double bestScore = -1.0;

    void consider(Iterable<ScryfallCard> cards) {
      for (final c in cards) {
        final s = _scoreCandidate(c, parsed);
        if (s > bestScore) {
          bestScore = s;
          best = c;
        }
      }
    }

    bool done() => bestScore >= _shortCircuitScore;

    // Path 1: name + each candidate collector number.
    if (name.isNotEmpty) {
      for (final cn in candidates) {
        if (done()) break;
        final hits = await scry.cardsByNameAndCollectorNumber(name, cn);
        consider(hits);
      }
    }

    // Path 2: setCode + each candidate collector number. Iterates all cn
    // candidates — the primary cn is frequently noise (year numbers, mana
    // cost glyphs), so a secondary candidate often holds the real cn. List
    // lookup fires only for the primary cn, since the icon hint correlates
    // with the printed number directly under the set symbol.
    final primaryCn = parsed.collectorNumber;
    if (!done() && parsed.setCode != null) {
      for (final cn in candidates) {
        if (done()) break;
        if (isListCard && cn == primaryCn) {
          try {
            final listCn = '${parsed.setCode!}-$cn'.toLowerCase();
            consider([await scry.cardBySetAndNumber('plst', listCn)]);
          } on ScryfallNotFound {
            // Not on The List — continue.
          }
          if (done()) break;
        }
        try {
          consider([await scry.cardBySetAndNumber(parsed.setCode!, cn)]);
        } on ScryfallNotFound {
          // Try next candidate, or fall through.
        }
      }
    }

    // Path 3: fuzzy name. Prefer the speculative future if one was started
    // earlier by the pipeline — it's already in flight or complete by now,
    // overlapping with OCR refinement passes.
    ScryfallCard? fuzzy;
    if (!done() && name.isNotEmpty) {
      try {
        if (speculativeFuzzy != null) {
          fuzzy = await speculativeFuzzy;
        } else {
          fuzzy = await scry.cardByFuzzyName(name);
        }
        if (fuzzy != null) consider([fuzzy]);
      } on ScryfallNotFound {
        fuzzy = null;
      }
    }

    // Path 4: printings-of-name walk (only when fuzzy resolved and we have
    // cn candidates that disagree with fuzzy's printing — same heuristic as
    // before, just feeding the candidate pool instead of returning early).
    if (!done() && fuzzy != null && candidates.isNotEmpty) {
      try {
        final printings =
            await scry.printingsOfName(fuzzy.name, maxPages: 1);
        for (final cn in candidates) {
          final matching = printings.where(
              (p) => p.collectorNumber.toLowerCase() == cn);
          consider(matching);
          if (done()) break;
        }
      } on ScryfallException {
        // Best-effort — skip.
      }
    }

    // Path 5: autocomplete rescue.
    if (!done() && name.isNotEmpty) {
      try {
        final suggestions = await scry.autocomplete(name);
        final tried = <String>{name.toLowerCase()};
        var attempts = 0;
        for (final s in suggestions) {
          if (done() || attempts >= maxAutocompleteRetries) break;
          final key = s.toLowerCase();
          if (!tried.add(key)) continue;
          attempts++;
          if (candidates.isNotEmpty) {
            for (final cn in candidates) {
              if (done()) break;
              final hits = await scry.cardsByNameAndCollectorNumber(s, cn);
              consider(hits);
            }
          } else {
            try {
              consider([await scry.cardByFuzzyName(s)]);
            } on ScryfallNotFound {
              // next suggestion
            }
          }
        }
      } on ScryfallException {
        // Autocomplete is best-effort.
      }
    }

    return (best != null && bestScore >= _acceptThreshold) ? best : null;
  }

  double _scoreCandidate(ScryfallCard card, ParsedOcr parsed) {
    final nameSim = _nameSimilarity(parsed.name, card.name);
    final cnMatch = parsed.collectorNumberCandidates.any(
            (cn) => cn.toLowerCase() == card.collectorNumber.toLowerCase())
        ? 1.0
        : 0.0;
    final setMatch = (parsed.setCode != null &&
            card.set.toUpperCase() == parsed.setCode!.toUpperCase())
        ? 1.0
        : 0.0;
    return 0.5 * nameSim + 0.3 * cnMatch + 0.2 * setMatch;
  }

  static final _nonAlphaNum = RegExp(r'[^a-z0-9 ]');

  /// Normalized Levenshtein similarity, 0..1 (1 = identical). For
  /// adventure / DFC / split cards Scryfall returns a compound "Front //
  /// Back" name but OCR only ever sees the front face; we strip anything
  /// after `//` on both sides before comparing.
  static double _nameSimilarity(String a, String b) {
    final na = _normalizeFace(a);
    final nb = _normalizeFace(b);
    if (na.isEmpty && nb.isEmpty) return 1.0;
    if (na.isEmpty || nb.isEmpty) return 0.0;
    final dist = _levenshtein(na, nb);
    final longest = na.length > nb.length ? na.length : nb.length;
    return 1.0 - dist / longest;
  }

  static String _normalizeFace(String s) {
    final split = s.indexOf('//');
    final face = split >= 0 ? s.substring(0, split) : s;
    return face.toLowerCase().replaceAll(_nonAlphaNum, '').trim();
  }

  static int _levenshtein(String a, String b) {
    final m = a.length;
    final n = b.length;
    if (m == 0) return n;
    if (n == 0) return m;
    var prev = List<int>.generate(n + 1, (i) => i);
    var curr = List<int>.filled(n + 1, 0);
    for (var i = 1; i <= m; i++) {
      curr[0] = i;
      for (var j = 1; j <= n; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        final del = prev[j] + 1;
        final ins = curr[j - 1] + 1;
        final sub = prev[j - 1] + cost;
        curr[j] = del < ins ? (del < sub ? del : sub) : (ins < sub ? ins : sub);
      }
      final tmp = prev;
      prev = curr;
      curr = tmp;
    }
    return prev[n];
  }

}
