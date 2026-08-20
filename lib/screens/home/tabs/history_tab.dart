import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../providers/analysis_provider.dart';
import '../../../widgets/analysis_card.dart';
import '../../analysis/analysis_detail_screen.dart';

class HistoryTab extends StatefulWidget {
  const HistoryTab({super.key});

  @override
  State<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<HistoryTab> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AnalysisProvider>().loadHistory(refresh: true);
    });
    _scrollController.addListener(() {
      if (_scrollController.position.pixels > _scrollController.position.maxScrollExtent - 200) {
        context.read<AnalysisProvider>().loadMoreHistory();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.darkMutedForeground : AppColors.lightMutedForeground;
    final analysisProvider = context.watch<AnalysisProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat')),
      body: RefreshIndicator(
        onRefresh: () => context.read<AnalysisProvider>().loadHistory(refresh: true),
        child: analysisProvider.history.isEmpty && !analysisProvider.isLoadingHistory
            ? ListView(
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.28),
                  Icon(Icons.history_rounded, size: 40, color: muted),
                  const SizedBox(height: 12),
                  Center(child: Text('Belum ada analisis', style: TextStyle(color: muted, fontWeight: FontWeight.w600))),
                  const SizedBox(height: 4),
                  Center(
                    child: Text('Analisis AI kamu akan muncul di sini', style: TextStyle(color: muted, fontSize: 12.5)),
                  ),
                ],
              )
            : ListView.separated(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: analysisProvider.history.length + (analysisProvider.isLoadingHistory ? 1 : 0),
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  if (index >= analysisProvider.history.length) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(child: CircularProgressIndicator(strokeWidth: 2.4)),
                    );
                  }
                  final a = analysisProvider.history[index];
                  return AnalysisCard(
                    analysis: a,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => AnalysisDetailScreen(analysisId: a.id, preloaded: a)),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
