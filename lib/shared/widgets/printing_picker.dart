import 'package:flutter/material.dart';
import '../../data/scryfall/scryfall_client.dart';
import '../../data/scryfall/scryfall_models.dart';

class PrintingPicker extends StatefulWidget {
  const PrintingPicker({
    required this.name,
    required this.scry,
    required this.onPick,
    super.key,
  });
  final String name;
  final ScryfallClient scry;
  final void Function(ScryfallCard) onPick;

  @override
  State<PrintingPicker> createState() => _PrintingPickerState();
}

class _PrintingPickerState extends State<PrintingPicker> {
  late final Future<List<ScryfallCard>> _future =
      widget.scry.printingsOfName(widget.name);

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
        final printings = snap.data!;
        if (printings.isEmpty) {
          return const Center(child: Text('No printings found'));
        }
        return ListView.separated(
          itemCount: printings.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (_, i) {
            final p = printings[i];
            final price = p.prices.usd == null
                ? '—'
                : '\$${p.prices.usd!.toStringAsFixed(2)}';
            return ListTile(
              leading: p.imageUriSmall == null
                  ? const SizedBox(width: 40)
                  : Image.network(p.imageUriSmall!, width: 40),
              title: Text('${p.set.toUpperCase()} · ${p.collectorNumber}'),
              subtitle: Text(price),
              onTap: () => widget.onPick(p),
            );
          },
        );
      },
    );
  }
}
