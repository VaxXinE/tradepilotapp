import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:trade_pilot_api_client/trade_pilot_api_client.dart';

import '../../../core/theme/app_colors.dart';
import '../../../l10n/l10n.dart';
import '../../../core/history/history_statistics.dart';
import '../../../models/history_filters.dart';
import '../../../providers/analysis_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/market_provider.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/history/history_analysis_card.dart';
import '../../../widgets/history/history_summary_card.dart';
import '../../analysis/analysis_detail_screen.dart';

class HistoryTab extends StatefulWidget {
  const HistoryTab({super.key, this.onReanalyze, this.onNewAnalysis});

  final void Function(String instrument, String timeframe)? onReanalyze;

  /// Membuka form analisis baru tanpa mengunci instrumen apa pun, sehingga
  /// trader bebas memilih simbol lain (BRENT, NIKKEI, HSI, ...).
  final VoidCallback? onNewAnalysis;

  @override
  State<HistoryTab> createState() => _HistoryTabState();
}

enum _HistoryPresetAction { open, save }

class _HistoryTabState extends State<HistoryTab> {
  final TextEditingController _searchController = TextEditingController();

  Timer? _searchDebounce;
  List<FilterPreset> _presets = const [];
  bool _loadingPresets = false;
  bool _summaryView = true;
  String _summaryRange = '30';
  String _focusedInstrument = 'XAU/USD';
  int _listPage = 1;
  static const _itemsPerPage = 5;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      final filters = context.read<AnalysisProvider>().historyFilters;

