import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/device_helper.dart';
import '../utils/version_helper.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _handleStartupLogic();
  }

  Future<void> _handleStartupLogic() async {
    final version = await getAppVersion();
    final isXiaomi = await isXiaomiOrPoco();
    final alreadyShown = await hasShownXiaomiWarning(version);

    if (isXiaomi && !alreadyShown && mounted) {
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Perhatian"),
          content: const Text(
            "Perangkat Xiaomi/Poco terdeteksi.\n\nAgar notifikasi berjalan lancar, aktifkan izin notifikasi dan atur aplikasi ke mode \"Tidak dibatasi\" di Penghemat Baterai.",
          ),
          actions: [
            TextButton(
              child: const Text("Oke"),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );

      await markXiaomiWarningShown(version);
    }

    await _checkAppStatus();
  }

  Future<void> _checkAppStatus() async {
    await Future.delayed(const Duration(milliseconds: 1500));

    final doc = await FirebaseFirestore.instance
        .collection('app_config')
        .doc('status')
        .get();

    final isMaintenance = doc.data()?['maintenance_mode'] ?? false;
    final message =
        doc.data()?['maintenance_message'] ?? "Sedang dalam pemeliharaan.";

    if (!mounted) return;

    if (isMaintenance) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => MaintenanceScreen(message: message)),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      await user.reload();

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final isDisabled = userDoc.data()?['disabled'] ?? false;

      if (isDisabled) {
        await FirebaseAuth.instance.signOut();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Akun Anda telah dinonaktifkan oleh admin'),
            ),
          );
          Navigator.pushReplacementNamed(context, '/login');
        }
      } else {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Image.asset(
          'lib/assets/icon/mynoteplus.png', // pastikan path sesuai file logo kamu
          width: 250,
          height: 250,
        ),
      ),
    );
  }
}

class MaintenanceScreen extends StatelessWidget {
  final String message;
  const MaintenanceScreen({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade900,
      body: Center(
        child: Card(
          margin: const EdgeInsets.all(24),
          color: Colors.orange.shade100,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.build, size: 72, color: Colors.deepOrange.shade700),
                const SizedBox(height: 16),
                Text(
                  "Maintenance Mode",
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepOrange.shade700,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
/// Panggil fungsi ini saat user berhasil ajukan hapus akun:
Future<void> handleAccountDeletionSuccess(BuildContext context) async {
  await FirebaseAuth.instance.signOut();
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Pengajuan hapus akun berhasil. Terima kasih.'),
      ),
    );
    Navigator.pushReplacementNamed(context, '/login');
  }
}
