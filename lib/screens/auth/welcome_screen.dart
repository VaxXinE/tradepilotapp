import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_colors.dart';
import '../../l10n/l10n.dart';
import '../../widgets/language_menu_button.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key, required this.preferences});

  static const preferenceKey = 'tradepilot.onboarding.seen';

  final SharedPreferences preferences;

  Future<void> _open(BuildContext context, Widget screen) async {
    await preferences.setBool(preferenceKey, true);
    if (!context.mounted) return;
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = context.l10n;
    final accent = isDark ? AppColors.darkPrimary : AppColors.lightPrimaryText;
    final background = isDark
        ? AppColors.darkBackground
        : AppColors.lightBackground;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -0.45),
            radius: 1.15,
            colors: [
              Color.alphaBlend(accent.withValues(alpha: 0.13), background),
              background,
            ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 40,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Image.asset(
                              'assets/images/trade_pilot_app_icon.png',
                              width: 38,
                              height: 38,
                              semanticLabel: l10n.tradePilotLogo,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text.rich(
                                TextSpan(
                                  text: 'TradePilot',
                                  children: [
                                    TextSpan(
                                      text: '.id',
                                      style: TextStyle(color: accent),
                                    ),
                                  ],
                                ),
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.8,
                                ),
                              ),
                            ),
                            const LanguageMenuButton(),
                          ],
                        ),
                        const SizedBox(height: 56),
                        Text(
                          l10n.onboardingEyebrow.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: accent,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          l10n.onboardingTitle,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.displaySmall?.copyWith(
                            fontSize: 40,
                            height: 1.05,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1.8,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.onboardingDescription,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.55,
                          ),
                        ),
                        const SizedBox(height: 36),
                        _FeatureRow(
                          icon: Icons.psychology_alt_outlined,
                          label: l10n.registerValueInsight,
                        ),
                        const SizedBox(height: 12),
                        _FeatureRow(
                          icon: Icons.query_stats_rounded,
                          label: l10n.onboardingStructuredAnalysis,
                        ),
                        const SizedBox(height: 12),
                        _FeatureRow(
                          icon: Icons.gps_fixed_rounded,
                          label: l10n.registerValueRisk,
                        ),
                        const SizedBox(height: 36),
                        FilledButton.icon(
                          key: const Key('onboarding-register-button'),
                          onPressed: () =>
                              _open(context, const RegisterScreen()),
                          icon: const Icon(Icons.arrow_forward_rounded),
                          iconAlignment: IconAlignment.end,
                          label: Text(l10n.onboardingPrimaryAction),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(56),
                            backgroundColor: isDark
                                ? AppColors.darkPrimary
                                : AppColors.lightPrimary,
                            foregroundColor: AppColors.darkPrimaryForeground,
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          key: const Key('onboarding-login-button'),
                          onPressed: () => _open(context, const LoginScreen()),
                          style: TextButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                          ),
                          child: Text(l10n.onboardingSecondaryAction),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          l10n.analysisSafetyDisclaimerTitle,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = isDark ? AppColors.darkPrimary : AppColors.lightPrimaryText;

    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: accent.withValues(alpha: 0.45)),
          ),
          child: Icon(icon, color: accent, size: 21),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