      _searchController.text = filters.query;
      unawaited(_loadPresets());
      unawaited(
        context.read<AnalysisProvider>().loadHistoryOutcomeSummary(
          range: _summaryRange,
        ),
      );
    });
  }

  Future<void> _loadPresets() async {
    if (_loadingPresets) return;
    setState(() => _loadingPresets = true);
    try {
      final response = await context
          .read<AuthProvider>()
          .client
          .filterPresets
          .listFilterPresets();
      if (mounted) {
        setState(() => _presets = response.data?.presets.toList() ?? const []);
      }
    } catch (_) {
      if (mounted) _showPresetError();
    } finally {
      if (mounted) setState(() => _loadingPresets = false);
    }
  }

  Future<void> _savePreset() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.saveBasicFilter),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.basicFilterExplanation,
              style: Theme.of(dialogContext).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              maxLength: 60,
              decoration: InputDecoration(labelText: context.l10n.presetName),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: Text(context.l10n.save),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.isEmpty || !mounted) return;
    final filters = context
        .read<AnalysisProvider>()
        .historyFilters
        .normalized();
    try {
      await context
          .read<AuthProvider>()
          .client
          .filterPresets
          .createFilterPreset(
            createFilterPresetBody: CreateFilterPresetBody((builder) {
              builder
                ..name = name
                ..filters.mode = switch (filters.mode) {
                  HistoryModeFilter.beginner =>
                    FilterPresetFiltersModeEnum.beginner,
                  HistoryModeFilter.pro => FilterPresetFiltersModeEnum.pro,
                  HistoryModeFilter.all => FilterPresetFiltersModeEnum.empty,
                }
                ..filters.instruments.addAll(filters.instruments)
                ..filters.timeframes.addAll(filters.timeframes)
                ..filters.from = filters.from == null
                    ? ''
                    : DateFormat('yyyy-MM-dd').format(filters.from!)
                ..filters.to = filters.to == null
                    ? ''
                    : DateFormat('yyyy-MM-dd').format(filters.to!)
                ..filters.q = filters.query;
            }),
          );
      if (!mounted) return;
      await _loadPresets();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.filterPresetSaved)));
      }
    } catch (_) {
      if (mounted) _showPresetError();
    }
  }

  Future<void> _showPresets() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(sheetContext).height * 0.62,
          child: Column(
            children: [
              ListTile(title: Text(context.l10n.savedFilters)),
              const Divider(height: 1),
              Expanded(
                child: _presets.isEmpty
                    ? Center(child: Text(context.l10n.noSavedFilters))
                    : ListView.builder(
                        itemCount: _presets.length,
                        itemBuilder: (_, index) {
                          final preset = _presets[index];
                          return ListTile(
                            title: Text(preset.name),
                            onTap: () {
                              Navigator.pop(sheetContext);
                              _applyPreset(preset);
                            },
                            trailing: IconButton(
                              tooltip: context.l10n.delete,
                              icon: const Icon(Icons.delete_outline_rounded),
                              onPressed: () async {
                                final confirmed = await showDialog<bool>(
                                  context: sheetContext,
                                  builder: (dialogContext) => AlertDialog(
                                    title: Text(context.l10n.delete),
                                    content: Text(preset.name),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(dialogContext, false),
                                        child: Text(context.l10n.cancel),
                                      ),
                                      FilledButton(
                                        onPressed: () =>
                                            Navigator.pop(dialogContext, true),
                                        child: Text(context.l10n.delete),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirmed != true ||
                                    !mounted ||
                                    !sheetContext.mounted) {
                                  return;
                                }
                                try {
                                  await context
                                      .read<AuthProvider>()
                                      .client
                                      .filterPresets
                                      .deleteFilterPreset(id: preset.id);
                                  if (!mounted || !sheetContext.mounted) return;
                                  Navigator.pop(sheetContext);
                                  await _loadPresets();
                                } catch (_) {
                                  if (mounted) _showPresetError();
                                }
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _applyPreset(FilterPreset preset) async {
    final saved = preset.filters;
    final filters = HistoryFilters(
      query: saved.q,
      mode: saved.mode == FilterPresetFiltersModeEnum.beginner
          ? HistoryModeFilter.beginner
          : saved.mode == FilterPresetFiltersModeEnum.pro
          ? HistoryModeFilter.pro
          : HistoryModeFilter.all,
      instruments: saved.instruments.toList(),
      timeframes: saved.timeframes.toList(),
      from: DateTime.tryParse(saved.from),
      to: DateTime.tryParse(saved.to),
    );
    _searchController.text = saved.q;
    await context.read<AnalysisProvider>().applyHistoryFilters(filters);
  }

  void _showPresetError() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.l10n.filterPresetFailed)));
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();

    _searchController.dispose();

    super.dispose();
  }

  // ===========================================================================
  // SEARCH
  // ===========================================================================

  void _handleSearchChanged(String raw) {
    _searchDebounce?.cancel();

    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) {
        return;
      }

      var query = raw.trim();

      if (query.length > HistoryFilters.maxSearchLength) {
        query = query.substring(0, HistoryFilters.maxSearchLength);
      }

      final provider = context.read<AnalysisProvider>();

      if (provider.historyFilters.query == query) {
        return;
      }

      setState(() => _listPage = 1);

      unawaited(
        provider.applyHistoryFilters(
          provider.historyFilters.copyWith(query: query),
        ),
      );
    });
  }

  Future<void> _clearSearch() async {
    _searchDebounce?.cancel();

    _searchController.clear();
    setState(() => _listPage = 1);

    final provider = context.read<AnalysisProvider>();

    await provider.applyHistoryFilters(
      provider.historyFilters.copyWith(query: ''),
    );
  }

  // ===========================================================================
  // FILTER SHEET
  // ===========================================================================

  Future<void> _openFilters() async {
    final provider = context.read<AnalysisProvider>();

    final result = await showModalBottomSheet<HistoryFilters>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) {
        return _HistoryFilterSheet(initial: provider.historyFilters);
      },
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() => _listPage = 1);
    await provider.applyHistoryFilters(result);
  }

  Future<void> _resetFilters() async {
    _searchDebounce?.cancel();

    _searchController.clear();

    setState(() => _listPage = 1);

    await context.read<AnalysisProvider>().applyHistoryFilters(
      const HistoryFilters(),
    );
  }

  Future<void> _goToNextPage(AnalysisProvider provider) async {
    final totalPages =
        (provider.visibleHistoryTotal + _itemsPerPage - 1) ~/ _itemsPerPage;
    if (_listPage >= totalPages) return;
    final nextPage = _listPage + 1;
    if (provider.visibleHistory.length < nextPage * _itemsPerPage) {
      await provider.loadMoreVisibleHistory();
    }
    if (mounted) setState(() => _listPage = nextPage);
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final muted = isDark
        ? AppColors.darkMutedForeground
        : AppColors.lightMutedForeground;

    final provider = context.watch<AnalysisProvider>();

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () {
          final provider = context.read<AnalysisProvider>();
          return Future.wait([
            if (!_summaryView) provider.refreshVisibleHistory(silent: false),
            provider.loadHistoryOutcomeSummary(range: _summaryRange),
          ]);
        },
        child: _summaryView
            ? _buildSummaryContent(provider, muted)
            : _buildContent(context: context, provider: provider, muted: muted),
      ),
    );
  }

  Widget _buildPageHeader(AnalysisProvider provider, Color muted) {
    final filters = provider.historyFilters;
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.historyPageTitle,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 2),
        Text(
          provider.visibleHistoryTotal > 0
              ? l10n.historyTotalAnalyses(provider.visibleHistoryTotal)
              : l10n.noAnalyses,
          style: TextStyle(fontSize: 12, color: muted),
        ),
        const SizedBox(height: 12),
        _HistoryViewTabs(
          summarySelected: _summaryView,
          summaryLabel: l10n.historySummary,
          historyLabel: l10n.historyListTab,
          onChanged: (summary) => setState(() {
            _summaryView = summary;
            if (!summary) _listPage = 1;
          }),
        ),
        if (!_summaryView) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: _handleSearchChanged,
                  maxLength: HistoryFilters.maxSearchLength,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: l10n.searchInstrumentOrNote,
                    prefixIcon: const Icon(Icons.search_rounded, size: 18),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    suffixIcon: filters.query.isEmpty
                        ? null
                        : IconButton(
                            tooltip: l10n.clearSearch,
                            onPressed: _clearSearch,
                            icon: const Icon(Icons.close_rounded),
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _openFilters,
                icon: const Icon(Icons.filter_alt_outlined, size: 17),
                label: Text(
                  filters.activeCategoryCount == 0
                      ? l10n.historyFiltersButton
                      : '${l10n.historyFiltersButton} ${filters.activeCategoryCount}',
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
              if (_presets.isNotEmpty || filters.isActive)
                PopupMenuButton<_HistoryPresetAction>(
                  tooltip: l10n.basicFilters,
                  enabled: !_loadingPresets,
                  icon: const Icon(Icons.more_vert_rounded),
                  onSelected: (action) {
                    if (action == _HistoryPresetAction.open) {
                      unawaited(_showPresets());
                    } else {
                      unawaited(_savePreset());
                    }
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: _HistoryPresetAction.open,
                      child: Text(l10n.savedFilters),
                    ),
                    PopupMenuItem(
                      value: _HistoryPresetAction.save,
                      child: Text(l10n.saveBasicFilter),
                    ),
                  ],
                ),
            ],
          ),
          if (filters.isActive)
            _ActiveFilters(
              filters: filters,
              resultCount: provider.visibleHistoryTotal,
              onChanged: (next) {
                setState(() => _listPage = 1);
                unawaited(provider.applyHistoryFilters(next));
              },
              onReset: _resetFilters,
            ),
          if (provider.isLoadingVisibleHistory &&
              provider.visibleHistory.isNotEmpty)
            const LinearProgressIndicator(minHeight: 2),
          if (provider.visibleHistoryError != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: ErrorBanner(
                message: provider.visibleHistoryError,
                retryLabel: l10n.tryAgain,
                onRetry: () {
                  unawaited(provider.refreshVisibleHistory(silent: false));
                },
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildContent({
    required BuildContext context,
    required AnalysisProvider provider,
    required Color muted,
  }) {
    final items = provider.visibleHistory;

    if (items.isEmpty && provider.isLoadingVisibleHistory) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.all(16),
        children: [
          _buildPageHeader(provider, muted),
          SizedBox(height: MediaQuery.sizeOf(context).height * 0.28),
          const Center(child: CircularProgressIndicator(strokeWidth: 2.4)),
        ],
      );
    }

    if (items.isEmpty) {
      final filtered = provider.hasActiveHistoryFilters;

      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.all(16),
        children: [
          _buildPageHeader(provider, muted),
          SizedBox(height: MediaQuery.sizeOf(context).height * 0.1),
          Icon(
            filtered ? Icons.search_off_rounded : Icons.history_rounded,
            size: 42,
            color: muted,
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              filtered
                  ? context.l10n.noMatchingAnalyses
                  : context.l10n.noAnalyses,
              style: TextStyle(color: muted, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 5),
          Center(
            child: Text(
              filtered
                  ? context.l10n.changeSearchOrFilter
                  : context.l10n.analysesAppearHere,
              textAlign: TextAlign.center,
              style: TextStyle(color: muted, fontSize: 12),
            ),
          ),

          if (filtered) ...[
            const SizedBox(height: 10),
            Center(
              child: TextButton(
                onPressed: _resetFilters,
                child: Text(context.l10n.resetFilter),
              ),
            ),
          ] else if (widget.onNewAnalysis != null) ...[
            const SizedBox(height: 14),
            Center(
              child: FilledButton.icon(
                key: const Key('history-empty-new-analysis'),
                onPressed: widget.onNewAnalysis,
                icon: const Icon(Icons.add_rounded),
                label: Text(context.l10n.analyzeTitle),
              ),
            ),
          ],
        ],
      );
    }

    final total = provider.visibleHistoryTotal;
    final totalPages = (total + _itemsPerPage - 1) ~/ _itemsPerPage;
    final page = _listPage.clamp(1, totalPages == 0 ? 1 : totalPages);
    final start = (page - 1) * _itemsPerPage;
    final pageItems = start >= items.length
        ? const <Analysis>[]
        : items.skip(start).take(_itemsPerPage).toList();
    final end = start + pageItems.length;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.all(16),
      children: [
        _buildPageHeader(provider, muted),
        const SizedBox(height: 12),
        for (final analysis in pageItems) ...[
          HistoryAnalysisCard(
            analysis: analysis,
            onReanalyze: widget.onReanalyze == null
                ? null
                : () => widget.onReanalyze!(
                    analysis.instrument,
                    analysis.timeframe,
                  ),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AnalysisDetailScreen(
                    analysisId: analysis.id,
                    preloaded: analysis,
                    onNewAnalysis: widget.onNewAnalysis == null
                        ? null
                        : () {
                            Navigator.of(context).pop();
                            widget.onNewAnalysis!();
                          },
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 10),
        ],
        _HistoryPagination(
          page: page,
          totalPages: totalPages == 0 ? 1 : totalPages,
          start: total == 0 ? 0 : start + 1,
          end: end,
          total: total,
          loading: provider.isLoadingMoreVisibleHistory,
          onPrevious: page == 1
              ? null
              : () => setState(() => _listPage = page - 1),
          onNext: page >= totalPages
              ? null
              : () => unawaited(_goToNextPage(provider)),
        ),
      ],
    );
  }

  Widget _buildHistorySummary(AnalysisProvider provider) {
    final summary = provider.historyOutcomeSummary;
    if (summary != null) {
      return HistorySummaryCard(
        statistics: HistoryStatistics.fromOutcomeStats(summary.overall),
        onMetricTap: (metric) {
          final outcome = switch (metric) {
            HistorySummaryMetric.valid => HistoryOutcomeFilter.pending,
            HistorySummaryMetric.expired => HistoryOutcomeFilter.expired,
            HistorySummaryMetric.sl => HistoryOutcomeFilter.riskLimitHit,
            HistorySummaryMetric.tp1 ||
            HistorySummaryMetric.tp2 => HistoryOutcomeFilter.targetReached,
            HistorySummaryMetric.invalid => HistoryOutcomeFilter.invalidated,
            HistorySummaryMetric.total => HistoryOutcomeFilter.all,
          };
          _showHistoryFor(outcome: outcome);
        },
      );
    }
    if (provider.historyOutcomeSummaryError != null) {
      return ErrorBanner(
        message: provider.historyOutcomeSummaryError,
        retryLabel: context.l10n.tryAgain,
        onRetry: () {
          unawaited(provider.loadHistoryOutcomeSummary(range: _summaryRange));
        },
      );
    }
    return const Card(
      child: SizedBox(
        height: 96,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2.4)),
      ),
    );
  }

  Widget _buildSummaryContent(AnalysisProvider provider, Color muted) {
    final summary = provider.historyOutcomeSummary;
    final instrumentRows = summary == null
        ? const <_HistoryBreakdownRow>[]
        : _instrumentRows(summary);
    final selected = instrumentRows.where(
      (row) => row.label == _focusedInstrument,
    );
    final selectedInstrument = selected.isEmpty ? null : selected.first;
    final timeframeRows = summary == null
        ? const <_HistoryBreakdownRow>[]
        : _timeframeRows(summary, selectedInstrument);
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        _buildPageHeader(provider, muted),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final range in const ['7', '30', '90', 'all']) ...[
                _RangeButton(
                  label: range == 'all' ? context.l10n.all : '${range}D',
                  selected: _summaryRange == range,
                  onTap: () {
                    setState(() => _summaryRange = range);
                    unawaited(provider.loadHistoryOutcomeSummary(range: range));
                  },
                ),
                if (range != 'all') const SizedBox(width: 7),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        _buildHistorySummary(provider),
        if (summary != null) ...[
          const SizedBox(height: 12),
          _HistoryInsights(rows: timeframeRows, minSamples: summary.minSamples),
          const SizedBox(height: 12),
          _InstrumentPerformanceCard(
            minSamples: summary.minSamples,
            rows: instrumentRows,
            focused: _focusedInstrument,
            onFocus: (instrument) =>
                setState(() => _focusedInstrument = instrument),
            onViewHistory: (row) =>
                _showHistoryFor(instruments: row.filterInstruments),
          ),
          const SizedBox(height: 12),
          _TimeframePerformanceCard(
            instrument: selectedInstrument?.label,
            minSamples: summary.minSamples,
            rows: timeframeRows,
            onTap: (row) => _showHistoryFor(
              instruments: selectedInstrument?.filterInstruments,
              timeframes: [row.label],
            ),
          ),
        ],
      ],
    );
  }

  void _showHistoryFor({
    HistoryOutcomeFilter outcome = HistoryOutcomeFilter.all,
    List<String>? instruments,
    List<String>? timeframes,
  }) {
    final days = int.tryParse(_summaryRange);
    final from = days == null
        ? null
        : DateTime.now().subtract(Duration(days: days));
    final filters = HistoryFilters(
      outcome: outcome,
      instruments: instruments ?? const [],
      timeframes: timeframes ?? const [],
      from: from,
    );
    setState(() {
      _summaryView = false;
      _listPage = 1;
      _searchController.clear();
    });
    unawaited(context.read<AnalysisProvider>().applyHistoryFilters(filters));
  }

  List<_HistoryBreakdownRow> _instrumentRows(AnalysisHistorySummary summary) {
    final rows = <_HistoryBreakdownRow>[];
    var otherTotal = 0;
    var otherActive = 0;
    var otherTp1 = 0;
    var otherTp2 = 0;
    var otherSl = 0;
    var otherExpired = 0;
    var otherInvalid = 0;
    final otherInstruments = <String>[];
    for (final row in summary.byInstrument) {
      if (MarketProvider.analyzeVisibleInstruments.contains(row.instrument)) {
        rows.add(
          _HistoryBreakdownRow(
            label: row.instrument,
            total: row.total,
            activeValid: row.activeValid,
            tp1: row.tp1Hit,
            tp2: row.tp2Hit,
            sl: row.slHit,
            expired: row.expired,
            invalidated: row.invalidated,
            winRate: row.winRate,
            completionRate: row.completionRate,
            filterInstruments: [row.instrument],
          ),
        );
      } else {
        otherTotal += row.total;
        otherActive += row.activeValid;
        otherTp1 += row.tp1Hit;
        otherTp2 += row.tp2Hit;
        otherSl += row.slHit;
        otherExpired += row.expired;
        otherInvalid += row.invalidated;
        otherInstruments.add(row.instrument);
      }
    }
    if (otherTotal > 0) {
      final wins = otherTp1 + otherTp2;
      final evaluated = wins + otherSl;
      final completed = evaluated + otherExpired;
      rows.add(
        _HistoryBreakdownRow(
          label: context.l10n.otherInstruments,
          total: otherTotal,
          activeValid: otherActive,
          tp1: otherTp1,
          tp2: otherTp2,
          sl: otherSl,
          expired: otherExpired,
          invalidated: otherInvalid,
          winRate: evaluated == 0 ? null : wins / evaluated,
          completionRate: completed == 0 ? null : wins / completed,
          filterInstruments: otherInstruments,
        ),
      );
    }
    return rows;
  }

  List<_HistoryBreakdownRow> _timeframeRows(
    AnalysisHistorySummary summary,
    _HistoryBreakdownRow? selected,
  ) {
    final selectedFilters = selected?.filterInstruments ?? const <String>[];
    final source = selectedFilters.isEmpty
        ? summary.byTimeframe
        : summary.byInstrument
              .where((row) => selectedFilters.contains(row.instrument))
              .expand((row) => row.byTimeframe);
    final grouped = <String, List<AnalysisHistoryOutcomeStats>>{};
    for (final row in source) {
      grouped.putIfAbsent(row.timeframe, () => []).add(row);
    }
    final rows = grouped.entries.map((entry) {
      final stats = entry.value;
      final total = stats.fold(0, (sum, row) => sum + row.total);
      final active = stats.fold(0, (sum, row) => sum + row.activeValid);
      final tp1 = stats.fold(0, (sum, row) => sum + row.tp1Hit);
      final tp2 = stats.fold(0, (sum, row) => sum + row.tp2Hit);
      final sl = stats.fold(0, (sum, row) => sum + row.slHit);
      final expired = stats.fold(0, (sum, row) => sum + row.expired);
      final invalidated = stats.fold(0, (sum, row) => sum + row.invalidated);
      final wins = tp1 + tp2;
      final evaluated = wins + sl;
      final completed = evaluated + expired;
      return _HistoryBreakdownRow(
        label: entry.key,
        total: total,
        activeValid: active,
        tp1: tp1,
        tp2: tp2,
        sl: sl,
        expired: expired,
        invalidated: invalidated,
        winRate: evaluated == 0 ? null : wins / evaluated,
        completionRate: completed == 0 ? null : wins / completed,
        filterInstruments: selectedFilters,
      );
    }).toList();
    rows.sort((a, b) => b.total.compareTo(a.total));
    return rows;
  }
}

