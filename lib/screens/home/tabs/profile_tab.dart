import 'dart:async';

import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';
import 'package:trade_pilot_api_client/trade_pilot_api_client.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/localization/locale_controller.dart';
import '../../../core/preferences/mental_checklist_controller.dart';
import '../../../core/api/api_config.dart';
import '../../../core/config/sponsor_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../l10n/l10n.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/credit_provider.dart';
import '../../../providers/progression_provider.dart';
import '../../../services/native_push_service.dart';
import '../../../widgets/progression/progression_emblem.dart';
// import '../../../screens/notifications/notifications_screen.dart';
import '../../profile/change_password_screen.dart';
import '../../profile/change_security_question_screen.dart';
import '../../profile/delete_account_screen.dart';
import '../../profile/edit_profile_screen.dart';
import '../../topup/topup_screen.dart';
import '../../analytics/analytics_screen.dart';
import '../../daily_summary/daily_summary_screen.dart';
import '../../journal/trade_journal_screen.dart';
import '../../trader_mirror/trader_mirror_screen.dart';
import '../../mindset/mindset_screen.dart';
import '../../progression/progression_screen.dart';
import '../../performance/performance_screen.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  static const _privacyUrl = 'https://tradepilot.id/privacy';
  static const _termsUrl = 'https://tradepilot.id/terms';
  static const _supportUrl = 'https://tradepilot.id/support';

  Future<void> _openUrl(
    BuildContext context,
    String url, {
    OutboundClickBodyPlacementEnum? placement,
    OutboundClickBodyTargetEnum? target,
  }) async {
    if (placement != null && target != null) {
      unawaited(
        context.read<AuthProvider>().telemetry.recordOutboundClick(
          placement: placement,
          target: target,
          languageCode: Localizations.localeOf(context).languageCode,
        ),
      );
    }
    try {
      if (await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      )) {
        return;
      }
    } catch (_) {
      // Native plugin belum siap/gagal membuka browser; tampilkan error aman.
    }
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.linkOpenFailed)));
    }
  }

  Future<void> _toggleMode(BuildContext context, bool enabled) async {
    final auth = context.read<AuthProvider>();
    final success = await auth.updateSelectedMode(
      enabled ? UserSelectedModeEnum.pro : UserSelectedModeEnum.beginner,
    );

    if (!success && context.mounted && auth.profileError != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(auth.profileError!)));
    }
  }

  Future<void> _toggleTheme(BuildContext context, bool enabled) async {
    await context.read<ThemeController>().setDarkMode(enabled);
    if (!context.mounted) return;
    final auth = context.read<AuthProvider>();
    final success = await auth.updateTheme(enabled);
    if (!success && context.mounted && auth.profileError != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(auth.profileError!)));
    }
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.signOut),
        content: Text(l10n.signOutConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              l10n.signOut,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    await context.read<NativePushService?>()?.unregister();
    if (!context.mounted) return;
    await context.read<AuthProvider>().logout();
  }

  Future<void> _selectLanguage(
    BuildContext context,
    String currentLanguageCode,
  ) async {
    final selected = await showDialog<String>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: Text(context.l10n.language),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(dialogContext, 'en'),
            child: _LanguageOption(
              label: 'English',
              selected: currentLanguageCode == 'en',
            ),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(dialogContext, 'id'),
            child: _LanguageOption(
              label: 'Bahasa Indonesia',
              selected: currentLanguageCode == 'id',
            ),
          ),
        ],
      ),
    );

    if (selected != null && context.mounted) {
      await context.read<LocaleController>().setLanguage(selected);
      if (context.mounted) {
        await context.read<AuthProvider>().updateLanguage(selected);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark
        ? AppColors.darkMutedForeground
        : AppColors.lightMutedForeground;
    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
    final onPrimary = isDark
        ? AppColors.darkPrimaryForeground
        : AppColors.lightPrimaryForeground;
    final auth = context.watch<AuthProvider>();
    final themeController = context.watch<ThemeController>();
    final localeController = context.watch<LocaleController>();
    final l10n = context.l10n;
    final user = auth.user;

    if (user == null) return const SizedBox.shrink();
    final isPro = user.selectedMode == UserSelectedModeEnum.pro;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.profile)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ProfileHeader(
                    name: user.displayName,
                    email: user.email,
                    avatarUrl: user.avatarUrl,
                    primary: primary,
                    onPrimary: onPrimary,
                    muted: muted,
                  ),
                  const SizedBox(height: 12),
                  const _ProgressionProfileCard(),
                  const SizedBox(height: 24),
                  _Section(
                    title: l10n.account,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.person_outline_rounded),
                        title: Text(l10n.profileInformation),
                        subtitle: Text(l10n.changeDisplayName),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const EditProfileScreen(),
                          ),
                        ),
                      ),
                      const _TopUpMenuItem(),
                    ],
                  ),
                  _Section(
                    title: l10n.preferences,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.language_rounded),
                        title: Text(l10n.language),
                        subtitle: Text(
                          localeController.locale.languageCode == 'id'
                              ? l10n.indonesian
                              : l10n.english,
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => _selectLanguage(
                          context,
                          localeController.locale.languageCode,
                        ),
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        secondary: Icon(
                          themeController.isDarkMode
                              ? Icons.dark_mode_outlined
                              : Icons.light_mode_outlined,
                        ),
                        title: Text(l10n.darkTheme),
                        subtitle: Text(
                          themeController.isDarkMode
                              ? l10n.darkThemeEnabled
                              : l10n.darkThemeDisabled,
                        ),
                        value: themeController.isDarkMode,
                        onChanged: auth.isUpdatingProfile
                            ? null
                            : (value) => _toggleTheme(context, value),
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        secondary: const Icon(Icons.tune_rounded),
                        title: Text(l10n.analysisMode),
                        subtitle: Text(
                          isPro
                              ? l10n.proModeDescription
                              : l10n.beginnerModeDescription,
                        ),
                        value: isPro,
                        onChanged: auth.isUpdatingProfile
                            ? null
                            : (value) => _toggleMode(context, value),
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        secondary: const Icon(Icons.checklist_rounded),
                        title: Text(l10n.mentalChecklistPreference),
                        subtitle: Text(l10n.mentalChecklistPreferenceHint),
                        value: context
                            .watch<MentalChecklistController>()
                            .enabled,
                        onChanged: (value) => context
                            .read<MentalChecklistController>()
                            .setEnabled(value),
                      ),
                    ],
                  ),
                  _Section(
                    title: l10n.security,
                    children: [
                      const _BiometricLockTile(),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.lock_outline_rounded),
                        title: Text(l10n.changePassword),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ChangePasswordScreen(),
                          ),
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.help_outline_rounded),
                        title: Text(l10n.securityQuestion),
                        subtitle: Text(
                          user.securityQuestion ?? l10n.notAvailable,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                const ChangeSecurityQuestionScreen(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  _Section(
                    title: l10n.legalAndHelp,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.privacy_tip_outlined),
                        title: Text(l10n.privacyPolicy),
                        trailing: const Icon(Icons.open_in_new_rounded),
                        onTap: () => _openUrl(context, _privacyUrl),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.description_outlined),
                        title: Text(l10n.termsOfService),
                        trailing: const Icon(Icons.open_in_new_rounded),
                        onTap: () => _openUrl(context, _termsUrl),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.support_agent_rounded),
                        title: Text(l10n.support),
                        trailing: const Icon(Icons.open_in_new_rounded),
                        onTap: () => _openUrl(context, _supportUrl),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: Icon(
                          Icons.delete_forever_outlined,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        title: Text(
                          l10n.deleteAccount,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const DeleteAccountScreen(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  // _Section(
                  //   title: 'Notifikasi',
                  //   children: [
                  //     ListTile(
                  //       leading: const Icon(Icons.notifications_outlined),
                  //       title: const Text('Pengaturan Notifikasi'),
                  //       subtitle: const Text('Notifikasi dalam aplikasi'),
                  //       trailing: const Icon(Icons.chevron_right_rounded),
                  //       onTap: () => Navigator.of(context).push(
                  //         MaterialPageRoute(
                  //           builder: (_) => const NotificationsScreen(),
                  //         ),
                  //       ),
                  //     ),
                  //   ],
                  // ),
                  _Section(
                    title: l10n.insightsAndJournal,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.menu_book_outlined),
                        title: Text(l10n.tradeJournal),
                        subtitle: Text(l10n.tradeJournalDescription),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const TradeJournalScreen(),
                          ),
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.insights_outlined),
                        title: Text(l10n.analytics),
                        subtitle: Text(l10n.analyticsDescription),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const AnalyticsScreen(),
                          ),
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.public_rounded),
                        title: const Text('Kinerja AI Publik'),
                        subtitle: const Text(
                          'Rekam jejak anonim seluruh analisis Trade Pilot',
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const PerformanceScreen(),
                          ),
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.today_outlined),
                        title: Text(l10n.dailySummary),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const DailySummaryScreen(),
                          ),
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.self_improvement_outlined),
                        title: Text(l10n.traderMirror),
                        subtitle: Text(l10n.traderMirrorDescription),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const TraderMirrorScreen(),
                          ),
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.school_outlined),
                        title: Text(l10n.guide),
                        subtitle: Text(l10n.guideDescription),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const MindsetScreen(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (showSponsor) ...[
                    const SizedBox(height: 8),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              l10n.sponsoredBySolidPrime,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              l10n.sponsorDisclosure,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 12),
                            FilledButton.icon(
                              onPressed: () => _openUrl(
                                context,
                                sponsorWebsiteUrl,
                                placement:
                                    OutboundClickBodyPlacementEnum.profileCta,
                                target: OutboundClickBodyTargetEnum.sgBerjangka,
                              ),
                              icon: const Icon(Icons.open_in_new_rounded),
                              label: Text(l10n.openSponsorWebsite),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: auth.isBusy
                        ? null
                        : () => _confirmLogout(context),
                    icon: Icon(
                      Icons.logout_rounded,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    label: Text(
                      l10n.signOut,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressionProfileCard extends StatelessWidget {
  const _ProgressionProfileCard();

  @override
  Widget build(BuildContext context) {
    final summary = context.watch<ProgressionProvider>().summary;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const ProgressionScreen())),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              if (summary == null)
                const CircleAvatar(child: Icon(Icons.emoji_events_outlined))
              else
                ProgressionEmblem(
                  level: summary.level,
                  masteryLevel: summary.masteryLevel,
                  size: 54,
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.progressionTitle,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    Text(
                      summary == null
                          ? context.l10n.progressionSubtitle
                          : '${summary.totalXp} XP · ${context.l10n.progressionLevel(summary.level)} · ${summary.rank}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({required this.label, required this.selected});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        if (selected) const Icon(Icons.check_rounded),
      ],
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.name,
    required this.email,
    required this.avatarUrl,
    required this.primary,
    required this.onPrimary,
    required this.muted,
  });

  final String name;
  final String email;
  final String? avatarUrl;
  final Color primary;
  final Color onPrimary;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    final imageUrl = _avatarUrl(avatarUrl);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: primary,
              foregroundImage: imageUrl == null ? null : NetworkImage(imageUrl),
              child: Text(
                name.isEmpty ? '?' : name[0].toUpperCase(),
                style: TextStyle(
                  color: onPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(email, style: TextStyle(color: muted, fontSize: 12.5)),
                ],
              ),
            ),
            Icon(Icons.verified_user_outlined, color: primary, size: 20),
          ],
        ),
      ),
    );
  }

  String? _avatarUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    final clean = path.startsWith('/') ? path.substring(1) : path;
    return '${ApiConfig.baseUrl}/storage/$clean';
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(title, style: Theme.of(context).textTheme.titleSmall),
          ),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(children: children),
          ),
        ],
      ),
    );
  }
}

