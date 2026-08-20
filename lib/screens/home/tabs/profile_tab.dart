import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trade_pilot_api_client/trade_pilot_api_client.dart';

import '../../../core/theme/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../profile/change_password_screen.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  Future<void> _toggleMode(BuildContext context, User user) async {
    final auth = context.read<AuthProvider>();
    final newMode = user.selectedMode == UserSelectedModeEnum.pro
        ? UpdateProfileBodySelectedModeEnum.beginner
        : UpdateProfileBodySelectedModeEnum.pro;
    try {
      final response = await auth.client.auth.updateProfile(
        updateProfileBody: UpdateProfileBody((b) => b..selectedMode = newMode),
      );
      if (response.data != null) {
        await auth.refreshMe();
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal mengubah mode. Coba lagi.')),
        );
      }
    }
  }

Future<void> _confirmLogout(
  BuildContext context,
) async {
  final confirmed =
      await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text(
          'Keluar',
        ),
        content: const Text(
          'Yakin ingin keluar dari akun ini?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(
                dialogContext,
                false,
              );
            },
            child: const Text(
              'Batal',
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(
                dialogContext,
                true,
              );
            },
            child: Text(
              'Keluar',
              style: TextStyle(
                color:
                    Theme.of(
                  dialogContext,
                ).colorScheme.error,
              ),
            ),
          ),
        ],
      );
    },
  );

  if (confirmed != true ||
      !context.mounted) {
    return;
  }

  // Jangan melakukan Navigator.push/pop di sini.
  //
  // AuthProvider.logout() mengubah AuthStatus menjadi unauthenticated.
  // SplashScreen sebagai root auth-gate akan otomatis mengganti
  // HomeShell menjadi LoginScreen.
  await context
      .read<AuthProvider>()
      .logout();
}
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.darkMutedForeground : AppColors.lightMutedForeground;
    final primary = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
    final onPrimary = isDark ? AppColors.darkPrimaryForeground : AppColors.lightPrimaryForeground;
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    if (user == null) return const SizedBox.shrink();
    final isPro = user.selectedMode == UserSelectedModeEnum.pro;

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: primary,
                child: Text(
                  user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : '?',
                  style: TextStyle(color: onPrimary, fontWeight: FontWeight.w800, fontSize: 22),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.displayName, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(user.email, style: TextStyle(color: muted, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Mode Trading', style: TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text(isPro ? 'Pro' : 'Pemula', style: TextStyle(color: muted, fontSize: 12.5)),
                      ],
                    ),
                  ),
                  Switch(
                    value: isPro,
                    activeThumbColor: primary,
                    onChanged: (_) => _toggleMode(context, user),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.lock_outline_rounded),
                  title: const Text('Ganti Password'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.help_outline_rounded),
                  title: const Text('Pertanyaan Keamanan'),
                  subtitle: Text(user.securityQuestion ?? '-', maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => _confirmLogout(context),
            icon: Icon(Icons.logout_rounded, color: Theme.of(context).colorScheme.error),
            label: Text('Keluar', style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
  }
}
