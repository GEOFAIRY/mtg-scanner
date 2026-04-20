import 'dart:io';
import 'dart:typed_data';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:mocktail/mocktail.dart';
import 'package:mtg_card_scanner/data/db/database.dart';
import 'package:mtg_card_scanner/data/repositories/collection_repository.dart';
import 'package:mtg_card_scanner/data/scryfall/scryfall_client.dart';
import 'package:mtg_card_scanner/data/scryfall/scryfall_models.dart';
import 'package:mtg_card_scanner/features/scanner/ocr_runner.dart';
import 'package:mtg_card_scanner/features/scanner/parsed_ocr.dart';
import 'package:mtg_card_scanner/features/scanner/scan_matcher.dart';
import 'package:mtg_card_scanner/features/scanner/scan_pipeline.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

class _FakeOcr extends Mock implements OcrRunner {}

class _FakeMatcher extends Mock implements ScanMatcher {}

class _FakeScry extends Mock implements ScryfallClient {}

class _FakePathProvider extends PathProviderPlatform {
  _FakePathProvider(this.dir);
  final String dir;
  @override
  Future<String?> getApplicationDocumentsPath() async => dir;
}

ScryfallCard _card({double? usd = 1.80, double? usdFoil}) => ScryfallCard(
      id: 'sid-1',
      name: 'Lightning Bolt',
      set: '2xm',
      setName: 'Double Masters',
      collectorNumber: '137',
      rarity: 'uncommon',
      prices: ScryfallPrices(usd: usd, usdFoil: usdFoil),
    );

