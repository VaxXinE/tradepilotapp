import 'package:flutter/material.dart';

class ProgressionEmblem extends StatelessWidget {
  const ProgressionEmblem({
    super.key,
    required this.level,
    required this.masteryLevel,
    this.size = 72,
  });

  final int level;
  final int masteryLevel;
  final double size;

  @override
  Widget build(BuildContext context) {
    const palettes = [
      [Color(0xFF78936F), Color(0xFF334A35)],
      [Color(0xFF738395), Color(0xFF344252)],
      [Color(0xFF6F99B8), Color(0xFF294C69)],
      [Color(0xFFA47B52), Color(0xFF51351F)],
      [Color(0xFFD69B38), Color(0xFF745016)],
      [Color(0xFF946AB0), Color(0xFF4B2D63)],
      [Color(0xFFBD5454), Color(0xFF682323)],
      [Color(0xFF278DA2), Color(0xFF164F5B)],
      [Color(0xFFBBB486), Color(0xFF625D3D)],
      [Color(0xFF303943), Color(0xFF080A0D)],
    ];
    final mastery = masteryLevel > 0 || level > 100;
    final tier = ((level.clamp(1, 100) - 1) ~/ 10).clamp(0, 9);
    final palette = mastery
        ? const [Color(0xFFB97A08), Color(0xFF3D2106)]
        : palettes[tier];
    final label = masteryLevel > 0 ? 'M$masteryLevel' : '$level';
    return Semantics(
      label: masteryLevel > 0 ? 'Mastery level $masteryLevel' : 'Level $level',
      child: Container(
        width: size,
        height: size,
        padding: EdgeInsets.all(size * .07),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: palette,
          ),
          boxShadow: [
            BoxShadow(
              color: palette.first.withValues(alpha: .28),
              blurRadius: size * .2,
            ),
          ],
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF17130D),
            border: Border.all(color: Colors.white24),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                mastery
                    ? Icons.workspace_premium_rounded
                    : tier >= 9
                    ? Icons.diamond_outlined
                    : tier >= 8
                    ? Icons.emoji_events_outlined
                    : tier >= 3
                    ? Icons.star_rounded
                    : Icons.bar_chart_rounded,
                color: const Color(0xFFF5C219),
                size: size * .27,
              ),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: size * .21,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
