import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/history/history_statistics.dart';
import '../../../models/history_filters.dart';
import '../../../models/history_sort.dart';
import '../../../providers/analysis_provider.dart';
import '../../../providers/market_provider.dart';
import '../../../widgets/error_banner.dart';
import '../../../widgets/history/history_analysis_card.dart';
import '../../../widgets/history/history_summary_card.dart';
import '../../analysis/analysis_detail_screen.dart';

class HistoryTab extends StatefulWidget {
  const HistoryTab({super.key});

  @override
  State<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<HistoryTab> {
  final ScrollController _scrollController = ScrollController();

  final TextEditingController _searchController = TextEditingController();

  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(_handleScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      final filters = context.read<AnalysisProvider>().historyFilters;

      _searchController.text = filters.query;
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();

    _scrollController.removeListener(_handleScroll);

    _scrollController.dispose();

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

    final provider = context.read<AnalysisProvider>();

    await provider.applyHistoryFilters(
      provider.historyFilters.copyWith(query: ''),
    );
  }

  // ===========================================================================
  // PAGINATION
  // ===========================================================================

  void _handleScroll() {
    if (!_scrollController.hasClients) {
      return;
    }

    final position = _scrollController.position;

    if (position.pixels > position.maxScrollExtent - 240) {
      unawaited(context.read<AnalysisProvider>().loadMoreVisibleHistory());
    }
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

    await provider.applyHistoryFilters(result);
  }

  Future<void> _resetFilters() async {
    _searchDebounce?.cancel();

    _searchController.clear();

    await context.read<AnalysisProvider>().applyHistoryFilters(
      const HistoryFilters(),
    );
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

    final filters = provider.historyFilters;

    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: _handleSearchChanged,
                    maxLength: HistoryFilters.maxSearchLength,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: 'Cari instrumen atau catatan',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: filters.query.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Hapus pencarian',
                              onPressed: _clearSearch,
                              icon: const Icon(Icons.close_rounded),
                            ),
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton.filled(
                      tooltip: 'Filter',
                      onPressed: _openFilters,
                      icon: const Icon(Icons.filter_list_rounded),
                    ),

                    if (filters.activeCategoryCount > 0)
                      Positioned(
                        right: -3,
                        top: -3,
                        child: Container(
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${filters.activeCategoryCount}',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimary,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          if (filters.isActive)
            _ActiveFilters(
              filters: filters,
              resultCount: provider.visibleHistoryTotal,
              onChanged: (next) {
                unawaited(provider.applyHistoryFilters(next));
              },
              onReset: _resetFilters,
            ),

          if (provider.visibleHistoryError != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
              child: ErrorBanner(message: provider.visibleHistoryError),
            ),

          Expanded(
            child: RefreshIndicator(
              onRefresh: () {
                return context.read<AnalysisProvider>().refreshVisibleHistory(
                  silent: false,
                );
              },
              child: _buildContent(
                context: context,
                provider: provider,
                muted: muted,
              ),
            ),
          ),
        ],
      ),
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
        children: [
          SizedBox(height: MediaQuery.sizeOf(context).height * 0.28),
          const Center(child: CircularProgressIndicator(strokeWidth: 2.4)),
        ],
      );
    }

    if (items.isEmpty) {
      final filtered = provider.hasActiveHistoryFilters;

      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          SizedBox(height: MediaQuery.sizeOf(context).height * 0.18),
          Icon(
            filtered ? Icons.search_off_rounded : Icons.history_rounded,
            size: 42,
            color: muted,
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              filtered ? 'Tidak ada analisis yang cocok' : 'Belum ada analisis',
              style: TextStyle(color: muted, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 5),
          Center(
            child: Text(
              filtered
                  ? 'Coba ubah kata pencarian atau filter.'
                  : 'Analisis AI kamu akan muncul di sini.',
              textAlign: TextAlign.center,
              style: TextStyle(color: muted, fontSize: 12),
            ),
          ),

          if (filtered) ...[
            const SizedBox(height: 10),
            Center(
              child: TextButton(
                onPressed: _resetFilters,
                child: const Text('Reset filter'),
              ),
            ),
          ],
        ],
      );
    }

    return ListView.separated(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount:
          items.length + 1 + (provider.isLoadingMoreVisibleHistory ? 1 : 0),
      separatorBuilder: (_, _) {
        return const SizedBox(height: 10);
      },
      itemBuilder: (context, index) {
        if (index == 0) {
          return HistorySummaryCard(
            statistics: HistoryStatistics.fromAnalyses(items),
            isPartial:
                items.length < provider.visibleHistorySourceTotal ||
                provider.hasClientHistoryRefinement,
          );
        }

        final itemIndex = index - 1;

        if (itemIndex >= items.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2.4)),
          );
        }

        final analysis = items[itemIndex];

        return HistoryAnalysisCard(
          analysis: analysis,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => AnalysisDetailScreen(
                  analysisId: analysis.id,
                  preloaded: analysis,
                ),
              ),
            );
          },
        );
      },
    );
  }
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
                ? 'Mode: Pemula'
                : 'Mode: Pro',
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
          label: Text('Outcome: ${_outcomeLabel(filters.outcome)}'),
          onDeleted: () {
            onChanged(filters.copyWith(outcome: HistoryOutcomeFilter.all));
          },
        ),
      );
    }

    if (filters.minConfidence case final confidence?) {
      chips.add(
        InputChip(
          label: Text('Keyakinan ≥ $confidence%'),
          onDeleted: () {
            onChanged(filters.copyWith(clearConfidence: true));
          },
        ),
      );
    }

    for (final instrument in filters.instruments) {
      chips.add(
        InputChip(
          label: Text(instrument),
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
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '$resultCount hasil',
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              TextButton(onPressed: onReset, child: const Text('Reset')),
            ],
          ),

          if (chips.isNotEmpty)
            Wrap(spacing: 6, runSpacing: 4, children: chips),
        ],
      ),
    );
  }

  static String _outcomeLabel(HistoryOutcomeFilter outcome) {
    switch (outcome) {
      case HistoryOutcomeFilter.success:
        return 'Positif';
      case HistoryOutcomeFilter.failed:
        return 'Negatif';
      case HistoryOutcomeFilter.pending:
        return 'Menunggu';
      case HistoryOutcomeFilter.all:
        return 'Semua';
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
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    final formatter = DateFormat('d MMM yyyy');

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.86,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 12, 12),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Filter Riwayat',
                      style: TextStyle(
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
                    child: const Text('Reset'),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const Text(
                    'Mode',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                  ),

                  const SizedBox(height: 9),

                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Semua'),
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
                        label: const Text('Pemula'),
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
                        label: const Text('Pro'),
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

                  const Text(
                    'Status evaluasi',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                  ),

                  const SizedBox(height: 9),

                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: [
                      for (final option in HistoryOutcomeFilter.values)
                        ChoiceChip(
                          label: Text(_outcomeOptionLabel(option)),
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

                  const Text(
                    'Minimum keyakinan',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                  ),

                  const SizedBox(height: 9),

                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: [
                      ChoiceChip(
                        label: const Text('Semua'),
                        selected: _draft.minConfidence == null,
                        onSelected: (_) {
                          setState(() {
                            _draft = _draft.copyWith(clearConfidence: true);
                          });
                        },
                      ),
                      for (final confidence in const [60, 70, 80, 90])
                        ChoiceChip(
                          label: Text('≥ $confidence%'),
                          selected: _draft.minConfidence == confidence,
                          onSelected: (_) {
                            setState(() {
                              _draft = _draft.copyWith(
                                minConfidence: confidence,
                              );
                            });
                          },
                        ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    'Urutan',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                  ),

                  const SizedBox(height: 9),

                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: [
                      for (final sort in HistorySort.values)
                        ChoiceChip(
                          label: Text(_sortLabel(sort)),
                          selected: _draft.sort == sort,
                          onSelected: (_) {
                            setState(() {
                              _draft = _draft.copyWith(sort: sort);
                            });
                          },
                        ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    'Instrumen',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                  ),

                  const SizedBox(height: 10),

                  for (final group
                      in MarketProvider.instrumentGroups.entries) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 6),
                      child: Text(
                        group.key,
                        style: TextStyle(
                          color: muted,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),

                    Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      children: group.value.map((instrument) {
                        return FilterChip(
                          label: Text(instrument),
                          selected: _draft.instruments.contains(instrument),
                          onSelected: (_) {
                            _toggleInstrument(instrument);
                          },
                        );
                      }).toList(),
                    ),
                  ],

                  const SizedBox(height: 24),

                  const Text(
                    'Timeframe',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
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

                  const Text(
                    'Rentang Tanggal',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                  ),

                  const SizedBox(height: 9),

                  OutlinedButton.icon(
                    onPressed: _pickDateRange,
                    icon: const Icon(Icons.date_range_rounded),
                    label: Text(
                      _draft.from == null || _draft.to == null
                          ? 'Pilih tanggal'
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
                      child: const Text('Hapus rentang tanggal'),
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
                  label: const Text('Terapkan Filter'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _outcomeOptionLabel(HistoryOutcomeFilter outcome) {
    switch (outcome) {
      case HistoryOutcomeFilter.all:
        return 'Semua';
      case HistoryOutcomeFilter.pending:
        return 'Menunggu';
      case HistoryOutcomeFilter.success:
        return 'Outcome positif';
      case HistoryOutcomeFilter.failed:
        return 'Outcome negatif';
    }
  }

  static String _sortLabel(HistorySort sort) {
    switch (sort) {
      case HistorySort.newest:
        return 'Terbaru';
      case HistorySort.oldest:
        return 'Terlama';
      case HistorySort.confidenceHighest:
        return 'Keyakinan tertinggi';
    }
  }
}
