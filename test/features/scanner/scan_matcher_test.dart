import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mtg_scanner/data/scryfall/scryfall_client.dart';
import 'package:mtg_scanner/data/scryfall/scryfall_models.dart';
import 'package:mtg_scanner/features/scanner/parsed_ocr.dart';
import 'package:mtg_scanner/features/scanner/scan_matcher.dart';

class _FakeScry extends Mock implements ScryfallClient {}

ScryfallCard _card({
  String id = 'sid-1',
  String name = 'Lightning Bolt',
  String set = '2xm',
  String collector = '137',
  double? usd = 1.80,
  double? usdFoil,
}) =>
    ScryfallCard(
      id: id,
      name: name,
      set: set,
      collectorNumber: collector,
      prices: ScryfallPrices(usd: usd, usdFoil: usdFoil),
    );

void main() {
  late _FakeScry scry;
  late ScanMatcher matcher;

  setUp(() {
    scry = _FakeScry();
    matcher = ScanMatcher(scry: scry);
  });

  test('exact set+collector match returns confidence 1.0', () async {
    when(() => scry.cardBySetAndNumber('2XM', '137'))
        .thenAnswer((_) async => _card());

    final result = await matcher.match(ParsedOcr.from(
        rawName: 'Lightning Bolt', rawSetCollector: '2xm 137'));

    expect(result, isNotNull);
    expect(result!.confidence, 1.0);
    expect(result.card.name, 'Lightning Bolt');
  });

  test('fuzzy fallback when exact 404s returns confidence 0.6', () async {
    when(() => scry.cardBySetAndNumber('2XM', '999'))
        .thenThrow(ScryfallNotFound('2xm/999'));
    when(() => scry.cardByFuzzyName('Lightning Bolt'))
        .thenAnswer((_) async => _card());

    final result = await matcher.match(ParsedOcr.from(
        rawName: 'Lightning Bolt', rawSetCollector: '2xm 999'));

    expect(result!.confidence, 0.6);
  });

  test('fuzzy-only search when no set+collector present', () async {
    when(() => scry.cardByFuzzyName('Lightning Bolt'))
        .thenAnswer((_) async => _card());

    final result = await matcher
        .match(ParsedOcr.from(rawName: 'Lightning Bolt', rawSetCollector: ''));

    expect(result!.confidence, 0.6);
  });

  test('returns null when fuzzy 404s (no match found)', () async {
    when(() => scry.cardByFuzzyName('Gibberish'))
        .thenThrow(ScryfallNotFound('fuzzy'));

    final result = await matcher
        .match(ParsedOcr.from(rawName: 'Gibberish', rawSetCollector: ''));

    expect(result, isNull);
  });

  test('returns null when parsed name is empty and no set+collector', () async {
    final result =
        await matcher.match(ParsedOcr.from(rawName: '', rawSetCollector: ''));

    expect(result, isNull);
    verifyNever(() => scry.cardByFuzzyName(any()));
  });

  test('rethrows ScryfallException from exact lookup (network error)', () async {
    when(() => scry.cardBySetAndNumber('2XM', '137'))
        .thenThrow(ScryfallException('network down'));

    expect(
      () => matcher.match(
          ParsedOcr.from(rawName: 'Lightning Bolt', rawSetCollector: '2xm 137')),
      throwsA(isA<ScryfallException>()),
    );
  });

  test('rethrows ScryfallException from fuzzy lookup (network error)', () async {
    when(() => scry.cardByFuzzyName('Lightning Bolt'))
        .thenThrow(ScryfallException('network down'));

    expect(
      () => matcher
          .match(ParsedOcr.from(rawName: 'Lightning Bolt', rawSetCollector: '')),
      throwsA(isA<ScryfallException>()),
    );
  });
}
