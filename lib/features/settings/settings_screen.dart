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
  bool _refreshCancelled = false;

  @override
  void initState() {
    super.initState();
    widget.settings.addListener(_onSettingsChanged);
  }

  @override
  void dispose() {
    // A running refresh must see the screen go away and stop issuing
    // Scryfall requests + DB writes, otherwise it keeps the price loop
    // alive after the user has navigated away.
    _refreshCancelled = true;
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
      _refreshCancelled = false;
    });
    await widget.repo.refreshAllPrices(
      onProgress: (done, total) {
        if (!mounted) return;
        setState(() {
          _refreshDone = done;
          _refreshTotal = total;
        });
      },
      isCancelled: () => _refreshCancelled || !mounted,
    );
    if (!mounted) return;
    final cancelled = _refreshCancelled;
    setState(() {
      _refreshDone = null;
      _refreshTotal = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(cancelled ? 'Refresh cancelled' : 'Prices refreshed'),
    ));
  }

  void _cancelRefresh() {
    setState(() => _refreshCancelled = true);
  }

  Future<void> _editThreshold() async {
    final region = widget.settings.priceRegion;
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
          decoration: InputDecoration(
            prefixText: '${region.symbol} ',
            helperText:
                'Sound plays when scanned card is above this ${region.name.toUpperCase()} value',
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

  Future<void> _editPriceRegion() async {
    final current = widget.settings.priceRegion;
    final result = await showDialog<PriceRegion>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Price region'),
        children: [
          RadioGroup<PriceRegion>(
            groupValue: current,
            onChanged: (r) => Navigator.of(ctx).pop(r),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final r in PriceRegion.values)
                  RadioListTile<PriceRegion>(
                    value: r,
                    title: Text(r.label),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
    if (result != null) await widget.settings.setPriceRegion(result);
  }

  Future<void> _editThemeMode() async {
    final current = widget.settings.themeMode;
    final result = await showDialog<ThemeMode>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Theme'),
        children: [
          RadioGroup<ThemeMode>(
            groupValue: current,
            onChanged: (m) => Navigator.of(ctx).pop(m),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<ThemeMode>(
                  value: ThemeMode.system,
                  title: Text('System default'),
                ),
                RadioListTile<ThemeMode>(
                  value: ThemeMode.light,
                  title: Text('Light'),
                ),
                RadioListTile<ThemeMode>(
                  value: ThemeMode.dark,
                  title: Text('Dark'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    if (result != null) await widget.settings.setThemeMode(result);
  }

  String _themeModeLabel(ThemeMode mode) => switch (mode) {
        ThemeMode.system => 'System default',
        ThemeMode.light => 'Light',
        ThemeMode.dark => 'Dark',
      };

  @override
  Widget build(BuildContext context) {
    final backup = BackupRestoreService(widget.repo.db);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Theme'),
            subtitle: Text(_themeModeLabel(widget.settings.themeMode)),
            leading: const Icon(Icons.brightness_6),
            onTap: _editThemeMode,
          ),
          const Divider(),
          ListTile(
            title: const Text('Price region'),
            subtitle: Text(widget.settings.priceRegion.label),
            leading: const Icon(Icons.public),
            onTap: _editPriceRegion,
          ),
          const Divider(),
          ListTile(
            title: const Text('Value alert threshold'),
            subtitle: Text(
                '${widget.settings.priceRegion.symbol}${widget.settings.valueAlertThreshold.toStringAsFixed(2)}'),
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
                : IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: 'Cancel',
                    onPressed: _cancelRefresh,
                  ),
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
          const Divider(),
          SwitchListTile(
            title: const Text('Show scanner debug overlay'),
            subtitle: const Text(
                'Displays raw OCR text and block positions on failed scans'),
            secondary: const Icon(Icons.bug_report),
            value: widget.settings.debugOverlayEnabled,
            onChanged: (v) => widget.settings.setDebugOverlayEnabled(v),
          ),
        ],
      ),
    );
  }
}