/// Toggle for the biometric app lock.
///
/// Reads its own state rather than taking it from [AuthProvider] because the
/// value lives in secure storage and only this tile needs it. Hidden entirely
/// on devices with nothing enrolled — offering a lock that cannot engage would
/// just be a switch that silently does nothing.
class _BiometricLockTile extends StatefulWidget {
  const _BiometricLockTile();

  @override
  State<_BiometricLockTile> createState() => _BiometricLockTileState();
}

class _BiometricLockTileState extends State<_BiometricLockTile> {
  bool? _enabled;
  bool _available = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    try {
      final enrolled = await LocalAuthentication().getAvailableBiometrics();
      final enabled = await auth.biometricLockEnabled;
      if (!mounted) return;
      setState(() {
        _available = enrolled.isNotEmpty;
        _enabled = enabled;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _available = false;
        _enabled = false;
      });
    }
  }

  Future<void> _toggle(bool value) async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      await context.read<AuthProvider>().setBiometricLockEnabled(value);
      if (mounted) setState(() => _enabled = value);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final enabled = _enabled;

    if (enabled == null) {
      return ListTile(
        leading: const Icon(Icons.fingerprint_rounded),
        title: Text(l10n.biometricLock),
      );
    }

    if (!_available) {
      return ListTile(
        enabled: false,
        leading: const Icon(Icons.fingerprint_rounded),
        title: Text(l10n.biometricLock),
        subtitle: Text(l10n.biometricLockUnavailable),
      );
    }

    return SwitchListTile(
      key: const Key('biometric-lock-switch'),
      secondary: const Icon(Icons.fingerprint_rounded),
      value: enabled,
      onChanged: _isSaving ? null : _toggle,
      title: Text(l10n.biometricLock),
      subtitle: Text(enabled ? l10n.biometricLockOn : l10n.biometricLockOff),
    );
  }
}

/// Entri `Top Up Credit` beserta badge saldo.
///
/// Saldo di-watch terpisah supaya kegagalan `GET /topups/balance` hanya
/// menghilangkan badge-nya — menu Profile yang lain tidak ikut rusak.
class _TopUpMenuItem extends StatelessWidget {
  const _TopUpMenuItem();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final credit = context.watch<CreditProvider>();
    final theme = Theme.of(context);

    return ListTile(
      leading: const Icon(Icons.account_balance_wallet_outlined),
      title: Text(l10n.topUpCredit),
      subtitle: Text(l10n.creditBalance),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (credit.hasBalance)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '${credit.balance}',
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
      onTap: () async {
        await Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const TopUpScreen()));

        // Saldo bisa berubah setelah approval atau pemakaian credit, jadi
        // segarkan begitu kembali ke Profile.
        if (context.mounted) {
          await credit.loadBalance(silent: true);
        }
      },
    );
  }
}
