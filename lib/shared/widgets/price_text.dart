import 'package:flutter/material.dart';

class PriceText extends StatelessWidget {
  const PriceText({required this.usd, required this.updatedAt, super.key});
  final double? usd;
  final DateTime? updatedAt;

  @override
  Widget build(BuildContext context) {
    final stale = updatedAt == null ||
        DateTime.now().difference(updatedAt!).inDays >= 7;
    final text = usd == null ? '—' : '\$${usd!.toStringAsFixed(2)}';
    return Text(
      text,
      style: stale
          ? TextStyle(color: Theme.of(context).disabledColor)
          : null,
    );
  }
}

