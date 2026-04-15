import 'package:drift/drift.dart';
import '../../data/db/database.dart';
import 'parsed_ocr.dart';

class ScanWriter {
  ScanWriter(this._db);
  final AppDatabase _db;

  Future<int> insertPending({
    required ParsedOcr parsed,
    required String thumbPath,
    required int foilGuess,
  }) {
    return _db.into(_db.scans).insert(ScansCompanion.insert(
          capturedAt: DateTime.now(),
          rawName: parsed.rawName,
          rawSetCollector: parsed.rawSetCollector,
          confidence: const Value(0.0),
          foilGuess: Value(foilGuess),
          cropImagePath: Value(thumbPath),
        ));
  }
}
