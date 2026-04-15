import 'dart:io';
import 'dart:typed_data';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mtg_scanner/data/db/database.dart';
import 'package:mtg_scanner/data/repositories/collection_repository.dart';
import 'package:mtg_scanner/data/scryfall/scryfall_client.dart';
import 'package:mtg_scanner/data/scryfall/scryfall_models.dart';
import 'package:mtg_scanner/features/scanner/ocr_runner.dart';
import 'package:mtg_scanner/features/scanner/parsed_ocr.dart';
import 'package:mtg_scanner/features/scanner/scan_matcher.dart';
import 'package:mtg_scanner/features/scanner/scan_pipeline.dart';
import 'package:mtg_scanner/features/scanner/scan_writer.dart';
import 'package:mtg_scanner/features/scanner/thumbnail_storage.dart';
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
      collectorNumber: '137',
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
    registerFallbackValue(
        const OcrRegion(left: 0, top: 0, width: 1, height: 1));
    registerFallbackValue(Uint8List(0));
    registerFallbackValue(
        ParsedOcr.from(rawName: '', rawSetCollector: ''));
  });
  tearDown(() async {
    await db.close();
    await tempDir.delete(recursive: true);
  });

  ScanPipeline _pipeline() => ScanPipeline(
        ocr: ocr,
        writer: ScanWriter(db),
        storage: ThumbnailStorage(),
        matcher: matcher,
        collection: collection,
      );

  void _stubOcr({String name = 'Lightning Bolt', String setCol = '2xm 137'}) {
    when(() => ocr.recognizeRegion(any(), any())).thenAnswer((inv) async {
      final region = inv.positionalArguments[1] as OcrRegion;
      return region.top < 0.5 ? name : setCol;
    });
  }

  test('matched outcome inserts scan, auto-confirms, returns price (non-foil)',
      () async {
    _stubOcr();
    when(() => matcher.match(any()))
        .thenAnswer((_) async => MatchResult(_card(), 1.0));

    final res =
        await _pipeline().captureFromWarpedCrop(Uint8List(4), forceFoil: false);

    expect(res.outcome, CaptureOutcome.matched);
    expect(res.matchedName, 'Lightning Bolt');
    expect(res.price, 1.80);
    final rows = await db.select(db.scans).get();
    expect(rows, hasLength(1));
    expect(rows.single.status, 'confirmed');
    expect(rows.single.matchedName, 'Lightning Bolt');
    expect(rows.single.priceUsd, 1.80);
    final coll = await db.select(db.collection).get();
    expect(coll, hasLength(1));
  });

  test('matched outcome picks foil price when forceFoil is true', () async {
    _stubOcr();
    when(() => matcher.match(any())).thenAnswer(
        (_) async => MatchResult(_card(usd: 1.80, usdFoil: 5.50), 1.0));

    final res =
        await _pipeline().captureFromWarpedCrop(Uint8List(4), forceFoil: true);

    expect(res.price, 5.50);
  });

  test('matched outcome falls back to non-foil when foil price is null',
      () async {
    _stubOcr();
    when(() => matcher.match(any())).thenAnswer(
        (_) async => MatchResult(_card(usd: 1.80, usdFoil: null), 1.0));

    final res =
        await _pipeline().captureFromWarpedCrop(Uint8List(4), forceFoil: true);

    expect(res.price, 1.80);
  });

  test('low-confidence match inserts but does not auto-confirm', () async {
    _stubOcr();
    when(() => matcher.match(any()))
        .thenAnswer((_) async => MatchResult(_card(), 0.6));

    final res =
        await _pipeline().captureFromWarpedCrop(Uint8List(4), forceFoil: false);

    expect(res.outcome, CaptureOutcome.matched);
    final rows = await db.select(db.scans).get();
    expect(rows.single.status, 'pending');
    final coll = await db.select(db.collection).get();
    expect(coll, isEmpty);
  });

  test('no-match outcome: matcher returns null, nothing inserted', () async {
    _stubOcr(name: 'Gibberish', setCol: '');
    when(() => matcher.match(any())).thenAnswer((_) async => null);

    final res =
        await _pipeline().captureFromWarpedCrop(Uint8List(4), forceFoil: false);

    expect(res.outcome, CaptureOutcome.noMatch);
    expect(res.price, isNull);
    final rows = await db.select(db.scans).get();
    expect(rows, isEmpty);
  });

  test('offline outcome: ScryfallException becomes offline, nothing inserted',
      () async {
    _stubOcr();
    when(() => matcher.match(any()))
        .thenThrow(ScryfallException('network down'));

    final res =
        await _pipeline().captureFromWarpedCrop(Uint8List(4), forceFoil: false);

    expect(res.outcome, CaptureOutcome.offline);
    final rows = await db.select(db.scans).get();
    expect(rows, isEmpty);
  });

  test('offline outcome: timeout beyond 4s becomes offline', () async {
    _stubOcr();
    when(() => matcher.match(any())).thenAnswer((_) async {
      await Future<void>.delayed(const Duration(seconds: 5));
      return null;
    });

    final res = await _pipeline()
        .captureFromWarpedCrop(Uint8List(4), forceFoil: false);

    expect(res.outcome, CaptureOutcome.offline);
    final rows = await db.select(db.scans).get();
    expect(rows, isEmpty);
  }, timeout: const Timeout(Duration(seconds: 10)));
}
