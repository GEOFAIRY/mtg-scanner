import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'daos/collection_dao.dart';
import 'tables.dart';

part 'database.g.dart';

@DriftDatabase(tables: [Collection], daos: [CollectionDao])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_open());
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await customStatement('DROP TABLE IF EXISTS scans');
            await m.addColumn(collection, collection.rarity);
          }
          if (from < 3) {
            await m.addColumn(collection, collection.imageSmall);
          }
        },
      );
}

LazyDatabase _open() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'mtg_scanner.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}

