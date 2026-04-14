import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ThumbnailStorage {
  Future<String> save(List<int> bytes) async {
    final dir = await getApplicationDocumentsDirectory();
    final subdir = Directory(p.join(dir.path, 'scan_thumbs'));
    if (!subdir.existsSync()) subdir.createSync(recursive: true);
    final name = 'scan_${DateTime.now().microsecondsSinceEpoch}.png';
    final file = File(p.join(subdir.path, name));
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  Future<void> delete(String path) async {
    final f = File(path);
    if (await f.exists()) await f.delete();
  }
}
