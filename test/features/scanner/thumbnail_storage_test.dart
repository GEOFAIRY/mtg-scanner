import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mtg_card_scanner/features/scanner/thumbnail_storage.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:path/path.dart' as p;

class _FakePathProvider extends PathProviderPlatform {
  _FakePathProvider(this.dir);
  final String dir;
  @override
  Future<String?> getApplicationDocumentsPath() async => dir;
}

void main() {
  late Directory tempDir;
  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('thumb_test_');
    PathProviderPlatform.instance = _FakePathProvider(tempDir.path);
  });
  tearDown(() async => tempDir.delete(recursive: true));

  test('save writes bytes and returns a path under docs dir', () async {
    final storage = ThumbnailStorage();
    final path = await storage.save(List.filled(16, 0x42));
    expect(File(path).existsSync(), isTrue);
    expect(p.isWithin(tempDir.path, path), isTrue);
    expect(await File(path).length(), 16);
  });

  test('delete removes the file and is idempotent', () async {
    final storage = ThumbnailStorage();
    final path = await storage.save([1, 2, 3]);
    await storage.delete(path);
    expect(File(path).existsSync(), isFalse);
    await storage.delete(path); // no throw
  });
}

