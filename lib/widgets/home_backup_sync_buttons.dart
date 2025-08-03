import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeBackupSyncButtons extends StatelessWidget {
  const HomeBackupSyncButtons({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isGoogleLinked =
        user?.providerData.any((p) => p.providerId == 'google.com') ?? false;

    if (!isGoogleLinked) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.yellow[100],
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: const [
              Icon(Icons.warning, color: Colors.orange),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Untuk menggunakan fitur backup & sinkronisasi,\n"
                  "silakan tautkan akun Google terlebih dahulu.",
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: FilledButton.icon(
              onPressed: () {
                // TODO: Implement Backup
              },
              icon: const Icon(Icons.backup),
              label: const Text("Cadangkan"),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton.icon(
              onPressed: () {
                // TODO: Implement Sync
              },
              icon: const Icon(Icons.sync),
              label: const Text("Sinkronkan"),
            ),
          ),
        ],
      ),
    );
  }
}
