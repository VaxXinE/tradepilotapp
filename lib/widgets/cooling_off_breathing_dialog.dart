import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/l10n.dart';

enum _BreathingPhase { inhale, hold, exhale }

class CoolingOffBreathingDialog extends StatefulWidget {
  const CoolingOffBreathingDialog({
    required this.onWait,
    required this.onContinue,
    this.lossPercent,
    super.key,
  });

  final VoidCallback onWait;
  final VoidCallback onContinue;
  final String? lossPercent;

  @override
  State<CoolingOffBreathingDialog> createState() =>
      _CoolingOffBreathingDialogState();
}

class _CoolingOffBreathingDialogState extends State<CoolingOffBreathingDialog> {
  static const _phaseSeconds = 4;

  _BreathingPhase _phase = _BreathingPhase.inhale;
  int _secondsLeft = _phaseSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_secondsLeft > 1) {
          _secondsLeft--;
          return;
        }
        _phase = switch (_phase) {
          _BreathingPhase.inhale => _BreathingPhase.hold,
          _BreathingPhase.hold => _BreathingPhase.exhale,
          _BreathingPhase.exhale => _BreathingPhase.inhale,
        };
        _secondsLeft = _phaseSeconds;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loss = widget.lossPercent?.trim();
    final body = loss == null || loss.isEmpty
        ? context.l10n.coolingOffBreathingBodyGeneric
        : context.l10n.coolingOffBreathingBody(loss);
    final phaseLabel = switch (_phase) {
      _BreathingPhase.inhale => context.l10n.coolingOffBreathingInhale,
      _BreathingPhase.hold => context.l10n.coolingOffBreathingHold,
      _BreathingPhase.exhale => context.l10n.coolingOffBreathingExhale,
    };
    final size = _phase == _BreathingPhase.exhale ? 72.0 : 128.0;

    return AlertDialog(
      title: Text(context.l10n.coolingOffBreathingTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(body),
          const SizedBox(height: 24),
          SizedBox(
            height: 132,
            child: Center(
              child: AnimatedContainer(
                key: const ValueKey('breathing-orb'),
                duration: const Duration(seconds: _phaseSeconds),
                curve: Curves.easeInOut,
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFBBF24).withValues(alpha: .22),
                  border: Border.all(color: const Color(0xFFF59E0B), width: 2),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Semantics(
            liveRegion: true,
            child: Text(
              '$phaseLabel · $_secondsLeft',
              key: const ValueKey('breathing-phase'),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
      actions: [
        OutlinedButton(
          key: const ValueKey('cooling-off-wait'),
          onPressed: widget.onWait,
          child: Text(context.l10n.coolingOffBreathingWait),
        ),
        FilledButton(
          key: const ValueKey('cooling-off-continue'),
          onPressed: widget.onContinue,
          child: Text(context.l10n.coolingOffBreathingContinue),
        ),
      ],
    );
  }
}
