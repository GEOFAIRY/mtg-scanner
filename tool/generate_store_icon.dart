// Downsize the 1024x1024 app icon to 512x512 for the Play Store listing.
// Run: dart run tool/generate_store_icon.dart

import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final src = img.decodeImage(File('assets/icon/app_icon.png').readAsBytesSync());
  if (src == null) {
    stderr.writeln('Failed to read assets/icon/app_icon.png');
    exit(1);
  }
  final resized = img.copyResize(src,
      width: 512, height: 512, interpolation: img.Interpolation.cubic);
  File('assets/store/store_icon.png')
    ..createSync(recursive: true)
    ..writeAsBytesSync(img.encodePng(resized));
  stdout.writeln('Wrote assets/store/store_icon.png (512x512)');
}
