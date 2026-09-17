import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../l10n/l10n.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/language_menu_button.dart';

/// Provider-only registration, matching the current web flow.
///
/// The backend password registration endpoint remains available for existing
/// integrations, but new mobile accounts use a verified identity provider.
class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final muted = isDark
        ? AppColors.darkMutedForeground
        : AppColors.lightMutedForeground;
    final l10n = context.l10n;

    return Scaffold(
      body: SafeArea(
        child: Consumer<AuthProvider>(
          builder: (context, auth, _) => Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 448),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                        child: LanguageMenuButton(),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
                      decoration: const BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment(0, -1.25),
                          radius: 1.25,
                          colors: [
                            Color(0xFF201700),
                            Color(0xFF0A0802),
                            Color(0xFF000000),
                          ],
                          stops: [0, 0.45, 1],
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            key: const Key('register-brand-mark'),
                            width: 56,
                            height: 56,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.darkPrimary.withValues(alpha: 0.20),
                                  const Color(
                                    0xFFFACC15,
                                  ).withValues(alpha: 0.15),
                                ],
                              ),
                              border: Border.all(
                                color: AppColors.darkPrimary.withValues(
                                  alpha: 0.30,
                                ),
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Image.asset(
                              'assets/images/trade_pilot_app_icon.png',
                              fit: BoxFit.contain,
                              semanticLabel: l10n.tradePilotLogo,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            l10n.createAccount,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.registerDescription,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFFCBD5E1),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ErrorBanner(message: auth.errorMessage),
                          Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                              side: BorderSide(
                                color: theme.colorScheme.outline,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  OutlinedButton.icon(
                                    key: const Key('register-google-button'),
                                    onPressed: auth.isBusy
                                        ? null
                                        : auth.loginWithGoogle,
                                    icon: const ExcludeSemantics(
                                      child: Text(
                                        'G',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF4285F4),
                                        ),
                                      ),
                                    ),
                                    label: Text(l10n.continueWithGoogle),
                                  ),
                                  if (defaultTargetPlatform ==
                                      TargetPlatform.iOS) ...[
                                    const SizedBox(height: 10),
                                    SignInWithAppleButton(
                                      key: const Key('register-apple-button'),
                                      onPressed: auth.isBusy
                                          ? null
                                          : auth.loginWithApple,
                                      text: l10n.continueWithApple,
                                      height: 48,
                                      borderRadius: const BorderRadius.all(
                                        Radius.circular(AppColors.radiusMd),
                                      ),
                                      style: isDark
                                          ? SignInWithAppleButtonStyle.white
                                          : SignInWithAppleButtonStyle.black,
                                    ),
                                  ],
                                  const SizedBox(height: 16),
                                  Text(
                                    l10n.registerConsent,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: muted,
                                      fontSize: 11,
                                    ),
                                  ),
                                  Wrap(
                                    alignment: WrapAlignment.center,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      TextButton(
                                        onPressed: () => _openLegal('/terms'),
                                        child: Text(l10n.termsOfService),
                                      ),
                                      Text(l10n.andLabel),
                                      TextButton(
                                        onPressed: () => _openLegal('/privacy'),
                                        child: Text(l10n.privacyPolicy),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          for (final item in [
                            (
                              Icons.psychology_outlined,
                              l10n.registerValueInsight,
                            ),
                            (Icons.bolt_rounded, l10n.registerValueFast),
                            (Icons.gps_fixed_rounded, l10n.registerValueRisk),
                          ]) ...[
                            Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary.withValues(
                                      alpha: 0.10,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: theme.colorScheme.primary
                                          .withValues(alpha: 0.20),
                                    ),
                                  ),
                                  child: Icon(
                                    item.$1,
                                    size: 18,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    item.$2,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                          ],
                          const SizedBox(height: 20),
                          TextButton.icon(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.arrow_back_rounded),
                            label: Text(l10n.signIn),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openLegal(String path) => launchUrl(
    Uri.parse('https://tradepilot.id$path'),
    mode: LaunchMode.externalApplication,
  );
}
