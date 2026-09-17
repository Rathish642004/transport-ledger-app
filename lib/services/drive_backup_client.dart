import 'dart:convert';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;

/// Design-doc goal: *real* Google Drive backup/sync — the React prototype
/// only ever simulated this with a `setTimeout` (see `BackupNotifier`'s doc
/// comment in `lib/providers/backup_provider.dart`). This is genuinely new
/// functionality, not a port, and it is the one piece of this app that
/// cannot be exercised by `flutter analyze`/`flutter test` — it needs a real
/// device, a real Google account, and the OAuth client provisioned in the
/// `transport-ledger-c3580` Firebase/Google Cloud project (see
/// `android/app/google-services.json`, git-ignored). `BackupNotifier` is
/// tested against a fake [DriveBackupClient]; this real implementation is
/// unverified beyond `flutter build apk` compiling successfully.
abstract class DriveBackupClient {
  /// Runs the interactive sign-in + `drive.appdata` authorization flow.
  /// Returns the signed-in account's email. Throws on cancellation/failure.
  Future<String> connect();

  Future<void> disconnect();

  /// Overwrites (or creates, on first run) the single backup file in the
  /// app's private `appDataFolder`.
  Future<void> uploadBackup(String jsonContent);

  /// Returns the backup file's contents, or `null` if none has been
  /// uploaded yet.
  Future<String?> downloadBackup();

  /// Best-effort upload with no interactive sign-in fallback — for the
  /// `workmanager` periodic background task (`backup_background_task.dart`),
  /// which runs in a headless isolate with no UI to show a Google account
  /// picker in. Returns `false` (never throws) if there's no silently
  /// restorable session, or anything else goes wrong.
  Future<bool> trySilentUpload(String jsonContent);
}

class GoogleDriveBackupClient implements DriveBackupClient {
  static const _scope = 'https://www.googleapis.com/auth/drive.appdata';
  static const _fileName = 'transport_ledger_backup.json';

  GoogleSignInAccount? _account;
  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await GoogleSignIn.instance.initialize();
    _initialized = true;
  }

  Future<drive.DriveApi> _authorizedApi() async {
    await _ensureInitialized();

    var account = _account;
    account ??= await GoogleSignIn.instance.attemptLightweightAuthentication();
    account ??= await GoogleSignIn.instance.authenticate(scopeHint: [_scope]);

    final headers = await account.authorizationClient.authorizationHeaders([_scope], promptIfNecessary: true);
    if (headers == null) {
      throw StateError('Google Drive access was not authorized.');
    }

    _account = account;
    return drive.DriveApi(_HeaderHttpClient(headers));
  }

  /// Same as [_authorizedApi] but never triggers the interactive
  /// [GoogleSignIn.authenticate] UI, and never throws — returns `null` when
  /// no session can be silently restored or no authorization is cached.
  Future<drive.DriveApi?> _silentApi() async {
    await _ensureInitialized();
    final account = _account ?? await GoogleSignIn.instance.attemptLightweightAuthentication();
    if (account == null) return null;

    final headers = await account.authorizationClient.authorizationHeaders([_scope]);
    if (headers == null) return null;

    _account = account;
    return drive.DriveApi(_HeaderHttpClient(headers));
  }

  @override
  Future<String> connect() async {
    final api = await _authorizedApi();
    // Touch the API once so a bad/expired authorization surfaces here,
    // during "Connect", rather than silently on the first sync.
    await api.files.list(spaces: 'appDataFolder', pageSize: 1, $fields: 'files(id)');
    return _account!.email;
  }

  @override
  Future<void> disconnect() async {
    await GoogleSignIn.instance.disconnect();
    _account = null;
  }

  Future<drive.File?> _findBackupFile(drive.DriveApi api) async {
    final list = await api.files.list(spaces: 'appDataFolder', q: "name = '$_fileName'", $fields: 'files(id)');
    if (list.files == null || list.files!.isEmpty) return null;
    return list.files!.first;
  }

  Future<void> _upload(drive.DriveApi api, String jsonContent) async {
    final bytes = utf8.encode(jsonContent);
    final media = drive.Media(Stream.value(bytes), bytes.length, contentType: 'application/json');

    final existing = await _findBackupFile(api);
    if (existing != null) {
      await api.files.update(drive.File(), existing.id!, uploadMedia: media);
    } else {
      await api.files.create(drive.File(name: _fileName, parents: ['appDataFolder']), uploadMedia: media);
    }
  }

  @override
  Future<void> uploadBackup(String jsonContent) async {
    final api = await _authorizedApi();
    await _upload(api, jsonContent);
  }

  @override
  Future<bool> trySilentUpload(String jsonContent) async {
    try {
      final api = await _silentApi();
      if (api == null) return false;
      await _upload(api, jsonContent);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<String?> downloadBackup() async {
    final api = await _authorizedApi();
    final existing = await _findBackupFile(api);
    if (existing == null) return null;

    final media = await api.files.get(existing.id!, downloadOptions: drive.DownloadOptions.fullMedia) as drive.Media;
    final bytes = await media.stream.fold<List<int>>(<int>[], (acc, chunk) => acc..addAll(chunk));
    return utf8.decode(bytes);
  }
}

/// Attaches the headers from [GoogleSignInAuthorizationClient.authorizationHeaders]
/// to every request — `googleapis`' generated clients take a plain
/// `http.Client`, they don't know about `google_sign_in` at all.
class _HeaderHttpClient extends http.BaseClient {
  _HeaderHttpClient(this._headers) : _inner = http.Client();

  final Map<String, String> _headers;
  final http.Client _inner;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _inner.send(request);
  }
}
