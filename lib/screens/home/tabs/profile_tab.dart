import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trade_pilot_api_client/trade_pilot_api_client.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/localization/locale_controller.dart';
import '../../../core/api/api_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../l10n/l10n.dart';
import '../../../providers/auth_provider.dart';
// import '../../../screens/notifications/notifications_screen.dart';
import '../../profile/change_password_screen.dart';
import '../../profile/change_security_question_screen.dart';
import '../../profile/delete_account_screen.dart';
import '../../profile/edit_profile_screen.dart';
import '../../analytics/analytics_screen.dart';
import '../../daily_summary/daily_summary_screen.dart';
import '../../journal/trade_journal_screen.dart';
import '../../trader_mirror/trader_mirror_screen.dart';
import '../../mindset/mindset_screen.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  static const _privacyUrl = 'https://tradepilot.id/privacy';
  static const _termsUrl = 'https://tradepilot.id/terms';
  static const _supportUrl = 'https://tradepilot.id/support';

  Future<void> _openUrl(BuildContext context, String url) async {
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
                    ],
                  ),
                  _Section(
                    title: l10n.security,
                    children: [
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
                        leading: const Icon(Icons.psychology_alt_outlined),
                        title: Text(l10n.traderMindset),
                        subtitle: Text(l10n.traderMindsetDescription),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const MindsetScreen(),
                          ),
                        ),
                      ),
                    ],
                  ),
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
