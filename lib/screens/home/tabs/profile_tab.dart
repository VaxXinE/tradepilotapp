import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trade_pilot_api_client/trade_pilot_api_client.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../providers/auth_provider.dart';
import '../../../screens/notifications/notifications_screen.dart';
import '../../../services/native_push_service.dart';
import '../../profile/change_password_screen.dart';
import '../../profile/edit_profile_screen.dart';
import '../../analytics/analytics_screen.dart';
import '../../daily_summary/daily_summary_screen.dart';
import '../../journal/trade_journal_screen.dart';
import '../../trader_mirror/trader_mirror_screen.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

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

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Keluar'),
        content: const Text('Yakin ingin keluar dari akun ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              'Keluar',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await context.read<NativePushService>().unregister();
    } catch (_) {
      // Unregister push bersifat best effort; sesi lokal tetap harus berakhir.
    } finally {
      if (context.mounted) await context.read<AuthProvider>().logout();
    }
  }

  String _notificationStatus(NativePushService push) {
    if (push.isRegistered) return 'Aktif untuk perangkat ini';
    if (push.isPermissionDenied) return 'Izin sistem tidak diberikan';
    return 'Belum didaftarkan pada perangkat ini';
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
    final push = context.watch<NativePushService>();
    final themeController = context.watch<ThemeController>();
    final user = auth.user;

    if (user == null) return const SizedBox.shrink();
    final isPro = user.selectedMode == UserSelectedModeEnum.pro;

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
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
                    primary: primary,
                    onPrimary: onPrimary,
                    muted: muted,
                  ),
                  const SizedBox(height: 24),
                  _Section(
                    title: 'Akun',
                    children: [
                      ListTile(
                        leading: const Icon(Icons.person_outline_rounded),
                        title: const Text('Informasi Profil'),
                        subtitle: const Text('Ubah nama tampilan'),
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
                    title: 'Preferensi',
                    children: [
                      SwitchListTile(
                        secondary: Icon(
                          themeController.isDarkMode
                              ? Icons.dark_mode_outlined
                              : Icons.light_mode_outlined,
                        ),
                        title: const Text('Tema gelap'),
                        subtitle: Text(
                          themeController.isDarkMode
                              ? 'Aktif • nyaman digunakan pada cahaya rendah'
                              : 'Nonaktif • menggunakan tampilan terang',
                        ),
                        value: themeController.isDarkMode,
                        onChanged: themeController.setDarkMode,
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        secondary: const Icon(Icons.tune_rounded),
                        title: const Text('Mode analisis'),
                        subtitle: Text(
                          isPro
                              ? 'Saat ini: Pro • detail teknis lengkap'
                              : 'Saat ini: Pemula • penjelasan lebih sederhana',
                        ),
                        value: isPro,
                        onChanged: auth.isUpdatingProfile
                            ? null
                            : (value) => _toggleMode(context, value),
                      ),
                    ],
                  ),
                  _Section(
                    title: 'Keamanan',
                    children: [
                      ListTile(
                        leading: const Icon(Icons.lock_outline_rounded),
                        title: const Text('Ganti Password'),
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
                        title: const Text('Pertanyaan Keamanan'),
                        subtitle: Text(
                          user.securityQuestion ?? 'Belum tersedia',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  _Section(
                    title: 'Notifikasi',
                    children: [
                      ListTile(
                        leading: const Icon(Icons.notifications_outlined),
                        title: const Text('Pengaturan Notifikasi'),
                        subtitle: Text(_notificationStatus(push)),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const NotificationsScreen(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  _Section(
                    title: 'Insight & Jurnal',
                    children: [
                      ListTile(
                        leading: const Icon(Icons.menu_book_outlined),
                        title: const Text('Trade Journal'),
                        subtitle: const Text(
                          'Catatan transaksi dan refleksi pribadi',
                        ),
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
                        title: const Text('Analytics'),
                        subtitle: const Text(
                          'Pola aktivitas dan hasil evaluasi',
                        ),
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
                        title: const Text('Ringkasan Harian'),
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
                        title: const Text('Trader Mirror'),
                        subtitle: const Text(
                          'Refleksi kebiasaan berbasis data',
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const TraderMirrorScreen(),
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
                      'Keluar',
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

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.name,
    required this.email,
    required this.primary,
    required this.onPrimary,
    required this.muted,
  });

  final String name;
  final String email;
  final Color primary;
  final Color onPrimary;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: primary,
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