class _HistoryBreakdownRow {
  const _HistoryBreakdownRow({
    required this.label,
    required this.total,
    required this.activeValid,
    required this.tp1,
    required this.tp2,
    required this.sl,
    required this.expired,
    required this.invalidated,
    required this.winRate,
    required this.completionRate,
    required this.filterInstruments,
  });

  final String label;
  final int total;
  final int activeValid;
  final int tp1;
  final int tp2;
  final int sl;
  final int expired;
  final int invalidated;
  final num? winRate;
  final num? completionRate;
  final List<String> filterInstruments;

  int get wins => tp1 + tp2;
}

class _HistoryViewTabs extends StatelessWidget {
  const _HistoryViewTabs({
    required this.summarySelected,
    required this.summaryLabel,
    required this.historyLabel,
    required this.onChanged,
  });

  final bool summarySelected;
  final String summaryLabel;
  final String historyLabel;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 42,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: .35),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _HistoryTabButton(
              label: summaryLabel,
              selected: summarySelected,
              onTap: () => onChanged(true),
            ),
          ),
          Expanded(
            child: _HistoryTabButton(
              label: historyLabel,
              selected: !summarySelected,
              onTap: () => onChanged(false),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryTabButton extends StatelessWidget {
  const _HistoryTabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? theme.colorScheme.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected
                  ? theme.colorScheme.onSurface
                  : theme.colorScheme.onSurfaceVariant,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _RangeButton extends StatelessWidget {
  const _RangeButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 36,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          backgroundColor: selected ? theme.colorScheme.primary : null,
          foregroundColor: selected
              ? theme.colorScheme.onPrimary
              : theme.colorScheme.onSurfaceVariant,
          side: BorderSide(
            color: selected
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant,
          ),
        ),
        child: Text(label, style: const TextStyle(fontSize: 12)),
      ),
    );
  }
}

