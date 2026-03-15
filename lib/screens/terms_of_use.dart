import 'package:flutter/material.dart';

class TermsOfUseScreen extends StatelessWidget {
  const TermsOfUseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      // Menggunakan background yang sedikit berbeda agar card lebih terlihat
      backgroundColor: theme.brightness == Brightness.dark 
          ? colorScheme.surface 
          : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Syarat & Ketentuan', 
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          children: [
            // Header Ilustrasi/Ikon
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.gavel_rounded,
                size: 64,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Harap baca dengan teliti",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.outline,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 32),

            // Card Container untuk isi teks
            Container(
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  )
                ],
              ),
              child: Column(
                children: [
                  _buildModernSection(
                    context,
                    icon: Icons.info_outline,
                    title: 'Pendahuluan',
                    content: 'Selamat datang di aplikasi kami. Dengan menggunakan aplikasi ini, Anda menyetujui untuk mematuhi syarat dan ketentuan yang berlaku. Mohon baca dengan seksama sebelum menggunakan layanan kami.',
                    isFirst: true,
                  ),
                  _buildModernSection(
                    context,
                    icon: Icons.phonelink_setup_rounded,
                    title: 'Penggunaan Aplikasi',
                    content: 'Anda setuju untuk menggunakan aplikasi ini hanya untuk tujuan yang sah dan sesuai dengan hukum yang berlaku. Anda tidak diperkenankan menggunakan aplikasi untuk aktivitas yang melanggar hukum.',
                  ),
                  _buildModernSection(
                    context,
                    icon: Icons.admin_panel_settings_outlined,
                    title: 'Akun Pengguna',
                    content: 'Anda bertanggung jawab atas kerahasiaan akun dan kata sandi Anda. Kami tidak bertanggung jawab atas segala kerugian akibat penggunaan akun Anda oleh pihak lain.',
                  ),
                  _buildModernSection(
                    context,
                    icon: Icons.copyright_rounded,
                    title: 'Hak Kekayaan Intelektual',
                    content: 'Seluruh konten, termasuk teks, gambar, dan fitur dalam aplikasi ini dilindungi oleh hak cipta dan tidak boleh disalin tanpa izin tertulis.',
                  ),
                  _buildModernSection(
                    context,
                    icon: Icons.contact_support_outlined,
                    title: 'Kontak',
                    content: 'Jika Anda memiliki pertanyaan terkait syarat dan ketentuan ini, silakan hubungi kami melalui fitur bantuan di aplikasi.',
                    isLast: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),
            Text(
              'Terakhir diperbarui: Maret 2026',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildModernSection(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String content,
    bool isFirst = false,
    bool isLast = false,
  }) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(24),
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
              Icon(icon, size: 22, color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.6,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.justify,
          ),
        ],
      ),
    );
  }
}