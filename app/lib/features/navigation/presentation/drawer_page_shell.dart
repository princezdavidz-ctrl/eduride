import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/navigation/drawer_page_app_bar.dart';
import '../../../core/theme/app_theme.dart';
import 'providers/drawer_data_provider.dart';

typedef DrawerRecordMapper =
    List<DrawerPageItem> Function(List<Map<String, dynamic>> records);

class DrawerDataPage extends ConsumerWidget {
  const DrawerDataPage({
    required this.path,
    required this.title,
    required this.description,
    required this.emptyMessage,
    required this.mapRecords,
    super.key,
  });

  final String path;
  final String title;
  final String description;
  final String emptyMessage;
  final DrawerRecordMapper mapRecords;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final records = ref.watch(drawerRecordsProvider(path));
    return records.when(
      data: (data) => DrawerPageShell(
        title: title,
        description: description,
        items: mapRecords(data),
        emptyMessage: emptyMessage,
      ),
      loading: () => DrawerPageShell(
        title: title,
        description: description,
        isLoading: true,
        emptyMessage: emptyMessage,
      ),
      error: (error, _) => DrawerPageShell(
        title: title,
        description: description,
        errorMessage: 'Unable to load $title: $error',
        emptyMessage: emptyMessage,
        onRetry: () => ref.invalidate(drawerRecordsProvider(path)),
      ),
    );
  }
}

class DrawerPageShell extends StatelessWidget {
  const DrawerPageShell({
    required this.title,
    required this.description,
    this.items = const [],
    this.isLoading = false,
    this.errorMessage,
    this.onRetry,
    this.emptyMessage = 'No information is available yet.',
    super.key,
  });

  final String title;
  final String description;
  final List<DrawerPageItem> items;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: DrawerPageAppBar(
        title: title,
        backgroundColor: AppTheme.background,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(description),
              ],
            ),
          ),
          const SizedBox(height: 18),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.all(48),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (errorMessage != null)
            DrawerErrorState(message: errorMessage!, onRetry: onRetry)
          else if (items.isEmpty)
            DrawerEmptyState(message: emptyMessage)
          else
            ...items.map((item) => DrawerPageItemTile(item: item)),
        ],
      ),
    );
  }
}

class DrawerPageItem {
  const DrawerPageItem({
    required this.title,
    required this.icon,
    this.subtitle,
  });

  final String title;
  final IconData icon;
  final String? subtitle;
}

class DrawerPageItemTile extends StatelessWidget {
  const DrawerPageItemTile({required this.item, super.key});

  final DrawerPageItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: AppTheme.blueTint,
          child: Icon(item.icon, color: AppTheme.blue, size: 20),
        ),
        title: Text(
          item.title,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: item.subtitle == null ? null : Text(item.subtitle!),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}

class DrawerEmptyState extends StatelessWidget {
  const DrawerEmptyState({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          const Icon(Icons.inbox_outlined, color: AppTheme.blue, size: 42),
          const SizedBox(height: 14),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class DrawerErrorState extends StatelessWidget {
  const DrawerErrorState({required this.message, this.onRetry, super.key});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 40),
    child: Column(
      children: [
        Text(message, textAlign: TextAlign.center),
        if (onRetry != null) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try again'),
          ),
        ],
      ],
    ),
  );
}