class _HistoryInsights extends StatelessWidget {
  const _HistoryInsights({required this.rows, required this.minSamples});

  final List<_HistoryBreakdownRow> rows;
  final int minSamples;

  @override
  Widget build(BuildContext context) {
    final qualified = rows.where((row) => row.total >= minSamples).toList();
    final byWin = [...qualified]
      ..removeWhere((row) => row.winRate == null)
      ..sort((a, b) => (b.winRate ?? 0).compareTo(a.winRate ?? 0));
    final byExpired = [...qualified]
      ..sort(
        (a, b) => (b.expired / (b.total == 0 ? 1 : b.total)).compareTo(
          a.expired / (a.total == 0 ? 1 : a.total),
        ),
      );
    final bySl = [...qualified]..sort((a, b) => b.sl.compareTo(a.sl));
    final unavailable = context.l10n.historyNeedMoreSamples;
    return Column(
      children: [
        _InsightCard(
          label: context.l10n.historyInsightConsistent,
          value: byWin.isEmpty
              ? unavailable
              : '${byWin.first.label} · ${(byWin.first.winRate! * 100).round()}%',
        ),
        const SizedBox(height: 8),
        _InsightCard(
          label: context.l10n.historyInsightExpired,
          value: byExpired.isEmpty
              ? unavailable
              : '${byExpired.first.label} · ${byExpired.first.expired}',
        ),
        const SizedBox(height: 8),
        _InsightCard(
          label: context.l10n.historyInsightSl,
          value: bySl.isEmpty
              ? unavailable
              : '${bySl.first.label} · ${bySl.first.sl}',
        ),
      ],
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    ),
  );
}

