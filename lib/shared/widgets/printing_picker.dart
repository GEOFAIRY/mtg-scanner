import 'package:flutter/material.dart';
import '../../data/scryfall/scryfall_client.dart';
import '../../data/scryfall/scryfall_models.dart';

class PrintingPicker extends StatefulWidget {
  const PrintingPicker({
    required this.name,
    required this.scry,
    required this.onPick,
    this.selectedId,
    super.key,
  });
  final String name;
  final ScryfallClient scry;
  final void Function(ScryfallCard) onPick;
  final String? selectedId;

  @override
  State<PrintingPicker> createState() => _PrintingPickerState();
}

class _PrintingPickerState extends State<PrintingPicker> {
  late final Future<List<ScryfallCard>> _future =
      widget.scry.printingsOfName(widget.name);
  final TextEditingController _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<ScryfallCard> _filter(List<ScryfallCard> all) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return all;
    return all.where((p) {
      return p.set.toLowerCase().contains(q) ||
          p.setName.toLowerCase().contains(q) ||
          p.collectorNumber.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ScryfallCard>>(
      future: _future,
      builder: (ctx, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(child: Text('Error: ${snap.error}'));
        }
        final all = snap.data!;
        if (all.isEmpty) {
          return const Center(child: Text('No printings found'));
        }
        final printings = _filter(all);
        final theme = Theme.of(context);
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: TextField(
                controller: _search,
                decoration: InputDecoration(
                  isDense: true,
                  prefixIcon: const Icon(Icons.search, size: 20),
                  hintText: 'Filter by set code, set name, or number',
                  border: const OutlineInputBorder(),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            _search.clear();
                            setState(() => _query = '');
                          },
                        ),
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            if (printings.isEmpty)
              const Expanded(
                child: Center(child: Text('No matches')),
              )
            else
              Expanded(
                child: ListView.separated(
                  itemCount: printings.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final p = printings[i];
                    final selected = p.id == widget.selectedId;
                    final price = p.prices.usd == null
                        ? '—'
                        : '\$${p.prices.usd!.toStringAsFixed(2)}';
                    return Container(
                      color: selected
                          ? theme.colorScheme.primaryContainer
                          : null,
                      child: ListTile(
                        leading: p.imageUriSmall == null
                            ? const SizedBox(width: 40)
                            : Image.network(p.imageUriSmall!, width: 40),
                        title: Text(
                          '${p.setName} (${p.set.toUpperCase()}) · ${p.collectorNumber}',
                          style: selected
                              ? const TextStyle(fontWeight: FontWeight.w600)
                              : null,
                        ),
                        subtitle: Text(price),
                        trailing: selected
                            ? Icon(Icons.check_circle,
                                color: theme.colorScheme.primary)
                            : null,
                        onTap: () => widget.onPick(p),
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}

