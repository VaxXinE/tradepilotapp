import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:trade_pilot_api_client/trade_pilot_api_client.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/notifications_provider.dart';

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
      context.read<NotificationsProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.darkMutedForeground : AppColors.lightMutedForeground;
    final provider = context.watch<NotificationsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi'),
        actions: [
          if (provider.unreadCount > 0)
            TextButton(
              onPressed: () => context.read<NotificationsProvider>().markAllRead(),
              child: const Text('Tandai semua dibaca'),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<NotificationsProvider>().load(),
        child: provider.isLoading && provider.items.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : provider.items.isEmpty
                ? ListView(
                    children: [
                      SizedBox(height: MediaQuery.of(context).size.height * 0.28),
                      Icon(Icons.notifications_none_rounded, size: 40, color: muted),
                      const SizedBox(height: 12),
                      Center(child: Text('Belum ada notifikasi', style: TextStyle(color: muted, fontWeight: FontWeight.w600))),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: provider.items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final n = provider.items[index];
                      final isUnread = n.readAt == null;
                      final accent = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;
                      return ListTile(
                        onTap: () {
                          if (isUnread) context.read<NotificationsProvider>().markRead(n.id);
                        },
                        leading: CircleAvatar(
                          backgroundColor: accent.withValues(alpha: 0.15),
                          child: Icon(_iconFor(n.type), color: accent, size: 18),
                        ),
                        title: Text(
                          n.title,
                          style: TextStyle(fontWeight: isUnread ? FontWeight.w800 : FontWeight.w600),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 2),
                            Text(n.message, style: TextStyle(color: muted, fontSize: 12.5)),
                            const SizedBox(height: 4),
                            Text(DateFormat('d MMM, HH:mm').format(n.createdAt),
                                style: TextStyle(color: muted, fontSize: 11)),
                          ],
                        ),
                        trailing: isUnread
                            ? Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
                              )
                            : null,
                      );
                    },
                  ),
      ),
    );
  }

  IconData _iconFor(NotificationTypeEnum type) {
    switch (type.name) {
      case 'broadcast':
        return Icons.campaign_outlined;
      case 'analysis_expiring':
        return Icons.schedule_rounded;
      case 'system':
        return Icons.info_outline_rounded;
      default:
        return Icons.notifications_none_rounded;
    }
  }
}
