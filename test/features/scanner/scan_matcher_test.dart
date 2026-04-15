import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mtg_scanner/data/scryfall/scryfall_client.dart';
import 'package:mtg_scanner/data/scryfall/scryfall_models.dart';
import 'package:mtg_scanner/features/scanner/parsed_ocr.dart';
import 'package:mtg_scanner/features/scanner/scan_matcher.dart';

class _FakeScry extends Mock implements ScryfallClient {}

ScryfallCard _card() => ScryfallCard(
      id: 'sid-1',
      name: 'Lightning Bolt',
      set: '2xm',
      collectorNumber: '137',
      rarity: 'uncommon',
      prices: ScryfallPrices(usd: 1.80),
    );

void main() {
  late _FakeScry scry;
  late ScanMatcher matcher;

  setUp(() {
    scry = _FakeScry();
    matcher = ScanMatcher(scry: scry);
  });

  test('exact set+collector match returns the card', () async {
    when(() => scry.cardBySetAndNumber('2XM', '137'))
        .thenAnswer((_) async => _card());
    final r = await matcher.match(
        ParsedOcr.from(rawName: 'Lightning Bolt', rawSetCollector: '2xm 137'));
    expect(r, isNotNull);
    expect(r!.name, 'Lightning Bolt');
  });

  test('fuzzy fallback when exact 404s', () async {
    when(() => scry.cardBySetAndNumber('2XM', '999'))
        .thenThrow(ScryfallNotFound('2xm/999'));
    when(() => scry.cardByFuzzyName('Lightning Bolt'))
        .thenAnswer((_) async => _card());
    final r = await matcher.match(
        ParsedOcr.from(rawName: 'Lightning Bolt', rawSetCollector: '2xm 999'));
    expect(r, isNotNull);
  });

  test('fuzzy-only search when no set+collector present', () async {
    when(() => scry.cardByFuzzyName('Lightning Bolt'))
        .thenAnswer((_) async => _card());
    final r = await matcher
        .match(ParsedOcr.from(rawName: 'Lightning Bolt', rawSetCollector: ''));
    expect(r, isNotNull);
  });

  test('returns null when fuzzy 404s', () async {
    when(() => scry.cardByFuzzyName('Gibberish'))
        .thenThrow(ScryfallNotFound('fuzzy'));
    final r = await matcher
        .match(ParsedOcr.from(rawName: 'Gibberish', rawSetCollector: ''));
    expect(r, isNull);
  });

  test('returns null when name empty and no set+collector', () async {
    final r = await matcher
        .match(ParsedOcr.from(rawName: '', rawSetCollector: ''));
    expect(r, isNull);
    verifyNever(() => scry.cardByFuzzyName(any()));
  });

  test('rethrows ScryfallException from exact lookup', () async {
    when(() => scry.cardBySetAndNumber('2XM', '137'))
        .thenThrow(ScryfallException('network down'));
    expect(
      () => matcher.match(ParsedOcr.from(
          rawName: 'Lightning Bolt', rawSetCollector: '2xm 137')),
      throwsA(isA<ScryfallException>()),
    );
  });

  test('rethrows ScryfallException from fuzzy lookup', () async {
    when(() => scry.cardByFuzzyName('Lightning Bolt'))
        .thenThrow(ScryfallException('network down'));
    expect(
      () => matcher
          .match(ParsedOcr.from(rawName: 'Lightning Bolt', rawSetCollector: '')),
      throwsA(isA<ScryfallException>()),
    );
  });
}
