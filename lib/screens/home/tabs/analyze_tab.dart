import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trade_pilot_api_client/trade_pilot_api_client.dart';

import '../../../core/theme/app_colors.dart';
import '../../../providers/analysis_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/error_banner.dart';
import '../../analysis/analysis_detail_screen.dart';

const _instrumentGroups = {
  'Forex': ['EUR/USD', 'GBP/USD', 'USD/JPY', 'USD/CHF', 'AUD/USD', 'USD/CAD', 'NZD/USD'],
  'Crypto': ['BTC/USD', 'ETH/USD', 'SOL/USD', 'BNB/USD', 'XRP/USD'],
  'Futures': ['XAU/USD', 'XAG/USD', 'WTI/USD', 'US30', 'NAS100', 'SPX500'],
};

const _timeframes = [
  ('1m', CreateAnalysisBodyTimeframeEnum.n1m),
  ('5m', CreateAnalysisBodyTimeframeEnum.n5m),
  ('15m', CreateAnalysisBodyTimeframeEnum.n15m),
  ('30m', CreateAnalysisBodyTimeframeEnum.n30m),
  ('1h', CreateAnalysisBodyTimeframeEnum.n1h),
  ('4h', CreateAnalysisBodyTimeframeEnum.n4h),
  ('1D', CreateAnalysisBodyTimeframeEnum.n1d),
  ('1W', CreateAnalysisBodyTimeframeEnum.n1w),
];

class AnalyzeTab extends StatefulWidget {
  const AnalyzeTab({super.key});

  @override
  State<AnalyzeTab> createState() => _AnalyzeTabState();
}

class _AnalyzeTabState extends State<AnalyzeTab> {
  String _selectedInstrument = _instrumentGroups['Forex']!.first;
  CreateAnalysisBodyTimeframeEnum _selectedTimeframe = CreateAnalysisBodyTimeframeEnum.n1h;
  final _contextController = TextEditingController();

  @override
  void dispose() {
    _contextController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final auth = context.read<AuthProvider>();
    final analysisProvider = context.read<AnalysisProvider>();
    final userMode = auth.user?.selectedMode == UserSelectedModeEnum.pro
        ? CreateAnalysisBodyModeEnum.pro
        : CreateAnalysisBodyModeEnum.beginner;

    final result = await analysisProvider.createAnalysis(
      instrument: _selectedInstrument,
      timeframe: _selectedTimeframe,
      mode: userMode,
      userInputContext: _contextController.text.trim().isEmpty ? null : _contextController.text.trim(),
    );

    if (result != null && mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => AnalysisDetailScreen(analysisId: result.id, preloaded: result)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.darkMutedForeground : AppColors.lightMutedForeground;
    final analysisProvider = context.watch<AnalysisProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Analisis AI')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ErrorBanner(message: analysisProvider.errorMessage),
            Text('Pilih Instrumen', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 12),
            for (final entry in _instrumentGroups.entries) ...[
              Text(entry.key, style: TextStyle(color: muted, fontSize: 12.5, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: entry.value.map((instrument) {
                  final selected = instrument == _selectedInstrument;
                  return _SelectChip(
                    label: instrument,
                    selected: selected,
                    onTap: () => setState(() => _selectedInstrument = instrument),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],
            const SizedBox(height: 4),
            Text('Timeframe', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _timeframes.map((tf) {
                final selected = tf.$2 == _selectedTimeframe;
                return _SelectChip(
                  label: tf.$1,
                  selected: selected,
                  onTap: () => setState(() => _selectedTimeframe = tf.$2),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            Text('Catatan Tambahan (opsional)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 10),
            TextField(
              controller: _contextController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Mis. saya sudah punya posisi buy dari 1900...',
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: analysisProvider.isSubmitting ? null : _submit,
              icon: analysisProvider.isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                    )
                  : const Icon(Icons.auto_awesome_rounded, size: 18),
              label: Text(analysisProvider.isSubmitting ? 'Menganalisis pasar...' : 'Dapatkan Analisis AI'),
            ),
            if (analysisProvider.quota != null && !analysisProvider.quota!.unlimited) ...[
              const SizedBox(height: 10),
              Center(
                child: Text(
                  '${analysisProvider.quota!.daily.remaining} analisis tersisa hari ini',
                  style: TextStyle(color: muted, fontSize: 12.5),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SelectChip extends StatelessWidget {
  const _SelectChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final onPrimary = isDark ? AppColors.darkPrimaryForeground : AppColors.lightPrimaryForeground;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? primary : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? primary : border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? onPrimary : null,
          ),
        ),
      ),
    );
  }
}
