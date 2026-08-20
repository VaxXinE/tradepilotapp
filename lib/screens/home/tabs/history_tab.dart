import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../providers/analysis_provider.dart';
import '../../../widgets/analysis_card.dart';
import '../../analysis/analysis_detail_screen.dart';

class HistoryTab extends StatefulWidget {
  const HistoryTab({
    super.key,
  });

  @override
  State<HistoryTab> createState() =>
      _HistoryTabState();
}

class _HistoryTabState
    extends State<HistoryTab> {
  final ScrollController _scrollController =
      ScrollController();

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(
      _handleScroll,
    );
  }

  @override
  void dispose() {
    _scrollController.removeListener(
      _handleScroll,
    );

    _scrollController.dispose();

    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // PAGINATION
  // ---------------------------------------------------------------------------

  void _handleScroll() {
    if (!_scrollController.hasClients) {
      return;
    }

    final position =
        _scrollController.position;

    if (position.pixels >
        position.maxScrollExtent - 200) {
      context
          .read<AnalysisProvider>()
          .loadMoreHistory();
    }
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

    final analysisProvider =
        context.watch<AnalysisProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat'),
      ),
      body: RefreshIndicator(
        onRefresh: () {
          return context
              .read<AnalysisProvider>()
              .loadHistory(
                refresh: true,
                silent: false,
              );
        },
        child: _buildContent(
          context: context,
          provider: analysisProvider,
          muted: muted,
        ),
      ),
    );
  }

  Widget _buildContent({
    required BuildContext context,
    required AnalysisProvider provider,
    required Color muted,
  }) {
    // -----------------------------------------------------------------------
    // INITIAL LOADING
    // -----------------------------------------------------------------------

    if (provider.history.isEmpty &&
        provider.isLoadingHistory) {
      return ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height:
                MediaQuery.of(context).size.height *
                    0.35,
          ),
          const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
            ),
          ),
        ],
      );
    }

    // -----------------------------------------------------------------------
    // EMPTY STATE
    // -----------------------------------------------------------------------

    if (provider.history.isEmpty) {
      return ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height:
                MediaQuery.of(context).size.height *
                    0.28,
          ),
          Icon(
            Icons.history_rounded,
            size: 40,
            color: muted,
          ),
          const SizedBox(
            height: 12,
          ),
          Center(
            child: Text(
              'Belum ada analisis',
              style: TextStyle(
                color: muted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(
            height: 4,
          ),
          Center(
            child: Text(
              'Analisis AI kamu akan muncul di sini',
              style: TextStyle(
                color: muted,
                fontSize: 12.5,
              ),
            ),
          ),
        ],
      );
    }

    // -----------------------------------------------------------------------
    // LIST
    // -----------------------------------------------------------------------

    return ListView.separated(
      controller: _scrollController,
      physics:
          const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount:
          provider.history.length +
              (provider.isLoadingMoreHistory
                  ? 1
                  : 0),
      separatorBuilder: (_, __) {
        return const SizedBox(
          height: 10,
        );
      },
      itemBuilder: (
        context,
        index,
      ) {
        // Pagination spinner.
        if (index >= provider.history.length) {
          return const Padding(
            padding:
                EdgeInsets.symmetric(
              vertical: 16,
            ),
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
              ),
            ),
          );
        }

        final analysis =
            provider.history[index];

        return AnalysisCard(
          analysis: analysis,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    AnalysisDetailScreen(
                  analysisId:
                      analysis.id,

                  // Gunakan cache yang sudah ada supaya
                  // detail langsung tampil tanpa loading.
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