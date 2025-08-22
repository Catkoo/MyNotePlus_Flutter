import 'package:flutter/material.dart';

class TermsOfUseScreen extends StatelessWidget {
  const TermsOfUseScreen({super.key});

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 32, bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.primary, // ikut theme
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSectionContent(BuildContext context, String content) {
    return Text(
      content,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        fontSize: 16,
        height: 1.7,
        letterSpacing: 0.3,
      ),
      textAlign: TextAlign.justify,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Syarat dan Ketentuan'),
        centerTitle: true,
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(context, 'Pendahuluan'),
            _buildSectionContent(
              context,
              'Selamat datang di aplikasi kami. Dengan menggunakan aplikasi ini, Anda menyetujui untuk mematuhi syarat dan ketentuan yang berlaku. Mohon baca dengan seksama sebelum menggunakan layanan kami.',
            ),
            _buildSectionTitle(context, 'Penggunaan Aplikasi'),
            _buildSectionContent(
              context,
              'Anda setuju untuk menggunakan aplikasi ini hanya untuk tujuan yang sah dan sesuai dengan hukum yang berlaku. Anda tidak diperkenankan menggunakan aplikasi untuk aktivitas yang melanggar hukum, merugikan pihak lain, atau mengganggu layanan.',
            ),
            _buildSectionTitle(context, 'Akun Pengguna'),
            _buildSectionContent(
              context,
              'Anda bertanggung jawab atas kerahasiaan akun dan kata sandi Anda. Kami tidak bertanggung jawab atas segala kerugian akibat penggunaan akun Anda oleh pihak lain. Jika ada dugaan penyalahgunaan, segera laporkan kepada kami.',
            ),
            _buildSectionTitle(context, 'Hak Kekayaan Intelektual'),
            _buildSectionContent(
              context,
              'Seluruh konten, termasuk teks, gambar, dan fitur dalam aplikasi ini dilindungi oleh hak cipta dan tidak boleh disalin, didistribusikan, atau digunakan tanpa izin tertulis dari pemilik aplikasi.',
            ),
            _buildSectionTitle(context, 'Pembatasan Tanggung Jawab'),
            _buildSectionContent(
              context,
              'Kami berusaha menyediakan layanan terbaik, namun tidak bertanggung jawab atas kerugian langsung atau tidak langsung yang timbul dari penggunaan aplikasi ini, termasuk kehilangan data atau gangguan layanan.',
            ),
            _buildSectionTitle(context, 'Perubahan Syarat dan Ketentuan'),
            _buildSectionContent(
              context,
              'Kami dapat memperbarui syarat dan ketentuan ini sewaktu-waktu. Perubahan akan diinformasikan melalui aplikasi atau media komunikasi lainnya. Penggunaan layanan setelah perubahan berarti Anda menyetujui syarat yang telah diperbarui.',
            ),
            _buildSectionTitle(context, 'Pengakhiran Layanan'),
            _buildSectionContent(
              context,
              'Kami berhak menghentikan layanan atau menonaktifkan akun pengguna tanpa pemberitahuan sebelumnya jika terjadi pelanggaran syarat dan ketentuan ini.',
            ),
            _buildSectionTitle(context, 'Kontak'),
            _buildSectionContent(
              context,
              'Jika Anda memiliki pertanyaan atau keluhan terkait syarat dan ketentuan ini, silakan hubungi kami melalui fitur bantuan di aplikasi.',
            ),
            const SizedBox(height: 48),
            Center(
              child: Text(
                'Terima kasih telah menggunakan aplikasi kami dan mematuhi syarat dan ketentuan yang berlaku.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                  letterSpacing: 0.3,
                  color: Theme.of(
                    context,
                  ).textTheme.bodySmall?.color?.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
