import 'dart:async';
import 'package:flutter/material.dart';
import '../../app_settings.dart';
import '../../data/repositories/collection_repository.dart';
import '../../data/scryfall/scryfall_client.dart';
import '../../data/scryfall/scryfall_models.dart';
import '../../shared/widgets/printing_picker.dart';

class EditScanResult {
  EditScanResult({required this.card, required this.foil, required this.count});
  final ScryfallCard card;
  final bool foil;
  final int count;
}

class EditScanModal extends StatefulWidget {
  const EditScanModal({
    required this.initialCard,
    required this.initialFoil,
    required this.initialCount,
    required this.collection,
    required this.scry,
    required this.collectionId,
    required this.settings,
    super.key,
  });
  final ScryfallCard initialCard;
  final bool initialFoil;
  final int initialCount;
  final CollectionRepository collection;
  final ScryfallClient scry;
  final int collectionId;
  final AppSettings settings;

  @override
  State<EditScanModal> createState() => _EditScanModalState();
}

class _EditScanModalState extends State<EditScanModal> {
  late final TextEditingController _ctrl;
  Timer? _debounce;
  List<String> _suggestions = const [];
  String? _pickedName;
  bool _loadingSuggestions = false;
  late ScryfallCard _card;
  late bool _foil;
  late int _count;
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    _card = widget.initialCard;
    _foil = widget.initialFoil;
    _count = widget.initialCount;
    _ctrl = TextEditingController(text: _card.name);
    _pickedName = _card.name;
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

  void _onPrintingPicked(ScryfallCard c) {
    setState(() => _card = c);
    _autoSave();
  }

  void _setFoil(bool v) {
    setState(() => _foil = v);
    _autoSave();
  }

  void _incrementCount() {
    setState(() => _count += 1);
    _autoSave();
  }

  void _decrementCount() {
    if (_count <= 1) return;
    setState(() => _count -= 1);
    _autoSave();
  }

  Future<void> _autoSave() async {
    _dirty = true;
    await widget.collection.updateMatch(
      id: widget.collectionId,
      card: _card,
      foil: _foil,
      count: _count,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        Navigator.of(context).pop(
          _dirty
              ? EditScanResult(card: _card, foil: _foil, count: _count)
              : null,
        );
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Edit scan'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(
              _dirty
                  ? EditScanResult(card: _card, foil: _foil, count: _count)
                  : null,
            ),
          ),
        ),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  controller: _ctrl,
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    FilterChip(
                      avatar: Icon(Icons.auto_awesome,
                          size: 16, color: _foil ? Colors.black : null),
                      label: const Text('Foil'),
                      selected: _foil,
                      onSelected: _setFoil,
                      selectedColor: const Color(0xFFECC460),
                      showCheckmark: false,
                    ),
                    const Spacer(),
                    const Text('Qty'),
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: _count > 1 ? _decrementCount : null,
                    ),
                    SizedBox(
                        width: 24,
                        child: Text('$_count',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600))),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: _incrementCount,
                    ),
                  ],
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
                        color:
                            Theme.of(context).colorScheme.surfaceContainerHighest,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            const Icon(Icons.style, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Printings of "$_pickedName"',
                                    style:
                                        Theme.of(context).textTheme.labelMedium,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (_card.name == _pickedName)
                                    Text(
                                      'Current: ${_card.setName} (${_card.set.toUpperCase()}) · ${_card.collectorNumber}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
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
                          region: widget.settings.priceRegion,
                          selectedId:
                              _card.name == _pickedName ? _card.id : null,
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
      ),
    );
  }
}
