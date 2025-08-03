import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/backup_service.dart';
import '../services/google_drive_service.dart';

class ProfileScreenWithBackup extends StatelessWidget {
  const ProfileScreenWithBackup({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profil & Sinkronisasi"),
        centerTitle: true,
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            "Profil",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (user != null)
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.indigo,
                  child: Icon(Icons.person, color: Colors.white),
                ),
                title: Text(user.email ?? "Tanpa email"),
                subtitle: Text("UID: ${user.uid}"),
              ),
            ),
          const SizedBox(height: 24),
          const Text(
            "Sinkronisasi",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          // Tombol Backup
          ElevatedButton.icon(
            icon: const Icon(Icons.backup),
            label: const Text("Backup ke Google Drive"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              try {
                final file = await BackupService().exportDataToJson();
                await GoogleDriveService().uploadJsonBackup(
                  file,
                  "mynoteplus_backup.json",
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("✅ Backup berhasil diupload ke Google Drive"),
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text("❌ Gagal backup: $e")));
              }
            },
          ),
          const SizedBox(height: 12),

          // Tombol Restore
          ElevatedButton.icon(
            icon: const Icon(Icons.restore),
            label: const Text("Pulihkan dari Google Drive"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              try {
                await BackupService().restoreFromJsonBackup();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("✅ Data berhasil dipulihkan")),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("❌ Gagal memulihkan data: $e")),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
