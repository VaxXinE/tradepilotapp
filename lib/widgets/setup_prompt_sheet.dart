import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../providers/auth_provider.dart';
import '../services/in_app_review_service.dart';
import '../services/native_push_service.dart';
import '../services/setup_prompt_service.dart';

/// Whether this device has a fingerprint or face enrolled.
typedef BiometricsAvailable = Future<bool> Function();

Future<bool> _deviceHasBiometrics() async {
  try {
    return (await LocalAuthentication().getAvailableBiometrics()).isNotEmpty;
  } catch (_) {
    return false;
  }
}

/// Suggests turning on notifications and the biometric lock, once the user has
/// used the app for a while (see `SetupPromptPolicy`). Shows nothing when both
/// are already on or cannot be turned on. Returns whether the sheet was shown.
Future<bool> showSetupPromptIfDue(
  BuildContext context, {
  BiometricsAvailable biometricsAvailable = _deviceHasBiometrics,
}) async {
  final service = context.read<SetupPromptService?>();
  final analyses = context.read<InAppReviewService?>()?.state.analysisCount;
  if (service == null || analyses == null || !service.isDue(analyses)) {
    return false;
  }

  final auth = context.read<AuthProvider>();
  if (auth.status != AuthStatus.authenticated || auth.isLocked) return false;

  final push = context.read<NativePushService?>();
  var needsNotifications = false;
  if (push != null) {
    try {
      await push.initialize();
      // Once the user denied it in system settings, the app cannot ask again.
      needsNotifications = !push.isActive && !push.isPermissionDenied;
    } catch (_) {
      needsNotifications = false;
    }
  }

  var needsBiometric = false;
  try {
    needsBiometric =
        !await auth.biometricLockEnabled && await biometricsAvailable();
  } catch (_) {
    needsBiometric = false;
  }

  if (!needsNotifications && !needsBiometric) return false;
  if (!context.mounted) return false;
  final route = ModalRoute.of(context);
  if (route != null && !route.isCurrent) return false;

  await service.recordAsked();
  if (!context.mounted) return false;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => SetupPromptSheet(
      notifications: needsNotifications ? push : null,
      auth: needsBiometric ? auth : null,
    ),
  );
  return true;
}

class SetupPromptSheet extends StatefulWidget {
  const SetupPromptSheet({super.key, this.notifications, this.auth});

  /// Offered when not null.
  final NativePushService? notifications;

  /// Offered when not null (the biometric lock is stored by [AuthProvider]).
  final AuthProvider? auth;

  @override
  State<SetupPromptSheet> createState() => _SetupPromptSheetState();
}

class _SetupPromptSheetState extends State<SetupPromptSheet> {
  bool _notificationsBusy = false;
  bool _notificationsOn = false;
  bool _biometricBusy = false;
  bool _biometricOn = false;
  String? _error;

  Future<void> _enableNotifications() async {
    final push = widget.notifications;
    if (push == null || _notificationsBusy) return;
    setState(() {
      _notificationsBusy = true;
      _error = null;
    });
    var ok = false;
    try {
      ok = await push.enable();
    } catch (_) {
      ok = false;
    }
    if (!mounted) return;
    setState(() {
      _notificationsBusy = false;
      _notificationsOn = ok;
      if (!ok) _error = push.errorMessage;
    });
  }

  Future<void> _enableBiometric() async {
    final auth = widget.auth;
    if (auth == null || _biometricBusy) return;
    setState(() {
      _biometricBusy = true;
      _error = null;
    });
    var ok = false;
    try {
      await auth.setBiometricLockEnabled(true);
      ok = true;
    } catch (_) {
      ok = false;
    }
    if (!mounted) return;
    setState(() {
      _biometricBusy = false;
      _biometricOn = ok;
      if (!ok) _error = context.l10n.setupPromptBiometricFailed;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final anyEnabled = _notificationsOn || _biometricOn;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.setupPromptTitle,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.setupPromptSubtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          if (widget.notifications != null)
            _SetupOption(
              key: const Key('setup-prompt-notifications'),
              icon: Icons.notifications_active_rounded,
              title: l10n.setupPromptNotificationsTitle,
              body: l10n.setupPromptNotificationsBody,
              busy: _notificationsBusy,
              enabled: _notificationsOn,
              onEnable: _enableNotifications,
            ),
          if (widget.notifications != null && widget.auth != null)
            const SizedBox(height: 12),
          if (widget.auth != null)
            _SetupOption(
              key: const Key('setup-prompt-biometric'),
              icon: Icons.fingerprint_rounded,
              title: l10n.setupPromptBiometricTitle,
              body: l10n.setupPromptBiometricBody,
              busy: _biometricBusy,
              enabled: _biometricOn,
              onEnable: _enableBiometric,
            ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              key: const Key('setup-prompt-error'),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ],
          const SizedBox(height: 12),
          TextButton(
            key: const Key('setup-prompt-dismiss'),
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              anyEnabled ? l10n.setupPromptDone : l10n.setupPromptNotNow,
            ),
          ),
        ],
      ),
    );
  }
}

class _SetupOption extends StatelessWidget {
  const _SetupOption({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    required this.busy,
    required this.enabled,
    required this.onEnable,
  });

  final IconData icon;
  final String title;
  final String body;
  final bool busy;
  final bool enabled;
  final VoidCallback onEnable;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        body,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: enabled
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          size: 18,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(l10n.setupPromptEnabled),
                      ],
                    )
                  : FilledButton.tonal(
                      onPressed: busy ? null : onEnable,
                      child: busy
                          ? const SizedBox.square(
                              dimension: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(l10n.setupPromptEnable),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
