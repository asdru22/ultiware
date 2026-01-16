import 'dart:convert';
import 'dart:io';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:flutter/foundation.dart';

class GoogleDriveService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [drive.DriveApi.driveFileScope, drive.DriveApi.driveAppdataScope],
  );

  GoogleSignInAccount? _currentUser;
  drive.DriveApi? _driveApi;

  GoogleSignInAccount? get currentUser => _currentUser;

  bool get isSignedIn => _currentUser != null;

  Future<GoogleSignInAccount?> signIn() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account != null) {
        _currentUser = account;
        await _initializeDriveApi();
      }
      return account;
    } catch (e) {
      debugPrint('Error signing in: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.disconnect();
    _currentUser = null;
    _driveApi = null;
  }

  Future<void> signInSilently() async {
    try {
      final account = await _googleSignIn.signInSilently();
      if (account != null) {
        _currentUser = account;
        await _initializeDriveApi();
      }
    } catch (e) {
      debugPrint('Error signing in silently: $e');
    }
  }

  Future<void> _initializeDriveApi() async {
    if (_currentUser == null) return;
    final httpClient = await _googleSignIn.authenticatedClient();
    if (httpClient != null) {
      _driveApi = drive.DriveApi(httpClient);
    }
  }

  Future<String?> getAppFolderId() async {
    if (_driveApi == null) return null;

    try {
      final fileList = await _driveApi!.files.list(
        q: "mimeType = 'application/vnd.google-apps.folder' andname = 'Ultiware_Data' and trashed = false",
        spaces: 'drive',
      );

      if (fileList.files != null && fileList.files!.isNotEmpty) {
        return fileList.files!.first.id;
      } else {
        final folder = drive.File()
          ..name = 'Ultiware_Data'
          ..mimeType = 'application/vnd.google-apps.folder';

        final createdFolder = await _driveApi!.files.create(folder);
        return createdFolder.id;
      }
    } catch (e) {
      debugPrint("Error getting/creating folder: $e");
      return null;
    }
  }

  Future<void> uploadJson(String jsonContent, String filename) async {
    if (_driveApi == null) return;

    try {
      final folderId = await getAppFolderId();
      if (folderId == null) return;

      final fileList = await _driveApi!.files.list(
        q: "name = '$filename' and '$folderId' in parents and trashed = false",
      );

      final file = drive.File()
        ..name = filename
        ..parents = [folderId];

      final media = drive.Media(
        Stream.value(utf8.encode(jsonContent)),
        utf8.encode(jsonContent).length,
      );

      if (fileList.files != null && fileList.files!.isNotEmpty) {
        await _driveApi!.files.update(
          file,
          fileList.files!.first.id!,
          uploadMedia: media,
        );
      } else {
        await _driveApi!.files.create(file, uploadMedia: media);
      }
      debugPrint("Uploaded JSON: $filename");
    } catch (e) {
      debugPrint("Error uploading JSON: $e");
    }
  }

  Future<void> uploadFile(File localFile, String filename) async {
    if (_driveApi == null) return;

    try {
      final folderId = await getAppFolderId();
      if (folderId == null) return;

      final fileList = await _driveApi!.files.list(
        q: "name = '$filename' and '$folderId' in parents and trashed = false",
      );

      final file = drive.File()
        ..name = filename
        ..parents = [folderId];

      var stream = localFile.openRead();
      var len = await localFile.length();

      final media = drive.Media(stream, len);

      if (fileList.files != null && fileList.files!.isNotEmpty) {
        await _driveApi!.files.update(
          file,
          fileList.files!.first.id!,
          uploadMedia: media,
        );
      } else {
        await _driveApi!.files.create(file, uploadMedia: media);
      }
      debugPrint("Uploaded file: $filename");
    } catch (e) {
      debugPrint("Error uploading file: $e");
    }
  }

  Future<String?> downloadJson(String filename) async {
    if (_driveApi == null) return null;

    try {
      final folderId = await getAppFolderId();
      if (folderId == null) return null;

      final fileList = await _driveApi!.files.list(
        q: "name = '$filename' and '$folderId' in parents and trashed = false",
        $fields: "files(id, name, mimeType)",
      );

      if (fileList.files == null || fileList.files!.isEmpty) {
        debugPrint("File not found on Drive: $filename");
        return null;
      }

      final fileId = fileList.files!.first.id!;
      final media = await _driveApi!.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      final stream = media.stream;
      final content = await utf8.decodeStream(stream);
      debugPrint("Downloaded JSON: $filename");
      return content;
    } catch (e) {
      debugPrint("Error downloading JSON: $e");
      return null;
    }
  }

  Future<void> downloadFile(String driveFilename, File targetFile) async {
    if (_driveApi == null) return;

    try {
      final folderId = await getAppFolderId();
      if (folderId == null) return;

      final fileList = await _driveApi!.files.list(
        q: "name = '$driveFilename' and '$folderId' in parents and trashed = false",
        $fields: "files(id, name, mimeType)",
      );

      if (fileList.files == null || fileList.files!.isEmpty) {
        debugPrint("File not found on Drive: $driveFilename");
        return;
      }

      final fileId = fileList.files!.first.id!;
      final media = await _driveApi!.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      final stream = media.stream;
      final ios = targetFile.openWrite();
      await stream.pipe(ios);
      debugPrint("Downloaded file: $driveFilename to ${targetFile.path}");
    } catch (e) {
      debugPrint("Error downloading file: $e");
    }
  }
}
