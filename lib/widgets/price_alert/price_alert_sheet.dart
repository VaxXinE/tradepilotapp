import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/price_alert_provider.dart';

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
        _error = 'Masukkan target harga yang valid.';
      });

      return;
    }

    final note = _noteController.text.trim();

    if (note.length > 200) {
      setState(() {
        _error = 'Catatan maksimal 200 karakter.';
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
      _error = provider.error ?? 'Gagal membuat price alert.';
    });
  }

  @override
  Widget build(BuildContext context) {
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
                'Alert Harga ${widget.instrument}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                'Harga sekarang '
                '${_formatPrice(widget.instrument, widget.currentPrice)}',
                style: TextStyle(color: muted, fontSize: 12.5),
              ),

              const SizedBox(height: 18),

              const Text(
                'Beri tahu saya ketika harga...',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),

              const SizedBox(height: 10),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Naik melewati'),
                    selected: _triggerAbove,
                    onSelected: (_) {
                      setState(() {
                        _triggerAbove = true;
                      });
                    },
                  ),
                  ChoiceChip(
                    label: const Text('Turun melewati'),
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
                decoration: const InputDecoration(labelText: 'Target Harga'),
              ),

              const SizedBox(height: 12),

              TextField(
                controller: _noteController,
                maxLength: 200,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Catatan (opsional)',
                  hintText: 'Contoh: cek ulang kondisi market saat ini',
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
                      ? const SizedBox(
                          width: 17,
                          height: 17,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.notifications_active_outlined),
                  label: Text(
                    _submitting ? 'Menyimpan...' : 'Buat Alert Harga',
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
