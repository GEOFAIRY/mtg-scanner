import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/scryfall/scryfall_client.dart';
import '../../data/repositories/collection_repository.dart';
import '../../shared/widgets/printing_picker.dart';

class ManualAddScreen extends StatefulWidget {
  const ManualAddScreen({required this.scry, required this.collection, super.key});
  final ScryfallClient scry;
  final CollectionRepository collection;
  @override
  State<ManualAddScreen> createState() => _ManualAddScreenState();
}

class _ManualAddScreenState extends State<ManualAddScreen> {
  final _ctrl = TextEditingController();
  Timer? _debounce;
  List<String> _suggestions = const [];
  String? _pickedName;
  bool _foil = false;

  void _onQueryChanged(String q) {
    _debounce?.cancel();
    if (q.trim().length < 2) {
      setState(() => _suggestions = const []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 200), () async {
      final list = await widget.scry.autocomplete(q);
      if (!mounted) return;
      setState(() => _suggestions = list);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add card')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _ctrl,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Card name',
                border: OutlineInputBorder(),
              ),
              onChanged: _onQueryChanged,
            ),
          ),
          SwitchListTile(
            title: const Text('Foil'),
            value: _foil,
            onChanged: (v) => setState(() => _foil = v),
          ),
          const Divider(height: 1),
          Expanded(
            child: _pickedName == null
                ? ListView(
                    children: [
                      for (final s in _suggestions)
                        ListTile(
                          title: Text(s),
                          onTap: () => setState(() => _pickedName = s),
                        ),
                    ],
                  )
                : PrintingPicker(
                    name: _pickedName!,
                    scry: widget.scry,
                    onPick: (card) async {
                      await widget.collection.addFromScryfall(card, foil: _foil);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Added ${card.name} (${card.set.toUpperCase()})')),
                      );
                      context.pop();
                    },
                  ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    super.dispose();
  }
}
