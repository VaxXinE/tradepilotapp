import 'package:trade_pilot_api_client/trade_pilot_api_client.dart';

import '../../l10n/app_messages.dart';

enum MindsetInsightType { frequency, concentration, pending, journal }

class MindsetInsight {
  const MindsetInsight({
    required this.type,
    required this.title,
    required this.message,
  });

  final MindsetInsightType type;
  final String title;
  final String message;
}

class MindsetEngine {
  const MindsetEngine();

  List<MindsetInsight> evaluate(List<Analysis> analyses) {
    if (analyses.length < 3) return const [];
    final ordered = List<Analysis>.of(analyses)
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final result = <MindsetInsight>[];

    for (var index = 2; index < ordered.length; index++) {
      if (ordered[index].createdAt.difference(ordered[index - 2].createdAt) <=
          const Duration(hours: 1)) {
        result.add(
          MindsetInsight(
            type: MindsetInsightType.frequency,
            title: AppMessages.l10n.mindsetPacingTitle,
            message: AppMessages.l10n.mindsetPacingBody,
          ),
        );
        break;
      }
    }

    final counts = <String, int>{};
    for (final analysis in analyses) {
      counts.update(
        analysis.instrument,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
    }
    final concentrated = counts.entries.where(
      (entry) => entry.value / analyses.length >= .6,
    );
    if (concentrated.isNotEmpty) {
      final entry = concentrated.first;
      result.add(
        MindsetInsight(
          type: MindsetInsightType.concentration,
          title: AppMessages.l10n.mindsetConcentrationTitle,
          message: AppMessages.l10n.mindsetConcentrationBody(
            entry.value,
            analyses.length,
            entry.key,
          ),
        ),
      );
    }

    final pending = analyses
        .where(
          (analysis) =>
              analysis.outcomeStatus == null ||
              analysis.outcomeStatus?.name == 'pending',
        )
        .length;
    if (pending >= 3) {
      result.add(
        MindsetInsight(
          type: MindsetInsightType.pending,
          title: AppMessages.l10n.mindsetPendingTitle,
          message: AppMessages.l10n.mindsetPendingBody(pending),
        ),
      );
    }

    final journaled = analyses
        .where((analysis) => analysis.hasNote == true)
        .length;
    if (analyses.length >= 4 && journaled * 4 < analyses.length) {
      result.add(
        MindsetInsight(
          type: MindsetInsightType.journal,
          title: AppMessages.l10n.mindsetJournalTitle,
          message: AppMessages.l10n.mindsetJournalBody,
        ),
      );
    }

    return result;
  }
}
