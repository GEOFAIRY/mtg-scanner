import 'package:drift/native.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:mtg_scanner/data/db/database.dart';
import 'package:mtg_scanner/data/repositories/collection_repository.dart';
import 'package:mtg_scanner/data/repositories/scans_repository.dart';
import 'package:mtg_scanner/data/scryfall/scryfall_client.dart';
import 'package:mtg_scanner/features/review_queue/review_queue_screen.dart';

class _Http extends Mock implements http.Client {}

void main() {
  late AppDatabase db;
  late CollectionRepository collection;
  late ScansRepository scansRepo;
  late ScryfallClient scry;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    scry = ScryfallClient(_Http(), minGap: Duration.zero);
    collection = CollectionRepository(db, scry);
    scansRepo = ScansRepository(db);
    await db.into(db.scans).insert(ScansCompanion.insert(
          capturedAt: DateTime(2026, 4, 14),
          rawName: 'Lightning Bolt',
          rawSetCollector: '2xm 137',
          matchedScryfallId: const Value('sid-1'),
          matchedName: const Value('Lightning Bolt'),
          matchedSet: const Value('2xm'),
          matchedCollectorNumber: const Value('137'),
          confidence: const Value(0.95),
          foilGuess: const Value(0),
          priceUsd: const Value(1.80),
        ));
  });
  tearDown(() => db.close());

  testWidgets('confirm moves scan from queue to collection', (t) async {
    await t.pumpWidget(MaterialApp(
        home: ReviewQueueScreen(
            scans: scansRepo, collection: collection, scry: scry)));
    for (var i = 0; i < 10; i++) {
      await t.pump(const Duration(milliseconds: 50));
    }
    expect(find.text('Lightning Bolt'), findsOneWidget);
    await t.tap(find.text('Confirm'));
    for (var i = 0; i < 20; i++) {
      await t.pump(const Duration(milliseconds: 50));
    }
    expect(find.text('Nothing to review'), findsOneWidget);
    final inCollection = await db.select(db.collection).get();
    expect(inCollection, hasLength(1));
    expect(inCollection.single.name, 'Lightning Bolt');
    // Dispose StreamBuilder before DB tearDown so drift's cancellation
    // Timer fires inside the test zone.
    await t.pumpWidget(const SizedBox.shrink());
    await t.pump(const Duration(milliseconds: 100));
  });
}
