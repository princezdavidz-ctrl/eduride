import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';

final drawerRecordsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((
      ref,
      path,
    ) async {
      final response = await ref.read(authApiClientProvider).get(path);
      final records =
          response['data'] ??
          response[path.split('/').where((part) => part.isNotEmpty).last];
      if (records is! List) {
        throw const FormatException('The server returned invalid list data.');
      }
      return records.whereType<Map<String, dynamic>>().toList();
    });
