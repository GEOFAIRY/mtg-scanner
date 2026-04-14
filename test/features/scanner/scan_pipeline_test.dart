import 'dart:io';
import 'dart:typed_data';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mtg_scanner/data/db/database.dart';
import 'package:mtg_scanner/features/scanner/ocr_runner.dart';
import 'package:mtg_scanner/features/scanner/parsed_ocr.dart';
import 'package:mtg_scanner/features/scanner/scan_matcher.dart';
import 'package:mtg_scanner/features/scanner/scan_pipeline.dart';
import 'package:mtg_scanner/features/scanner/scan_writer.dart';
import 'package:mtg_scanner/features/scanner/thumbnail_storage.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

class _FakeOcr extends Mock implements OcrRunner {}

class _FakeMatcher extends Mock implements ScanMatcher {}

class _FakePathProvider extends PathProviderPlatform {
  _FakePathProvider(this.dir);
  final String dir;
  @override
  Future<String?> getApplicationDocumentsPath() async => dir;
}

void main() {
  late AppDatabase db;
  late _FakeOcr ocr;
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('pipeline_');
    PathProviderPlatform.instance = _FakePathProvider(tempDir.path);
    db = AppDatabase.forTesting(NativeDatabase.memory());
    ocr = _FakeOcr();
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

  test('captureFromWarpedCrop writes a pending scan row with thumbnail', () async {
    when(() => ocr.recognizeRegion(any(), any())).thenAnswer((inv) async {
      final region = inv.positionalArguments[1] as OcrRegion;
      return region.top < 0.5 ? 'Lightning Bolt' : '2xm 137';
    });

    final matcher = _FakeMatcher();
    when(() => matcher.matchAfterInsert(
            scanId: any(named: 'scanId'), parsed: any(named: 'parsed')))
        .thenAnswer((_) async {});

    final pipeline = ScanPipeline(
      ocr: ocr,
      writer: ScanWriter(db),
      storage: ThumbnailStorage(),
      matcher: matcher,
    );

    final fakePng = Uint8List.fromList(List.filled(32, 0x89));
    final res = await pipeline.captureFromWarpedCrop(fakePng);

    final row = await (db.select(db.scans)..where((t) => t.id.equals(res.id)))
        .getSingle();
    expect(res.label, 'Lightning Bolt');
    expect(row.rawName, 'Lightning Bolt');
    expect(row.rawSetCollector, '2xm 137');
    expect(row.status, 'pending');
    expect(row.cropImagePath, isNotNull);
    expect(File(row.cropImagePath!).existsSync(), isTrue);

    await Future<void>.delayed(Duration.zero);
    verify(() => matcher.matchAfterInsert(
        scanId: res.id, parsed: any(named: 'parsed'))).called(1);
  });
}
