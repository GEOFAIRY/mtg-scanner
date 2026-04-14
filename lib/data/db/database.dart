import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'daos/collection_dao.dart';
import 'daos/scans_dao.dart';
import 'tables.dart';

part 'database.g.dart';

@DriftDatabase(tables: [Scans, Collection], daos: [CollectionDao, ScansDao])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_open());
  AppDatabase.forTesting(QueryExecutor e) : super(e);

  @override
  int get schemaVersion => 1;
}

LazyDatabase _open() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'mtg_scanner.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
