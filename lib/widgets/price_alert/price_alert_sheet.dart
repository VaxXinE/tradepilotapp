import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/price_alert_provider.dart';
import '../../l10n/l10n.dart';

Future<bool?> showPriceAlertSheet({
  required BuildContext context,
  required String instrument,
  required double currentPrice,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) {
      return _PriceAlertSheet(
        instrument: instrument,
        currentPrice: currentPrice,
      );
    },
  );
}

class _PriceAlertSheet extends StatefulWidget {
  const _PriceAlertSheet({
    required this.instrument,
    required this.currentPrice,
  });

  final String instrument;
  final double currentPrice;

  @override
  State<_PriceAlertSheet> createState() => _PriceAlertSheetState();
}

class _PriceAlertSheetState extends State<_PriceAlertSheet> {
  late final TextEditingController _priceController;

  final TextEditingController _noteController = TextEditingController();

  bool _triggerAbove = true;
  bool _submitting = false;

  String? _error;

  @override
  void initState() {
    super.initState();

    _priceController = TextEditingController(
      text: _priceForInput(widget.currentPrice),
    );
  }

  @override
  void dispose() {
    _priceController.dispose();
    _noteController.dispose();

    super.dispose();
  }

  Future<void> _create() async {
    if (_submitting) {
      return;
    }

    final normalized = _priceController.text.trim().replaceAll(',', '.');

    final targetPrice = double.tryParse(normalized);

    if (targetPrice == null || !targetPrice.isFinite || targetPrice <= 0) {
      setState(() {
        _error = context.l10n.invalidTargetPrice;
      });

      return;
    }

    final note = _noteController.text.trim();

    if (note.length > 200) {
      setState(() {
        _error = context.l10n.noteMaximumCharacters;
      });

      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    final provider = context.read<PriceAlertProvider>();

    final ok = await provider.createAlert(
      instrument: widget.instrument,
      targetPrice: targetPrice,
      triggerAbove: _triggerAbove,
      note: note.isEmpty ? null : note,
    );

    if (!mounted) {
      return;
    }

    if (ok) {
      Navigator.of(context).pop(true);
      return;
    }

    setState(() {
      _submitting = false;
      _error = provider.error ?? context.l10n.priceAlertCreateFailed;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 4, 20, 20 + bottomInset),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.priceAlertTitle(widget.instrument),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                l10n.currentMarketPrice(
                  _formatPrice(widget.instrument, widget.currentPrice),
                ),
                style: TextStyle(color: muted, fontSize: 12.5),
              ),

              const SizedBox(height: 18),

              Text(
                l10n.notifyWhenPrice,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),

              const SizedBox(height: 10),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    label: Text(l10n.risesAbove),
                    selected: _triggerAbove,
                    onSelected: (_) {
                      setState(() {
                        _triggerAbove = true;
                      });
                    },
                  ),
                  ChoiceChip(
                    label: Text(l10n.fallsBelow),
                    selected: !_triggerAbove,
                    onSelected: (_) {
                      setState(() {
                        _triggerAbove = false;
                      });
                    },
                  ),
                ],
              ),

              const SizedBox(height: 16),

              TextField(
                controller: _priceController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(labelText: l10n.targetPrice),
              ),

              const SizedBox(height: 12),

              TextField(
                controller: _noteController,
                maxLength: 200,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: l10n.optionalNote,
                  hintText: l10n.priceAlertNoteHint,
                ),
              ),

              if (_error != null) ...[
                const SizedBox(height: 4),
                Text(
                  _error!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 12,
                  ),
                ),
              ],

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _submitting ? null : _create,
                  icon: _submitting
                      ? SizedBox(
                          width: 17,
                          height: 17,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        )
                      : const Icon(Icons.notifications_active_outlined),
                  label: Text(
                    _submitting ? l10n.saving : l10n.createPriceAlertButton,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _priceForInput(double value) {
    if (value >= 1000) {
      return value.toStringAsFixed(2);
    }

    if (value >= 1) {
      return value.toStringAsFixed(4);
    }

    return value.toStringAsFixed(6);
  }
}

String _formatPrice(String instrument, double value) {
  if (instrument == 'USD/IDR') {
    return value.toStringAsFixed(0);
  }

  if (instrument == 'USD/JPY') {
    return value.toStringAsFixed(2);
  }

  if (value >= 1000) {
    return value.toStringAsFixed(2);
  }

  if (value >= 100) {
    return value.toStringAsFixed(2);
  }

  if (value >= 1) {
    return value.toStringAsFixed(4);
  }

  return value.toStringAsFixed(6);
}