class _InstrumentPerformanceCard extends StatelessWidget {
  const _InstrumentPerformanceCard({
    required this.minSamples,
    required this.rows,
    required this.focused,
    required this.onFocus,
    required this.onViewHistory,
  });

  final int minSamples;
  final List<_HistoryBreakdownRow> rows;
  final String focused;
  final ValueChanged<String> onFocus;
  final ValueChanged<_HistoryBreakdownRow> onViewHistory;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.performanceByInstrument,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  context.l10n.historyInstrumentHint,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(context.l10n.noAnalyses),
            )
          else
            for (final row in rows) ...[
              InkWell(
                onTap: () => onFocus(row.label),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: row.label == focused
                        ? theme.colorScheme.primary.withValues(alpha: .1)
                        : null,
                    border: row.label == focused
                        ? Border.all(
                            color: theme.colorScheme.primary.withValues(
                              alpha: .55,
                            ),
                          )
                        : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              row.label,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          Text(
                            context.l10n.historySampleCount(row.total),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Win ${row.total >= minSamples && row.winRate != null ? '${(row.winRate! * 100).round()}%' : '—'}',
                            ),
                          ),
                          Expanded(child: Text('TP ${row.wins}')),
                          Expanded(child: Text('SL ${row.sl}')),
                        ],
                      ),
                      _HistoryOutcomeBar(row: row),
                      if (row.total < minSamples) ...[
                        const SizedBox(height: 7),
                        Text(
                          context.l10n.historySamplesNeeded(
                            minSamples - row.total,
                            row.total,
                            minSamples,
                          ),
                          style: theme.textTheme.labelSmall,
                        ),
                      ],
                      if (row.label == context.l10n.otherInstruments) ...[
                        const SizedBox(height: 8),
                        Text(
                          context.l10n.historyOtherInstrumentsHint,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => onViewHistory(row),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 32),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(context.l10n.historyViewHistory),
                      ),
                    ],
                  ),
                ),
              ),
              if (row != rows.last) const Divider(height: 1),
            ],
        ],
      ),
    );
  }
}

