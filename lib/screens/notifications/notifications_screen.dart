import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:trade_pilot_api_client/trade_pilot_api_client.dart' as api;

import '../../core/theme/app_colors.dart';
import '../../providers/analysis_provider.dart';
import '../../providers/notifications_provider.dart';
import '../analysis/analysis_detail_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
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

    final actionType = notification.actionType;

    final actionId = notification.actionId;

    if (actionType == null) {
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

    switch (actionType) {
      case api.NotificationActionTypeEnum.analysis:
        if (actionId == null || actionId <= 0) {
          _showInvalidAction();

          return;
        }

        await _openAnalysis(actionId);

        return;

      case api.NotificationActionTypeEnum.history:
      case api.NotificationActionTypeEnum.notifications:
      case api.NotificationActionTypeEnum.dailySummary:
      case api.NotificationActionTypeEnum.alerts:
        // Akan di-wire ketika screen mobile terkait
        // sudah masuk parity.
        return;

      default:
        // Unknown action dari future backend
        // harus fail closed.
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
        const SnackBar(
          content: Text(
            'Analisis tidak tersedia atau kamu tidak memiliki akses.',
          ),
        ),
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

  void _showInvalidAction() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Target notifikasi tidak valid.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final muted = isDark
        ? AppColors.darkMutedForeground
        : AppColors.lightMutedForeground;

    final provider = context.watch<NotificationsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi'),
        actions: [
          if (provider.unreadCount > 0)
            TextButton(
              onPressed: () {
                unawaited(provider.markAllRead());
              },
              child: const Text('Baca semua'),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: provider.isRealtimeConnected ? Colors.green : muted,
                  ),
                ),
                const SizedBox(width: 7),
                Text(
                  provider.isRealtimeConnected
                      ? 'Realtime aktif'
                      : 'Menghubungkan realtime...',
                  style: TextStyle(color: muted, fontSize: 10.5),
                ),
              ],
            ),

            const SizedBox(height: 14),

            _PreferencesCard(provider: provider),

            const SizedBox(height: 20),

            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Kotak Masuk',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                  ),
                ),
                if (provider.unreadCount > 0)
                  Text(
                    '${provider.unreadCount} belum dibaca',
                    style: TextStyle(color: muted, fontSize: 10.5),
                  ),
              ],
            ),

            const SizedBox(height: 10),

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
        ),
      ),
    );
  }
}

// =============================================================================
// PREFERENCES
// =============================================================================

class _PreferencesCard extends StatelessWidget {
  const _PreferencesCard({required this.provider});

  final NotificationsProvider provider;

  @override
  Widget build(BuildContext context) {
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
              const Text('Preferensi notifikasi belum dapat dimuat.'),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  unawaited(provider.loadPreferences());
                },
                child: const Text('Coba lagi'),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: ExpansionTile(
        leading: const Icon(Icons.notifications_active_outlined),
        title: const Text(
          'Preferensi Notifikasi',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
        ),
        subtitle: Text(
          'Pilih jenis pemberitahuan yang ingin kamu terima.',
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

          _PreferenceSwitch(
            title: 'Analisis kedaluwarsa',
            subtitle: 'Peringatan ketika masa berlaku analisis hampir selesai.',
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
            title: 'Pengumuman',
            subtitle: 'Informasi dan broadcast penting dari Trade Pilot.',
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
            title: 'Ringkasan harian',
            subtitle: 'Ringkasan aktivitas dan market harian.',
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
            title: 'Berita market',
            subtitle: 'Berita penting yang relevan dengan market.',
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
            title: 'Kalender ekonomi',
            subtitle: 'Pengingat event ekonomi berdampak tinggi.',
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
            title: 'Pergerakan harga',
            subtitle: 'Anomali dan perubahan harga yang signifikan.',
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
            title: 'Perubahan sinyal',
            subtitle: 'Ketika bias AI berubah secara bermakna.',
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
            title: 'Rekap mingguan',
            subtitle: 'Ringkasan aktivitas trading setiap minggu.',
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

          const Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: EdgeInsets.fromLTRB(8, 8, 8, 4),
              child: Text(
                'Pengingat Sesi Market',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
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
              'Sebagian notifikasi "$category" otomatis dijeda karena lama tidak dibuka.',
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
        return Colors.orange;

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
              'Belum ada notifikasi',
              style: TextStyle(color: muted, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
