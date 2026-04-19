import 'package:flutter_test/flutter_test.dart';
import 'package:mtg_card_scanner/features/export/formatters/moxfield_text_formatter.dart';

void main() {
  test('formats basic rows', () {
    final lines = formatMoxfieldText([
      const MoxRow(count: 4, name: 'Lightning Bolt', set: '2xm', collector: '137', foil: false),
      const MoxRow(count: 1, name: 'Lightning Bolt', set: '2xm', collector: '137', foil: true),
      const MoxRow(count: 2, name: 'Snapcaster Mage', set: 'mm3', collector: '58', foil: false),
    ]);
    expect(lines, [
      '4 Lightning Bolt (2XM) 137',
      '1 Lightning Bolt (2XM) 137 *F*',
      '2 Snapcaster Mage (MM3) 58',
    ]);
  });

  test('uppercases set code', () {
    final lines = formatMoxfieldText([
      const MoxRow(count: 1, name: 'Island', set: 'neo', collector: '1', foil: false),
    ]);
    expect(lines.single, '1 Island (NEO) 1');
  });
}

