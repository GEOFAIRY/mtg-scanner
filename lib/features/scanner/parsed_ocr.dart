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
  // Collector numbers are 1-4 digits, optionally suffixed with a single letter
  // (e.g. `137a`, `25b`). Scryfall also allows prefixes like `SB123` or
  // specials like `12★` — rare enough to skip.
  static final _bareNum = RegExp(r'\b(\d{1,4}[a-z]?)\b', caseSensitive: false);
  // "137/274" → group 1 is the collector number, group 2 the set total.
  static final _fractionNum =
      RegExp(r'\b(\d{1,4}[a-z]?)/(\d{1,4})\b', caseSensitive: false);

  static bool _looksLikeYear(String n) {
    final i = int.tryParse(n);
    return i != null && i >= 1990 && i <= 2099;
  }

  static List<String> _rankedCollectorNumbers(String input) {
    final fractionHits = _fractionNum
        .allMatches(input)
        .map((m) => m.group(1)!.toLowerCase())
        .toList();
    if (fractionHits.isNotEmpty) return fractionHits;

    final all = _bareNum
        .allMatches(input)
        .map((m) => m.group(1)!.toLowerCase())
        .toList();
    // Years are almost never the collector number; push them to the back but
    // keep them as a last resort in case an OCR artifact corrupts the real one.
    final primary = all.where((n) => !_looksLikeYear(n)).toList();
    final years = all.where(_looksLikeYear).toList();
    return [...primary, ...years];
  }

  static SetCollector? parseSetCollector(String input) {
    final nums = _rankedCollectorNumbers(input);
    final s = input.toUpperCase();
    final codes = _setCode
        .allMatches(s)
        .map((m) => m.group(1)!)
        .where((c) => !RegExp(r'^\d+[A-Z]?$').hasMatch(c))
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
