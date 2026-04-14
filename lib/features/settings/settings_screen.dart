import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../data/repositories/collection_repository.dart';
import 'backup_restore_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({required this.repo, super.key});
  final CollectionRepository repo;
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int? _refreshDone;
  int? _refreshTotal;

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
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Prices refreshed')));
  }

  @override
  Widget build(BuildContext context) {
    final backup = BackupRestoreService(widget.repo.db);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Refresh all prices'),
            subtitle: _refreshDone == null
                ? const Text('Re-fetches every card from Scryfall (rate-limited)')
                : Text('Refreshing… $_refreshDone / ${_refreshTotal ?? "?"}'),
            trailing: _refreshDone == null
                ? const Icon(Icons.refresh)
                : const SizedBox(
                    width: 24, height: 24,
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
