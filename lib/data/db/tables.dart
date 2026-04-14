import 'package:drift/drift.dart';

class Scans extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get capturedAt => dateTime()();
  TextColumn get rawName => text()();
  TextColumn get rawSetCollector => text()();
  TextColumn get matchedScryfallId => text().nullable()();
  TextColumn get matchedName => text().nullable()();
  TextColumn get matchedSet => text().nullable()();
  TextColumn get matchedCollectorNumber => text().nullable()();
  RealColumn get confidence => real().withDefault(const Constant(0))();
  IntColumn get foilGuess => integer().withDefault(const Constant(-1))();
  TextColumn get cropImagePath => text().nullable()();
  RealColumn get priceUsd => real().nullable()();
  RealColumn get priceUsdFoil => real().nullable()();
  TextColumn get status =>
      text().withDefault(const Constant('pending'))();
}

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
}
