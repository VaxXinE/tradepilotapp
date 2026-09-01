import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/price_alert_provider.dart';
import '../../widgets/price_alert/price_alert_card.dart';

class PriceAlertListScreen extends StatefulWidget {
  const PriceAlertListScreen({super.key});

  @override
  State<PriceAlertListScreen> createState() => _PriceAlertListScreenState();
}

class _PriceAlertListScreenState extends State<PriceAlertListScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      unawaited(context.read<PriceAlertProvider>().loadAlerts());
    });
  }

  Future<void> _handleDelete(int id) async {
    final provider = context.read<PriceAlertProvider>();

    final ok = await provider.deleteAlert(id);

    if (!mounted) {
      return;
    }

    if (!ok && provider.error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(provider.error!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PriceAlertProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Price Alert Saya')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: provider.loadAlerts,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              PriceAlertCard(
                alerts: provider.alerts,
                isLoading: provider.isLoading,
                hasError: provider.hasError,
                onRetry: () {
                  unawaited(provider.loadAlerts());
                },
                isDeleting: provider.isDeleting,
                onDelete: (id) {
                  unawaited(_handleDelete(id));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
