import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../data/db/database.dart';
import '../../data/repositories/collection_repository.dart';
import '../../data/scryfall/scryfall_client.dart';
import '../../data/scryfall/scryfall_models.dart';
import '../../shared/widgets/price_text.dart';
import '../../shared/widgets/set_icon.dart';
import '../scanner/edit_scan_modal.dart';

class CollectionDetailScreen extends StatefulWidget {
  const CollectionDetailScreen({
    required this.id,
    required this.repo,
    required this.scry,
    super.key,
  });
  final int id;
  final CollectionRepository repo;
  final ScryfallClient scry;
  @override
  State<CollectionDetailScreen> createState() => _CollectionDetailScreenState();
}

class _CollectionDetailScreenState extends State<CollectionDetailScreen> {
  late Future<CollectionData> _future = widget.repo.getById(widget.id);
  Future<ScryfallCard?>? _cardFuture;
  Future<ScryfallSet?>? _setFuture;
  String? _loadedSetCode;
  String? _loadedCollectorNumber;
  late int _count;
  bool _initialized = false;

  Future<ScryfallCard?> _loadCard(CollectionData r) async {
    try {
      return await widget.scry.cardBySetAndNumber(r.setCode, r.collectorNumber);
    } catch (_) {
      return null;
    }
  }

  Future<ScryfallSet?> _loadSet(CollectionData r) async {
    try {
      return await widget.scry.setByCode(r.setCode);
    } catch (_) {
      return null;
    }
  }

  void _ensureScryfallFutures(CollectionData r) {
    // Only re-fetch if the row's identity changed (edit flow swaps to a
    // different printing). Without this, every setState/increment would
    // re-issue two Scryfall requests.
    if (_cardFuture == null ||
        _loadedSetCode != r.setCode ||
        _loadedCollectorNumber != r.collectorNumber) {
      _loadedSetCode = r.setCode;
      _loadedCollectorNumber = r.collectorNumber;
      _cardFuture = _loadCard(r);
      _setFuture = _loadSet(r);
    }
  }

  void _increment(CollectionData r) {
    setState(() => _count++);
    unawaited(widget.repo.updateQuantity(r.id, _count));
  }

  Future<void> _decrement(CollectionData r) async {
    if (_count == 0) return;
    final nextCount = _count - 1;
    if (nextCount == 0) {
      // Delete immediately with an undo snackbar; don't couple destructive
      // DB state to navigation lifecycle.
      final messenger = ScaffoldMessenger.of(context);
      final navigator = Navigator.of(context);
      // Snapshot at the current count so undo restores what the user had.
      final snapshot = r.copyWith(count: _count);
      await widget.repo.delete(r.id);
      if (!mounted) return;
      messenger.clearSnackBars();
      messenger.showSnackBar(SnackBar(
        content: Text('Removed ${r.name}'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () => unawaited(widget.repo.restore(snapshot)),
        ),
      ));
      navigator.pop();
      return;
    }
    setState(() => _count = nextCount);
    unawaited(widget.repo.updateQuantity(r.id, _count));
  }

  Future<void> _edit(CollectionData r) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final card = await _cardFuture;
    if (!mounted) return;
    if (card == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not load card details (offline?)')),
      );
      return;
    }
    final result = await navigator.push<EditScanResult>(
      MaterialPageRoute(
        builder: (_) => EditScanModal(
          initialCard: card,
          initialFoil: r.foil == 1,
          initialCount: r.count,
          collection: widget.repo,
          scry: widget.scry,
          collectionId: r.id,
        ),
      ),
    );
    if (!mounted) return;
    if (result != null) {
      setState(() => _future = widget.repo.getById(widget.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Card'),
        actions: [
          FutureBuilder<CollectionData>(
            future: _future,
            builder: (_, snap) => IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Edit',
              onPressed: snap.hasData ? () => _edit(snap.data!) : null,
            ),
          ),
        ],
      ),
      body: FutureBuilder<CollectionData>(
        future: _future,
        builder: (ctx, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final r = snap.data!;
          if (!_initialized) {
            _count = r.count;
            _initialized = true;
          }
          _ensureScryfallFutures(r);
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Center(
                child: FutureBuilder<ScryfallCard?>(
                  future: _cardFuture,
                  builder: (_, cardSnap) {
                    final url = cardSnap.data?.imageUriNormal;
                    if (cardSnap.connectionState != ConnectionState.done) {
                      return const SizedBox(
                        height: 360,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    if (url == null) {
                      return const SizedBox(
                        height: 360,
                        child: Center(
                          child: Icon(Icons.broken_image,
                              size: 48, color: Colors.grey),
                        ),
                      );
                    }
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: url,
                        height: 360,
                        fit: BoxFit.contain,
                        errorWidget: (_, __, ___) => const SizedBox(
                          height: 360,
                          child: Center(
                            child: Icon(Icons.broken_image,
                                size: 48, color: Colors.grey),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Text(r.name, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              FutureBuilder<ScryfallSet?>(
                future: _setFuture,
                builder: (ctx, setSnap) {
                  final setName = setSnap.data?.name ?? r.setCode.toUpperCase();
                  return Row(
                    children: [
                      SetIcon(code: r.setCode, size: 20),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          '$setName (${r.setCode.toUpperCase()}) · ${r.collectorNumber}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 8),
              PriceText(
                usd: r.foil == 1 ? (r.priceUsdFoil ?? r.priceUsd) : r.priceUsd,
                updatedAt: r.priceUpdatedAt,
              ),
              const Spacer(),
              Row(children: [
                FilledButton.tonal(
                  onPressed: () async {
                    await widget.repo.refreshOne(r.id);
                    if (!context.mounted) return;
                    setState(() => _future = widget.repo.getById(widget.id));
                  },
                  child: const Text('Refresh price'),
                ),
                const Spacer(),
                IconButton(onPressed: () => _decrement(r), icon: const Icon(Icons.remove)),
                Text('$_count'),
                IconButton(onPressed: () => _increment(r), icon: const Icon(Icons.add)),
              ]),
            ]),
          );
        },
      ),
    );
  }

}
