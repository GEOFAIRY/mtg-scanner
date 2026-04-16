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
    when(() => scry.autocomplete(any())).thenAnswer((_) async => <String>[]);
    when(() => scry.printingsOfName(any(),
        maxPages: any(named: 'maxPages'))).thenAnswer((_) async => <ScryfallCard>[]);
    // Default: plst lookups 404 unless a test overrides.
    when(() => scry.cardBySetAndNumber('plst', any()))
        .thenThrow(ScryfallNotFound('plst'));
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

  test('iterates alternate collector-number candidates', () async {
    // "SPM 143 C 2024": primary cn is "143", alternate is the year "2024".
    when(() => scry.cardsByNameAndCollectorNumber('Lightning Bolt', '143'))
        .thenAnswer((_) async => <ScryfallCard>[]);
    when(() => scry.cardsByNameAndCollectorNumber('Lightning Bolt', '2024'))
        .thenAnswer((_) async => [_card(set: 'spm', cn: '2024')]);
    final r = await matcher.match(ParsedOcr.from(
        rawName: 'Lightning Bolt', rawSetCollector: 'SPM 143 C 2024'));
    expect(r, isNotNull);
    expect(r!.collectorNumber, '2024');
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

  test('fuzzy + cn candidates resolves correct printing via printingsOfName',
      () async {
    // Name+cn search returns empty (OCR noise on retro cn), but fuzzy
    // resolves the name. printingsOfName finds the retro printing whose cn
    // matches the OCR candidate.
    when(() => scry.cardsByNameAndCollectorNumber('Lightning Bolt', '381'))
        .thenAnswer((_) async => <ScryfallCard>[]);
    when(() => scry.cardBySetAndNumber('DMR', '381'))
        .thenThrow(ScryfallNotFound('dmr/381'));
    when(() => scry.cardByFuzzyName('Lightning Bolt'))
        .thenAnswer((_) async => _card(set: 'a25', cn: '141'));
    when(() => scry.printingsOfName('Lightning Bolt',
        maxPages: any(named: 'maxPages'))).thenAnswer(
        (_) async => [_card(set: 'a25', cn: '141'), _card(set: 'dmr', cn: '381')]);

    final r = await matcher.match(
        ParsedOcr.from(rawName: 'Lightning Bolt', rawSetCollector: 'DMR 381'));
    expect(r, isNotNull);
    expect(r!.set, 'dmr');
    expect(r.collectorNumber, '381');
  });

  test('autocomplete rescue recovers when OCR name is close but wrong', () async {
    // Simulate a retro/showcase card where the name region OCRs "Lghtning Blt"
    // but the collector number came through cleanly.
    when(() => scry.cardsByNameAndCollectorNumber('Lghtning Blt', '137'))
        .thenAnswer((_) async => <ScryfallCard>[]);
    when(() => scry.cardBySetAndNumber('2XM', '137'))
        .thenThrow(ScryfallNotFound('2xm/137'));
    when(() => scry.cardByFuzzyName('Lghtning Blt'))
        .thenThrow(ScryfallNotFound('fuzzy'));
    when(() => scry.autocomplete('Lghtning Blt'))
        .thenAnswer((_) async => ['Lightning Bolt']);
    when(() => scry.cardsByNameAndCollectorNumber('Lightning Bolt', '137'))
        .thenAnswer((_) async => [_card()]);

    final r = await matcher.match(
        ParsedOcr.from(rawName: 'Lghtning Blt', rawSetCollector: '2xm 137'));
    expect(r, isNotNull);
    expect(r!.name, 'Lightning Bolt');
  });

  test('autocomplete rescue falls back to fuzzy when no cn candidates', () async {
    when(() => scry.cardByFuzzyName('Lghtning Blt'))
        .thenThrow(ScryfallNotFound('fuzzy'));
    when(() => scry.autocomplete('Lghtning Blt'))
        .thenAnswer((_) async => ['Lightning Bolt']);
    when(() => scry.cardByFuzzyName('Lightning Bolt'))
        .thenAnswer((_) async => _card());

    final r = await matcher
        .match(ParsedOcr.from(rawName: 'Lghtning Blt', rawSetCollector: ''));
    expect(r, isNotNull);
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
