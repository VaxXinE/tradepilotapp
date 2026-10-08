import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/l10n.dart';
import '../../providers/auth_provider.dart';
import 'auth_visuals.dart';

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
    final muted = theme.colorScheme.onSurfaceVariant;
    final l10n = context.l10n;

    return Consumer<AuthProvider>(
      builder: (context, auth, _) => AuthPage(
        brandKey: const Key('register-brand-mark'),
        title: l10n.createAccount,
        subtitle: l10n.registerDescription,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthErrorBanner(message: auth.errorMessage),
            AuthPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AuthGoogleButton(
                    buttonKey: const Key('register-google-button'),
                    label: l10n.continueWithGoogle,
                    onPressed: auth.isBusy ? null : auth.loginWithGoogle,
                  ),
                  if (defaultTargetPlatform == TargetPlatform.iOS) ...[
                    const SizedBox(height: 10),
                    SignInWithAppleButton(
                      key: const Key('register-apple-button'),
                      onPressed: auth.isBusy ? null : auth.loginWithApple,
                      text: l10n.continueWithApple,
                      height: 50,
                      borderRadius: const BorderRadius.all(Radius.circular(12)),
                      style: isDark
                          ? SignInWithAppleButtonStyle.white
                          : SignInWithAppleButtonStyle.black,
                    ),
                  ],
                  /* Facebook dan TikTok disembunyikan sampai provider OAuth
                     production tersedia di backend.
                  const SizedBox(height: 10),
                  AuthSocialButton(
                    buttonKey: const Key('register-facebook-button'),
                    label: l10n.continueWithFacebook,
                    onPressed: auth.isBusy ? null : auth.loginWithFacebook,
                    mark: 'f',
                    markColor: const Color(0xFF1877F2),
                  ),
                  const SizedBox(height: 10),
                  AuthSocialButton(
                    buttonKey: const Key('register-tiktok-button'),
                    label: l10n.continueWithTikTok,
                    onPressed: auth.isBusy ? null : auth.loginWithTikTok,
                    mark: '♪',
                    markColor: isDark ? Colors.white : Colors.black,
                  ),
                  */
                  const SizedBox(height: 18),
                  Text(
                    l10n.registerConsent,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: muted, fontSize: 12, height: 1.45),
                  ),
                  const SizedBox(height: 2),
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      TextButton(
                        onPressed: auth.isBusy
                            ? null
                            : () => _openLegal('/terms'),
                        child: Text(l10n.termsOfService),
                      ),
                      Text(l10n.andLabel, style: TextStyle(color: muted)),
                      TextButton(
                        onPressed: auth.isBusy
                            ? null
                            : () => _openLegal('/privacy'),
                        child: Text(l10n.privacyPolicy),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Column(
              children: [
                _BenefitCard(
                  icon: Icons.query_stats_rounded,
                  label: l10n.registerValueInsight,
                ),
                const SizedBox(height: 10),
                _BenefitCard(
                  icon: Icons.speed_rounded,
                  label: l10n.registerValueFast,
                ),
                const SizedBox(height: 10),
                _BenefitCard(
                  icon: Icons.gps_fixed_rounded,
                  label: l10n.registerValueRisk,
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: auth.isBusy ? null : () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back_rounded, size: 18),
              label: Text(l10n.signIn),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openLegal(String path) => launchUrl(
    Uri.parse('https://tradepilot.id$path'),
    mode: LaunchMode.externalApplication,
  );
}

class _BenefitCard extends StatelessWidget {
  const _BenefitCard({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0E1014) : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: authBorderColor(context)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: authAccentColor(context).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: authAccentColor(context).withValues(alpha: 0.45),
              ),
            ),
            child: Icon(icon, size: 20, color: authAccentColor(context)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
