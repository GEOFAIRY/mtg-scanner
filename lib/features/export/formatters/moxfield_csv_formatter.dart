import 'moxfield_text_formatter.dart';

const _languages = {
  'en': 'English', 'ja': 'Japanese', 'de': 'German', 'fr': 'French',
  'it': 'Italian', 'es': 'Spanish', 'pt': 'Portuguese', 'ru': 'Russian',
  'ko': 'Korean', 'zhs': 'Chinese Simplified', 'zht': 'Chinese Traditional',
};

const _conditions = {
  'NM': 'Near Mint',
  'LP': 'Lightly Played',
  'MP': 'Moderately Played',
  'HP': 'Heavily Played',
  'DMG': 'Damaged',
};

String _q(String v) => '"${v.replaceAll('"', '""')}"';

String _ts(DateTime t) {
  String p2(int n) => n.toString().padLeft(2, '0');
  return '${t.year}-${p2(t.month)}-${p2(t.day)} '
      '${p2(t.hour)}:${p2(t.minute)}:${p2(t.second)}.000000';
}

String formatMoxfieldCsv(List<MoxRow> rows, {DateTime? now}) {
  final ts = _ts(now ?? DateTime.now());
  final buf = StringBuffer()
    ..write('"Count","Tradelist Count","Name","Edition","Condition",'
        '"Language","Foil","Tags","Last Modified","Collector Number",'
        '"Alter","Proxy","Purchase Price"');
  for (final r in rows) {
    final lang = _languages[r.language] ?? r.language;
    final cond = _conditions[r.condition] ?? r.condition;
    buf
      ..write('\n')
      ..write([
        _q('${r.count}'),
        _q('0'),
        _q(r.name),
        _q(r.set),
        _q(cond),
        _q(lang),
        _q(r.foil ? 'foil' : ''),
        _q(''),
        _q(ts),
        _q(r.collector),
        _q('False'),
        _q('False'),
        _q(''),
      ].join(','));
  }
  return buf.toString();
}

