import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:trade_pilot_api_client/trade_pilot_api_client.dart';

import '../../core/localization/locale_controller.dart';
import '../../l10n/l10n.dart';
import '../../providers/auth_provider.dart';
import '../../providers/progression_provider.dart';
import '../../widgets/responsive_page.dart';

class MindsetScreen extends StatefulWidget {
  const MindsetScreen({this.initialGuideId, this.embedded = false, super.key});

  final ProgressionEvidenceStartInputGuideIdEnum? initialGuideId;

  /// Ketika dipakai sebagai tab di dalam app shell, header dan footer
  /// aplikasi sudah disediakan oleh shell sehingga AppBar tidak dipakai.
  final bool embedded;

  @override
  State<MindsetScreen> createState() => _MindsetScreenState();
}

class _MindsetScreenState extends State<MindsetScreen> {
  List<_MindsetModule> _modules = const [];
  String _query = '';
  String? _selectedCategory;
  bool _openedInitialGuide = false;

  @override
  void initState() {
    super.initState();
    _loadGuide();
  }

  Future<void> _loadGuide() async {
    final raw = await Future.wait([
      rootBundle.loadString('assets/guide_core.json'),
      rootBundle.loadString('assets/guide_more.json'),
    ]);
    final categories = [
      for (final source in raw) ...jsonDecode(source) as List<dynamic>,
    ];
    final modules = <_MindsetModule>[];
    for (final value in categories.cast<Map<String, dynamic>>()) {
      final category = value['id'] as String;
      for (final article
          in (value['articles'] as List<dynamic>)
              .cast<Map<String, dynamic>>()) {
        modules.add(_MindsetModule.fromJson(category, article));
      }
    }
    if (!mounted) return;
    setState(() => _modules = modules);
    _openInitialGuide();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _openInitialGuide();
  }

