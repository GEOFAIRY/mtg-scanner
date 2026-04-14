import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/db/database.dart';
import '../../data/repositories/collection_repository.dart';
import '../../shared/widgets/price_text.dart';

class CollectionDetailScreen extends StatefulWidget {
  const CollectionDetailScreen({required this.id, required this.repo, super.key});
  final int id;
  final CollectionRepository repo;
  @override
  State<CollectionDetailScreen> createState() => _CollectionDetailScreenState();
}

class _CollectionDetailScreenState extends State<CollectionDetailScreen> {
  late Future<CollectionData> _future = widget.repo.getById(widget.id);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Card')),
      body: FutureBuilder<CollectionData>(
        future: _future,
        builder: (ctx, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final r = snap.data!;
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(r.name, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text('${r.setCode.toUpperCase()} · ${r.collectorNumber}'),
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
                OutlinedButton(
                  onPressed: () async {
                    await widget.repo.delete(r.id);
                    if (!context.mounted) return;
                    context.pop();
                  },
                  child: const Text('Delete'),
                ),
              ]),
            ]),
          );
        },
      ),
    );
  }
}
