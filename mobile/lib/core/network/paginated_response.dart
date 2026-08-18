// lib/core/network/paginated_response.dart

import 'package:mobile/features/home/domain/feed_response.dart';

class PaginatedResponse<T> {
  final List<T> data;
  final FeedMetaDto meta;

  const PaginatedResponse({required this.data, required this.meta});
}
