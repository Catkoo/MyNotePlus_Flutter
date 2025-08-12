import 'package:flutter/material.dart';

class TermsOfUseScreen extends StatelessWidget {
  const TermsOfUseScreen({super.key});

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 32, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: Colors.deepPurple,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSectionContent(String content) {
    return Text(
      content,
      style: const TextStyle(
        fontSize: 16,
        height: 1.7,
        color: Colors.black87,
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
        backgroundColor: Colors.deepPurple,
        centerTitle: true,
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Pendahuluan'),
            _buildSectionContent(
              'Selamat datang di aplikasi kami. Dengan menggunakan aplikasi ini, Anda menyetujui untuk mematuhi syarat dan ketentuan yang berlaku. Mohon baca dengan seksama sebelum menggunakan layanan kami.',
            ),
            _buildSectionTitle('Penggunaan Aplikasi'),
            _buildSectionContent(
              'Anda setuju untuk menggunakan aplikasi ini hanya untuk tujuan yang sah dan sesuai dengan hukum yang berlaku. Anda tidak diperkenankan menggunakan aplikasi untuk aktivitas yang melanggar hukum, merugikan pihak lain, atau mengganggu layanan.',
            ),
            _buildSectionTitle('Akun Pengguna'),
            _buildSectionContent(
              'Anda bertanggung jawab atas kerahasiaan akun dan kata sandi Anda. Kami tidak bertanggung jawab atas segala kerugian akibat penggunaan akun Anda oleh pihak lain. Jika ada dugaan penyalahgunaan, segera laporkan kepada kami.',
            ),
            _buildSectionTitle('Hak Kekayaan Intelektual'),
            _buildSectionContent(
              'Seluruh konten, termasuk teks, gambar, dan fitur dalam aplikasi ini dilindungi oleh hak cipta dan tidak boleh disalin, didistribusikan, atau digunakan tanpa izin tertulis dari pemilik aplikasi.',
            ),
            _buildSectionTitle('Pembatasan Tanggung Jawab'),
            _buildSectionContent(
              'Kami berusaha menyediakan layanan terbaik, namun tidak bertanggung jawab atas kerugian langsung atau tidak langsung yang timbul dari penggunaan aplikasi ini, termasuk kehilangan data atau gangguan layanan.',
            ),
            _buildSectionTitle('Perubahan Syarat dan Ketentuan'),
            _buildSectionContent(
              'Kami dapat memperbarui syarat dan ketentuan ini sewaktu-waktu. Perubahan akan diinformasikan melalui aplikasi atau media komunikasi lainnya. Penggunaan layanan setelah perubahan berarti Anda menyetujui syarat yang telah diperbarui.',
            ),
            _buildSectionTitle('Pengakhiran Layanan'),
            _buildSectionContent(
              'Kami berhak menghentikan layanan atau menonaktifkan akun pengguna tanpa pemberitahuan sebelumnya jika terjadi pelanggaran syarat dan ketentuan ini.',
            ),
            _buildSectionTitle('Kontak'),
            _buildSectionContent(
              'Jika Anda memiliki pertanyaan atau keluhan terkait syarat dan ketentuan ini, silakan hubungi kami melalui fitur bantuan di aplikasi.',
            ),
            const SizedBox(height: 48),
            Center(
              child: Text(
                'Terima kasih telah menggunakan aplikasi kami dan mematuhi syarat dan ketentuan yang berlaku.',
                style: TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey[700],
                  letterSpacing: 0.3,
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
