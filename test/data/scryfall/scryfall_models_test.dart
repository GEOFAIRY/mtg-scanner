import 'package:flutter_test/flutter_test.dart';
import 'package:mtg_card_scanner/data/scryfall/scryfall_models.dart';

void main() {
  test('parses rarity from Scryfall JSON', () {
    final c = ScryfallCard.fromJson({
      'id': 'abc',
      'name': 'Lightning Bolt',
      'set': '2xm',
      'collector_number': '137',
      'rarity': 'uncommon',
      'prices': {'usd': '1.80'},
    });
    expect(c.rarity, 'uncommon');
  });

  test('rarity is null when absent', () {
    final c = ScryfallCard.fromJson({
      'id': 'abc',
      'name': 'Lightning Bolt',
      'set': '2xm',
      'collector_number': '137',
      'prices': const <String, dynamic>{},
    });
    expect(c.rarity, isNull);
  });
}

