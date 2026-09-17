import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/config/sponsor_config.dart';
import '../l10n/l10n.dart';
import '../screens/profile/delete_account_screen.dart';

/// Footer yang tampil di bawah konten seperti pada mobile web.
///
/// Web menampilkan disclaimer, tautan legal, dan atribusi sponsor di setiap
/// halaman `Layout`. Versi mobile memakai konten yang sama, tetapi tautan
/// "Hapus Akun" mengarah ke alur native agar sesi dan token tetap ditangani
/// oleh aplikasi.
class AppFooter extends StatelessWidget {
  const AppFooter({super.key});

  static const privacyUrl = 'https://tradepilot.id/privacy';
  static const termsUrl = 'https://tradepilot.id/terms';
  static const supportUrl = 'https://tradepilot.id/support';

  Future<void> _open(BuildContext context, String url) async {
    final messenger = ScaffoldMessenger.of(context);
    final failed = context.l10n.linkOpenFailed;
    try {
      final opened = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
      if (opened) return;
    } catch (_) {
      // Jatuh ke pesan gagal di bawah.
    }
    messenger.showSnackBar(SnackBar(content: Text(failed)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colors = theme.colorScheme;
    final muted = colors.onSurfaceVariant;

    return Container(
      key: const Key('app-footer'),
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.5)),
        ),
      ),
      child: Column(
        children: [
          Text(
            context.l10n.appFooterDisclaimer,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              height: 1.6,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFFFCD34D) : const Color(0xFFB45309),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              _FooterLink(
                label: context.l10n.privacyPolicy,
                onTap: () => unawaited(_open(context, privacyUrl)),
              ),
              _FooterDot(color: muted),
              _FooterLink(
                label: context.l10n.termsOfService,
                onTap: () => unawaited(_open(context, termsUrl)),
              ),
              _FooterDot(color: muted),
              _FooterLink(
                label: context.l10n.support,
                onTap: () => unawaited(_open(context, supportUrl)),
              ),
              _FooterDot(color: muted),
              _FooterLink(
                label: context.l10n.deleteAccount,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const DeleteAccountScreen(),
                  ),
                ),
              ),
            ],
          ),
          if (showSponsor) ...[
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 4,
              children: [
                Text(
                  context.l10n.sponsoredBy,
                  style: TextStyle(
                    fontSize: 10,
                    color: muted.withValues(alpha: 0.7),
                  ),
                ),
                InkWell(
                  onTap: () => unawaited(_open(context, sponsorWebsiteUrl)),
                  child: Text(
                    'SOLID PRIME',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? const Color(0xFFFCD34D)
                          : const Color(0xFFB45309),
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (showNewsmaker) ...[
            const SizedBox(height: 6),
            Text(
              context.l10n.newsDataVia,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 9,
                color: muted.withValues(alpha: 0.5),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FooterLink extends StatelessWidget {
  const _FooterLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(6),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    ),
  );
}

class _FooterDot extends StatelessWidget {
  const _FooterDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Text(
      '·',
      style: TextStyle(fontSize: 11, color: color.withValues(alpha: 0.5)),
    ),
  );
}
