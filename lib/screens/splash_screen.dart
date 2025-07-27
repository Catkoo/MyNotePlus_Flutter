import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.indigo,
      body: Center(
        child: Text(
          'MyNotePlus',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.2,
          ),
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
      backgroundColor: const Color(0xFF212121),
      body: Center(
        child: Card(
          margin: const EdgeInsets.all(24),
          color: Colors.orange[100],
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "\u{1F6E0}️ Maintenance Mode",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepOrange,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  style: const TextStyle(fontSize: 16),
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