class _TimeframePerformanceCard extends StatelessWidget {
  const _TimeframePerformanceCard({
    required this.instrument,
    required this.minSamples,
    required this.rows,
    required this.onTap,
  });

  final String? instrument;
  final int minSamples;
  final List<_HistoryBreakdownRow> rows;
  final ValueChanged<_HistoryBreakdownRow> onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${context.l10n.historyTimeframePerformance}${instrument == null ? '' : ' · $instrument'}',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 5),
                Text(
                  context.l10n.historyRateExplainer,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(context.l10n.noAnalyses),
            )
          else
            for (final row in rows) ...[
              InkWell(
                onTap: () => onTap(row),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              row.label,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          Text(context.l10n.historySampleCount(row.total)),
                        ],
                      ),
                      const SizedBox(height: 9),
                      Wrap(
                        spacing: 18,
                        runSpacing: 8,
                        children: [
                          Text(
                            '${context.l10n.historyMetricValid}: ${row.activeValid}',
                          ),
                          Text('${context.l10n.expired}: ${row.expired}'),
                          Text('SL: ${row.sl}'),
                          Text('TP1: ${row.tp1}'),
                          Text('TP2: ${row.tp2}'),
                          Text(
                            row.total >= minSamples && row.winRate != null
                                ? '${(row.winRate! * 100).round()}%'
                                : '+${(minSamples - row.total).clamp(0, minSamples)} ${context.l10n.historySampleShort}',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          Text(
                            row.total >= minSamples &&
                                    row.completionRate != null
                                ? '${(row.completionRate! * 100).round()}%'
                                : '—',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (row != rows.last) const Divider(height: 1),
            ],
        ],
      ),
    );
  }
}

class _HistoryOutcomeBar extends StatelessWidget {
  const _HistoryOutcomeBar({required this.row});
  final _HistoryBreakdownRow row;

