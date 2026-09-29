import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/l10n.dart';
import '../../providers/credit_provider.dart';
import '../../widgets/responsive_page.dart';

class CreditsScreen extends StatefulWidget {
  const CreditsScreen({super.key});

  @override
  State<CreditsScreen> createState() => _CreditsScreenState();
}

class _CreditsScreenState extends State<CreditsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(context.read<CreditProvider>().loadBalance());
    });
  }

  @override
  Widget build(BuildContext context) {
    final credit = context.watch<CreditProvider>();
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.profileAnalysisCredits)),
      body: RefreshIndicator(
        onRefresh: credit.loadBalance,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: responsivePagePadding(context),
          children: [
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: colors.primary.withValues(alpha: .12),
                      child: Icon(
                        Icons.account_balance_wallet_outlined,
                        color: colors.primary,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.l10n.creditBalance,
                            style: TextStyle(color: colors.onSurfaceVariant),
                          ),
                          const SizedBox(height: 4),
                          if (credit.isLoadingBalance && !credit.hasBalance)
                            const SizedBox.square(
                              dimension: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          else
                            Text(
                              '${credit.balance ?? 0}',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (credit.balanceError != null) ...[
              const SizedBox(height: 12),
              Text(credit.balanceError!, style: TextStyle(color: colors.error)),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: credit.loadBalance,
                  child: Text(context.l10n.tryAgain),
                ),
              ),
            ],
            const SizedBox(height: 20),
            Text(
              context.l10n.analysisCreditsDescription,
              style: TextStyle(color: colors.onSurfaceVariant, height: 1.5),
            ),
            const SizedBox(height: 12),
            Text(
              context.l10n.mobileCreditPurchaseUnavailable,
              style: const TextStyle(fontWeight: FontWeight.w600, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
