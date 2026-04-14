import 'dart:async';
import 'dart:typed_data';
import 'ocr_runner.dart';
import 'parsed_ocr.dart';
import 'scan_matcher.dart';
import 'scan_writer.dart';
import 'thumbnail_storage.dart';

class ScanPipeline {
  ScanPipeline({
    required this.ocr,
    required this.writer,
    required this.storage,
    required this.matcher,
  });
  final OcrRunner ocr;
  final ScanWriter writer;
  final ThumbnailStorage storage;
  final ScanMatcher matcher;

  static const _nameRegion =
      OcrRegion(left: 0.02, top: 0.02, width: 0.96, height: 0.14);
  static const _setRegion =
      OcrRegion(left: 0.02, top: 0.86, width: 0.60, height: 0.12);

  Future<({int id, String label})> captureFromWarpedCrop(
      Uint8List uprightPng) async {
    final rawName = await ocr.recognizeRegion(uprightPng, _nameRegion);
    final rawSet = await ocr.recognizeRegion(uprightPng, _setRegion);
    final parsed =
        ParsedOcr.from(rawName: rawName, rawSetCollector: rawSet);
    final thumbPath = await storage.save(uprightPng);
    final id = await writer.insertPending(parsed: parsed, thumbPath: thumbPath);
    // Fire-and-forget so the scanner loop isn't blocked by Scryfall latency.
    unawaited(matcher.matchAfterInsert(scanId: id, parsed: parsed));
    final label = parsed.name.isNotEmpty ? parsed.name : 'scan';
    return (id: id, label: label);
  }
}
