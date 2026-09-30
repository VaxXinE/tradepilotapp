import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/l10n.dart';
import '../../providers/auth_provider.dart';
import 'delete_account_screen.dart';

class PrivacySecurityScreen extends StatelessWidget {
  const PrivacySecurityScreen({super.key});

  Future<void> _open(BuildContext context, String path) async {
    try {
      if (await launchUrl(
        Uri.parse('https://tradepilot.id$path'),
        mode: LaunchMode.externalApplication,
      )) {
        return;
      }
    } catch (_) {
      // The localized error below is safer than leaking plugin details.
    }
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.linkOpenFailed)));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(context.l10n.profilePrivacySecurity)),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Card(child: BiometricLockTile()),
        const SizedBox(height: 12),
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: Text(context.l10n.privacyPolicy),
                trailing: const Icon(Icons.open_in_new_rounded),
                onTap: () => _open(context, '/privacy'),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.description_outlined),
                title: Text(context.l10n.termsOfService),
                trailing: const Icon(Icons.open_in_new_rounded),
                onTap: () => _open(context, '/terms'),
              ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(
                  Icons.delete_forever_outlined,
                  color: Theme.of(context).colorScheme.error,
                ),
                title: Text(
                  context.l10n.deleteAccount,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
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
        ),
      ],
    ),
  );
}

class BiometricLockTile extends StatefulWidget {
  const BiometricLockTile({super.key});

  @override
  State<BiometricLockTile> createState() => BiometricLockTileState();
}

class BiometricLockTileState extends State<BiometricLockTile> {
  bool? _enabled;
  bool _available = false;
  bool _saving = false;

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
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await context.read<AuthProvider>().setBiometricLockEnabled(value);
      if (mounted) setState(() => _enabled = value);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_enabled == null) {
      return ListTile(
        leading: const Icon(Icons.fingerprint_rounded),
        title: Text(context.l10n.biometricLock),
      );
    }
    if (!_available) {
      return ListTile(
        enabled: false,
        leading: const Icon(Icons.fingerprint_rounded),
        title: Text(context.l10n.biometricLock),
        subtitle: Text(context.l10n.biometricLockUnavailable),
      );
    }
    return SwitchListTile(
      key: const Key('biometric-lock-switch'),
      secondary: const Icon(Icons.fingerprint_rounded),
      value: _enabled!,
      onChanged: _saving ? null : _toggle,
      title: Text(context.l10n.biometricLock),
      subtitle: Text(
        _enabled!
            ? context.l10n.biometricLockOn
            : context.l10n.biometricLockOff,
      ),
    );
  }
}
