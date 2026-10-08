import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/l10n.dart';
import '../../providers/progression_provider.dart';
import 'progression_emblem.dart';

/// Shows the level-up celebration once when [ProgressionProvider] reports a
/// level reached in this session (web `ProgressionLevelUpWatcher`).
class ProgressionLevelUpWatcher extends StatefulWidget {
  const ProgressionLevelUpWatcher({required this.child, super.key});

  final Widget child;

  @override
  State<ProgressionLevelUpWatcher> createState() =>
      _ProgressionLevelUpWatcherState();
}

class _ProgressionLevelUpWatcherState extends State<ProgressionLevelUpWatcher> {
  bool _showing = false;

  void _maybeShow(int? level) {
    if (level == null || _showing) return;
    _showing = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final progression = context.read<ProgressionProvider>();
      await showProgressionLevelUpDialog(context, level);
      progression.acknowledgeCelebration();
      _showing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    _maybeShow(
      context.select<ProgressionProvider, int?>((p) => p.celebrationLevel),
    );
    return widget.child;
  }
}

Future<void> showProgressionLevelUpDialog(BuildContext context, int level) =>
    showDialog<void>(
      context: context,
      builder: (dialogContext) => _LevelUpDialog(level: level),
    );

class _LevelUpDialog extends StatelessWidget {
  const _LevelUpDialog({required this.level});

  final int level;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Dialog(
      key: const ValueKey('progression-level-up-dialog'),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  tooltip: l10n.levelUpCloseLabel,
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ),
              ProgressionEmblem(level: level, masteryLevel: 0, size: 112),
              const SizedBox(height: 18),
              Text(
                l10n.levelUpTitle('$level'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                l10n.levelUpDescription,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                key: const ValueKey('progression-level-up-continue'),
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.continueLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