  void _openInitialGuide() {
    final guideId = widget.initialGuideId;
    if (_openedInitialGuide || guideId == null || _modules.isEmpty) return;
    _openedInitialGuide = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      for (final module in _modules) {
        if (module.guideId != guideId) continue;
        final id = context.read<LocaleController>().locale.languageCode == 'id';
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => _MindsetModuleScreen(
              module: module,
              id: id,
              initiallyCompleted: context
                  .read<ProgressionProvider>()
                  .completedGuideIds
                  .contains(module.guideKey),
            ),
          ),
        );
        break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_modules.isEmpty) {
      return Scaffold(
        appBar: widget.embedded
            ? null
            : AppBar(title: Text(context.l10n.guide)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final id = context.watch<LocaleController>().locale.languageCode == 'id';
    final filtered = _modules.where((module) {
      final query = _query.trim().toLowerCase();
      if (query.isEmpty) return true;
      return '${id ? module.titleId : module.titleEn} '
              '${id ? module.summaryId : module.summaryEn} '
              '${module.searchText(id)}'
          .toLowerCase()
          .contains(query);
    }).toList();
    final allCategories = _modules.map((module) => module.category).toSet();
    final visible = _selectedCategory == null
        ? filtered
        : filtered
              .where((module) => module.category == _selectedCategory)
              .toList();
    final categories = visible.map((module) => module.category).toSet();
    final l10n = context.l10n;
    final completedGuideIds = context
        .watch<ProgressionProvider?>()
        ?.completedGuideIds;
    final quickStart = [
      _modules.firstWhere(
        (module) =>
            module.guideId ==
            ProgressionEvidenceStartInputGuideIdEnum.analysisWorkflow,
      ),
      _modules.firstWhere(
        (module) => module.articleId == 'history-performance',
      ),
      _modules.firstWhere(
        (module) =>
            module.guideId ==
            ProgressionEvidenceStartInputGuideIdEnum.adaptivePositionPlan,
      ),
    ];

    void openModule(_MindsetModule module) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => _MindsetModuleScreen(
            module: module,
            id: id,
            initiallyCompleted:
                completedGuideIds?.contains(module.guideKey) == true,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: widget.embedded ? null : AppBar(title: Text(l10n.guide)),
      body: ListView(
        key: ValueKey('guide-${_selectedCategory ?? 'all'}-${_query.isEmpty}'),
        padding: responsivePagePadding(context),
        children: [
          if (widget.embedded) ...[
            Text(
              l10n.guide,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 2),
            Text(
              l10n.guideSubtitle,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
          ],
          TextField(
            onChanged: (value) => setState(() => _query = value),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search_rounded),
              hintText: l10n.guideSearchHint,
            ),
          ),
          const SizedBox(height: 12),
          if (_query.trim().isEmpty && _selectedCategory == null) ...[
            Text(
              l10n.guideQuickStart,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 2),
            Text(
              l10n.guideQuickStartHint,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            for (var index = 0; index < quickStart.length; index++) ...[
              Card(
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  key: ValueKey(
                    'guide-quick-start-${quickStart[index].guideKey}',
                  ),
                  leading: CircleAvatar(child: Text('${index + 1}')),
                  title: Text(
                    id ? quickStart[index].titleId : quickStart[index].titleEn,
                  ),
                  trailing:
                      completedGuideIds?.contains(quickStart[index].guideKey) ==
                          true
                      ? const Icon(
                          Icons.check_circle_rounded,
                          color: Colors.green,
                        )
                      : const Icon(Icons.chevron_right_rounded),
                  onTap: () => openModule(quickStart[index]),
                ),
              ),
              const SizedBox(height: 6),
            ],
            const SizedBox(height: 6),
          ],
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(l10n.all),
                    selected: _selectedCategory == null,
                    onSelected: (_) => setState(() => _selectedCategory = null),
                  ),
                ),
                for (final category in allCategories)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      avatar: Icon(_categoryIcon(category), size: 16),
                      label: Text(_categoryName(category, id)),
                      selected: _selectedCategory == category,
                      onSelected: (_) =>
                          setState(() => _selectedCategory = category),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          if (visible.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Text(
                l10n.guideNoResults,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          for (final category in categories) ...[
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 8),
              child: Text(
                _categoryName(category, id),
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
            ),
            for (final module in visible.where(
              (item) => item.category == category,
            )) ...[
              Card(
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  leading: Icon(_categoryIcon(category)),
                  title: Text(id ? module.titleId : module.titleEn),
                  subtitle: Text(id ? module.summaryId : module.summaryEn),
                  trailing: completedGuideIds?.contains(module.guideKey) == true
                      ? const Icon(
                          Icons.check_circle_rounded,
                          color: Colors.green,
                        )
                      : const Icon(Icons.chevron_right_rounded),
                  onTap: () => openModule(module),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ],
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              l10n.mindsetDisclaimer,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  String _categoryName(String category, bool id) => switch (category) {
    'getting-started' =>
      id ? 'Panduan Awal & Fitur' : 'Getting Started & Features',
    'analysis-manual' => id ? 'Manual Analisis' : 'Analysis Manual',
    'glossary' => id ? 'Glosarium' : 'Glossary',
    'privacy' => id ? 'Data & Privasi' : 'Data & Privacy',
    _ => id ? 'Psikologi & Disiplin' : 'Psychology & Discipline',
  };

  IconData _categoryIcon(String category) => switch (category) {
    'getting-started' => Icons.lightbulb_outline_rounded,
    'analysis-manual' => Icons.candlestick_chart_rounded,
    'glossary' => Icons.menu_book_outlined,
    'privacy' => Icons.shield_outlined,
    _ => Icons.psychology_alt_outlined,
  };
}

class _MindsetModuleScreen extends StatefulWidget {
  const _MindsetModuleScreen({
    required this.module,
    required this.id,
    required this.initiallyCompleted,
  });
  final _MindsetModule module;
  final bool id;
  final bool initiallyCompleted;

  @override
  State<_MindsetModuleScreen> createState() => _MindsetModuleScreenState();
}

class _MindsetModuleScreenState extends State<_MindsetModuleScreen> {
  ProgressionEvidenceSession? _evidence;
  Timer? _timer;
  bool _isStarting = false;
  bool _isCompleting = false;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _completed = widget.initiallyCompleted;
    if (widget.module.guideId != null && !_completed) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _startEvidence());
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _startEvidence() async {
    setState(() => _isStarting = true);
    try {
      final response = await context
          .read<AuthProvider>()
          .client
          .progression
          .startProgressionEvidence(
            progressionEvidenceStartInput: ProgressionEvidenceStartInput(
              (b) => b
                ..source_ =
                    ProgressionEvidenceStartInputSource_Enum.guideCompletion
                ..guideId = widget.module.guideId,
            ),
          );
      if (!mounted) return;
      setState(() => _evidence = response.data);
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    } catch (_) {
      // Artikel tetap bisa dibaca ketika XP sudah pernah diklaim/tidak tersedia.
    } finally {
      if (mounted) setState(() => _isStarting = false);
    }
  }

  Future<void> _complete() async {
    final evidence = _evidence;
    if (evidence == null || !_canComplete || _isCompleting) return;
    setState(() => _isCompleting = true);
    try {
      final award =
          (await context
                  .read<AuthProvider>()
                  .client
                  .progression
                  .recordProgressionActivity(
                    progressionActivityInput: ProgressionActivityInput(
                      (b) => b.token = evidence.token,
                    ),
                  ))
              .data;
      if (!mounted) return;
      setState(() => _completed = true);
      if (award?.awarded == true) {
        unawaited(context.read<ProgressionProvider>().refresh(silent: true));
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            award?.awarded == true
                ? context.l10n.xpAwarded(award!.xp, context.l10n.guide)
                : context.l10n.guideComplete,
          ),
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.guideProgressFailed)),
        );
      }
    } finally {
      if (mounted) setState(() => _isCompleting = false);
    }
  }

  bool get _canComplete =>
      _evidence != null &&
      !DateTime.now().isBefore(_evidence!.minimumCompleteAt);

  @override
  Widget build(BuildContext context) {
    final module = widget.module;
    final id = widget.id;
    final blocks = id ? module.blocksId : module.blocksEn;
    return Scaffold(
      appBar: AppBar(title: Text(id ? module.titleId : module.titleEn)),
      body: ListView(
        padding: responsivePagePadding(context, horizontal: 20),
        children: [
          for (final block in blocks) _GuideBlockView(block: block),
          if (module.guideId != null) ...[
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _completed || !_canComplete || _isCompleting
                  ? null
                  : _complete,
              icon: _isStarting || _isCompleting
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_circle_outline_rounded),
              label: Text(context.l10n.guideComplete),
            ),
            if (!_canComplete && !_completed) ...[
              const SizedBox(height: 8),
              Text(
                context.l10n.guideReading,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _GuideBlockView extends StatelessWidget {
  const _GuideBlockView({required this.block});

  final _GuideBlock block;

  @override
  Widget build(BuildContext context) => switch (block.type) {
    'h' => Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Text(
        block.text,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
      ),
    ),
    'list' => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          for (final item in block.items)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Icon(Icons.circle, size: 6),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(item, style: const TextStyle(height: 1.55)),
                  ),
                ],
              ),
            ),
        ],
      ),
    ),
    'callout' => Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        border: Border(
          left: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 3,
          ),
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        block.text,
        style: const TextStyle(fontWeight: FontWeight.w700, height: 1.55),
      ),
    ),
    _ => Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Text(
        block.text,
        style: const TextStyle(fontSize: 16, height: 1.55),
      ),
    ),
  };
}

