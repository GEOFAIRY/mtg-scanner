import 'package:flutter_test/flutter_test.dart';
import 'package:mtg_card_scanner/features/export/formatters/moxfield_text_formatter.dart';
import 'package:mtg_card_scanner/features/export/formatters/moxfield_csv_formatter.dart';

void main() {
  test('emits header + rows in Moxfield CSV format', () {
    final csv = formatMoxfieldCsv(
      [
        const MoxRow(count: 4, name: 'Lightning Bolt', set: '2xm', collector: '137', foil: false),
        const MoxRow(count: 1, name: 'Lightning Bolt', set: '2xm', collector: '137', foil: true, condition: 'LP', language: 'ja'),
      ],
      now: DateTime.utc(2026, 4, 14, 12, 0, 0),
    );
    final lines = csv.split('\n');
    expect(lines[0],
        '"Count","Tradelist Count","Name","Edition","Condition","Language","Foil","Tags","Last Modified","Collector Number","Alter","Proxy","Purchase Price"');
    expect(lines[1],
        '"4","0","Lightning Bolt","2xm","Near Mint","English","","","2026-04-14 12:00:00.000000","137","False","False",""');
    expect(lines[2],
        '"1","0","Lightning Bolt","2xm","Lightly Played","Japanese","foil","","2026-04-14 12:00:00.000000","137","False","False",""');
  });

  test('escapes embedded quotes', () {
    final csv = formatMoxfieldCsv(
      [const MoxRow(count: 1, name: 'Say "Hi"', set: 'xyz', collector: '1', foil: false)],
      now: DateTime.utc(2026, 4, 14),
    );
    expect(csv.split('\n')[1].contains('"Say ""Hi"""'), isTrue);
  });
}

