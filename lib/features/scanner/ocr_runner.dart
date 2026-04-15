import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Region of interest, expressed in normalized card coordinates (0..1).
class OcrRegion {
  const OcrRegion({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });
  final double left, top, width, height;
}

abstract class OcrRunner {
  /// Crops [imageBytes] (upright card PNG) to [region] and returns the
  /// recognized text. Returns '' on failure.
  Future<String> recognizeRegion(Uint8List imageBytes, OcrRegion region);
  Future<void> dispose();
}

class MlKitOcrRunner implements OcrRunner {
  final TextRecognizer _recognizer =
      TextRecognizer(script: TextRecognitionScript.latin);

  @override
  Future<String> recognizeRegion(Uint8List imageBytes, OcrRegion region) async {
    final decoded = img.decodeImage(imageBytes);
    if (decoded == null) return '';
    final x = (region.left * decoded.width).round();
    final y = (region.top * decoded.height).round();
    final w = (region.width * decoded.width).round();
    final h = (region.height * decoded.height).round();
    final crop = img.copyCrop(decoded, x: x, y: y, width: w, height: h);
    final pngBytes = img.encodePng(crop);
    final temp = File(
        '${Directory.systemTemp.path}/ocr_${DateTime.now().microsecondsSinceEpoch}.png');
    await temp.writeAsBytes(pngBytes);
    try {
      final input = InputImage.fromFilePath(temp.path);
      final result = await _recognizer.processImage(input);
      return result.blocks.map((b) => b.text).join(' ').trim();
    } finally {
      if (await temp.exists()) await temp.delete();
    }
  }

  @override
  Future<void> dispose() => _recognizer.close();
}

