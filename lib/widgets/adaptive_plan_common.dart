import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/analysis/adaptive_position_plan.dart';
import '../core/theme/app_colors.dart';
import '../l10n/l10n.dart';

/// Number formatting for the Adaptive plan, matching the web helpers
/// (`formatNumber` / `formatMoney` / `formatRequiredFunds` / `formatProfit`).
class AdaptiveFormat {
  const AdaptiveFormat(this.locale);

  factory AdaptiveFormat.of(BuildContext context) =>
      AdaptiveFormat(Localizations.localeOf(context).toString());

  final String locale;

  static const _dash = '—';

  String number(double? value, [int maxFractionDigits = 2]) {
    if (value == null || !value.isFinite) return _dash;
    final digits = maxFractionDigits <= 0 ? '' : '.${'#' * maxFractionDigits}';
    return NumberFormat('#,##0$digits', locale).format(value);
  }

  String money(double? value, [int maxFractionDigits = 2]) {
    final formatted = number(value, maxFractionDigits);
    return formatted == _dash ? formatted : '\$$formatted';
  }

  /// A funding suggestion must never round below the raw value compared.
  String requiredFunds(double? value) {
    if (value == null || !value.isFinite) return _dash;
    return money((value * 100).ceilToDouble() / 100);
  }

  String profit(double? value) {
    final formatted = money(value);
    return formatted == _dash ? formatted : '+$formatted';
  }
}

String adaptiveTierLabel(BuildContext context, AdaptiveAccountTier tier) =>
    switch (tier) {
      AdaptiveAccountTier.micro => context.l10n.adaptiveAccountMicro,
      AdaptiveAccountTier.mini => context.l10n.adaptiveAccountMini,
      AdaptiveAccountTier.regular => context.l10n.adaptiveAccountRegular,
    };

String adaptiveRiskStyleLabel(BuildContext context, AdaptiveRiskStyle style) =>
    switch (style) {
      AdaptiveRiskStyle.conservative => context.l10n.riskStyleConservative,
      AdaptiveRiskStyle.balanced => context.l10n.riskStyleBalanced,
      AdaptiveRiskStyle.aggressive => context.l10n.riskStyleAggressive,
    };

/// Theme-aware Adaptive colors. The web uses emerald-700 / red-600 / amber-700
/// on light surfaces and emerald-400 / red-400 / amber-300 on dark ones; the
/// bright dark-theme tones reach only ~1.9:1 on white, so light mode must not
/// reuse them.
extension AdaptiveColors on BuildContext {
  bool get _dark => Theme.of(this).brightness == Brightness.dark;

  /// Buy / profit.
  Color get adaptiveBuyColor =>
      _dark ? AppColors.bullishDark : const Color(0xFF047857);

  /// Sell / stop loss / loss.
  Color get adaptiveSellColor =>
      _dark ? AppColors.bearishDark : AppColors.bearishLight;

  /// Warnings and conditional / blocked states.
  Color get adaptiveAmber =>
      _dark ? AppColors.warningDark : AppColors.warningLight;
}

bool adaptiveHas(String? value) => value?.trim().isNotEmpty == true;

class AdaptiveNotice extends StatelessWidget {
  const AdaptiveNotice(this.text, {this.warning = false, super.key});
  final String text;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    final color = warning
        ? context.adaptiveAmber
        : Theme.of(context).colorScheme.primary;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .09),
        border: Border.all(color: color.withValues(alpha: .35)),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Text(text, style: const TextStyle(fontSize: 12.5, height: 1.45)),
    );
  }
}

class AdaptivePanel extends StatelessWidget {
  const AdaptivePanel({required this.children, super.key});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    ),
  );
}

class AdaptiveValueCard extends StatelessWidget {
  const AdaptiveValueCard(
    this.label, {
    this.value,
    this.detail,
    this.borderColor,
    this.valueColor,
    this.detailColor,
    super.key,
  });
  final String label;
  final String? value;
  final String? detail;
  final Color? borderColor;
  final Color? valueColor;
  final Color? detailColor;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(8),
      border: borderColor == null ? null : Border.all(color: borderColor!),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        if (value != null) ...[
          const SizedBox(height: 4),
          Text(
            value!,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: valueColor,
            ),
          ),
        ],
        if (detail != null) ...[
          const SizedBox(height: 4),
          Text(detail!, style: TextStyle(color: detailColor)),
        ],
      ],
    ),
  );
}

class AdaptiveMetric {
  const AdaptiveMetric(this.label, this.value, {this.color});
  final String label;
  final String value;
  final Color? color;
}

class AdaptiveMetricRows extends StatelessWidget {
  const AdaptiveMetricRows(this.values, {super.key});
  final List<AdaptiveMetric> values;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (final entry in values)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  entry.label,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                entry.value,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color:
                      entry.color ??
                      (entry.value.startsWith('+')
                          ? context.adaptiveBuyColor
                          : null),
                ),
              ),
            ],
          ),
        ),
    ],
  );
}

class AdaptiveDetailsExpansion extends StatelessWidget {
  const AdaptiveDetailsExpansion({
    required this.title,
    required this.children,
    this.titleColor,
    this.initiallyExpanded = false,
    super.key,
  });
  final String title;
  final List<Widget> children;
  final Color? titleColor;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      borderRadius: BorderRadius.circular(10),
    ),
    child: ExpansionTile(
      initiallyExpanded: initiallyExpanded,
      tilePadding: const EdgeInsets.symmetric(horizontal: 14),
      childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
      shape: const Border(),
      collapsedShape: const Border(),
      title: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.w900, color: titleColor),
      ),
      children: children,
    ),
  );
}

class AdaptiveOptionRow<T> extends StatelessWidget {
  const AdaptiveOptionRow({
    required this.options,
    required this.selected,
    required this.onSelected,
    this.enabled,
    super.key,
  });

  final List<(T, String)> options;
  final T selected;
  final ValueChanged<T> onSelected;

  /// Options that cannot be picked (kept visible, greyed out).
  final bool Function(T value)? enabled;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (var index = 0; index < options.length; index++) ...[
        if (index > 0) const SizedBox(width: 8),
        Expanded(child: _option(context, options[index])),
      ],
    ],
  );

  Widget _option(BuildContext context, (T, String) option) {
    final scheme = Theme.of(context).colorScheme;
    final isSelected = selected == option.$1;
    final isEnabled = enabled?.call(option.$1) ?? true;
    return Semantics(
      button: true,
      selected: isSelected,
      enabled: isEnabled,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: isEnabled ? () => onSelected(option.$1) : null,
        child: Opacity(
          opacity: isEnabled ? 1 : .4,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            constraints: const BoxConstraints(minHeight: 54),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: isSelected ? scheme.primary.withValues(alpha: 0.16) : null,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? scheme.primary : scheme.outlineVariant,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Text(
              option.$2,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ),
    );
  }
}

/// Small red info box for risk clarifications (web `border-red-500/20`).
class AdaptiveInfoNote extends StatelessWidget {
  const AdaptiveInfoNote(this.text, {this.fontSize = 12, super.key});
  final String text;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    // red-700 on light, red-400 on dark, as on the web.
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textColor = dark ? const Color(0xFFF87171) : const Color(0xFFB91C1C);
    const color = Color(0xFFEF4444);
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        border: Border.all(color: color.withValues(alpha: .25)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: fontSize + 2,
            color: textColor,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: textColor,
                fontSize: fontSize,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
