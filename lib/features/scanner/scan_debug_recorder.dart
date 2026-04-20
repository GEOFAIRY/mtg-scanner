import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../../data/scryfall/scryfall_models.dart';
import 'ocr_runner.dart';
import 'parsed_ocr.dart';

/// Writes one `<ts>.png` + `<ts>.json` pair per capture into the app's
/// external files dir. Intended to be pulled off-device via `adb pull` to
/// diagnose scan failures where the overlay alone isn't enough (warp crop
/// wrong, OCR grabbing oddly, matcher snapping to the wrong printing).
///
/// Gated by [AppSettings.debugOverlayEnabled] at the call site — this class
/// writes unconditionally when invoked.
class ScanDebugRecorder {
  ScanDebugRecorder({this.maxRecent = 20});

  final int maxRecent;

  Future<void> record({
    required Uint8List uprightPng,
    required List<OcrBlock> blocks,
    required ParsedOcr parsed,
    required ScryfallCard? matched,
  }) async {
    try {
      final dir = await getExternalStorageDirectory();
      if (dir == null) return;
      final debugDir = Directory('${dir.path}/scan_debug');
      if (!debugDir.existsSync()) debugDir.createSync(recursive: true);
      final ts = DateTime.now()
          .toUtc()
          .toIso8601String()
          .replaceAll(':', '-')
          .replaceAll('.', '-');
      await File('${debugDir.path}/$ts.png').writeAsBytes(uprightPng);
      final meta = <String, Object?>{
        'timestamp': ts,
        'parsed': {
          'name': parsed.name,
          'rawName': parsed.rawName,
          'setCode': parsed.setCode,
          'primaryCn': parsed.collectorNumber,
          'cnCandidates': parsed.collectorNumberCandidates,
        },
        'match': matched == null
            ? null
            : {
                'name': matched.name,
                'set': matched.set,
                'collectorNumber': matched.collectorNumber,
              },
        'blocks': [
          for (final b in blocks)
            {
              'text': b.text,
              'left': b.left,
              'top': b.top,
              'width': b.width,
              'height': b.height,
            },
        ],
      };
      await File('${debugDir.path}/$ts.json')
          .writeAsString(const JsonEncoder.withIndent('  ').convert(meta));
      _prune(debugDir);
      if (kDebugMode) {
        debugPrint('[scan_debug] $ts name="${parsed.name}" '
            'set=${parsed.setCode} cns=${parsed.collectorNumberCandidates} '
            'match=${matched == null ? "null" : "${matched.name} ${matched.set}/${matched.collectorNumber}"}');
      }
    } catch (e, s) {
      if (kDebugMode) debugPrint('[scan_debug] record failed: $e\n$s');
    }
  }

  void _prune(Directory dir) {
    try {
      final pngs = dir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.png'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));
      while (pngs.length > maxRecent) {
        final old = pngs.removeAt(0);
        try {
          old.deleteSync();
        } catch (_) {}
        final jsonPath =
            '${old.path.substring(0, old.path.length - 4)}.json';
        try {
          File(jsonPath).deleteSync();
        } catch (_) {}
      }
    } catch (_) {}
  }
}
