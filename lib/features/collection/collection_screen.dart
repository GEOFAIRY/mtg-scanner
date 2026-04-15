import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/db/database.dart';
import '../../data/repositories/collection_repository.dart';
import '../../shared/widgets/price_text.dart';

enum _Sort { set, nameAsc, priceDesc, dateDesc }

class CollectionScreen extends StatefulWidget {
  const CollectionScreen({required this.repo, super.key});
  final CollectionRepository repo;
  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> {
  String _query = '';
  _Sort _sort = _Sort.set;

  double _rowPrice(CollectionData r) => r.foil == 1
      ? (r.priceUsdFoil ?? r.priceUsd ?? 0)
      : (r.priceUsd ?? 0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Collection'),
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share),
            tooltip: 'Export',
            onPressed: () => context.push('/export'),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.go('/collection/add'),
          ),
          PopupMenuButton<_Sort>(
            icon: const Icon(Icons.sort),
            onSelected: (v) => setState(() => _sort = v),
            itemBuilder: (_) => const [
              PopupMenuItem(value: _Sort.set, child: Text('By set')),
              PopupMenuItem(value: _Sort.nameAsc, child: Text('Name A–Z')),
              PopupMenuItem(value: _Sort.priceDesc, child: Text('Price (high → low)')),
              PopupMenuItem(value: _Sort.dateDesc, child: Text('Recently added')),
            ],
          ),
        ],
      ),
      body: StreamBuilder<List<CollectionData>>(
        stream: widget.repo.watchAll(),
        builder: (ctx, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          var rows = snap.data!;
          if (_query.isNotEmpty) {
            final q = _query.toLowerCase();
            rows = rows.where((r) =>
                r.name.toLowerCase().contains(q) ||
                r.setCode.toLowerCase().contains(q)).toList();
          }
          rows.sort((a, b) {
            switch (_sort) {
              case _Sort.set:
                return a.setCode.compareTo(b.setCode);
              case _Sort.nameAsc:
                return a.name.compareTo(b.name);
              case _Sort.priceDesc:
                return _rowPrice(b).compareTo(_rowPrice(a));
              case _Sort.dateDesc:
                return b.addedAt.compareTo(a.addedAt);
            }
          });
          final total = rows.fold<double>(0, (s, r) => s + _rowPrice(r) * r.count);
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search name or set code',
                    prefixIcon: Icon(Icons.search),
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Showing ${rows.length} cards · \$${total.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
              Expanded(
                child: ListView.separated(
                  itemCount: rows.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final r = rows[i];
                    return ListTile(
                      title: Text('${r.count}× ${r.name}${r.foil == 1 ? " ✦" : ""}'),
                      subtitle: Text('${r.setCode.toUpperCase()} · ${r.collectorNumber}'),
                      trailing: PriceText(
                        usd: r.foil == 1 ? (r.priceUsdFoil ?? r.priceUsd) : r.priceUsd,
                        updatedAt: r.priceUpdatedAt,
                      ),
                      onTap: () => context.go('/collection/${r.id}'),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
