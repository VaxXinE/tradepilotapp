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
    final primary = Theme.of(context).colorScheme.primary;
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
            colors: [primary, const Color(0xFFF59E0B)],
          ),
          boxShadow: [
            BoxShadow(
              color: primary.withValues(alpha: .28),
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
                masteryLevel > 0
                    ? Icons.workspace_premium_rounded
                    : Icons.navigation_rounded,
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
