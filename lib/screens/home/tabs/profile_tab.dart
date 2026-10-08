import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:provider/provider.dart';
import 'package:trade_pilot_api_client/trade_pilot_api_client.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/api/api_config.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../core/topup/topup_return_controller.dart';
import '../../../core/topup/topup_return_link.dart';
import '../../../l10n/l10n.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/credit_provider.dart';
import '../../../providers/progression_provider.dart';
import '../../../services/native_push_service.dart';
import '../../../services/web_handoff.dart';
import '../../../widgets/app_footer.dart';
import '../../../widgets/progression/progression_emblem.dart';
import '../../notifications/notifications_screen.dart';
import '../../price_alert/price_alert_list_screen.dart';
import '../../profile/change_password_screen.dart';
import '../../profile/change_security_question_screen.dart';
import '../../profile/edit_profile_screen.dart';
import '../../profile/privacy_security_screen.dart';
import '../../progression/progression_screen.dart';

/// Opens a URL in an in-app browser tab and resolves with the callback URL.
typedef InAppBrowserAuthenticate =
    Future<String> Function({
      required String url,
      required String callbackUrlScheme,
      FlutterWebAuth2Options options,
    });

class ProfileTab extends StatelessWidget {
  const ProfileTab({
    super.key,
    this.authenticate = FlutterWebAuth2.authenticate,
  });

  /// Replaceable so tests do not open a real browser tab.
  final InAppBrowserAuthenticate authenticate;

  Future<void> _toggleTheme(BuildContext context, bool dark) async {
    await context.read<ThemeController>().setDarkMode(dark);
    if (!context.mounted) return;
    final auth = context.read<AuthProvider>();
    final success = await auth.updateTheme(dark);
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
    // Read both before awaiting: signing out must not depend on this screen
    // still being mounted, nor on push cleanup succeeding.
    final push = context.read<NativePushService?>();
    final auth = context.read<AuthProvider>();
    await push?.unregisterForLogout();
    await auth.logout();
  }

