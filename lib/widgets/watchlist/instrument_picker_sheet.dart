import 'package:flutter/material.dart';

import '../../providers/market_provider.dart';
import '../../l10n/l10n.dart';

class InstrumentPickerSheet extends StatefulWidget {
  const InstrumentPickerSheet({
    super.key,
    required this.onSelected,
    this.existingInstruments = const {},
    this.selectedInstrument,
    this.title,
  });

  final Future<void> Function(String instrument) onSelected;

  final Set<String> existingInstruments;
  final String? selectedInstrument;
  final String? title;

  static Future<void> show(
    BuildContext context, {
    required Future<void> Function(String instrument) onSelected,
    Set<String> existingInstruments = const {},
    String? selectedInstrument,
    String? title,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return InstrumentPickerSheet(
          onSelected: onSelected,
          existingInstruments: existingInstruments,
          selectedInstrument: selectedInstrument,
          title: title,
        );
      },
    );
  }

  @override
  State<InstrumentPickerSheet> createState() => _InstrumentPickerSheetState();
}

class _InstrumentPickerSheetState extends State<InstrumentPickerSheet> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    final filteredGroups = MarketProvider.instrumentGroups.map((
      category,
      instruments,
    ) {
      final filtered = instruments.where((item) {
        if (query.trim().isEmpty) {
          return true;
        }

        return item.toLowerCase().contains(query.toLowerCase());
      }).toList();

      return MapEntry(category, filtered);
    });

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),

        child: SizedBox(
          height: MediaQuery.of(context).size.height * .75,

          child: Column(
            children: [
              const SizedBox(height: 12),

              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              const SizedBox(height: 16),

              Text(
                widget.title ?? context.l10n.addInstrument,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(16),

                child: TextField(
                  decoration: InputDecoration(
                    hintText: context.l10n.searchInstrument,
                    prefixIcon: const Icon(Icons.search),
                  ),
                  textCapitalization: TextCapitalization.characters,
                  autocorrect: false,

                  onChanged: (value) {
                    setState(() {
                      query = value;
                    });
                  },
                ),
              ),

              Expanded(
                child: ListView(
                  children: filteredGroups.entries.expand<Widget>((entry) {
                    if (entry.value.isEmpty) {
                      return const <Widget>[];
                    }

                    return [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),

                        child: Text(
                          entry.key,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),

                      ...entry.value.map((instrument) {
                        final exists = widget.existingInstruments.contains(
                          instrument,
                        );
                        final selected =
                            widget.selectedInstrument == instrument;

                        return ListTile(
                          title: Text(instrument),

                          trailing: exists || selected
                              ? const Icon(Icons.check)
                              : const Icon(Icons.add),

                          enabled: !exists && !selected,

                          onTap: exists || selected
                              ? null
                              : () async {
                                  await widget.onSelected(instrument);

                                  if (context.mounted) {
                                    Navigator.pop(context);
                                  }
                                },
                        );
                      }),
                    ];
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
