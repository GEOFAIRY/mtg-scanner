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

  test('autocomplete rescue fuzzy-branch runs without cn but scoring rejects '
      'low-confidence result', () async {
    // With no cn/set signal and a noisy OCR name, the autocomplete-rescued
    // card only contributes its name similarity to the score. The name-only
    // path caps below 0.5 for any imperfect OCR (non-zero edit distance), so
    // the result is correctly rejected as low confidence.
    when(() => scry.cardByFuzzyName('Lghtning Blt'))
        .thenThrow(ScryfallNotFound('fuzzy'));
    when(() => scry.autocomplete('Lghtning Blt'))
        .thenAnswer((_) async => ['Lightning Bolt']);
    when(() => scry.cardByFuzzyName('Lightning Bolt'))
        .thenAnswer((_) async => _card());

    final r = await matcher
        .match(ParsedOcr.from(rawName: 'Lghtning Blt', rawSetCollector: ''));
    // Verify the cn-less branch was taken (fuzzy on the suggestion).
    verify(() => scry.cardByFuzzyName('Lightning Bolt')).called(1);
    // Low-confidence result gets rejected.
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

  test('scoring prefers name+cn+set match over a first-hit with wrong printing',
      () async {
    // name+cn returns two hits: the first has a wrong set, the second agrees
    // with the OCR'd set code. Old behavior: first-hit wins. New behavior:
    // score picks the set-matching one.
    when(() => scry.cardsByNameAndCollectorNumber('Lightning Bolt', '137'))
        .thenAnswer((_) async => [
              _card(set: 'dmr', cn: '137'),
              _card(set: '2xm', cn: '137'),
            ]);
    final r = await matcher.match(ParsedOcr.from(
        rawName: 'Lightning Bolt', rawSetCollector: '2xm 137'));
    expect(r, isNotNull);
    expect(r!.set, '2xm');
  });

  test('scoring short-circuits at >= 0.95 and skips later lookup paths',
      () async {
    when(() => scry.cardsByNameAndCollectorNumber('Lightning Bolt', '137'))
        .thenAnswer((_) async => [_card(set: '2xm', cn: '137')]);
    // These should never be called.
    when(() => scry.cardBySetAndNumber(any(), any()))
        .thenAnswer((_) async => _card(set: 'dmr', cn: '137'));
    when(() => scry.cardByFuzzyName(any()))
        .thenAnswer((_) async => _card(set: 'dmr', cn: '999'));

    await matcher.match(ParsedOcr.from(
        rawName: 'Lightning Bolt', rawSetCollector: '2xm 137'));

    verifyNever(() => scry.cardBySetAndNumber(any(), any()));
    verifyNever(() => scry.cardByFuzzyName(any()));
  });

  test('returns null when best candidate scores below threshold', () async {
    // OCR'd something totally unrelated; every path returns a card with low
    // name similarity. Threshold 0.5 -> null.
    when(() => scry.cardsByNameAndCollectorNumber(any(), any()))
        .thenAnswer((_) async => <ScryfallCard>[]);
    when(() => scry.cardBySetAndNumber(any(), any()))
        .thenThrow(ScryfallNotFound('na'));
    when(() => scry.cardByFuzzyName('xyzzy nonexistent'))
        .thenAnswer((_) async => ScryfallCard(
              id: 'sid-irr',
              name: 'A Completely Different Card Name',
              set: 'zzz',
              setName: 'Z',
              collectorNumber: '999',
              rarity: 'common',
              prices: ScryfallPrices(usd: 0.05),
            ));

    final r = await matcher.match(ParsedOcr.from(
        rawName: 'xyzzy nonexistent', rawSetCollector: ''));

    expect(r, isNull);
  });

  test('scoring accepts compound-name cards when OCR only sees the front face',
      () async {
    // Adventure/DFC/split cards: Scryfall returns the full compound name
    // (e.g. "Cruel Somnophage // Can't Wake Up"), but OCR only ever reads
    // the front face. Without face-stripping, nameSim is ~0.55, and the
    // score on a name-only match caps at 0.5 * 0.55 = 0.275 — rejected.
    // With face-stripping, nameSim is 1.0, score caps at 0.5 — accepted.
    final compound = ScryfallCard(
      id: 'sid-woe-222',
      name: "Cruel Somnophage // Can't Wake Up",
      set: 'woe',
      setName: 'Wilds of Eldraine',
      collectorNumber: '222',
      rarity: 'rare',
      prices: ScryfallPrices(usd: 0.72, usdFoil: 0.82),
    );
    when(() => scry.cardByFuzzyName('Cruel Somnophage'))
        .thenAnswer((_) async => compound);
    final r = await matcher.match(ParsedOcr.from(
        rawName: 'Cruel Somnophage', rawSetCollector: ''));
    expect(r, isNotNull);
    expect(r!.collectorNumber, '222');
  });

  test('set+cn path iterates alternate cn candidates when primary misses',
      () async {
    // OCR'd "WOE 137 222" — primary cn "137" is wrong, "222" is right.
    // name+cn fails for both. Old behavior: path 2 tries only primary cn
    // "137", fails, falls to fuzzy. New behavior: path 2 iterates all cn
    // candidates and succeeds on "222".
    when(() => scry.cardsByNameAndCollectorNumber(any(), any()))
        .thenAnswer((_) async => <ScryfallCard>[]);
    when(() => scry.cardBySetAndNumber('WOE', '137'))
        .thenThrow(ScryfallNotFound('woe/137'));
    when(() => scry.cardBySetAndNumber('WOE', '222'))
        .thenAnswer((_) async => _card(set: 'woe', cn: '222'));
    // Fuzzy would otherwise rescue under the old code; stub it to 404 so
    // this test isolates the path 2 iteration behavior.
    when(() => scry.cardByFuzzyName(any()))
        .thenThrow(ScryfallNotFound('fuzzy'));
    final r = await matcher.match(ParsedOcr.from(
        rawName: 'Lightning Bolt', rawSetCollector: 'WOE 137 222'));
    expect(r, isNotNull);
    expect(r!.collectorNumber, '222');
  });
}
