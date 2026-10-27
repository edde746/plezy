/// A comprehensive background file downloader and uploader for iOS, Android, Desktop and Web
///
/// Use [FileDownloader] to download and upload files.
library;

export 'src/database.dart';
export 'src/exceptions.dart';
export 'src/file_downloader.dart';
export 'src/models.dart';
export 'src/options/auth.dart';
export 'src/options/auth_callback.dart';
export 'src/options/mtls.dart';
export 'src/options/task_options.dart';
export 'src/permissions.dart' show PermissionType, PermissionStatus;
export 'src/persistent_storage.dart';
export 'src/progress_widget.dart';
export 'src/queue/task_queue.dart';
export 'src/task.dart';
export 'src/transfer.dart';
export 'src/transfers.dart';
export 'src/transfer_hint.dart';
export 'src/uri/uri_utils.dart';
export 'src/widgets/transfer_button.dart';
export 'src/widgets/transfer_list_tile.dart';
export 'src/widgets/transfer_progress_bar.dart';
