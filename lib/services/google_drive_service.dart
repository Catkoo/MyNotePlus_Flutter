import 'dart:io';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:google_sign_in/google_sign_in.dart';
import 'google_auth_client.dart'; // Pastikan file ini ada & benar

class GoogleDriveService {
  final GoogleSignIn _googleSignIn = GoogleSignIn.standard(
    scopes: [drive.DriveApi.driveFileScope],
  );
    GoogleSignIn get googleSignIn => _googleSignIn; // 🆕 Getter
  /// ✅ Upload file JSON ke Google Drive
    Future<void> uploadJsonBackup(File file, String filename) async {
      final googleUser =
          await _googleSignIn.signInSilently() ?? await _googleSignIn.signIn();
      if (googleUser == null) throw Exception("Pengguna belum login Google");

      final auth = await googleUser.authentication;
      final client = GoogleAuthClient({
        'Authorization': 'Bearer ${auth.accessToken}',
      });

      final driveApi = drive.DriveApi(client);

      // 🔍 Cek apakah file backup lama ada
      final fileList = await driveApi.files.list(
        q: "name = '$filename' and mimeType = 'application/json'",
        spaces: 'drive',
        $fields: 'files(id, name)',
      );

      // 🗑️ Hapus file lama jika ada
      if (fileList.files != null && fileList.files!.isNotEmpty) {
        for (var oldFile in fileList.files!) {
          await driveApi.files.delete(oldFile.id!);
        }
      }

      // ⬆️ Upload file baru
      final media = drive.Media(file.openRead(), file.lengthSync());
      final driveFile = drive.File()
        ..name = filename
        ..mimeType = 'application/json';

      final uploadedFile = await driveApi.files.create(
        driveFile,
        uploadMedia: media,
      );

      print('✅ File berhasil diupload/replace: ${uploadedFile.id}');
    }

  /// ✅ Download file backup JSON terbaru dari Google Drive
  Future<File?> downloadLatestBackup(String filename) async {
    final googleUser =
        await _googleSignIn.signInSilently() ?? await _googleSignIn.signIn();
    if (googleUser == null) throw Exception("Pengguna belum login Google");

    final auth = await googleUser.authentication;
    final client = GoogleAuthClient({
      'Authorization': 'Bearer ${auth.accessToken}',
    });

    final driveApi = drive.DriveApi(client);

    final fileList = await driveApi.files.list(
      q: "name = '$filename' and mimeType = 'application/json'",
      spaces: 'drive',
      $fields: 'files(id, name, modifiedTime)',
      orderBy: 'modifiedTime desc',
    );

    if (fileList.files == null || fileList.files!.isEmpty) {
      print('❌ File backup tidak ditemukan.');
      return null;
    }

    final fileId = fileList.files!.first.id;
    final mediaStream =
        await driveApi.files.get(
              fileId!,
              downloadOptions: drive.DownloadOptions.fullMedia,
            )
            as drive.Media;

    final bytes = <int>[];
    await for (final chunk in mediaStream.stream) {
      bytes.addAll(chunk);
    }

    final tempDir = Directory.systemTemp;
    final file = File('${tempDir.path}/$filename');
    await file.writeAsBytes(bytes);

    return file;
  }
}