class _MindsetModule {
  const _MindsetModule({
    required this.articleId,
    required this.category,
    required this.titleEn,
    required this.titleId,
    required this.summaryEn,
    required this.summaryId,
    required this.blocksEn,
    required this.blocksId,
    this.guideId,
  });

  factory _MindsetModule.fromJson(String category, Map<String, dynamic> json) {
    List<_GuideBlock> blocks(String key) => (json[key] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(_GuideBlock.fromJson)
        .toList(growable: false);

    String summary(String language, List<_GuideBlock> content) {
      final supplied = json['summary_$language'] as String?;
      if (supplied != null) return supplied;
      final body = content
          .firstWhere((block) => block.type == 'p', orElse: () => content.first)
          .text;
      return body.length <= 150
          ? body
          : '${body.substring(0, 147).trimRight()}…';
    }

    final blocksEn = blocks('content_en');
    final blocksId = blocks('content_id');
    final articleId = json['id'] as String;
    return _MindsetModule(
      articleId: articleId,
      category: category,
      titleEn: json['title_en'] as String,
      titleId: json['title_id'] as String,
      summaryEn: summary('en', blocksEn),
      summaryId: summary('id', blocksId),
      blocksEn: blocksEn,
      blocksId: blocksId,
      guideId: _progressionGuideId(articleId),
    );
  }

  final String articleId;
  final String category;
  final String titleEn;
  final String titleId;
  final String summaryEn;
  final String summaryId;
  final List<_GuideBlock> blocksEn;
  final List<_GuideBlock> blocksId;
  final ProgressionEvidenceStartInputGuideIdEnum? guideId;

  String get guideKey => articleId;

  String searchText(bool id) => (id ? blocksId : blocksEn)
      .expand((block) => [block.text, ...block.items])
      .join(' ');
}

class _GuideBlock {
  const _GuideBlock({
    required this.type,
    this.text = '',
    this.items = const [],
  });

