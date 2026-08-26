import 'package:flutter/material.dart';

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
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final timeframe in timeframes)
          ChoiceChip(
            key: ValueKey('timeframe-$timeframe'),
            label: Text(timeframe),
            selected: timeframe == selected,
            onSelected: isLoading
                ? null
                : (_) {
                    if (timeframe != selected) onSelected(timeframe);
                  },
          ),
      ],
    );
  }
}
