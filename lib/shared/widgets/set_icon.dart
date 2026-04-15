import 'package:flutter/material.dart';
import '../keyrune_codepoints.dart';

class SetIcon extends StatelessWidget {
  const SetIcon({required this.code, this.size = 16, this.color, super.key});
  final String code;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final cp = keyruneCodepoints[code.toLowerCase()];
    if (cp == null) {
      return Icon(Icons.style, size: size, color: color);
    }
    return Text(
      String.fromCharCode(cp),
      style: TextStyle(
        fontFamily: 'Keyrune',
        fontSize: size,
        color: color ?? DefaultTextStyle.of(context).style.color,
        height: 1,
      ),
    );
  }
}

