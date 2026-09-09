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
import '../../../widgets/app_footer.dart';
// import '../../../screens/notifications/notifications_screen.dart';
import '../../profile/change_password_screen.dart';
import '../../profile/change_security_question_screen.dart';
import '../../profile/delete_account_screen.dart';
import '../../profile/edit_profile_screen.dart';
import '../../price_alert/price_alert_list_screen.dart';
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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.profile,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 14),
                  _ProfileHeader(
                    name: user.displayName,
                    email: user.email,
                    role: user.role,
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
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  themeController.isDarkMode
                                      ? Icons.dark_mode_outlined
                                      : Icons.light_mode_outlined,
                                  size: 20,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  l10n.appearance,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            _ThemeSegmentedControl(
                              isDarkMode: themeController.isDarkMode,
                              enabled: !auth.isUpdatingProfile,
                              onSelected: (dark) => _toggleTheme(context, dark),
                            ),
                          ],
                        ),
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
                      if (user.hasPassword) ...[
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
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  const ChangeSecurityQuestionScreen(),
                            ),
                          ),
                        ),
                      ],
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
                        key: const Key('profile-my-alerts'),
                        leading: const Icon(
                          Icons.notifications_active_outlined,
                        ),
                        title: Text(l10n.myPriceAlerts),
                        subtitle: Text(l10n.priceAlertsSubtitle),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const PriceAlertListScreen(),
                          ),
                        ),
                      ),
                      const Divider(height: 1),
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
                        title: Text(l10n.publicAiPerformance),
                        subtitle: Text(l10n.publicAiPerformanceSubtitle),
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
          const AppFooter(),
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
    required this.role,
    required this.avatarUrl,
    required this.primary,
    required this.onPrimary,
    required this.muted,
  });

  final String name;
  final String email;
  final UserRoleEnum role;
  final String? avatarUrl;
  final Color primary;
  final Color onPrimary;
  final Color muted;

  String _roleLabel(BuildContext context) => switch (role) {
    UserRoleEnum.superAdmin => context.l10n.roleSuperAdmin,
    UserRoleEnum.admin => context.l10n.roleAdmin,
    _ => context.l10n.roleUser,
  };

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
                  const SizedBox(height: 6),
                  Container(
                    key: const Key('profile-role-badge'),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondary,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      _roleLabel(context),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSecondary,
                      ),
                    ),
                  ),
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

// =============================================================================
// THEME SEGMENTED CONTROL
// =============================================================================

/// Pilihan tema Terang/Gelap mengikuti kontrol segmented pada mobile web.
class _ThemeSegmentedControl extends StatelessWidget {
  const _ThemeSegmentedControl({
    required this.isDarkMode,
    required this.enabled,
    required this.onSelected,
  });

  final bool isDarkMode;
  final bool enabled;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l10n = context.l10n;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        key: const Key('profile-theme-segmented'),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colors.outlineVariant.withValues(alpha: 0.6),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ThemeSegment(
              icon: Icons.light_mode_outlined,
              label: l10n.lightMode,
              selected: !isDarkMode,
              onTap: enabled && isDarkMode ? () => onSelected(false) : null,
            ),
            const SizedBox(width: 4),
            _ThemeSegment(
              icon: Icons.dark_mode_outlined,
              label: l10n.darkMode,
              selected: isDarkMode,
              onTap: enabled && !isDarkMode ? () => onSelected(true) : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeSegment extends StatelessWidget {
  const _ThemeSegment({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        borderRadius: BorderRadius.circular(9),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? colors.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: selected
                ? const [
                    BoxShadow(
                      color: Color(0x1A000000),
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected ? colors.primary : colors.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? colors.onSurface : colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
