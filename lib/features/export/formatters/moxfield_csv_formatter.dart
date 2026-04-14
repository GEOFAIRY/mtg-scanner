import 'moxfield_text_formatter.dart';

const _languages = {
  'en': 'English', 'ja': 'Japanese', 'de': 'German', 'fr': 'French',
  'it': 'Italian', 'es': 'Spanish', 'pt': 'Portuguese', 'ru': 'Russian',
  'ko': 'Korean', 'zhs': 'Chinese Simplified', 'zht': 'Chinese Traditional',
};

String _q(String v) {
  if (v.contains(',') || v.contains('"') || v.contains('\n')) {
    return '"${v.replaceAll('"', '""')}"';
  }
  return v;
}

String _ts(DateTime t) {
  String p2(int n) => n.toString().padLeft(2, '0');
  return '${t.year}-${p2(t.month)}-${p2(t.day)} '
      '${p2(t.hour)}:${p2(t.minute)}:${p2(t.second)}';
}

String formatMoxfieldCsv(List<MoxRow> rows, {DateTime? now}) {
  final ts = _ts(now ?? DateTime.now());
  final buf = StringBuffer()
    ..write('Count,Tradelist Count,Name,Edition,Condition,Language,Foil,Tags,Last Modified,Collector Number');
  for (final r in rows) {
    final lang = _languages[r.language] ?? r.language;
    buf
      ..write('\n')
      ..write('${r.count},0,${_q(r.name)},${r.set},${r.condition},$lang,${r.foil ? 'foil' : ''},,$ts,${r.collector}');
  }
  return buf.toString();
}
