import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart';
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

  Future<int> importJson(String jsonText) async {
    final data = jsonDecode(jsonText) as Map<String, dynamic>;
    final cards = (data['cards'] as List).cast<Map<String, dynamic>>();
    var imported = 0;
    for (final c in cards) {
      await _db.into(_db.collection).insert(CollectionCompanion.insert(
            scryfallId: c['scryfall_id'] as String,
            name: c['name'] as String,
            setCode: c['set_code'] as String,
            collectorNumber: c['collector_number'] as String,
            count: Value(c['count'] as int),
            foil: Value(c['foil'] as int),
            condition: Value(c['condition'] as String),
            language: Value(c['language'] as String),
            addedAt: DateTime.parse(c['added_at'] as String),
            priceUsd: Value(c['price_usd'] as double?),
            priceUsdFoil: Value(c['price_usd_foil'] as double?),
            priceUpdatedAt: Value(c['price_updated_at'] == null
                ? null
                : DateTime.parse(c['price_updated_at'] as String)),
            notes: Value(c['notes'] as String?),
          ));
      imported++;
    }
    return imported;
  }
}