  @override
  Widget build(BuildContext context) {
    final total = row.wins + row.sl + row.expired;
    if (total == 0) {
      return const LinearProgressIndicator(value: 0, minHeight: 7);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: Row(
        children: [
          if (row.wins > 0)
            Expanded(
              flex: row.wins,
              child: Container(height: 7, color: const Color(0xFF10B981)),
            ),
          if (row.sl > 0)
            Expanded(
              flex: row.sl,
              child: Container(height: 7, color: const Color(0xFFEF4444)),
            ),
          if (row.expired > 0)
            Expanded(
              flex: row.expired,
              child: Container(height: 7, color: Colors.grey),
            ),
        ],
      ),
    );
  }
}

class _HistoryPagination extends StatelessWidget {
  const _HistoryPagination({
    required this.page,
    required this.totalPages,
    required this.start,
    required this.end,
    required this.total,
    required this.loading,
    required this.onPrevious,
    required this.onNext,
  });

  final int page;
  final int totalPages;
  final int start;
  final int end;
  final int total;
  final bool loading;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 6, bottom: 20),
    child: Column(
      children: [
        Text(
          context.l10n.historyPageStatus(page, totalPages),
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 2),
        Text(
          context.l10n.historyRangeStatus(start, end, total),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: loading ? null : onPrevious,
                child: Text(context.l10n.historyPrevious),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: loading ? null : onNext,
                child: loading
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(context.l10n.historyNext),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

// =============================================================================
// ACTIVE FILTERS
// =============================================================================

class _ActiveFilters extends StatelessWidget {
  const _ActiveFilters({
    required this.filters,
    required this.resultCount,
    required this.onChanged,
    required this.onReset,
  });

  final HistoryFilters filters;

  final int resultCount;

  final ValueChanged<HistoryFilters> onChanged;

  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[];

    if (filters.mode != HistoryModeFilter.all) {
      chips.add(
        InputChip(
          label: Text(
            filters.mode == HistoryModeFilter.beginner
                ? context.l10n.modeBeginner
                : context.l10n.modePro,
          ),
          onDeleted: () {
            onChanged(filters.copyWith(mode: HistoryModeFilter.all));
          },
        ),
      );
    }

    if (filters.outcome != HistoryOutcomeFilter.all) {
      chips.add(
        InputChip(
          label: Text(
            context.l10n.outcomeLabel(
              _outcomeLabel(context.l10n, filters.outcome),
            ),
          ),
          onDeleted: () {
            onChanged(filters.copyWith(outcome: HistoryOutcomeFilter.all));
          },
        ),
      );
    }

    for (final instrument in filters.instruments) {
      chips.add(
        InputChip(
          label: Text(
            instrument == HistoryFilters.otherInstruments
                ? context.l10n.otherInstruments
                : instrument,
          ),
          onDeleted: () {
            onChanged(
              filters.copyWith(
                instruments: filters.instruments
                    .where((item) => item != instrument)
                    .toList(),
              ),
            );
          },
        ),
      );
    }

    for (final timeframe in filters.timeframes) {
      chips.add(
        InputChip(
          label: Text(timeframe),
          onDeleted: () {
            onChanged(
              filters.copyWith(
                timeframes: filters.timeframes
                    .where((item) => item != timeframe)
                    .toList(),
              ),
            );
          },
        ),
      );
    }

    if (filters.from != null || filters.to != null) {
      final formatter = DateFormat('d MMM yyyy');

      final from = filters.from == null
          ? '...'
          : formatter.format(filters.from!);

      final to = filters.to == null ? '...' : formatter.format(filters.to!);

      chips.add(
        InputChip(
          label: Text('$from – $to'),
          onDeleted: () {
            onChanged(filters.copyWith(clearFrom: true, clearTo: true));
          },
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 2, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  context.l10n.resultCount(resultCount),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton(onPressed: onReset, child: Text(context.l10n.reset)),
            ],
          ),

          if (chips.isNotEmpty)
            Wrap(spacing: 6, runSpacing: 4, children: chips),
        ],
      ),
    );
  }

  static String _outcomeLabel(
    AppLocalizations l10n,
    HistoryOutcomeFilter outcome,
  ) {
    switch (outcome) {
      case HistoryOutcomeFilter.pending:
        return l10n.pending;
      case HistoryOutcomeFilter.targetReached:
        return l10n.targetReached;
      case HistoryOutcomeFilter.riskLimitHit:
        return l10n.riskLimitTouched;
      case HistoryOutcomeFilter.expired:
        return l10n.periodEnded;
      case HistoryOutcomeFilter.invalidated:
        return l10n.cannotBeEvaluated;
      case HistoryOutcomeFilter.all:
        return l10n.all;
    }
  }
}

// =============================================================================
// FILTER SHEET
// =============================================================================

class _HistoryFilterSheet extends StatefulWidget {
  const _HistoryFilterSheet({required this.initial});

  final HistoryFilters initial;

  @override
  State<_HistoryFilterSheet> createState() => _HistoryFilterSheetState();
}

class _HistoryFilterSheetState extends State<_HistoryFilterSheet> {
  late HistoryFilters _draft;

