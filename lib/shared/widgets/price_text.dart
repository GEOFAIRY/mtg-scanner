import 'package:flutter/material.dart';

import '../../app_settings.dart';

class PriceText extends StatelessWidget {
  const PriceText({
    required this.price,
    required this.region,
    required this.updatedAt,
    super.key,
  });
  final double? price;
  final PriceRegion region;
  final DateTime? updatedAt;

  @override
  Widget build(BuildContext context) {
    final stale = updatedAt == null ||
        DateTime.now().difference(updatedAt!).inDays >= 7;
    final text =
        price == null ? '—' : '${region.symbol}${price!.toStringAsFixed(2)}';
    return Text(
      text,
      style: stale
          ? TextStyle(color: Theme.of(context).disabledColor)
          : null,
    );
  }
}

