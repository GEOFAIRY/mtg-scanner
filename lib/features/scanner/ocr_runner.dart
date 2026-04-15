import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// A single recognized text block with its bounding box in normalized card
/// coordinates (0..1 of the input image width/height).
class OcrBlock {
  const OcrBlock({
    required this.text,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });
  final String text;
  final double left, top, width, height;

  double get right => left + width;
  double get bottom => top + height;
  double get area => width * height;
}

abstract class OcrRunner {
  /// Recognize every text block in [imageBytes] (an upright card PNG).
  /// Returns blocks with bounding boxes normalized to the image dimensions.
  Future<List<OcrBlock>> recognizeBlocks(Uint8List imageBytes);
  Future<void> dispose();
}

class MlKitOcrRunner implements OcrRunner {
  final TextRecognizer _recognizer =
      TextRecognizer(script: TextRecognitionScript.latin);

  @override
  Future<List<OcrBlock>> recognizeBlocks(Uint8List imageBytes) async {
    final decoded = img.decodeImage(imageBytes);
    if (decoded == null) return const [];

    // Full-art, showcase, and retro-frame cards render text over low-contrast
    // or textured backgrounds. Grayscale + normalize + contrast boost makes
    // the text far more legible to ML Kit.
    var pp = img.grayscale(decoded);
    pp = img.normalize(pp, min: 0, max: 255);
    pp = img.contrast(pp, contrast: 140);
    final pngBytes = img.encodePng(pp);

    final temp = File(
        '${Directory.systemTemp.path}/ocr_${DateTime.now().microsecondsSinceEpoch}.png');
    await temp.writeAsBytes(pngBytes);
    try {
      final input = InputImage.fromFilePath(temp.path);
      final result = await _recognizer.processImage(input);
      final w = decoded.width.toDouble();
      final h = decoded.height.toDouble();
      if (w <= 0 || h <= 0) return const [];
      return [
        for (final b in result.blocks)
          OcrBlock(
            text: b.text,
            left: b.boundingBox.left / w,
            top: b.boundingBox.top / h,
            width: b.boundingBox.width / w,
            height: b.boundingBox.height / h,
          ),
      ];
    } finally {
      if (await temp.exists()) await temp.delete();
    }
  }

  @override
  Future<void> dispose() => _recognizer.close();
}
