// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scans_dao.dart';

// ignore_for_file: type=lint
mixin _$ScansDaoMixin on DatabaseAccessor<AppDatabase> {
  $ScansTable get scans => attachedDatabase.scans;
  ScansDaoManager get managers => ScansDaoManager(this);
}

class ScansDaoManager {
  final _$ScansDaoMixin _db;
  ScansDaoManager(this._db);
  $$ScansTableTableManager get scans =>
      $$ScansTableTableManager(_db.attachedDatabase, _db.scans);
}
