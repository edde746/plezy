import 'package:plezy/media/media_item.dart';
import 'package:plezy/services/data_aggregation_service.dart';

/// A reverse-lookup wave fixture. By default every listed server answered;
/// name [failed] / [cancelled] servers to model a wave a server sat out.
LibraryLookupResult libraryLookupResult(
  List<MediaItem> items, {
  Set<String> succeeded = const {},
  Set<String> failed = const {},
  Set<String> cancelled = const {},
}) => (items: items, succeededServerIds: succeeded, cancelledServerIds: cancelled, failedServerIds: failed);
