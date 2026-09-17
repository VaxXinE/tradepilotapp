import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:trade_pilot_api_client/trade_pilot_api_client.dart' as api;

import '../../core/theme/app_colors.dart';
import '../../l10n/l10n.dart';
import '../../models/notification_action.dart';
import '../../providers/analysis_provider.dart';
import '../../providers/notifications_provider.dart';
import '../../services/native_push_service.dart';
import '../../widgets/error_banner.dart';
import '../analysis/analysis_detail_screen.dart';
import '../home/tabs/history_tab.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _showSettings = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      final provider = context.read<NotificationsProvider>();

      unawaited(provider.load());

      unawaited(provider.loadPreferences());
    });
  }

  Future<void> _refresh() async {
    final provider = context.read<NotificationsProvider>();

    await Future.wait([provider.load(), provider.loadPreferences()]);
  }

  Future<void> _handleNotificationTap(api.Notification notification) async {
    final notifications = context.read<NotificationsProvider>();

    // -------------------------------------------------------------------------
    // Mark read dulu.
    // -------------------------------------------------------------------------

    if (notification.readAt == null) {
      await notifications.markRead(notification.id);

      if (!mounted) {
        return;
      }
    }

    final action = NotificationAction.fromData({
      'actionType': notification.actionType?.name,
      'actionId': notification.actionId,
      'notificationId': notification.id,
    });

    if (action == null) {
      return;
    }

    // -------------------------------------------------------------------------
    // SECURITY:
    //
    // Action HARUS allowlisted.
    //
    // Jangan pernah melakukan:
    //
    // Navigator.pushNamed(context, actionType)
    //
    // atau membuka arbitrary URL.
    // -------------------------------------------------------------------------

    switch (action.type) {
      case NotificationActionType.analysis:
        await _openAnalysis(action.actionId!);

        return;

      case NotificationActionType.history:
        await Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const HistoryTab()));
        return;

      case NotificationActionType.notifications:
      case NotificationActionType.dailySummary:
      case NotificationActionType.alerts:
        // Akan di-wire ketika screen mobile terkait
        // sudah masuk parity.
        return;
    }
  }

  Future<void> _openAnalysis(int analysisId) async {
    final provider = context.read<AnalysisProvider>();

    final analysis = await provider.getAnalysis(analysisId, silent: true);

    if (!mounted) {
      return;
    }

    if (analysis == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.notificationAnalysisUnavailable)),
      );

      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            AnalysisDetailScreen(analysisId: analysisId, preloaded: analysis),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final muted = isDark
        ? AppColors.darkMutedForeground
        : AppColors.lightMutedForeground;

    final provider = context.watch<NotificationsProvider>();
    final nativePush = context.watch<NativePushService?>();
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.notifications),
        actions: [
          if (!_showSettings && provider.unreadCount > 0)
            TextButton(
              onPressed: () {
                unawaited(provider.markAllRead());
              },
              child: Text(context.l10n.markAllRead),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            SegmentedButton<bool>(
              segments: [
                ButtonSegment(
                  value: false,
                  icon: const Icon(Icons.inbox_outlined),
                  label: Text(context.l10n.notificationInbox),
                ),
                ButtonSegment(
                  value: true,
                  icon: const Icon(Icons.tune_rounded),
                  label: Text(context.l10n.notificationSettingsTab),
                ),
              ],
              selected: {_showSettings},
              onSelectionChanged: (selection) {
                setState(() => _showSettings = selection.first);
              },
            ),
            const SizedBox(height: 14),

            if (_showSettings) ...[
              if (nativePush != null) ...[
                _NativePushCard(service: nativePush),
                const SizedBox(height: 12),
              ],
              _PreferencesCard(provider: provider),
            ] else ...[
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: provider.isRealtimeConnected
                          ? (isDark
                                ? AppColors.bullishDark
                                : AppColors.bullishLight)
                          : muted,
                    ),
                  ),
                  const SizedBox(width: 7),
                  Text(
                    provider.isRealtimeConnected
                        ? context.l10n.realtimeActive
                        : context.l10n.realtimeConnecting,
                    style: TextStyle(color: muted, fontSize: 10.5),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: Text(
                      context.l10n.notificationInbox,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  if (provider.unreadCount > 0)
                    Text(
                      context.l10n.notificationUnreadCount(
                        provider.unreadCount,
                      ),
                      style: TextStyle(color: muted, fontSize: 10.5),
                    ),
                ],
              ),

              const SizedBox(height: 10),

              ErrorBanner(message: provider.loadError),

              if (provider.isLoading && provider.items.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 50),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (provider.items.isEmpty)
                _EmptyState(muted: muted)
              else
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      for (
                        var index = 0;
                        index < provider.items.length;
                        index++
                      ) ...[
                        _NotificationTile(
                          notification: provider.items[index],
                          onTap: () {
                            unawaited(
                              _handleNotificationTap(provider.items[index]),
                            );
                          },
                        ),
                        if (index != provider.items.length - 1)
                          const Divider(height: 1),
                      ],
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// PREFERENCES
// =============================================================================

class _NativePushCard extends StatelessWidget {
  const _NativePushCard({required this.service});

  final NativePushService service;

  Future<void> _sendTest(BuildContext context) async {
    final accepted = await service.sendTestPush();
    if (!context.mounted) return;

    final message = accepted == null
        ? service.errorMessage ?? context.l10n.errPushTestFailed
        : context.l10n.pushTestConfirmed(accepted);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final lastReceived = service.lastMessageReceivedAt;
    final subtitle = service.isBusy
        ? l10n.pushUpdatingDevice
        : service.isRegistered
        ? lastReceived == null
              ? l10n.pushDeviceRegistered
              : l10n.pushDeviceRegisteredLastReceived(
                  DateFormat('d MMM, HH:mm').format(lastReceived),
                )
        : service.isPermissionDenied
        ? l10n.pushPermissionDenied
        : service.errorMessage ?? l10n.pushReceiveWhenInactive;

    return Card(
      child: Column(
        children: [
          SwitchListTile(
            secondary: const Icon(Icons.phone_android_rounded),
            title: Text(
              l10n.mobilePush,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
            ),
            subtitle: Text(subtitle, style: const TextStyle(fontSize: 11)),
            value: service.isEnabled,
            onChanged: service.isBusy
                ? null
                : (enabled) =>
                      unawaited(enabled ? service.enable() : service.disable()),
          ),
          if (service.isEnabled && service.isRegistered) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: service.isBusy
                      ? null
                      : () => unawaited(_sendTest(context)),
                  icon: service.isBusy
                      ? const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_to_mobile_rounded),
                  label: Text(l10n.sendTestPush),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PreferencesCard extends StatelessWidget {
  const _PreferencesCard({required this.provider});

  final NotificationsProvider provider;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final prefs = provider.preferences;

    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    if (provider.isLoadingPreferences && prefs == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (prefs == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(l10n.notificationPreferencesLoadFailed),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  unawaited(provider.loadPreferences());
                },
                child: Text(l10n.tryAgain),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: ExpansionTile(
        leading: const Icon(Icons.notifications_active_outlined),
        title: Text(
          l10n.notificationPreferences,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
        ),
        subtitle: Text(
          l10n.notificationPreferencesDescription,
          style: TextStyle(color: muted, fontSize: 11),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
        children: [
          if (prefs.disengageNoticeCategory != null)
            _AutoPauseBanner(
              category: prefs.disengageNoticeCategory!,
              onDismiss: provider.isSavingPreferences
                  ? null
                  : () {
                      unawaited(provider.dismissDisengageNotice());
                    },
            ),

          _QuietHoursSettings(provider: provider, prefs: prefs),

          const Divider(),

          _PreferenceSwitch(
            title: l10n.notificationExpiryTitle,
            subtitle: l10n.notificationExpiryDescription,
            value: prefs.pushExpiry,
            enabled: !provider.isSavingPreferences,
            onChanged: (value) {
              unawaited(
                provider.updatePreference(
                  key: NotificationPreferenceKey.expiry,
                  enabled: value,
                ),
              );
            },
          ),

          _PreferenceSwitch(
            title: l10n.notificationBroadcastTitle,
            subtitle: l10n.notificationBroadcastDescription,
            value: prefs.pushBroadcast,
            enabled: !provider.isSavingPreferences,
            onChanged: (value) {
              unawaited(
                provider.updatePreference(
                  key: NotificationPreferenceKey.broadcast,
                  enabled: value,
                ),
              );
            },
          ),

          _PreferenceSwitch(
            title: l10n.notificationDailyTitle,
            subtitle: l10n.notificationDailyDescription,
            value: prefs.pushDailySummary,
            enabled: !provider.isSavingPreferences,
            onChanged: (value) {
              unawaited(
                provider.updatePreference(
                  key: NotificationPreferenceKey.dailySummary,
                  enabled: value,
                ),
              );
            },
          ),

          _PreferenceSwitch(
            title: l10n.notificationNewsTitle,
            subtitle: l10n.notificationNewsDescription,
            value: prefs.pushMarketNews,
            enabled: !provider.isSavingPreferences,
            onChanged: (value) {
              unawaited(
                provider.updatePreference(
                  key: NotificationPreferenceKey.marketNews,
                  enabled: value,
                ),
              );
            },
          ),

          _PreferenceSwitch(
            title: l10n.notificationCalendarTitle,
            subtitle: l10n.notificationCalendarDescription,
            value: prefs.pushCalendarEvents,
            enabled: !provider.isSavingPreferences,
            onChanged: (value) {
              unawaited(
                provider.updatePreference(
                  key: NotificationPreferenceKey.calendarEvents,
                  enabled: value,
                ),
              );
            },
          ),

          _PreferenceSwitch(
            title: l10n.notificationPriceTitle,
            subtitle: l10n.notificationPriceDescription,
            value: prefs.pushPriceAnomaly,
            enabled: !provider.isSavingPreferences,
            onChanged: (value) {
              unawaited(
                provider.updatePreference(
                  key: NotificationPreferenceKey.priceAnomaly,
                  enabled: value,
                ),
              );
            },
          ),

          _PreferenceSwitch(
            title: l10n.notificationSignalTitle,
            subtitle: l10n.notificationSignalDescription,
            value: prefs.pushSignalFlip,
            enabled: !provider.isSavingPreferences,
            onChanged: (value) {
              unawaited(
                provider.updatePreference(
                  key: NotificationPreferenceKey.signalFlip,
                  enabled: value,
                ),
              );
            },
          ),

          _PreferenceSwitch(
            title: l10n.notificationWeeklyTitle,
            subtitle: l10n.notificationWeeklyDescription,
            value: prefs.pushWeeklyRecap,
            enabled: !provider.isSavingPreferences,
            onChanged: (value) {
              unawaited(
                provider.updatePreference(
                  key: NotificationPreferenceKey.weeklyRecap,
                  enabled: value,
                ),
              );
            },
          ),

          const Divider(),
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
              child: Text(
                l10n.notificationGuardrails,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          _PreferenceSwitch(
            title: l10n.notificationRevengeTitle,
            subtitle: l10n.notificationRevengeDescription,
            value: prefs.guardrailRevenge,
            enabled: !provider.isSavingPreferences,
            onChanged: (value) => unawaited(
              provider.updatePreference(
                key: NotificationPreferenceKey.guardrailRevenge,
                enabled: value,
              ),
            ),
          ),
          _PreferenceSwitch(
            title: l10n.notificationOvertradingTitle,
            subtitle: l10n.notificationOvertradingDescription,
            value: prefs.guardrailOvertrading,
            enabled: !provider.isSavingPreferences,
            onChanged: (value) => unawaited(
              provider.updatePreference(
                key: NotificationPreferenceKey.guardrailOvertrading,
                enabled: value,
              ),
            ),
          ),
          _PreferenceSwitch(
            title: l10n.notificationHighRiskTitle,
            subtitle: l10n.notificationHighRiskDescription,
            value: prefs.guardrailHighRisk,
            enabled: !provider.isSavingPreferences,
            onChanged: (value) => unawaited(
              provider.updatePreference(
                key: NotificationPreferenceKey.guardrailHighRisk,
                enabled: value,
              ),
            ),
          ),
          _PreferenceSwitch(
            title: l10n.notificationCoolingOffTitle,
            subtitle: l10n.notificationCoolingOffDescription,
            value: prefs.coolingOffEnabled,
            enabled: !provider.isSavingPreferences,
            onChanged: (value) => unawaited(
              provider.updatePreference(
                key: NotificationPreferenceKey.coolingOff,
                enabled: value,
              ),
            ),
          ),

          const Divider(),

          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
              child: Text(
                l10n.notificationSessionReminders,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),

          _SessionSwitch(
            title: 'Tokyo',
            selected: prefs.marketOpenSessions.any(
              (item) => item.name == 'tokyo',
            ),
            enabled: !provider.isSavingPreferences,
            onChanged: (value) {
              unawaited(
                provider.updateMarketSession(session: 'tokyo', enabled: value),
              );
            },
          ),

          _SessionSwitch(
            title: 'London',
            selected: prefs.marketOpenSessions.any(
              (item) => item.name == 'london',
            ),
            enabled: !provider.isSavingPreferences,
            onChanged: (value) {
              unawaited(
                provider.updateMarketSession(session: 'london', enabled: value),
              );
            },
          ),

          _SessionSwitch(
            title: 'New York',
            selected: prefs.marketOpenSessions.any(
              (item) => item.name == 'newyork',
            ),
            enabled: !provider.isSavingPreferences,
            onChanged: (value) {
              unawaited(
                provider.updateMarketSession(
                  session: 'newyork',
                  enabled: value,
                ),
              );
            },
          ),

          if (provider.preferencesError != null)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                provider.preferencesError!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 11,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _QuietHoursSettings extends StatelessWidget {
  const _QuietHoursSettings({required this.provider, required this.prefs});

  static const _timezones = <String>[
    'Asia/Jakarta',
    'Asia/Makassar',
    'Asia/Jayapura',
    'Asia/Singapore',
    'Asia/Kuala_Lumpur',
    'Asia/Bangkok',
    'Asia/Tokyo',
    'Europe/London',
    'America/New_York',
    'UTC',
  ];

  final NotificationsProvider provider;
  final api.PushPrefs prefs;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final enabled = !provider.isSavingPreferences;
    final zones = {prefs.notificationTimezone, ..._timezones}.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PreferenceSwitch(
          title: l10n.quietHours,
          subtitle: l10n.quietHoursDescription,
          value: prefs.quietHoursEnabled,
          enabled: enabled,
          onChanged: (value) =>
              unawaited(provider.updateQuietHours(enabled: value)),
        ),
        if (prefs.quietHoursEnabled) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Expanded(
                  child: _HourDropdown(
                    label: l10n.quietHoursStart,
                    value: prefs.quietHoursStart,
                    enabled: enabled,
                    onChanged: (value) =>
                        unawaited(provider.updateQuietHours(start: value)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _HourDropdown(
                    label: l10n.quietHoursEnd,
                    value: prefs.quietHoursEnd,
                    enabled: enabled,
                    onChanged: (value) =>
                        unawaited(provider.updateQuietHours(end: value)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: DropdownButtonFormField<String>(
              initialValue: prefs.notificationTimezone,
              decoration: InputDecoration(
                labelText: l10n.notificationTimezone,
                prefixIcon: const Icon(Icons.public_rounded, size: 19),
              ),
              items: zones
                  .map(
                    (zone) => DropdownMenuItem(value: zone, child: Text(zone)),
                  )
                  .toList(),
              onChanged: enabled
                  ? (value) {
                      if (value != null) {
                        unawaited(provider.updateQuietHours(timezone: value));
                      }
                    }
                  : null,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 7, 12, 4),
            child: Text(
              l10n.quietHoursSecurityNotice,
              style: const TextStyle(fontSize: 10.5),
            ),
          ),
        ],
      ],
    );
  }
}

class _HourDropdown extends StatelessWidget {
  const _HourDropdown({
    required this.label,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final String label;
  final String value;
  final bool enabled;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final hour = int.tryParse(value.split(':').first) ?? 0;
    final normalized = '${hour.toString().padLeft(2, '0')}:00';

    return DropdownButtonFormField<String>(
      initialValue: normalized,
      decoration: InputDecoration(labelText: label),
      items: List.generate(24, (index) {
        final value = '${index.toString().padLeft(2, '0')}:00';
        return DropdownMenuItem(value: value, child: Text(value));
      }),
      onChanged: enabled
          ? (value) {
              if (value != null) onChanged(value);
            }
          : null,
    );
  }
}

class _PreferenceSwitch extends StatelessWidget {
  const _PreferenceSwitch({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final String title;
  final String subtitle;

  final bool value;
  final bool enabled;

  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      title: Text(
        title,
        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
      ),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 10.5)),
      value: value,
      onChanged: enabled ? onChanged : null,
    );
  }
}

class _SessionSwitch extends StatelessWidget {
  const _SessionSwitch({
    required this.title,
    required this.selected,
    required this.enabled,
    required this.onChanged,
  });

  final String title;

  final bool selected;
  final bool enabled;

  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      title: Text(title, style: const TextStyle(fontSize: 12)),
      value: selected,
      onChanged: enabled
          ? (value) {
              onChanged(value ?? false);
            }
          : null,
    );
  }
}

class _AutoPauseBanner extends StatelessWidget {
  const _AutoPauseBanner({required this.category, required this.onDismiss});

  final String category;

  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 8, 8, 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Theme.of(context).colorScheme.secondaryContainer,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.notifications_paused_outlined, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              context.l10n.notificationAutoPaused(category),
              style: const TextStyle(fontSize: 11),
            ),
          ),
          IconButton(
            onPressed: onDismiss,
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.close, size: 17),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// NOTIFICATION LIST
// =============================================================================

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, required this.onTap});

  final api.Notification notification;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isUnread = notification.readAt == null;

    final color = _colorFor(context, notification.type);

    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.12),
        child: Icon(_iconFor(notification.type), color: color, size: 18),
      ),
      title: Text(
        notification.title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: isUnread ? FontWeight.w900 : FontWeight.w600,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notification.message,
              style: TextStyle(color: muted, fontSize: 11.5, height: 1.4),
            ),
            const SizedBox(height: 5),
            Text(
              DateFormat(
                'd MMM yyyy, HH:mm',
              ).format(notification.createdAt.toLocal()),
              style: TextStyle(color: muted, fontSize: 9.5),
            ),
          ],
        ),
      ),
      trailing: isUnread
          ? Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color),
            )
          : null,
    );
  }

  static IconData _iconFor(api.NotificationTypeEnum type) {
    switch (type.name) {
      case 'warning':
        return Icons.warning_amber_rounded;

      case 'error':
        return Icons.error_outline_rounded;

      case 'info':
      default:
        return Icons.notifications_none_rounded;
    }
  }

  static Color _colorFor(BuildContext context, api.NotificationTypeEnum type) {
    switch (type.name) {
      case 'warning':
        return Theme.of(context).brightness == Brightness.dark
            ? AppColors.neutralDark
            : AppColors.neutralLight;

      case 'error':
        return Theme.of(context).colorScheme.error;

      case 'info':
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.muted});

  final Color muted;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 42),
        child: Column(
          children: [
            Icon(Icons.notifications_none_rounded, size: 40, color: muted),
            const SizedBox(height: 10),
            Text(
              context.l10n.noNotifications,
              style: TextStyle(color: muted, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
