import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../data/db/database.dart';
import '../../data/repositories/collection_repository.dart';
import 'formatters/moxfield_text_formatter.dart';
import 'formatters/moxfield_csv_formatter.dart';

enum _Format { text, csv }

class ExportScreen extends StatefulWidget {
  const ExportScreen({required this.repo, super.key});
  final CollectionRepository repo;
  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  _Format _format = _Format.text;

  List<MoxRow> _toRows(List<CollectionData> rows) => rows
      .map((r) => MoxRow(
            count: r.count,
            name: r.name,
            set: r.setCode,
            collector: r.collectorNumber,
            foil: r.foil == 1,
            condition: r.condition,
            language: r.language,
          ))
      .toList();

  String _render(List<MoxRow> rows) =>
      _format == _Format.text ? formatMoxfieldText(rows).join('\n')
                              : formatMoxfieldCsv(rows);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Export')),
      body: StreamBuilder<List<CollectionData>>(
        stream: widget.repo.watchAll(),
        builder: (ctx, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final rows = _toRows(snap.data!);
          final text = _render(rows);
          final preview = text.split('\n').take(20).join('\n');
          return Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(children: [
                  const Text('Format: '),
                  DropdownButton<_Format>(
                    value: _format,
                    items: const [
                      DropdownMenuItem(value: _Format.text, child: Text('Moxfield text')),
                      DropdownMenuItem(value: _Format.csv, child: Text('CSV')),
                    ],
                    onChanged: (v) => setState(() => _format = v!),
                  ),
                ]),
                const SizedBox(height: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Theme.of(context).dividerColor),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: SingleChildScrollView(child: SelectableText(preview)),
                  ),
                ),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(
                    child: FilledButton.tonal(
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: text));
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Copied')));
                      },
                      child: const Text('Copy'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.tonal(
                      onPressed: () async {
                        final ext = _format == _Format.csv ? 'csv' : 'txt';
                        final dir = await getTemporaryDirectory();
                        final f = File(p.join(dir.path, 'collection.$ext'));
                        await f.writeAsString(text);
                        await Share.shareXFiles([XFile(f.path)]);
                      },
                      child: const Text('Share'),
                    ),
                  ),
                ]),
              ],
            ),
          );
        },
      ),
    );
  }
}
