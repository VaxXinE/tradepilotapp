import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:trade_pilot_api_client/trade_pilot_api_client.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/analysis_provider.dart';

class AnalysisDetailScreen
    extends StatefulWidget {
  const AnalysisDetailScreen({
    super.key,
    required this.analysisId,
    this.preloaded,
  });

  final int analysisId;
  final Analysis? preloaded;

  @override
  State<AnalysisDetailScreen>
      createState() =>
          _AnalysisDetailScreenState();
}

class _AnalysisDetailScreenState
    extends State<AnalysisDetailScreen> {
  Analysis? _analysis;

  bool _loading = true;
  bool _submittingFeedback = false;
  bool _detailRequestInFlight = false;

  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();

    _analysis = widget.preloaded;

    _load();

    _startOutcomePolling();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _pollTimer = null;

    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // OUTCOME POLLING
  // ---------------------------------------------------------------------------

  void _startOutcomePolling() {
    _pollTimer?.cancel();

    _pollTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) {
        final status =
            _analysis?.outcomeStatus;

        // Hanya request ke server saat analysis masih pending.
        //
        // Kalau sudah TP/SL/expired/invalidated, tidak ada alasan
        // terus-menerus polling.
        if (status ==
            AnalysisOutcomeStatusEnum.pending) {
          unawaited(
            _load(
              silent: true,
            ),
          );
        }
      },
    );
  }

  void _stopOutcomePollingIfResolved(
    Analysis analysis,
  ) {
    final status =
        analysis.outcomeStatus;

    if (status == null) {
      return;
    }

    if (status !=
        AnalysisOutcomeStatusEnum.pending) {
      _pollTimer?.cancel();
      _pollTimer = null;
    }
  }

  // ---------------------------------------------------------------------------
  // LOAD
  // ---------------------------------------------------------------------------

  Future<void> _load({
    bool silent = false,
  }) async {
    if (_detailRequestInFlight) {
      return;
    }

    _detailRequestInFlight = true;

    try {
      final provider =
          context.read<AnalysisProvider>();

      final result =
          await provider.getAnalysis(
        widget.analysisId,
        silent: silent,
      );

      if (!mounted) {
        return;
      }

      if (result != null) {
        _stopOutcomePollingIfResolved(
          result,
        );
      }

      setState(
        () {
          if (result != null) {
            _analysis = result;
          }

          _loading = false;
        },
      );
    } finally {
      _detailRequestInFlight = false;
    }
  }

  // ---------------------------------------------------------------------------
  // FEEDBACK
  // ---------------------------------------------------------------------------

  Future<void> _sendFeedback(
    FeedbackBodyFeedbackTypeEnum type,
  ) async {
    if (_submittingFeedback) {
      return;
    }

    setState(
      () {
        _submittingFeedback = true;
      },
    );

    final ok = await context
        .read<AnalysisProvider>()
        .submitFeedback(
          analysisId:
              widget.analysisId,
          type: type,
        );

    if (!mounted) {
      return;
    }

    setState(
      () {
        _submittingFeedback = false;
      },
    );

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Terima kasih atas feedback kamu!'
              : 'Gagal mengirim feedback.',
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    final muted = isDark
        ? AppColors.darkMutedForeground
        : AppColors.lightMutedForeground;

    if (_loading &&
        _analysis == null) {
      return const Scaffold(
        body: Center(
          child:
              CircularProgressIndicator(),
        ),
      );
    }

    final analysis = _analysis;

    if (analysis == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Text(
            'Analisis tidak ditemukan',
            style: TextStyle(
              color: muted,
            ),
          ),
        ),
      );
    }

    final isExpired =
        analysis.validUntil.isBefore(
      DateTime.now(),
    );

    final bias =
        (analysis.tradingBias ?? '')
            .toLowerCase();

    final biasColor =
        bias.contains('bull')
            ? (isDark
                ? AppColors.bullishDark
                : AppColors.bullishLight)
            : bias.contains('bear')
                ? (isDark
                    ? AppColors.bearishDark
                    : AppColors.bearishLight)
                : (isDark
                    ? AppColors.neutralDark
                    : AppColors.neutralLight);

    final biasLabel =
        bias.contains('bull')
            ? 'Bullish'
            : bias.contains('bear')
                ? 'Bearish'
                : 'Netral';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          analysis.instrument,
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics:
              const AlwaysScrollableScrollPhysics(),
          padding:
              const EdgeInsets.all(16),
          children: [
            _HeaderCard(
              analysis: analysis,
              biasColor: biasColor,
              biasLabel: biasLabel,
              isExpired: isExpired,
              muted: muted,
            ),

            const SizedBox(
              height: 16,
            ),

            // ---------------------------------------------------------------
            // OUTCOME STATUS
            // ---------------------------------------------------------------

            if (analysis.outcomeStatus !=
                null) ...[
              _OutcomeCard(
                analysis: analysis,
              ),
              const SizedBox(
                height: 16,
              ),
            ],

            // ---------------------------------------------------------------
            // SCENARIO
            // ---------------------------------------------------------------

            if (analysis.mainScenario !=
                null)
              _SectionCard(
                title:
                    'Skenario Utama',
                body:
                    analysis.mainScenario!,
              ),

            if (analysis
                    .alternativeScenario !=
                null) ...[
              const SizedBox(
                height: 12,
              ),
              _SectionCard(
                title:
                    'Skenario Alternatif',
                body: analysis
                    .alternativeScenario!,
              ),
            ],

            if (analysis.whyReason !=
                null) ...[
              const SizedBox(
                height: 12,
              ),
              _SectionCard(
                title: 'Alasan',
                body:
                    analysis.whyReason!,
              ),
            ],

            if (analysis
                    .failureConditions !=
                null) ...[
              const SizedBox(
                height: 12,
              ),
              _SectionCard(
                title:
                    'Kondisi Invalidasi',
                body: analysis
                    .failureConditions!,
                isWarning: true,
              ),
            ],

            // ---------------------------------------------------------------
            // TRADE PLAN
            // ---------------------------------------------------------------

            if (analysis.tradePlan !=
                null) ...[
              const SizedBox(
                height: 20,
              ),
              const Text(
                'Rencana Trading',
                style: TextStyle(
                  fontWeight:
                      FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              const SizedBox(
                height: 12,
              ),
              _TradePlanCard(
                plan:
                    analysis.tradePlan!,
                isDark: isDark,
              ),
            ],

            // ---------------------------------------------------------------
            // FEEDBACK
            // ---------------------------------------------------------------

            const SizedBox(
              height: 24,
            ),

            const Text(
              'Apakah analisis ini membantu?',
              style: TextStyle(
                fontWeight:
                    FontWeight.w700,
                fontSize: 14,
              ),
            ),

            const SizedBox(
              height: 10,
            ),

            Row(
              children: [
                Expanded(
                  child:
                      OutlinedButton.icon(
                    onPressed:
                        _submittingFeedback
                            ? null
                            : () {
                                _sendFeedback(
                                  FeedbackBodyFeedbackTypeEnum
                                      .useful,
                                );
                              },
                    icon: const Icon(
                      Icons
                          .thumb_up_alt_outlined,
                      size: 18,
                    ),
                    label: const Text(
                      'Membantu',
                    ),
                  ),
                ),

                const SizedBox(
                  width: 10,
                ),

                Expanded(
                  child:
                      OutlinedButton.icon(
                    onPressed:
                        _submittingFeedback
                            ? null
                            : () {
                                _sendFeedback(
                                  FeedbackBodyFeedbackTypeEnum
                                      .notUseful,
                                );
                              },
                    icon: const Icon(
                      Icons
                          .thumb_down_alt_outlined,
                      size: 18,
                    ),
                    label: const Text(
                      'Kurang Membantu',
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 24,
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// OUTCOME CARD
// =============================================================================

class _OutcomeCard extends StatelessWidget {
  const _OutcomeCard({
    required this.analysis,
  });

  final Analysis analysis;

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    final muted = isDark
        ? AppColors.darkMutedForeground
        : AppColors.lightMutedForeground;

    final bullishColor = isDark
        ? AppColors.bullishDark
        : AppColors.bullishLight;

    final bearishColor = isDark
        ? AppColors.bearishDark
        : AppColors.bearishLight;

    final neutralColor = isDark
        ? AppColors.neutralDark
        : AppColors.neutralLight;

    final status =
        analysis.outcomeStatus;

    late final String label;
    late final IconData icon;
    late final Color color;

    if (status ==
        AnalysisOutcomeStatusEnum.pending) {
      label = 'Menunggu hasil';
      icon = Icons.schedule_rounded;
      color = neutralColor;
    } else if (status ==
        AnalysisOutcomeStatusEnum.tp1Hit) {
      label = 'TP1 Tercapai';
      icon =
          Icons.trending_up_rounded;
      color = bullishColor;
    } else if (status ==
        AnalysisOutcomeStatusEnum.tp2Hit) {
      label = 'TP2 Tercapai';
      icon =
          Icons.rocket_launch_outlined;
      color = bullishColor;
    } else if (status ==
        AnalysisOutcomeStatusEnum.slHit) {
      label = 'Stop Loss Tersentuh';
      icon =
          Icons.trending_down_rounded;
      color = bearishColor;
    } else if (status ==
        AnalysisOutcomeStatusEnum.expired) {
      label = 'Kedaluwarsa';
      icon =
          Icons.timer_off_outlined;
      color = neutralColor;
    } else if (status ==
        AnalysisOutcomeStatusEnum
            .invalidated) {
      label = 'Analisis Tidak Valid';
      icon =
          Icons.warning_amber_rounded;
      color = bearishColor;
    } else {
      label = 'Status belum tersedia';
      icon = Icons.info_outline;
      color = muted;
    }

    return Card(
      child: Padding(
        padding:
            const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(
                  alpha: 0.15,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: 20,
              ),
            ),

            const SizedBox(
              width: 12,
            ),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [
                  Text(
                    'Status Hasil',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: muted,
                    ),
                  ),

                  const SizedBox(
                    height: 2,
                  ),

                  Text(
                    label,
                    style: TextStyle(
                      fontWeight:
                          FontWeight.w700,
                      color: color,
                    ),
                  ),

                  if (analysis
                          .outcomeResolvedAt !=
                      null) ...[
                    const SizedBox(
                      height: 3,
                    ),
                    Text(
                      DateFormat(
                        'd MMM yyyy, HH:mm',
                      ).format(
                        analysis
                            .outcomeResolvedAt!,
                      ),
                      style: TextStyle(
                        color: muted,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            if (status ==
                AnalysisOutcomeStatusEnum
                    .pending)
              SizedBox(
                width: 16,
                height: 16,
                child:
                    CircularProgressIndicator(
                  strokeWidth: 2,
                  color: color,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// HEADER
// =============================================================================

class _HeaderCard
    extends StatelessWidget {
  const _HeaderCard({
    required this.analysis,
    required this.biasColor,
    required this.biasLabel,
    required this.isExpired,
    required this.muted,
  });

  final Analysis analysis;
  final Color biasColor;
  final String biasLabel;
  final bool isExpired;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding:
            const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration:
                      BoxDecoration(
                    color:
                        biasColor.withValues(
                      alpha: 0.15,
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      999,
                    ),
                  ),
                  child: Text(
                    biasLabel,
                    style: TextStyle(
                      color: biasColor,
                      fontWeight:
                          FontWeight.w700,
                      fontSize: 12.5,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  analysis.timeframe,
                  style: TextStyle(
                    color: muted,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 14,
            ),

            if (analysis.confidenceMin !=
                    null &&
                analysis.confidenceMax !=
                    null) ...[
              Row(
                mainAxisAlignment:
                    MainAxisAlignment
                        .spaceBetween,
                children: [
                  Text(
                    'Keyakinan',
                    style: TextStyle(
                      color: muted,
                      fontSize: 12.5,
                    ),
                  ),
                  Text(
                    '${analysis.confidenceMin}% - '
                    '${analysis.confidenceMax}%',
                    style:
                        const TextStyle(
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height: 6,
              ),

              ClipRRect(
                borderRadius:
                    BorderRadius.circular(
                  999,
                ),
                child:
                    LinearProgressIndicator(
                  value: ((analysis
                                  .confidenceMax ??
                              0) /
                          100)
                      .clamp(0, 1)
                      .toDouble(),
                  minHeight: 8,
                  backgroundColor:
                      muted.withValues(
                    alpha: 0.15,
                  ),
                  valueColor:
                      AlwaysStoppedAnimation(
                    biasColor,
                  ),
                ),
              ),

              const SizedBox(
                height: 12,
              ),
            ],

            Row(
              children: [
                Icon(
                  Icons.schedule_rounded,
                  size: 15,
                  color: isExpired
                      ? biasColor
                      : muted,
                ),

                const SizedBox(
                  width: 6,
                ),

                Text(
                  isExpired
                      ? 'Kedaluwarsa'
                      : 'Berlaku sampai '
                          '${DateFormat('d MMM, HH:mm').format(analysis.validUntil)}',
                  style: TextStyle(
                    color: isExpired
                        ? Theme.of(context)
                            .colorScheme
                            .error
                        : muted,
                    fontSize: 12.5,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// SECTION
// =============================================================================

class _SectionCard
    extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.body,
    this.isWarning = false,
  });

  final String title;
  final String body;
  final bool isWarning;

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    final warnColor = isDark
        ? AppColors.bearishDark
        : AppColors.bearishLight;

    return Card(
      child: Padding(
        padding:
            const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (isWarning)
                  Icon(
                    Icons
                        .warning_amber_rounded,
                    size: 16,
                    color: warnColor,
                  ),
                if (isWarning)
                  const SizedBox(
                    width: 6,
                  ),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight:
                        FontWeight.w700,
                    fontSize: 13.5,
                    color: isWarning
                        ? warnColor
                        : null,
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 8,
            ),

            Text(
              body,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// TRADE PLAN
// =============================================================================

class _TradePlanCard
    extends StatelessWidget {
  const _TradePlanCard({
    required this.plan,
    required this.isDark,
  });

  final TradePlan plan;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final preferBuy =
        plan.preferredSide ==
            TradePlanPreferredSideEnum.buy;

    return Column(
      children: [
        _SideCard(
          side: plan.buy,
          label: 'Beli',
          color: isDark
              ? AppColors.bullishDark
              : AppColors.bullishLight,
          icon:
              Icons.trending_up_rounded,
          highlighted: preferBuy,
        ),

        const SizedBox(
          height: 10,
        ),

        _SideCard(
          side: plan.sell,
          label: 'Jual',
          color: isDark
              ? AppColors.bearishDark
              : AppColors.bearishLight,
          icon:
              Icons.trending_down_rounded,
          highlighted: !preferBuy,
        ),
      ],
    );
  }
}

class _SideCard
    extends StatelessWidget {
  const _SideCard({
    required this.side,
    required this.label,
    required this.color,
    required this.icon,
    required this.highlighted,
  });

  final TradeSide side;
  final String label;
  final Color color;
  final IconData icon;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness ==
            Brightness.dark;

    final muted = isDark
        ? AppColors.darkMutedForeground
        : AppColors.lightMutedForeground;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(
          AppColors.radius,
        ),
        side: BorderSide(
          color: highlighted
              ? color
              : (isDark
                  ? AppColors.darkBorder
                  : AppColors.lightBorder),
          width:
              highlighted ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding:
            const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: color,
                ),

                const SizedBox(
                  width: 6,
                ),

                Text(
                  label,
                  style: TextStyle(
                    fontWeight:
                        FontWeight.w800,
                    color: color,
                  ),
                ),

                if (highlighted) ...[
                  const SizedBox(
                    width: 8,
                  ),
                  Container(
                    padding:
                        const EdgeInsets
                            .symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration:
                        BoxDecoration(
                      color:
                          color.withValues(
                        alpha: 0.15,
                      ),
                      borderRadius:
                          BorderRadius
                              .circular(
                        999,
                      ),
                    ),
                    child: Text(
                      'Direkomendasikan',
                      style: TextStyle(
                        fontSize: 10,
                        color: color,
                        fontWeight:
                            FontWeight
                                .w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),

            const SizedBox(
              height: 10,
            ),

            _row(
              'Zona Entry',
              side.entryZone,
              muted,
            ),

            _row(
              'Stop Loss',
              side.stopLoss,
              muted,
            ),

            _row(
              'Take Profit 1',
              side.takeProfit1,
              muted,
            ),

            _row(
              'Take Profit 2',
              side.takeProfit2,
              muted,
            ),

            _row(
              'Risiko : Reward',
              side.riskRewardRatio,
              muted,
            ),

            const SizedBox(
              height: 8,
            ),

            Text(
              side.rationale,
              style: TextStyle(
                fontSize: 12.5,
                color: muted,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(
    String label,
    String value,
    Color muted,
  ) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 3,
      ),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment
                .spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              color: muted,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight:
                  FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}