  factory _GuideBlock.fromJson(Map<String, dynamic> json) {
    final value = json['val'];
    return _GuideBlock(
      type: json['type'] as String,
      text: value is String ? value : '',
      items: value is List<dynamic> ? value.cast<String>() : const [],
    );
  }

  final String type;
  final String text;
  final List<String> items;
}

ProgressionEvidenceStartInputGuideIdEnum? _progressionGuideId(String id) =>
    switch (id) {
      'how-ai-works' => ProgressionEvidenceStartInputGuideIdEnum.howAiWorks,
      'feature-map' => ProgressionEvidenceStartInputGuideIdEnum.featureMap,
      'reading-analysis' =>
        ProgressionEvidenceStartInputGuideIdEnum.readingAnalysis,
      'validity-confidence' =>
        ProgressionEvidenceStartInputGuideIdEnum.validityConfidence,
      'adaptive-plan' => ProgressionEvidenceStartInputGuideIdEnum.adaptivePlan,
      'personal-progression' =>
        ProgressionEvidenceStartInputGuideIdEnum.personalProgression,
      'analysis-workflow' =>
        ProgressionEvidenceStartInputGuideIdEnum.analysisWorkflow,
      'bias-confidence-validity' =>
        ProgressionEvidenceStartInputGuideIdEnum.biasConfidenceValidity,
      'levels-chart' => ProgressionEvidenceStartInputGuideIdEnum.levelsChart,
      'timeframe-risk-map' =>
        ProgressionEvidenceStartInputGuideIdEnum.timeframeRiskMap,
      'technical-fundamental' =>
        ProgressionEvidenceStartInputGuideIdEnum.technicalFundamental,
      'standard-plan' => ProgressionEvidenceStartInputGuideIdEnum.standardPlan,
      'adaptive-position-plan' =>
        ProgressionEvidenceStartInputGuideIdEnum.adaptivePositionPlan,
      'account-rules' => ProgressionEvidenceStartInputGuideIdEnum.accountRules,
      'terms' => ProgressionEvidenceStartInputGuideIdEnum.terms,
      _ => null,
    };
