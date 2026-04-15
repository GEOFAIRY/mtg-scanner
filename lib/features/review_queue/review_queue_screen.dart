import 'package:flutter/material.dart';
import 'package:drift/drift.dart' as d;
import '../../data/db/database.dart';
import '../../data/repositories/collection_repository.dart';
import '../../data/repositories/scans_repository.dart';
import '../../data/scryfall/scryfall_client.dart';
import '../../data/scryfall/scryfall_models.dart';
import 'edit_match_modal.dart';
import 'review_queue_item_tile.dart';

class ReviewQueueScreen extends StatelessWidget {
  const ReviewQueueScreen({
    required this.scans,
    required this.collection,
    required this.scry,
    super.key,
  });
  final ScansRepository scans;
  final CollectionRepository collection;
  final ScryfallClient scry;

  Future<void> _confirm(Scan s) async {
    if (s.matchedScryfallId == null) return;
    final foil = s.foilGuess == 1;
    final card = ScryfallCard(
      id: s.matchedScryfallId!,
      name: s.matchedName!,
      set: s.matchedSet!,
      collectorNumber: s.matchedCollectorNumber!,
      prices: ScryfallPrices(usd: s.priceUsd, usdFoil: s.priceUsdFoil),
    );
    await collection.addFromScryfall(card, foil: foil);
    await scans.confirm(s.id);
  }

  @override
  Widget build(BuildContext context) {
    final db = collection.db;
    return Scaffold(
      appBar: AppBar(title: const Text('Review queue')),
      body: StreamBuilder<List<Scan>>(
        stream: scans.watchPending(),
        builder: (ctx, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snap.data!;
          if (items.isEmpty) {
            return const Center(child: Text('Nothing to review'));
          }
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final s = items[i];
              return ReviewQueueItemTile(
                scan: s,
                onConfirm: () => _confirm(s),
                onReject: () => scans.reject(s.id),
                onToggleFoil: (v) async {
                  await (db.update(db.scans)..where((t) => t.id.equals(s.id)))
                      .write(ScansCompanion(foilGuess: d.Value(v ? 1 : 0)));
                },
                onEdit: () => Navigator.of(ctx).push<bool>(
                  MaterialPageRoute(
                    builder: (_) =>
                        EditMatchModal(scan: s, db: db, scry: scry),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
