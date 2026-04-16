import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../data/scryfall/scryfall_models.dart';

class BannerData {
  const BannerData({
    required this.collectionId,
    required this.card,
    required this.price,
    required this.foil,
    required this.wasInsertion,
  });
  final int collectionId;
  final ScryfallCard card;
  final double? price;
  final bool foil;
  final bool wasInsertion;
}

class ResultBanner extends StatelessWidget {
  const ResultBanner({
    required this.data,
    required this.onDismiss,
    required this.onEdit,
    super.key,
  });
  final BannerData? data;
  final VoidCallback onDismiss;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final d = data;
    if (d == null) return const SizedBox.shrink();
    final card = d.card;
    final subtitleParts = <String>[
      card.set.toUpperCase(),
      card.collectorNumber,
      if (card.rarity != null) card.rarity!,
      if (d.price != null) '\$${d.price!.toStringAsFixed(2)}',
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(12),
        color: Colors.black.withValues(alpha: 0.85),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onEdit,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
            child: Row(
              children: [
                _Thumbnail(url: card.imageUriSmall),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              card.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                          if (d.foil) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFECC460),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.auto_awesome,
                                      color: Colors.black, size: 10),
                                  SizedBox(width: 2),
                                  Text('FOIL',
                                      style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.6)),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitleParts.join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.white70),
                  onPressed: onEdit,
                  tooltip: 'Edit',
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: onDismiss,
                  tooltip: 'Dismiss',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.url});
  final String? url;
  @override
  Widget build(BuildContext context) {
    const w = 40.0, h = 56.0;
    if (url == null) {
      return const SizedBox(
          width: w,
          height: h,
          child: DecoratedBox(
            decoration: BoxDecoration(color: Colors.white10),
          ));
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: CachedNetworkImage(
        imageUrl: url!,
        width: w,
        height: h,
        fit: BoxFit.cover,
        errorWidget: (_, __, ___) => const SizedBox(
            width: w, height: h, child: ColoredBox(color: Colors.white10)),
      ),
    );
  }
}

