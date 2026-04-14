import 'dart:async';
import 'package:flutter/material.dart';
import '../../data/scryfall/scryfall_client.dart';
import '../../data/scryfall/scryfall_models.dart';
import '../../shared/widgets/printing_picker.dart';

class EditMatchModal extends StatefulWidget {
  const EditMatchModal({required this.scry, super.key});
  final ScryfallClient scry;
  @override
  State<EditMatchModal> createState() => _EditMatchModalState();
}

class _EditMatchModalState extends State<EditMatchModal> {
  final _ctrl = TextEditingController();
  Timer? _debounce;
  List<String> _suggestions = const [];
  String? _picked;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit match')),
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
              onChanged: (q) {
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
              },
            ),
          ),
          Expanded(
            child: _picked == null
                ? ListView(
                    children: [
                      for (final s in _suggestions)
                        ListTile(
                          title: Text(s),
                          onTap: () => setState(() => _picked = s),
                        ),
                    ],
                  )
                : PrintingPicker(
                    name: _picked!,
                    scry: widget.scry,
                    onPick: (card) => Navigator.of(context).pop<ScryfallCard>(card),
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
