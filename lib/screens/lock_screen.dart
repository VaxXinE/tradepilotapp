import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../l10n/l10n.dart';
import '../providers/auth_provider.dart';

/// Biometric gate in front of an already-valid session.
///
/// The session token outlives the app process, so without this screen anyone
/// holding an unlocked phone opens Trade Pilot straight into the owner's
/// account. Nothing here re-authenticates against the server — the session is
/// already good; this only proves the person holding the device is the owner.
///
/// Signing out stays reachable, otherwise a device whose biometric sensor stops
/// working would trap the user on this screen forever.
class LockScreen extends StatefulWidget {
  const LockScreen({super.key, this.localAuthentication});

  final LocalAuthentication? localAuthentication;

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  late final LocalAuthentication _localAuthentication;

  bool _isAuthenticating = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _localAuthentication = widget.localAuthentication ?? LocalAuthentication();

    // Prompt straight away: an extra tap before the system sheet adds nothing.
    WidgetsBinding.instance.addPostFrameCallback((_) => _unlock());
  }

  Future<void> _unlock() async {
    if (_isAuthenticating || !mounted) return;
    setState(() {
      _isAuthenticating = true;
      _failed = false;
    });

    try {
      final unlocked = await _localAuthentication.authenticate(
        localizedReason: context.l10n.biometricUnlockReason,
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
      if (!mounted) return;
      if (unlocked) {
        context.read<AuthProvider>().unlockSession();
        return;
      }
      setState(() => _failed = true);
    } on LocalAuthException {
      // Sensor missing, disabled, or no enrolled biometrics. Leaving the user
      // stranded would be worse than dropping the lock for this launch.
      if (!mounted) return;
      context.read<AuthProvider>().unlockSession();
    } finally {
      if (mounted) setState(() => _isAuthenticating = false);
    }
  }

  Future<void> _signOut() async {
    await context.read<AuthProvider>().logout();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final muted = theme.brightness == Brightness.dark
        ? AppColors.darkMutedForeground
        : AppColors.lightMutedForeground;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 120,
                      height: 80,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.darkBackground,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Image.asset(
                        'assets/images/trade_pilot_app_icon.png',
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                        semanticLabel: l10n.tradePilotLogo,
                      ),
                    ),
                  ),
                  const SizedBox(height: 36),
                  Text(
                    l10n.appLocked,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _failed ? l10n.unlockFailed : l10n.appLockedDescription,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _failed ? theme.colorScheme.error : muted,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    key: const Key('unlock-button'),
                    onPressed: _isAuthenticating ? null : _unlock,
                    icon: _isAuthenticating
                        ? const SizedBox.shrink()
                        : const Icon(Icons.fingerprint_rounded),
                    label: Text(
                      _isAuthenticating ? l10n.verifying : l10n.unlock,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    key: const Key('lock-sign-out-button'),
                    onPressed: _isAuthenticating ? null : _signOut,
                    child: Text(l10n.signOut),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
