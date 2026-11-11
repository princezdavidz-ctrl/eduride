import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/navigation/drawer_page_app_bar.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../../navigation/presentation/drawer_page_shell.dart';
import '../../navigation/presentation/providers/drawer_data_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  static const _path = '/notifications';

  Future<void> _markRead(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> notification,
  ) async {
    if (notification['read'] == true) return;
    final id = notification['id']?.toString();
    if (id == null || id.isEmpty) return;

    try {
      await ref.read(authApiClientProvider).patch('/alerts/$id');
      ref.invalidate(drawerRecordsProvider(_path));
    } on Exception catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to update notification: $error')),
      );
    }
  }

  Future<void> _markAllRead(
    BuildContext context,
    WidgetRef ref,
    List<Map<String, dynamic>> notifications,
  ) async {
    final unread = notifications
        .where((notification) => notification['read'] != true)
        .toList();
    try {
      for (final notification in unread) {
        final id = notification['id']?.toString();
        if (id == null || id.isEmpty) continue;
        await ref.read(authApiClientProvider).patch('/alerts/$id');
      }
      ref.invalidate(drawerRecordsProvider(_path));
    } on Exception catch (error) {
      ref.invalidate(drawerRecordsProvider(_path));
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to update notifications: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(drawerRecordsProvider(_path));
    final unread = notifications.valueOrNull
        ?.where((notification) => notification['read'] != true)
        .toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: DrawerPageAppBar(
        title: 'Notifications',
        backgroundColor: AppTheme.background,
        actions: [
          if (unread?.isNotEmpty ?? false)
            TextButton(
              onPressed: () =>
                  _markAllRead(context, ref, notifications.valueOrNull!),
              child: const Text('Mark all read'),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(drawerRecordsProvider(_path).future),
        child: notifications.when(
          data: (items) => items.isEmpty
              ? ListView(
                  children: const [
                    SizedBox(height: 100),
                    DrawerEmptyState(message: 'You have no notifications.'),
                  ],
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
                  children: [
                    ...items.map(
                      (item) => _Notice(
                        data: item,
                        onTap: () => _markRead(context, ref, item),
                      ),
                    ),
                  ],
                ),
          loading: () => ListView(
            children: [
              SizedBox(height: 100),
              Center(child: CircularProgressIndicator()),
            ],
          ),
          error: (error, _) => ListView(
            children: [
              const SizedBox(height: 80),
              DrawerErrorState(
                message: 'Unable to load notifications: $error',
                onRetry: () => ref.invalidate(drawerRecordsProvider(_path)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.data, required this.onTap});

  final Map<String, dynamic> data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isRead = data['read'] == true;
    final title = data['title']?.toString() ?? 'Notification';
    final detail = data['message']?.toString() ?? '';
    final timestamp = DateTime.tryParse(data['createdAt']?.toString() ?? '');
    final timeLabel = timestamp?.toLocal().toString().split('.').first;

    return Semantics(
      button: !isRead,
      label: '$title${isRead ? '' : ', unread'}',
      child: InkWell(
        onTap: isRead ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isRead ? AppTheme.surface : AppTheme.blueTint,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: AppTheme.surface,
                child: Icon(
                  data['severity'] == 'warning'
                      ? Icons.warning_amber_rounded
                      : Icons.notifications_outlined,
                  color: AppTheme.blue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        if (!isRead)
                          const Padding(
                            padding: EdgeInsets.only(left: 8, top: 5),
                            child: _UnreadDot(),
                          ),
                      ],
                    ),
                    if (detail.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        detail,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                    if (timeLabel != null) ...[
                      const SizedBox(height: 7),
                      Text(
                        timeLabel,
                        style: const TextStyle(
                          color: Color(0xFF87938C),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UnreadDot extends StatelessWidget {
  const _UnreadDot();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 8,
      height: 8,
      child: DecoratedBox(
        decoration: BoxDecoration(color: AppTheme.blue, shape: BoxShape.circle),
      ),
    );
  }
}
