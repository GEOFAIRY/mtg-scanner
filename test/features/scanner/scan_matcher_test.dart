import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mtg_card_scanner/data/scryfall/scryfall_client.dart';
import 'package:mtg_card_scanner/data/scryfall/scryfall_models.dart';
import 'package:mtg_card_scanner/features/scanner/parsed_ocr.dart';
import 'package:mtg_card_scanner/features/scanner/scan_matcher.dart';

class _FakeScry extends Mock implements ScryfallClient {}

ScryfallCard _card({String set = '2xm', String cn = '137'}) => ScryfallCard(
      id: 'sid-$set-$cn',
      name: 'Lightning Bolt',
      set: set,
      setName: 'Double Masters',
      collectorNumber: cn,
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

  test('name+cn lookup wins even when set code is present', () async {
    when(() => scry.cardsByNameAndCollectorNumber('Lightning Bolt', '137'))
        .thenAnswer((_) async => [_card()]);
    final r = await matcher.match(
        ParsedOcr.from(rawName: 'Lightning Bolt', rawSetCollector: '2xm 137'));
    expect(r, isNotNull);
    expect(r!.set, '2xm');
    verifyNever(() => scry.cardBySetAndNumber(any(), any()));
  });

  test('falls back to set+cn when name+cn returns empty', () async {
    when(() => scry.cardsByNameAndCollectorNumber('Lightning Bolt', '137'))
        .thenAnswer((_) async => <ScryfallCard>[]);
    when(() => scry.cardBySetAndNumber('2XM', '137'))
        .thenAnswer((_) async => _card());
    final r = await matcher.match(
        ParsedOcr.from(rawName: 'Lightning Bolt', rawSetCollector: '2xm 137'));
    expect(r, isNotNull);
  });

  test('falls back to fuzzy when name+cn and set+cn both fail', () async {
    when(() => scry.cardsByNameAndCollectorNumber('Lightning Bolt', '999'))
        .thenAnswer((_) async => <ScryfallCard>[]);
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
    verifyNever(() => scry.cardsByNameAndCollectorNumber(any(), any()));
  });

  test('rethrows ScryfallException from name+cn lookup', () async {
    when(() => scry.cardsByNameAndCollectorNumber('Lightning Bolt', '137'))
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
