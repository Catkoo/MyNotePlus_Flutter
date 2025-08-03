import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'google_drive_service.dart';

class BackupService {
  // 🔧 Konversi Timestamp ke String agar bisa di-backup
  dynamic cleanTimestamps(dynamic value) {
    if (value is Timestamp) {
      return value.toDate().toIso8601String();
    } else if (value is Map) {
      return value.map((key, val) => MapEntry(key, cleanTimestamps(val)));
    } else if (value is List) {
      return value.map(cleanTimestamps).toList();
    } else {
      return value;
    }
  }

  /// 📤 Export data ke file JSON
  Future<File> exportDataToJson() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("Pengguna belum login");

    final uid = user.uid;
    final firestore = FirebaseFirestore.instance;

    final personalSnap = await firestore
        .collection('users')
        .doc(uid)
        .collection('notes')
        .get();

    final filmSnap = await firestore
        .collection('users')
        .doc(uid)
        .collection('film_notes')
        .get();

    final personalNotes = personalSnap.docs
        .map((doc) => cleanTimestamps(doc.data()))
        .toList();
    final filmNotes = filmSnap.docs
        .map((doc) => cleanTimestamps(doc.data()))
        .toList();

    final data = {'uid': uid, 'notes': personalNotes, 'filmNotes': filmNotes};

    final jsonString = jsonEncode(data);

    final tempDir = Directory.systemTemp;
    final file = File('${tempDir.path}/backup_mynoteplus.json');
    await file.writeAsString(jsonString);

    return file;
  }

  /// 📥 Restore dari file JSON backup di Google Drive
  Future<void> restoreFromJsonBackup() async {
    final file = await GoogleDriveService().downloadLatestBackup(
      'mynoteplus_backup.json',
    );
    if (file == null) throw Exception('Tidak ada file backup ditemukan.');

    final jsonContent = await file.readAsString();
    final Map<String, dynamic> data = jsonDecode(jsonContent);

    final uid = FirebaseAuth.instance.currentUser!.uid;
    final notes = List<Map<String, dynamic>>.from(data['notes']);
    final films = List<Map<String, dynamic>>.from(data['filmNotes']);

    final firestore = FirebaseFirestore.instance;

    final personalRef = firestore
        .collection('users')
        .doc(uid)
        .collection('notes');
    final filmRef = firestore
        .collection('users')
        .doc(uid)
        .collection('film_notes');

    // 🧹 Kosongkan koleksi lama
    final batches = [await personalRef.get(), await filmRef.get()];
    for (var snapshot in batches) {
      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }
    }

    // ⏳ Konversi kembali String ke Timestamp jika ada
for (var note in notes) {
      // Konversi createdAt
      if (note.containsKey('createdAt') && note['createdAt'] is String) {
        note['createdAt'] = Timestamp.fromDate(
          DateTime.parse(note['createdAt']),
        );
      }

      // Konversi lastEdited
      if (note.containsKey('lastEdited') && note['lastEdited'] is String) {
        note['lastEdited'] = Timestamp.fromDate(
          DateTime.parse(note['lastEdited']),
        );
      }

      await personalRef.add(note);
    }

    for (var film in films) {
      if (film.containsKey('createdAt') && film['createdAt'] is String) {
        film['createdAt'] = Timestamp.fromDate(
          DateTime.parse(film['createdAt']),
        );
      }
      if (film.containsKey('nextEpisodeDate') &&
          film['nextEpisodeDate'] is String) {
        film['nextEpisodeDate'] = Timestamp.fromDate(
          DateTime.parse(film['nextEpisodeDate']),
        );
      }
      await filmRef.add(film);
    }

    print("✅ Restore selesai.");
  }
}