void main() {
  late AppDatabase db;
  late _FakeOcr ocr;
  late _FakeMatcher matcher;
  late _FakeScry scry;
  late CollectionRepository collection;
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('pipeline_');
    PathProviderPlatform.instance = _FakePathProvider(tempDir.path);
    db = AppDatabase.forTesting(NativeDatabase.memory());
    ocr = _FakeOcr();
    matcher = _FakeMatcher();
    scry = _FakeScry();
    collection = CollectionRepository(db, scry);
    registerFallbackValue(Uint8List(0));
    registerFallbackValue(
        ParsedOcr.from(rawName: '', rawSetCollector: ''));
    registerFallbackValue(Future<ScryfallCard?>.value(null));
    // Speculative-fuzzy support: pipeline calls matcher.scry.cardByFuzzyName
    // directly. Expose the fake scry through the fake matcher, and default
    // the fuzzy call to a 404 so individual tests don't have to care.
    when(() => matcher.scry).thenReturn(scry);
    when(() => scry.cardByFuzzyName(any()))
        .thenThrow(ScryfallNotFound('fuzzy'));
  });
  tearDown(() async {
    await db.close();
    await tempDir.delete(recursive: true);
  });

  ScanPipeline pipeline() => ScanPipeline(
        ocr: ocr,
        matcher: matcher,
        collection: collection,
      );

  void stubOcr({String name = 'Lightning Bolt', String setCol = '2xm 137'}) {
    when(() => ocr.recognizeBlocks(any())).thenAnswer((_) async => [
          if (name.isNotEmpty)
            OcrBlock(
                text: name, left: 0.05, top: 0.05, width: 0.85, height: 0.08),
          if (setCol.isNotEmpty)
            OcrBlock(
                text: setCol, left: 0.05, top: 0.88, width: 0.45, height: 0.05),
        ]);
  }

  test('matched outcome adds to collection and returns id + price', () async {
    stubOcr();
    when(() => matcher.match(any(),
            isListCard: any(named: 'isListCard'),
            speculativeFuzzy: any(named: 'speculativeFuzzy')))
        .thenAnswer((_) async => _card());

    final res =
        await pipeline().captureFromWarpedCrop(Uint8List(4), forceFoil: false);

    expect(res.outcome, CaptureOutcome.matched);
    expect(res.card?.name, 'Lightning Bolt');
    expect(res.price, 1.80);
    expect(res.wasInsertion, isTrue);
    expect(res.collectionId, isNotNull);

    final rows = await db.select(db.collection).get();
    expect(rows, hasLength(1));
    expect(rows.single.id, res.collectionId);
  });

  test('matched outcome with forceFoil picks foil price', () async {
    stubOcr();
    when(() => matcher.match(any(),
            isListCard: any(named: 'isListCard'),
            speculativeFuzzy: any(named: 'speculativeFuzzy')))
        .thenAnswer((_) async => _card(usd: 1.80, usdFoil: 5.50));

    final res =
        await pipeline().captureFromWarpedCrop(Uint8List(4), forceFoil: true);

    expect(res.price, 5.50);
    expect(res.foil, isTrue);
  });

  test('matched outcome falls back to non-foil when foil price is null',
      () async {
    stubOcr();
    when(() => matcher.match(any(),
            isListCard: any(named: 'isListCard'),
            speculativeFuzzy: any(named: 'speculativeFuzzy')))
        .thenAnswer((_) async => _card(usd: 1.80, usdFoil: null));

    final res =
        await pipeline().captureFromWarpedCrop(Uint8List(4), forceFoil: true);

    expect(res.price, 1.80);
  });

  test('matched outcome reports wasInsertion=false on second scan', () async {
    stubOcr();
    when(() => matcher.match(any(),
            isListCard: any(named: 'isListCard'),
            speculativeFuzzy: any(named: 'speculativeFuzzy')))
        .thenAnswer((_) async => _card());

    await pipeline().captureFromWarpedCrop(Uint8List(4), forceFoil: false);
    final second =
        await pipeline().captureFromWarpedCrop(Uint8List(4), forceFoil: false);

    expect(second.wasInsertion, isFalse);
  });

  test('no-match outcome inserts nothing', () async {
    stubOcr(name: 'Gibberish', setCol: '');
    when(() => matcher.match(any(),
            isListCard: any(named: 'isListCard'),
            speculativeFuzzy: any(named: 'speculativeFuzzy')))
        .thenAnswer((_) async => null);

    final res =
        await pipeline().captureFromWarpedCrop(Uint8List(4), forceFoil: false);

    expect(res.outcome, CaptureOutcome.noMatch);
    expect(res.card, isNull);
    expect(res.collectionId, isNull);
    expect(await db.select(db.collection).get(), isEmpty);
  });

  test('offline outcome: ScryfallException becomes offline', () async {
    stubOcr();
    when(() => matcher.match(any(),
            isListCard: any(named: 'isListCard'),
            speculativeFuzzy: any(named: 'speculativeFuzzy')))
        .thenThrow(ScryfallException('network down'));

    final res =
        await pipeline().captureFromWarpedCrop(Uint8List(4), forceFoil: false);

    expect(res.outcome, CaptureOutcome.offline);
    expect(await db.select(db.collection).get(), isEmpty);
  });

  test('offline outcome: timeout beyond matchTimeout becomes offline',
      () async {
    stubOcr();
    when(() => matcher.match(any(),
            isListCard: any(named: 'isListCard'),
            speculativeFuzzy: any(named: 'speculativeFuzzy')))
        .thenAnswer((_) async {
      await Future<void>.delayed(const Duration(seconds: 8));
      return null;
    });

    final res = await pipeline()
        .captureFromWarpedCrop(Uint8List(4), forceFoil: false);

    expect(res.outcome, CaptureOutcome.offline);
  }, timeout: const Timeout(Duration(seconds: 10)));

  test('pickName prefers tallest block over widest in name band', () async {
    // Simulates the "glued mana cost + type line" failure: a wide short block
    // that would outrank a taller title block under the old width heuristic.
    when(() => ocr.recognizeBlocks(any())).thenAnswer((_) async => [
          OcrBlock(
              text: '{2}{W}{U} Legendary Creature Human Wizard',
              left: 0.05,
              top: 0.08,
              width: 0.90,
              height: 0.03),
          OcrBlock(
              text: 'Urza, Lord Protector',
              left: 0.05,
              top: 0.05,
              width: 0.60,
              height: 0.06),
          OcrBlock(
              text: 'dmu 125', left: 0.05, top: 0.88, width: 0.45, height: 0.05),
        ]);
    final captured = <ParsedOcr>[];
    when(() => matcher.match(any(),
            isListCard: any(named: 'isListCard'),
            speculativeFuzzy: any(named: 'speculativeFuzzy')))
        .thenAnswer((inv) async {
      captured.add(inv.positionalArguments.first as ParsedOcr);
      return _card();
    });

    await pipeline().captureFromWarpedCrop(Uint8List(4), forceFoil: false);

    expect(captured.single.rawName, 'Urza, Lord Protector');
  });

  test('pickName keeps multi-line name and drops mana-cost / digit lines',
      () async {
    when(() => ocr.recognizeBlocks(any())).thenAnswer((_) async => [
          // Winning block: mana cost line + two-line name.
          OcrBlock(
              text: '{2}{W}{U}\nUrza, Lord\nProtector',
              left: 0.05,
              top: 0.05,
              width: 0.60,
              height: 0.10),
          OcrBlock(
              text: 'dmu 125', left: 0.05, top: 0.88, width: 0.45, height: 0.05),
        ]);
    final captured = <ParsedOcr>[];
    when(() => matcher.match(any(),
            isListCard: any(named: 'isListCard'),
            speculativeFuzzy: any(named: 'speculativeFuzzy')))
        .thenAnswer((inv) async {
      captured.add(inv.positionalArguments.first as ParsedOcr);
      return _card();
    });

    await pipeline().captureFromWarpedCrop(Uint8List(4), forceFoil: false);

    expect(captured.single.rawName, 'Urza, Lord Protector');
  });

  test('orientation: retries multiple rotations when initial pass finds no name',
      () async {
    // Calls 1 and 2 return a mid-card block — picker always returns empty.
    // Today's code makes one 180° retry (call 2), then gives up with empty
    // name. Under the new multi-angle loop, call 3 (next rotation) returns
    // an upright top-band block and the picker finds the name.
    var call = 0;
    when(() => ocr.recognizeBlocks(any())).thenAnswer((_) async {
      call++;
      if (call <= 2) {
        return [
          OcrBlock(
              text: 'mid-card noise',
              left: 0.10,
              top: 0.50,
              width: 0.60,
              height: 0.04),
        ];
      }
      return [
        OcrBlock(
            text: 'Lightning Bolt',
            left: 0.05,
            top: 0.05,
            width: 0.60,
            height: 0.06),
        OcrBlock(
            text: '2xm 137',
            left: 0.05,
            top: 0.88,
            width: 0.45,
            height: 0.05),
      ];
    });
    final captured = <ParsedOcr>[];
    when(() => matcher.match(any(),
            isListCard: any(named: 'isListCard'),
            speculativeFuzzy: any(named: 'speculativeFuzzy')))
        .thenAnswer((inv) async {
      captured.add(inv.positionalArguments.first as ParsedOcr);
      return _card();
    });

    // Encode a real PNG from the `image` package so decodeImage + copyRotate
    // roundtrip cleanly regardless of platform.
    final tinyImg = img.Image(width: 64, height: 64);
    final tinyPng = Uint8List.fromList(img.encodePng(tinyImg));

    await pipeline().captureFromWarpedCrop(tinyPng, forceFoil: false);

    expect(call, greaterThanOrEqualTo(3),
        reason:
            'new code must make at least 3 OCR calls (original + 2 rotations) '
            'before the upright blocks at call 3 are accepted');
    expect(captured.single.rawName, 'Lightning Bolt');
  });

  test('pipeline pre-starts a speculative fuzzy query when setCode or cn is missing',
      () async {
    // Name-only OCR — no cn/set strip detected. Path 1 / path 2 in matcher
    // can't fire, so the overlap win from speculation is real.
    when(() => ocr.recognizeBlocks(any())).thenAnswer((_) async => [
          OcrBlock(
              text: 'Lightning Bolt',
              left: 0.05,
              top: 0.05,
              width: 0.60,
              height: 0.06),
        ]);

    Future<ScryfallCard?>? capturedSpeculative;
    when(() => matcher.match(any(),
        isListCard: any(named: 'isListCard'),
        speculativeFuzzy: any(named: 'speculativeFuzzy'))).thenAnswer((inv) {
      capturedSpeculative =
          inv.namedArguments[#speculativeFuzzy] as Future<ScryfallCard?>?;
      return Future.value(_card());
    });

    await pipeline().captureFromWarpedCrop(Uint8List(4), forceFoil: false);

    expect(capturedSpeculative, isNotNull,
        reason:
            'pipeline should pass a speculative fuzzy future to the matcher '
            'when OCR lacks setCode/cn (path 3 fuzzy will be the primary '
            'resolver)');
  });

  test('pipeline skips speculative fuzzy when setCode AND cn are both present',
      () async {
    // With all three signals (name + setCode + cn), path 1 in the matcher is
    // likely to short-circuit at score >= 0.95 — the speculative query would
    // fire an unused extra Scryfall request. Gate on signal completeness.
    when(() => ocr.recognizeBlocks(any())).thenAnswer((_) async => [
          OcrBlock(
              text: 'Lightning Bolt',
              left: 0.05,
              top: 0.05,
              width: 0.60,
              height: 0.06),
          OcrBlock(
              text: '2xm 137',
              left: 0.05,
              top: 0.90,
              width: 0.45,
              height: 0.05),
        ]);

    Future<ScryfallCard?>? capturedSpeculative = Future.value(_card());
    when(() => matcher.match(any(),
        isListCard: any(named: 'isListCard'),
        speculativeFuzzy: any(named: 'speculativeFuzzy'))).thenAnswer((inv) {
      capturedSpeculative =
          inv.namedArguments[#speculativeFuzzy] as Future<ScryfallCard?>?;
      return Future.value(_card());
    });

    await pipeline().captureFromWarpedCrop(Uint8List(4), forceFoil: false);

    expect(capturedSpeculative, isNull,
        reason:
            'speculative fuzzy should not fire when setCode + cn are both '
            'present; matcher path 1 will likely short-circuit and the '
            'speculative HTTP call would be wasted');
    verifyNever(() => scry.cardByFuzzyName(any()));
  });

  test('pickName tiebreaks near-equal heights by proximity to left edge',
      () async {
    when(() => ocr.recognizeBlocks(any())).thenAnswer((_) async => [
          // Right-side block first — same height as the left one, should lose.
          OcrBlock(
              text: 'Flavor Banner',
              left: 0.50,
              top: 0.05,
              width: 0.45,
              height: 0.062),
          OcrBlock(
              text: 'Lightning Bolt',
              left: 0.05,
              top: 0.05,
              width: 0.45,
              height: 0.060),
          OcrBlock(
              text: '2xm 137', left: 0.05, top: 0.88, width: 0.45, height: 0.05),
        ]);
    final captured = <ParsedOcr>[];
    when(() => matcher.match(any(),
            isListCard: any(named: 'isListCard'),
            speculativeFuzzy: any(named: 'speculativeFuzzy')))
        .thenAnswer((inv) async {
      captured.add(inv.positionalArguments.first as ParsedOcr);
      return _card();
    });

    await pipeline().captureFromWarpedCrop(Uint8List(4), forceFoil: false);

    expect(captured.single.rawName, 'Lightning Bolt');
  });
}

