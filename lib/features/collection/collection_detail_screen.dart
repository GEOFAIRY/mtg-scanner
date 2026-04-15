import 'package:flutter/material.dart';
import '../../data/db/database.dart';
import '../../data/repositories/collection_repository.dart';
import '../../data/scryfall/scryfall_client.dart';
import '../../data/scryfall/scryfall_models.dart';
import '../../shared/widgets/price_text.dart';

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
  late int _count;
  late int _id;
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

  void _increment(CollectionData r) {
    setState(() => _count++);
    widget.repo.updateQuantity(r.id, _count);
  }

  void _decrement(CollectionData r) {
    if (_count > 0) {
      setState(() => _count--);
      widget.repo.updateQuantity(r.id, _count);
    }
  }

  @override
  void dispose() {
    if (_count == 0) {
      widget.repo.delete(_id);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Card')),
      body: FutureBuilder<CollectionData>(
        future: _future,
        builder: (ctx, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final r = snap.data!;
          if (!_initialized) {
            _count = r.count;
            _id = r.id;
            _initialized = true;
          }
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Center(
                child: FutureBuilder<ScryfallCard?>(
                  future: _loadCard(r),
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
                      child: Image.network(
                        url,
                        height: 360,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const SizedBox(
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
                future: _loadSet(r),
                builder: (ctx, setSnap) {
                  final setName = setSnap.data?.name ?? r.setCode.toUpperCase();
                  return Text('$setName (${r.setCode.toUpperCase()}) · ${r.collectorNumber}');
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
