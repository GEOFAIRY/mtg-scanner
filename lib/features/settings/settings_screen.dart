import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../app_settings.dart';
import '../../data/repositories/collection_repository.dart';
import 'backup_restore_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    required this.repo,
    required this.settings,
    super.key,
  });
  final CollectionRepository repo;
  final AppSettings settings;
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int? _refreshDone;
  int? _refreshTotal;

  @override
  void initState() {
    super.initState();
    widget.settings.addListener(_onSettingsChanged);
  }

  @override
  void dispose() {
    widget.settings.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _refreshAll() async {
    setState(() {
      _refreshDone = 0;
      _refreshTotal = null;
    });
    await widget.repo.refreshAllPrices(onProgress: (done, total) {
      if (!mounted) return;
      setState(() {
        _refreshDone = done;
        _refreshTotal = total;
      });
    });
    if (!mounted) return;
    setState(() {
      _refreshDone = null;
      _refreshTotal = null;
    });
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Prices refreshed')));
  }

  Future<void> _editThreshold() async {
    final ctrl = TextEditingController(
        text: widget.settings.valueAlertThreshold.toStringAsFixed(2));
    final result = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Value alert threshold'),
        content: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          decoration: const InputDecoration(
            prefixText: r'$ ',
            helperText: 'Sound plays when scanned card is above this USD value',
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final v = double.tryParse(ctrl.text.trim());
              if (v != null && v.isFinite && v > 0) Navigator.of(ctx).pop(v);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result != null) await widget.settings.setValueAlertThreshold(result);
  }

  @override
  Widget build(BuildContext context) {
    final backup = BackupRestoreService(widget.repo.db);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Value alert threshold'),
            subtitle: Text(
                r'$' '${widget.settings.valueAlertThreshold.toStringAsFixed(2)}'),
            leading: const Icon(Icons.notifications_active),
            onTap: _editThreshold,
          ),
          const Divider(),
          ListTile(
            title: const Text('Refresh all prices'),
            subtitle: _refreshDone == null
                ? const Text('Re-fetches every card from Scryfall (rate-limited)')
                : Text('Refreshing… $_refreshDone / ${_refreshTotal ?? "?"}'),
            trailing: _refreshDone == null
                ? const Icon(Icons.refresh)
                : const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2)),
            onTap: _refreshDone == null ? _refreshAll : null,
          ),
          const Divider(),
          ListTile(
            title: const Text('Export JSON backup'),
            leading: const Icon(Icons.save_alt),
            onTap: () async {
              final f = await backup.exportJson();
              await Share.shareXFiles([XFile(f.path)]);
            },
          ),
        ],
      ),
    );
  }
}
