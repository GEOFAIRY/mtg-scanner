import 'package:drift/drift.dart';
import '../../data/db/database.dart';
import 'parsed_ocr.dart';

class ScanWriter {
  ScanWriter(this._db);
  final AppDatabase _db;

  /// Inserts a pending scan row. Returns the new row id.
  Future<int> insertPending({
    required ParsedOcr parsed,
    required String thumbPath,
  }) {
    return _db.into(_db.scans).insert(ScansCompanion.insert(
          capturedAt: DateTime.now(),
          rawName: parsed.rawName,
          rawSetCollector: parsed.rawSetCollector,
          confidence: const Value(0.0),
          foilGuess: const Value(-1),
          cropImagePath: Value(thumbPath),
        ));
  }
}
