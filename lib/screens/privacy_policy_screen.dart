import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? colorScheme.surface : const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Kebijakan Privasi', 
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          children: [
            // Header Section
            _buildHeader(colorScheme),
            const SizedBox(height: 32),

            // Main Content Card
            Container(
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              child: Column(
                children: [
                  _buildPolicySection(
                    context,
                    icon: Icons.shield_outlined,
                    title: 'Pendahuluan',
                    content: 'Kami menghargai kepercayaan Anda. Kebijakan ini menjelaskan bagaimana kami mengelola data pribadi Anda saat menggunakan layanan kami.',
                  ),
                  _buildPolicySection(
                    context,
                    icon: Icons.storage_rounded,
                    title: 'Data yang Dikumpulkan',
                    content: '• Informasi akun (Nama, Email, Foto)\n• Catatan pribadi & Pengingat\n• Daftar film & status tontonan\n• Data teknis perangkat',
                  ),
                  _buildPolicySection(
                    context,
                    icon: Icons.insights_rounded,
                    title: 'Tujuan Penggunaan',
                    content: 'Data digunakan untuk sinkronisasi akun, manajemen catatan, keamanan autentikasi, dan peningkatan performa aplikasi secara berkala.',
                  ),
                  _buildPolicySection(
                    context,
                    icon: Icons.lock_outline_rounded,
                    title: 'Keamanan Data',
                    content: 'Kami menggunakan enkripsi dan standar keamanan modern untuk melindungi data Anda, meskipun tidak ada metode internet yang 100% aman.',
                  ),
                  _buildPolicySection(
                    context,
                    icon: Icons.person_search_outlined,
                    title: 'Hak & Pilihan Anda',
                    content: 'Anda berhak mengakses, memperbarui, atau menghapus seluruh data Anda kapan saja melalui pengaturan akun di aplikasi ini.',
                    isLast: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),
            
            // Footer message
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Terima kasih telah mempercayakan catatan dan data tontonan Anda kepada kami 🙏',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme colorScheme) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.privacy_tip_rounded, size: 50, color: colorScheme.primary),
        ),
        const SizedBox(height: 16),
        const Text(
          "Privasi Anda adalah Prioritas",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          "Versi Terbaru: Maret 2026",
          style: TextStyle(fontSize: 12, color: colorScheme.outline),
        ),
      ],
    );
  }

  Widget _buildPolicySection(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String content,
    bool isLast = false,
  }) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: isLast 
            ? null 
            : Border(bottom: BorderSide(color: theme.dividerColor.withValues(alpha: 0.5))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: theme.colorScheme.secondary),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.5,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}