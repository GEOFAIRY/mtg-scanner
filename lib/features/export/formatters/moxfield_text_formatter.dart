class MoxRow {
  const MoxRow({
    required this.count,
    required this.name,
    required this.set,
    required this.collector,
    required this.foil,
    this.condition = 'NM',
    this.language = 'en',
  });
  final int count;
  final String name;
  final String set;
  final String collector;
  final bool foil;
  final String condition;
  final String language;
}

List<String> formatMoxfieldText(List<MoxRow> rows) {
  return rows
      .map((r) =>
          '${r.count} ${r.name} (${r.set.toUpperCase()}) ${r.collector}${r.foil ? ' *F*' : ''}')
      .toList();
}
