import 'dart:io';
import 'dart:typed_data';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mtg_card_scanner/data/db/database.dart';
import 'package:mtg_card_scanner/data/repositories/collection_repository.dart';
import 'package:mtg_card_scanner/data/scryfall/scryfall_client.dart';
import 'package:mtg_card_scanner/data/scryfall/scryfall_models.dart';
import 'package:mtg_card_scanner/features/scanner/ocr_runner.dart';
import 'package:mtg_card_scanner/features/scanner/parsed_ocr.dart';
import 'package:mtg_card_scanner/features/scanner/scan_matcher.dart';
import 'package:mtg_card_scanner/features/scanner/scan_pipeline.dart';
import 'package:mtg_card_scanner/features/scanner/thumbnail_storage.dart';
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
  });
  tearDown(() async {
    await db.close();
    await tempDir.delete(recursive: true);
  });

  ScanPipeline pipeline() => ScanPipeline(
        ocr: ocr,
        storage: ThumbnailStorage(),
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
    when(() => matcher.match(any())).thenAnswer((_) async => _card());

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
    when(() => matcher.match(any())).thenAnswer(
        (_) async => _card(usd: 1.80, usdFoil: 5.50));

    final res =
        await pipeline().captureFromWarpedCrop(Uint8List(4), forceFoil: true);

    expect(res.price, 5.50);
    expect(res.foil, isTrue);
  });

  test('matched outcome falls back to non-foil when foil price is null',
      () async {
    stubOcr();
    when(() => matcher.match(any())).thenAnswer(
        (_) async => _card(usd: 1.80, usdFoil: null));

    final res =
        await pipeline().captureFromWarpedCrop(Uint8List(4), forceFoil: true);

    expect(res.price, 1.80);
  });

  test('matched outcome reports wasInsertion=false on second scan', () async {
    stubOcr();
    when(() => matcher.match(any())).thenAnswer((_) async => _card());

    await pipeline().captureFromWarpedCrop(Uint8List(4), forceFoil: false);
    final second =
        await pipeline().captureFromWarpedCrop(Uint8List(4), forceFoil: false);

    expect(second.wasInsertion, isFalse);
  });

  test('no-match outcome inserts nothing', () async {
    stubOcr(name: 'Gibberish', setCol: '');
    when(() => matcher.match(any())).thenAnswer((_) async => null);

    final res =
        await pipeline().captureFromWarpedCrop(Uint8List(4), forceFoil: false);

    expect(res.outcome, CaptureOutcome.noMatch);
    expect(res.card, isNull);
    expect(res.collectionId, isNull);
    expect(await db.select(db.collection).get(), isEmpty);
  });

  test('offline outcome: ScryfallException becomes offline', () async {
    stubOcr();
    when(() => matcher.match(any()))
        .thenThrow(ScryfallException('network down'));

    final res =
        await pipeline().captureFromWarpedCrop(Uint8List(4), forceFoil: false);

    expect(res.outcome, CaptureOutcome.offline);
    expect(await db.select(db.collection).get(), isEmpty);
  });

  test('offline outcome: timeout beyond 4s becomes offline', () async {
    stubOcr();
    when(() => matcher.match(any())).thenAnswer((_) async {
      await Future<void>.delayed(const Duration(seconds: 5));
      return null;
    });

    final res = await pipeline()
        .captureFromWarpedCrop(Uint8List(4), forceFoil: false);

    expect(res.outcome, CaptureOutcome.offline);
  }, timeout: const Timeout(Duration(seconds: 10)));
}

