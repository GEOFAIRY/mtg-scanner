import 'dart:async';
import 'package:flutter/material.dart';
import '../../data/db/database.dart';
import '../../data/scryfall/scryfall_client.dart';
import '../../data/scryfall/scryfall_models.dart';
import '../../shared/widgets/printing_picker.dart';

/// Edit a scan by seeding Scryfall's autocomplete with the detected name.
/// The user can refine the name, pick a suggestion, then pick the exact
/// printing (set + collector number). Saving writes match columns with
/// confidence 1.0 since the user explicitly picked it.
class EditMatchModal extends StatefulWidget {
  const EditMatchModal({
    required this.scan,
    required this.db,
    required this.scry,
    super.key,
  });
  final Scan scan;
  final AppDatabase db;
  final ScryfallClient scry;
  @override
  State<EditMatchModal> createState() => _EditMatchModalState();
}

class _EditMatchModalState extends State<EditMatchModal> {
  late final TextEditingController _ctrl;
  Timer? _debounce;
  List<String> _suggestions = const [];
  String? _pickedName;
  bool _loadingSuggestions = false;

  @override
  void initState() {
    super.initState();
    final seed = (widget.scan.matchedName ?? widget.scan.rawName).trim();
    _ctrl = TextEditingController(text: seed);
    if (seed.length >= 2) {
      _pickedName = seed;
      _fetchSuggestions(seed);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  void _onChanged(String q) {
    _debounce?.cancel();
    setState(() => _pickedName = null);
    if (q.trim().length < 2) {
      setState(() => _suggestions = const []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 220), () {
      _fetchSuggestions(q.trim());
    });
  }

  Future<void> _fetchSuggestions(String q) async {
    setState(() => _loadingSuggestions = true);
    try {
      final list = await widget.scry.autocomplete(q);
      if (!mounted) return;
      setState(() => _suggestions = list);
    } catch (_) {
      if (!mounted) return;
      setState(() => _suggestions = const []);
    } finally {
      if (mounted) setState(() => _loadingSuggestions = false);
    }
  }

  void _pickName(String name) {
    _ctrl.text = name;
    setState(() {
      _pickedName = name;
      _suggestions = const [];
    });
  }

  Future<void> _onPrintingPicked(ScryfallCard c) async {
    await widget.db.scansDao.updateMatch(
      widget.scan.id,
      scryfallId: c.id,
      name: c.name,
      setCode: c.set,
      collectorNumber: c.collectorNumber,
      confidence: 1.0,
      priceUsd: c.prices.usd,
      priceUsdFoil: c.prices.usdFoil,
    );
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit scan')),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _ctrl,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Card name',
                  border: const OutlineInputBorder(),
                  suffixIcon: _loadingSuggestions
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                              width: 16,
                              height: 16,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2)),
                        )
                      : (_ctrl.text.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                _ctrl.clear();
                                _onChanged('');
                              },
                            )),
                ),
                onChanged: _onChanged,
              ),
            ),
            if (_suggestions.isNotEmpty && _pickedName == null)
              Expanded(
                child: ListView.separated(
                  itemCount: _suggestions.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) => ListTile(
                    title: Text(_suggestions[i]),
                    onTap: () => _pickName(_suggestions[i]),
                  ),
                ),
              )
            else if (_pickedName != null)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.style, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Printings of "$_pickedName"',
                              style:
                                  Theme.of(context).textTheme.labelMedium,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: PrintingPicker(
                        key: ValueKey(_pickedName),
                        name: _pickedName!,
                        scry: widget.scry,
                        onPick: _onPrintingPicked,
                      ),
                    ),
                  ],
                ),
              )
            else
              const Expanded(
                child: Center(
                  child: Text('Type at least 2 letters',
                      style: TextStyle(color: Colors.grey)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
