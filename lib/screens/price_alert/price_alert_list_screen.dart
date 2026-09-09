import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/l10n.dart';
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
      appBar: AppBar(title: Text(context.l10n.myPriceAlerts)),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: provider.loadAlerts,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Icon(
                    Icons.notifications_active_outlined,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      context.l10n.myPriceAlerts,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                context.l10n.priceAlertsSubtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
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
