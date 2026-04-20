class SetCollector {
  const SetCollector(this.set, this.collectorNumber);
  final String set;
  final String collectorNumber;
}

class ParsedOcr {
  const ParsedOcr({
    required this.name,
    required this.rawName,
    required this.rawSetCollector,
    this.setCode,
    this.collectorNumber,
    this.collectorNumberCandidates = const [],
  });

  final String name;
  final String rawName;
  final String rawSetCollector;
  final String? setCode;
  final String? collectorNumber;

  /// Every plausible collector number OCR'd from [rawSetCollector], ranked
  /// best-first. The top entry matches [collectorNumber]. Callers try the
  /// alternates when a Scryfall lookup on the primary returns nothing — on
  /// cards without an `N/M` fraction, year numbers and mana costs often
  /// outrank the real collector number in raw OCR.
  final List<String> collectorNumberCandidates;

  static final _symbolNoise = RegExp(r'[{(\[][^})\]]*[})\]]');
  static final _ws = RegExp(r'\s+');

  static String cleanName(String input) {
    var s = input.replaceAll(_symbolNoise, '');
    s = s.replaceAll(_ws, ' ').trim();
    return s;
  }

  static final _setCode = RegExp(r'\b([a-zA-Z0-9]{3,4})\b');
  // Collector numbers are 2-4 digits, optionally suffixed with a single
  // letter (e.g. `137a`, `25b`). The `(?<![a-z])` guard rejects digit-then-
  // letter tokens like "2xm" where 2 is a set-code fragment, not a cn.
  // The `(?!\d)` guard keeps us from matching a prefix of a longer digit run.
  // Unanchored on the leading side so we can lift "324" out of noisy OCR
  // like `"R O324"` where the letter O swallows the word boundary.
  static final _bareNum =
      RegExp(r'(?<!\d)(\d{2,4}[a-z]?)(?![a-z\d])', caseSensitive: false);
  // "137/274" → group 1 is the collector number, group 2 the set total.
  static final _fractionNum =
      RegExp(r'(\d{1,4}[a-z]?)/(\d{1,4})', caseSensitive: false);

  static bool _looksLikeYear(String n) {
    final i = int.tryParse(n);
    return i != null && i >= 1990 && i <= 2099;
  }

  /// Scryfall stores collector numbers without leading zeros ("13", not
  /// "013"), but many cards print them zero-padded. Expand the candidate list
  /// to include the stripped form too, so name+cn lookups actually hit.
  static List<String> _expandLeadingZeros(List<String> cns) {
    final out = <String>[];
    final seen = <String>{};
    for (final cn in cns) {
      if (seen.add(cn)) out.add(cn);
      final stripped = cn.replaceFirst(RegExp(r'^0+'), '');
      if (stripped.isNotEmpty && stripped != cn && seen.add(stripped)) {
        out.add(stripped);
      }
    }
    return out;
  }

  static List<String> _rankedCollectorNumbers(String input) {
    final fractionHits = _fractionNum
        .allMatches(input)
        .map((m) => m.group(1)!.toLowerCase())
        .toList();
    if (fractionHits.isNotEmpty) return _expandLeadingZeros(fractionHits);

    final all = _bareNum
        .allMatches(input)
        .map((m) => m.group(1)!.toLowerCase())
        .toList();
    // Years are almost never the collector number; push them to the back but
    // keep them as a last resort in case an OCR artifact corrupts the real one.
    final primary = all.where((n) => !_looksLikeYear(n)).toList();
    final years = all.where(_looksLikeYear).toList();
    return _expandLeadingZeros([...primary, ...years]);
  }

  // A token is plausibly a set code if it's all letters (DMC, STA, PLST) or
  // ends in a letter (10E, 40K). Letter-prefix + digit-suffix patterns like
  // "O324" are almost always misread collector numbers, not set codes.
  static final _plausibleSetCode = RegExp(r'^([A-Z]+|[0-9]+[A-Z]+)$');

  static SetCollector? parseSetCollector(String input) {
    final nums = _rankedCollectorNumbers(input);
    final s = input.toUpperCase();
    final codes = _setCode
        .allMatches(s)
        .map((m) => m.group(1)!)
        .where((c) => _plausibleSetCode.hasMatch(c))
        .toList();
    if (nums.isEmpty || codes.isEmpty) return null;
    return SetCollector(codes.first.toUpperCase(), nums.first);
  }

  factory ParsedOcr.from({
    required String rawName,
    required String rawSetCollector,
  }) {
    final ranked = _rankedCollectorNumbers(rawSetCollector);
    final sc = parseSetCollector(rawSetCollector);
    return ParsedOcr(
      name: cleanName(rawName),
      rawName: rawName,
      rawSetCollector: rawSetCollector,
      setCode: sc?.set,
      collectorNumber: ranked.isEmpty ? null : ranked.first,
      collectorNumberCandidates: ranked,
    );
  }
}
