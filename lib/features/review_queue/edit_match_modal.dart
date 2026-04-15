import 'package:drift/drift.dart' as d;
import 'package:flutter/material.dart';
import '../../data/db/database.dart';
import '../../data/scryfall/scryfall_client.dart';
import '../../data/scryfall/scryfall_models.dart';
import 'pick_different_card_modal.dart';

/// In-place editor for a single scan row. Lets the user correct the name,
/// set code, or collector number without re-matching from scratch. Saving
/// re-runs a Scryfall lookup against the edited values; on success the
/// matched_* fields are rewritten, on failure the edited values are saved
/// as-is at 90% confidence (manual override).
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
  late final TextEditingController _name;
  late final TextEditingController _set;
  late final TextEditingController _coll;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final s = widget.scan;
    _name = TextEditingController(text: s.matchedName ?? s.rawName);
    _set = TextEditingController(text: s.matchedSet ?? '');
    _coll = TextEditingController(text: s.matchedCollectorNumber ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _set.dispose();
    _coll.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    final set = _set.text.trim().toUpperCase();
    final coll = _coll.text.trim().toLowerCase();
    if (name.isEmpty && (set.isEmpty || coll.isEmpty)) {
      setState(() => _error = 'Fill a name or both set + collector number.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });

    ScryfallCard? card;
    var confidence = 0.9;

    if (set.isNotEmpty && coll.isNotEmpty) {
      try {
        card = await widget.scry.cardBySetAndNumber(set, coll);
        confidence = 1.0;
      } on ScryfallNotFound {
        // fall through
      } on ScryfallException {
        // fall through
      }
    }
    if (card == null && name.isNotEmpty) {
      try {
        card = await widget.scry.cardByFuzzyName(name);
        confidence = 0.6;
      } on ScryfallNotFound {
        // fall through
      } on ScryfallException {
        // fall through
      }
    }

    if (!mounted) return;

    if (card != null) {
      await widget.db.scansDao.updateMatch(
        widget.scan.id,
        scryfallId: card.id,
        name: card.name,
        setCode: card.set,
        collectorNumber: card.collectorNumber,
        confidence: confidence,
        priceUsd: card.prices.usd,
        priceUsdFoil: card.prices.usdFoil,
      );
    } else {
      // No Scryfall hit — save edited values verbatim as a manual override.
      await (widget.db.update(widget.db.scans)
            ..where((t) => t.id.equals(widget.scan.id)))
          .write(ScansCompanion(
        matchedName: d.Value(name.isEmpty ? null : name),
        matchedSet: d.Value(set.isEmpty ? null : set),
        matchedCollectorNumber: d.Value(coll.isEmpty ? null : coll),
        confidence: const d.Value(0.9),
      ));
    }

    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  Future<void> _pickDifferent() async {
    final picked = await Navigator.of(context).push<ScryfallCard>(
      MaterialPageRoute(
          builder: (_) => PickDifferentCardModal(scry: widget.scry)),
    );
    if (picked == null || !mounted) return;
    await widget.db.scansDao.updateMatch(
      widget.scan.id,
      scryfallId: picked.id,
      name: picked.name,
      setCode: picked.set,
      collectorNumber: picked.collectorNumber,
      confidence: 1.0,
      priceUsd: picked.prices.usd,
      priceUsdFoil: picked.prices.usdFoil,
    );
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit scan')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _name,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _set,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        labelText: 'Set code',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _coll,
                      decoration: const InputDecoration(
                        labelText: 'Collector #',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.save),
                label: const Text('Save'),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _saving ? null : _pickDifferent,
                icon: const Icon(Icons.search),
                label: const Text('Pick a different card instead'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
