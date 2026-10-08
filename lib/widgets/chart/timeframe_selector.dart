import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Baris timeframe satu-baris, lebar terbagi rata (bukan `Wrap` yang bisa
/// turun baris) — meniru tombol timeframe web: pill gelap berbingkai saat
/// tidak aktif, terisi emas + centang saat aktif.
class TimeframeSelector extends StatelessWidget {
  const TimeframeSelector({
    super.key,
    required this.timeframes,
    required this.selected,
    required this.onSelected,
    this.isLoading = false,
  });

  final List<String> timeframes;
  final String selected;
  final ValueChanged<String> onSelected;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final timeframe in timeframes) ...[
          if (timeframe != timeframes.first) const SizedBox(width: 6),
          Expanded(
            child: _TimeframePill(
              key: ValueKey('timeframe-$timeframe'),
              label: timeframe,
              selected: timeframe == selected,
              onTap: isLoading
                  ? null
                  : () {
                      if (timeframe != selected) onSelected(timeframe);
                    },
            ),
          ),
        ],
      ],
    );
  }
}

class _TimeframePill extends StatelessWidget {
  const _TimeframePill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final disabled = onTap == null;

    return Semantics(
      button: true,
      selected: selected,
      enabled: !disabled,
      child: Opacity(
        opacity: disabled && !selected ? 0.5 : 1,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppColors.radiusLg),
          child: Container(
            constraints: const BoxConstraints(minHeight: 44),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? colors.primary : colors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(AppColors.radiusLg),
              border: Border.all(
                color: selected ? colors.primary : colors.outlineVariant,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (selected) ...[
                  Icon(Icons.check_rounded, size: 14, color: colors.onPrimary),
                  const SizedBox(width: 3),
                ],
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                      color: selected
                          ? colors.onPrimary
                          : colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
