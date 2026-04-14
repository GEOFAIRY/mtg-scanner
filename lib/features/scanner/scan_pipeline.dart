import 'dart:typed_data';
import 'ocr_runner.dart';
import 'parsed_ocr.dart';
import 'scan_writer.dart';
import 'thumbnail_storage.dart';

class ScanPipeline {
  ScanPipeline({
    required this.ocr,
    required this.writer,
    required this.storage,
  });
  final OcrRunner ocr;
  final ScanWriter writer;
  final ThumbnailStorage storage;

  static const _nameRegion =
      OcrRegion(left: 0.04, top: 0.03, width: 0.70, height: 0.08);
  static const _setRegion =
      OcrRegion(left: 0.04, top: 0.92, width: 0.40, height: 0.05);

  /// Caller supplies an upright card PNG (already perspective-corrected).
  /// Persists a pending scan row and returns its id plus a display label.
  Future<({int id, String label})> captureFromWarpedCrop(
      Uint8List uprightPng) async {
    final rawName = await ocr.recognizeRegion(uprightPng, _nameRegion);
    final rawSet = await ocr.recognizeRegion(uprightPng, _setRegion);
    final parsed =
        ParsedOcr.from(rawName: rawName, rawSetCollector: rawSet);
    final thumbPath = await storage.save(uprightPng);
    final id = await writer.insertPending(parsed: parsed, thumbPath: thumbPath);
    final label = parsed.name.isNotEmpty ? parsed.name : 'scan';
    return (id: id, label: label);
  }
}
