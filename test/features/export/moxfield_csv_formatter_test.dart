import 'package:flutter_test/flutter_test.dart';
import 'package:mtg_scanner/features/export/formatters/moxfield_text_formatter.dart';
import 'package:mtg_scanner/features/export/formatters/moxfield_csv_formatter.dart';

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
        'Count,Tradelist Count,Name,Edition,Condition,Language,Foil,Tags,Last Modified,Collector Number');
    expect(lines[1],
        '4,0,Lightning Bolt,2xm,NM,English,,,2026-04-14 12:00:00,137');
    expect(lines[2],
        '1,0,Lightning Bolt,2xm,LP,Japanese,foil,,2026-04-14 12:00:00,137');
  });

  test('quotes fields containing commas', () {
    final csv = formatMoxfieldCsv(
      [const MoxRow(count: 1, name: 'Aetherworks, Inc.', set: 'xyz', collector: '1', foil: false)],
      now: DateTime.utc(2026, 4, 14),
    );
    expect(csv.split('\n')[1].contains('"Aetherworks, Inc."'), isTrue);
  });
}
