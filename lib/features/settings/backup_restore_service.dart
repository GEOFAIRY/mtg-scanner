import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../data/db/database.dart';

class BackupRestoreService {
  BackupRestoreService(this._db);
  final AppDatabase _db;

  Future<File> exportJson() async {
    final rows = await _db.select(_db.collection).get();
    final json = rows
        .map((r) => {
              'scryfall_id': r.scryfallId,
              'name': r.name,
              'set_code': r.setCode,
              'collector_number': r.collectorNumber,
              'count': r.count,
              'foil': r.foil,
              'condition': r.condition,
              'language': r.language,
              'added_at': r.addedAt.toIso8601String(),
              'price_usd': r.priceUsd,
              'price_usd_foil': r.priceUsdFoil,
              'price_updated_at': r.priceUpdatedAt?.toIso8601String(),
              'notes': r.notes,
            })
        .toList();
    final dir = await getApplicationDocumentsDirectory();
    final f = File(p.join(dir.path,
        'mtg-collection-${DateTime.now().toIso8601String().split('T').first}.json'));
    await f.writeAsString(jsonEncode({'version': 1, 'cards': json}));
    return f;
  }
}