  @override
  void initState() {
    super.initState();

    _draft = widget.initial;
  }

  void _toggleInstrument(String instrument) {
    final selected = _draft.instruments.contains(instrument);

    setState(() {
      _draft = _draft.copyWith(
        instruments: selected
            ? _draft.instruments.where((item) => item != instrument).toList()
            : [..._draft.instruments, instrument],
      );
    });
  }

  void _toggleTimeframe(String timeframe) {
    final selected = _draft.timeframes.contains(timeframe);

    setState(() {
      _draft = _draft.copyWith(
        timeframes: selected
            ? _draft.timeframes.where((item) => item != timeframe).toList()
            : [..._draft.timeframes, timeframe],
      );
    });
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();

    final initialRange = _draft.from != null && _draft.to != null
        ? DateTimeRange(start: _draft.from!, end: _draft.to!)
        : null;

    final result = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange: initialRange,
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      _draft = _draft.copyWith(from: result.start, to: result.end);
    });
  }

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('d MMM yyyy');
    final l10n = context.l10n;

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.86,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.historyFilters,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),

                  TextButton(
                    onPressed: () {
                      setState(() {
                        // Search tetap dipertahankan
                        // karena input search berada
                        // di luar filter sheet.
                        _draft = HistoryFilters(query: _draft.query);
                      });
                    },
                    child: Text(l10n.reset),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    l10n.mode,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 9),

                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: Text(l10n.all),
                        selected: _draft.mode == HistoryModeFilter.all,
                        onSelected: (_) {
                          setState(() {
                            _draft = _draft.copyWith(
                              mode: HistoryModeFilter.all,
                            );
                          });
                        },
                      ),
                      ChoiceChip(
                        label: Text(l10n.beginner),
                        selected: _draft.mode == HistoryModeFilter.beginner,
                        onSelected: (_) {
                          setState(() {
                            _draft = _draft.copyWith(
                              mode: HistoryModeFilter.beginner,
                            );
                          });
                        },
                      ),
                      ChoiceChip(
                        label: Text(l10n.pro),
                        selected: _draft.mode == HistoryModeFilter.pro,
                        onSelected: (_) {
                          setState(() {
                            _draft = _draft.copyWith(
                              mode: HistoryModeFilter.pro,
                            );
                          });
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  Text(
                    l10n.evaluationStatus,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 9),

                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: [
                      for (final option in HistoryOutcomeFilter.values)
                        ChoiceChip(
                          label: Text(_outcomeOptionLabel(l10n, option)),
                          selected: _draft.outcome == option,
                          onSelected: (_) {
                            setState(() {
                              _draft = _draft.copyWith(outcome: option);
                            });
                          },
                        ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  Text(
                    l10n.instrument,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: [
                      for (final instrument
                          in MarketProvider.analyzeVisibleInstruments)
                        FilterChip(
                          label: Text(instrument),
                          selected: _draft.instruments.contains(instrument),
                          onSelected: (_) => _toggleInstrument(instrument),
                        ),
                      FilterChip(
                        label: Text(l10n.otherInstruments),
                        selected: _draft.instruments.contains(
                          HistoryFilters.otherInstruments,
                        ),
                        onSelected: (_) =>
                            _toggleInstrument(HistoryFilters.otherInstruments),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  Text(
                    l10n.timeframe,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 9),

                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: MarketProvider.supportedTimeframes.map((
                      timeframe,
                    ) {
                      return FilterChip(
                        label: Text(timeframe),
                        selected: _draft.timeframes.contains(timeframe),
                        onSelected: (_) {
                          _toggleTimeframe(timeframe);
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),

                  Text(
                    l10n.dateRange,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 9),

                  OutlinedButton.icon(
                    onPressed: _pickDateRange,
                    icon: const Icon(Icons.date_range_rounded),
                    label: Text(
                      _draft.from == null || _draft.to == null
                          ? l10n.selectDate
                          : '${formatter.format(_draft.from!)} – '
                                '${formatter.format(_draft.to!)}',
                    ),
                  ),

                  if (_draft.from != null || _draft.to != null)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _draft = _draft.copyWith(
                            clearFrom: true,
                            clearTo: true,
                          );
                        });
                      },
                      child: Text(l10n.clearDateRange),
                    ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop(_draft.normalized());
                  },
                  icon: const Icon(Icons.filter_alt_rounded),
                  label: Text(l10n.applyFilters),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _outcomeOptionLabel(
    AppLocalizations l10n,
    HistoryOutcomeFilter outcome,
  ) {
    switch (outcome) {
      case HistoryOutcomeFilter.all:
        return l10n.all;
      case HistoryOutcomeFilter.pending:
        return l10n.pending;
      case HistoryOutcomeFilter.targetReached:
        return l10n.targetReached;
      case HistoryOutcomeFilter.riskLimitHit:
        return l10n.riskLimitTouched;
      case HistoryOutcomeFilter.expired:
        return l10n.periodEnded;
      case HistoryOutcomeFilter.invalidated:
        return l10n.cannotBeEvaluated;
    }
  }
}
