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
  });

  final String name;
  final String rawName;
  final String rawSetCollector;
  final String? setCode;
  final String? collectorNumber;

  static final _symbolNoise = RegExp(r'[{(\[][^})\]]*[})\]]');
  static final _ws = RegExp(r'\s+');

  static String cleanName(String input) {
    var s = input.replaceAll(_symbolNoise, '');
    s = s.replaceAll(_ws, ' ').trim();
    return s;
  }

  static final _setCode = RegExp(r'\b([a-zA-Z0-9]{3,4})\b');
  static final _collNum = RegExp(r'\b(\d{1,4}[a-z]?)\b(?:/\d+)?', caseSensitive: false);

  static SetCollector? parseSetCollector(String input) {
    final s = input.toUpperCase();
    final nums = _collNum.allMatches(input).map((m) => m.group(1)!).toList();
    final codes = _setCode
        .allMatches(s)
        .map((m) => m.group(1)!)
        .where((c) => !RegExp(r'^\d+[A-Z]?$').hasMatch(c))
        .toList();
    if (nums.isEmpty || codes.isEmpty) return null;
    return SetCollector(codes.first.toUpperCase(), nums.first.toLowerCase());
  }

  factory ParsedOcr.from({
    required String rawName,
    required String rawSetCollector,
  }) {
    final sc = parseSetCollector(rawSetCollector);
    return ParsedOcr(
      name: cleanName(rawName),
      rawName: rawName,
      rawSetCollector: rawSetCollector,
      setCode: sc?.set,
      collectorNumber: sc?.collectorNumber,
    );
  }
}
