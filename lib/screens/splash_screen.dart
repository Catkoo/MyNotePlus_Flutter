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

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    // Animasi fade-in untuk logo
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
    
    _handleStartupLogic();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // --- LOGIC TETAP SAMA ---
  Future<void> _handleStartupLogic() async {
    final version = await getAppVersion();
    final isXiaomi = await isXiaomiOrPoco();
    final alreadyShown = await hasShownXiaomiWarning(version);

    if (isXiaomi && !alreadyShown && mounted) {
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
    await Future.delayed(const Duration(milliseconds: 2000));
    final doc = await FirebaseFirestore.instance.collection('app_config').doc('status').get();

    final isMaintenance = doc.data()?['maintenance_mode'] ?? false;
    final message = doc.data()?['maintenance_message'] ?? "Sedang dalam pemeliharaan.";

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
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final isDisabled = userDoc.data()?['disabled'] ?? false;

      if (isDisabled) {
        await FirebaseAuth.instance.signOut();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Akun Anda telah dinonaktifkan oleh admin')),
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
      body: FadeTransition(
        opacity: _animation,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'lib/assets/icon/mynoteplus.png',
                width: 180, // Ukuran lebih proporsional
                height: 180,
              ),
              const SizedBox(height: 24),
              const SizedBox(
                width: 40,
                child: LinearProgressIndicator(
                  backgroundColor: Color(0xFFEEEEEE),
                  color: Colors.indigo,
                  minHeight: 3,
                ),
              )
            ],
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
    final theme = Theme.of(context);
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1A1A1A), Color(0xFF2C3E50)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Ilustrasi Maintenance yang lebih estetik
              Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  size: 80,
                  color: Colors.amberAccent,
                ),
              ),
              const SizedBox(height: 40),
              Text(
                "Ups! Sedang Diperbarui",
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  color: Colors.white70,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 50),
              // Tombol placeholder agar user merasa tenang
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.amberAccent.withOpacity(0.5)),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.amberAccent),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "Kembali Segera",
                      style: GoogleFonts.poppins(
                        color: Colors.amberAccent,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> handleAccountDeletionSuccess(BuildContext context) async {
  await FirebaseAuth.instance.signOut();
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Pengajuan hapus akun berhasil. Terima kasih.'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
    Navigator.pushReplacementNamed(context, '/login');
  }
}