  void _push(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  Future<void> _openTopUp(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final credits = context.read<CreditProvider>();
    final returned = context.read<TopupReturnController>();
    var opened = false;
    try {
      // Signs the browser in with a one-time code so the user does not have
      // to log in again; falls back to the plain page if that is unavailable.
      // `source=app` asks the web page to send the user back to the app once
      // the payment is done. A backend that does not know it yet rejects it,
      // and the plain handoff for /topup is used instead.
      final target = await WebHandoff.resolve(
        auth.client,
        '/topup?source=app',
        fallbackPaths: const ['/topup'],
      );
      credits.markTopupStarted();
      opened = await _openInAppBrowser(target, credits, returned);
      if (!opened) {
        opened = await launchUrl(target, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      // Native browser channel can fail when no compatible app is available.
    }
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.linkOpenFailed)));
    }
  }

  /// Opens the top-up page in an in-app browser tab that closes itself, and
  /// returns the user to the app, when the web page navigates to
  /// `id.tradepilot.app://topup/result?...`. A system browser would ask the
  /// user to confirm leaving the page, because a link opened without a tap is
  /// treated as untrusted. Returns false when the tab could not be opened.
  Future<bool> _openInAppBrowser(
    Uri target,
    CreditProvider credits,
    TopupReturnController returned,
  ) async {
    try {
      final result = await authenticate(
        url: target.toString(),
        callbackUrlScheme: TopupReturnLink.scheme,
        // One-time handoff code signs in inside the tab, so nothing needs to
        // be shared with the system browser; also skips iOS's sign-in notice.
        options: FlutterWebAuth2Options(
          preferEphemeral: defaultTargetPlatform == TargetPlatform.iOS,
        ),
      );
      returned.report(Uri.parse(result));
      return true;
    } on PlatformException catch (error) {
      if (error.code.toLowerCase().contains('cancel')) {
        // The user closed the tab, possibly after paying: check the balance.
        unawaited(credits.refreshAfterTopupReturn());
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    if (user == null) return const SizedBox.shrink();

    final progression = context.watch<ProgressionProvider>().summary;
    final credits = context.watch<CreditProvider>();
    final themeController = context.watch<ThemeController>();
    final l10n = context.l10n;

    return Scaffold(
      body: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 896),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.profile,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _IdentityCard(
                    user: user,
                    progression: progression,
                    onEdit: () => _push(context, const EditProfileScreen()),
                    onProgression: progression == null
                        ? null
                        : () => _push(context, const ProgressionScreen()),
                  ),
                  const SizedBox(height: 24),
                  _AppearanceCard(
                    dark: themeController.isDarkMode,
                    enabled: !auth.isUpdatingProfile,
                    onSelected: (dark) => _toggleTheme(context, dark),
                  ),
                  const SizedBox(height: 1),
                  _SettingsCard(
                    children: [
                      if (user.hasPassword) ...[
                        _ProfileSettingTile(
                          key: const Key('profile-change-password'),
                          icon: Icons.key_rounded,
                          title: l10n.changePassword,
                          onTap: () =>
                              _push(context, const ChangePasswordScreen()),
                        ),
                        const Divider(height: 1),
                        _ProfileSettingTile(
                          key: const Key('profile-security-question'),
                          icon: Icons.shield_outlined,
                          title: l10n.securityQuestion,
                          onTap: () => _push(
                            context,
                            const ChangeSecurityQuestionScreen(),
                          ),
                        ),
                        const Divider(height: 1),
                      ],
                      const BiometricLockTile(
                        key: Key('profile-biometric-lock'),
                      ),
                      const Divider(height: 1),
                      _ProfileSettingTile(
                        key: const Key('profile-privacy-security'),
                        icon: Icons.shield_outlined,
                        title: l10n.profilePrivacySecurity,
                        subtitle: l10n.profilePrivacySecuritySubtitle,
                        onTap: () =>
                            _push(context, const PrivacySecurityScreen()),
                      ),
                      const Divider(height: 1),
                      _ProfileSettingTile(
                        key: const Key('profile-my-alerts'),
                        icon: Icons.notifications_none_rounded,
                        title: l10n.profileMyAlerts,
                        subtitle: l10n.profileMyAlertsSubtitle,
                        onTap: () =>
                            _push(context, const PriceAlertListScreen()),
                      ),
                      const Divider(height: 1),
                      _ProfileSettingTile(
                        key: const Key('profile-notification-settings'),
                        icon: Icons.notifications_none_rounded,
                        title: l10n.profileNotificationSettings,
                        subtitle: l10n.profileNotificationSettingsSubtitle,
                        onTap: () => _push(
                          context,
                          const NotificationsScreen(
                            showSettingsInitially: true,
                          ),
                        ),
                      ),
                      const Divider(height: 1),
                      _ProfileSettingTile(
                        key: const Key('profile-analysis-credits'),
                        icon: Icons.account_balance_wallet_outlined,
                        title: l10n.profileAnalysisCredits,
                        // An unreadable balance must not look like a zero balance.
                        badge: credits.isLoadingBalance
                            ? '…'
                            : credits.balance?.toString() ?? '—',
                        onTap: () => unawaited(_openTopUp(context)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    key: const Key('profile-sign-out'),
                    onPressed: auth.isBusy
                        ? null
                        : () => _confirmLogout(context),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(42),
                      side: BorderSide(
                        color: Theme.of(
                          context,
                        ).colorScheme.error.withValues(alpha: .35),
                      ),
                      foregroundColor: Theme.of(context).colorScheme.error,
                    ),
                    icon: const Icon(Icons.logout_rounded, size: 17),
                    label: Text(l10n.signOut),
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

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({
    required this.user,
    required this.progression,
    required this.onEdit,
    required this.onProgression,
  });

  final User user;
  final ProgressionSummary? progression;
  final VoidCallback onEdit;
  final VoidCallback? onProgression;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _Avatar(
                  name: user.displayName,
                  avatarUrl: user.avatarUrl,
                  onTap: onEdit,
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              user.displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          TextButton(
                            onPressed: onEdit,
                            style: TextButton.styleFrom(
                              minimumSize: const Size(44, 44),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 2,
                              ),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              context.l10n.edit,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        user.email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Container(
                        key: const Key('profile-role-badge'),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colors.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _roleLabel(context, user.role),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (progression case final summary?) ...[
              const SizedBox(height: 24),
              InkWell(
                key: const Key('profile-progression'),
                onTap: onProgression,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHighest.withValues(
                      alpha: .18,
                    ),
                    border: Border.all(color: colors.outlineVariant),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      ProgressionEmblem(
                        level: summary.level,
                        masteryLevel: summary.masteryLevel,
                        size: 48,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.l10n.progressionLevel(summary.level),
                              style: TextStyle(
                                color: colors.primary,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.1,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              summary.rank,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: colors.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _roleLabel(BuildContext context, UserRoleEnum role) => switch (role) {
    UserRoleEnum.superAdmin => context.l10n.roleSuperAdmin,
    UserRoleEnum.admin => context.l10n.roleAdmin,
    _ => context.l10n.roleUser,
  };
}

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.name,
    required this.avatarUrl,
    required this.onTap,
  });

  final String name;
  final String? avatarUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final imageUrl = _resolvedAvatarUrl(avatarUrl);
    return Semantics(
      button: true,
      label: context.l10n.editProfile,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 80,
          height: 80,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: .10),
            border: Border.all(color: colors.outlineVariant),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (imageUrl == null)
                Center(
                  child: Text(
                    name.isEmpty ? '?' : name[0].toUpperCase(),
                    style: TextStyle(
                      color: colors.primary,
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                )
              else
                Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Center(
                    child: Text(
                      name.isEmpty ? '?' : name[0].toUpperCase(),
                      style: TextStyle(
                        color: colors.primary,
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  height: 20,
                  color: colors.surface.withValues(alpha: .85),
                  alignment: Alignment.center,
                  child: const Icon(Icons.photo_camera_outlined, size: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _resolvedAvatarUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    final clean = path.startsWith('/') ? path.substring(1) : path;
    return '${ApiConfig.baseUrl}/storage/$clean';
  }
}

class _AppearanceCard extends StatelessWidget {
  const _AppearanceCard({
    required this.dark,
    required this.enabled,
    required this.onSelected,
  });

  final bool dark;
  final bool enabled;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.appearance,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          _ThemeSegmentedControl(
            isDarkMode: dark,
            enabled: enabled,
            onSelected: onSelected,
          ),
        ],
      ),
    ),
  );
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    clipBehavior: Clip.antiAlias,
    child: Padding(
      padding: const EdgeInsets.all(8),
      child: Column(children: children),
    ),
  );
}

class _ProfileSettingTile extends StatelessWidget {
  const _ProfileSettingTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.badge,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(icon, size: 17, color: colors.onSurfaceVariant),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          color: colors.onSurfaceVariant,
                          fontSize: 11,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (badge != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    badge!,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: colors.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
    return Container(
      key: const Key('profile-theme-segmented'),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: .25),
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: _ThemeSegment(
              icon: Icons.light_mode_outlined,
              label: context.l10n.lightMode,
              selected: !isDarkMode,
              onTap: enabled && isDarkMode ? () => onSelected(false) : null,
            ),
          ),
          Flexible(
            child: _ThemeSegment(
              icon: Icons.dark_mode_outlined,
              label: context.l10n.darkMode,
              selected: isDarkMode,
              onTap: enabled && !isDarkMode ? () => onSelected(true) : null,
            ),
          ),
        ],
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
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: selected ? colors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected ? colors.onPrimary : colors.onSurfaceVariant,
              ),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: selected
                        ? colors.onPrimary
                        : colors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
