import 'dart:io';
import 'package:flutter/material.dart';
import '../../data/db/database.dart';

class ReviewQueueItemTile extends StatelessWidget {
  const ReviewQueueItemTile({
    required this.scan,
    required this.onConfirm,
    required this.onReject,
    required this.onEdit,
    required this.onToggleFoil,
    super.key,
  });
  final Scan scan;
  final VoidCallback onConfirm;
  final VoidCallback onReject;
  final VoidCallback onEdit;
  final ValueChanged<bool> onToggleFoil;

  @override
  Widget build(BuildContext context) {
    final name = scan.matchedName ??
        (scan.rawName.trim().isEmpty ? '(unmatched)' : 'OCR: ${scan.rawName}');
    final setNum = scan.matchedSet == null
        ? scan.rawSetCollector
        : '${scan.matchedSet!.toUpperCase()} · ${scan.matchedCollectorNumber ?? '?'}';
    final price = scan.foilGuess == 1 ? scan.priceUsdFoil : scan.priceUsd;
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            leading: scan.cropImagePath != null &&
                    File(scan.cropImagePath!).existsSync()
                ? SizedBox(
                    width: 48,
                    height: 64,
                    child: Image.file(File(scan.cropImagePath!),
                        fit: BoxFit.cover),
                  )
                : const SizedBox(width: 48, height: 64),
            title: Text(name),
            subtitle: Text('$setNum · ${(scan.confidence * 100).toStringAsFixed(0)}%'
                '${price == null ? "" : "  ·  \$${price.toStringAsFixed(2)}"}'),
            trailing: FilterChip(
              avatar: Icon(
                Icons.auto_awesome,
                size: 16,
                color: scan.foilGuess == 1 ? Colors.black : null,
              ),
              label: const Text('Foil'),
              selected: scan.foilGuess == 1,
              onSelected: onToggleFoil,
              selectedColor: const Color(0xFFECC460),
              checkmarkColor: Colors.black,
              showCheckmark: false,
            ),
          ),
          OverflowBar(
            spacing: 8,
            alignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(onPressed: onReject, child: const Text('Reject')),
              OutlinedButton(onPressed: onEdit, child: const Text('Edit')),
              FilledButton(onPressed: onConfirm, child: const Text('Confirm')),
            ],
          ),
        ],
      ),
    );
  }
}
