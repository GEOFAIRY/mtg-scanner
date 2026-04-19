import 'package:drift/drift.dart';

class Collection extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get scryfallId => text()();
  TextColumn get name => text()();
  TextColumn get setCode => text()();
  TextColumn get collectorNumber => text()();
  IntColumn get count => integer().withDefault(const Constant(1))();
  IntColumn get foil => integer().withDefault(const Constant(0))();
  TextColumn get condition => text().withDefault(const Constant('NM'))();
  TextColumn get language => text().withDefault(const Constant('en'))();
  DateTimeColumn get addedAt => dateTime()();
  RealColumn get priceUsd => real().nullable()();
  RealColumn get priceUsdFoil => real().nullable()();
  DateTimeColumn get priceUpdatedAt => dateTime().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get rarity => text().nullable()();
  TextColumn get imageSmall => text().nullable()();
}

