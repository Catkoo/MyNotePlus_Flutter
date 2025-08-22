import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 32, bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSectionContent(BuildContext context, String content) {
    return Text(
      content,
      style: TextStyle(
        fontSize: 16,
        height: 1.7,
        color: Theme.of(context).textTheme.bodyMedium?.color,
        letterSpacing: 0.3,
      ),
      textAlign: TextAlign.justify,
    );
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).textTheme.bodyMedium?.color;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kebijakan Privasi'),
        backgroundColor: Theme.of(context).colorScheme.primary,
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
              'Kami sangat menghargai kepercayaan Anda dalam menggunakan aplikasi ini. '
              'Kebijakan Privasi ini menjelaskan bagaimana kami mengumpulkan, menggunakan, '
              'menyimpan, dan melindungi data pribadi yang Anda berikan ketika menggunakan '
              'layanan kami. Dengan menggunakan aplikasi, Anda dianggap telah membaca, memahami, '
              'dan menyetujui isi dari Kebijakan Privasi ini.',
            ),

            _buildSectionTitle(context, 'Data yang Dikumpulkan'),
            _buildSectionContent(
              context,
              'Untuk mendukung fungsionalitas aplikasi, kami dapat mengumpulkan beberapa jenis data, '
              'antara lain:\n\n'
              '- Informasi akun seperti nama, email, atau foto profil (jika tersedia).\n'
              '- Catatan pribadi, termasuk judul, isi catatan, dan pengingat yang Anda simpan.\n'
              '- Data film/drama, termasuk judul, tahun rilis, dan status tontonan terakhir.\n'
              '- Data teknis seperti perangkat, sistem operasi, dan log aktivitas untuk keperluan diagnostik.',
            ),

            _buildSectionTitle(context, 'Tujuan Penggunaan Data'),
            _buildSectionContent(
              context,
              'Data yang kami kumpulkan digunakan untuk tujuan berikut:\n\n'
              '1. Menyediakan dan memelihara layanan utama aplikasi.\n'
              '2. Menyimpan dan mengelola catatan pribadi serta daftar film/drama Anda.\n'
              '3. Memproses autentikasi dan otorisasi agar akun Anda aman.\n'
              '4. Memberikan pengalaman pengguna yang lebih baik dengan rekomendasi atau fitur baru.\n'
              '5. Melakukan analisis internal untuk meningkatkan performa aplikasi.\n'
              '6. Mematuhi kewajiban hukum yang berlaku.',
            ),

            _buildSectionTitle(context, 'Keamanan Data'),
            _buildSectionContent(
              context,
              'Kami menerapkan langkah-langkah keamanan yang wajar untuk melindungi data Anda dari akses, '
              'penggunaan, atau pengungkapan yang tidak sah. Meski demikian, perlu diingat bahwa tidak ada '
              'metode transmisi data melalui internet atau metode penyimpanan elektronik yang sepenuhnya aman. '
              'Kami tidak dapat menjamin keamanan absolut, tetapi berkomitmen untuk selalu meningkatkan proteksi.',
            ),

            _buildSectionTitle(context, 'Pengungkapan dan Pembagian Data'),
            _buildSectionContent(
              context,
              'Kami tidak akan membagikan atau menjual data pribadi Anda kepada pihak ketiga untuk tujuan komersial. '
              'Namun, kami dapat mengungkapkan data Anda dalam keadaan berikut:\n\n'
              '- Jika diwajibkan oleh hukum atau perintah pengadilan.\n'
              '- Jika diperlukan untuk melindungi hak, keamanan, atau properti kami maupun pengguna lain.\n'
              '- Dalam hal terjadi penggabungan, akuisisi, atau penjualan aset perusahaan, data dapat menjadi bagian dari transaksi.',
            ),

            _buildSectionTitle(context, 'Hak dan Pilihan Anda'),
            _buildSectionContent(
              context,
              'Anda memiliki hak penuh atas data pribadi Anda, termasuk:\n\n'
              '- Hak untuk mengakses dan meninjau data yang tersimpan.\n'
              '- Hak untuk memperbarui atau memperbaiki informasi yang tidak akurat.\n'
              '- Hak untuk menghapus akun dan seluruh data yang terkait.\n'
              '- Hak untuk menolak pengumpulan data tertentu (yang tidak wajib) kapan saja.',
            ),

            _buildSectionTitle(context, 'Perubahan pada Kebijakan Privasi'),
            _buildSectionContent(
              context,
              'Kami dapat memperbarui Kebijakan Privasi ini dari waktu ke waktu. Setiap perubahan akan diberitahukan '
              'melalui pembaruan di aplikasi atau notifikasi lain yang sesuai. Kami mendorong Anda untuk meninjau '
              'halaman ini secara berkala agar tetap mengetahui bagaimana kami melindungi data Anda.',
            ),

            _buildSectionTitle(context, 'Kontak Kami'),
            _buildSectionContent(
              context,
              'Jika Anda memiliki pertanyaan, saran, atau permintaan terkait kebijakan privasi ini, '
              'silakan hubungi tim kami melalui email resmi yang tersedia di bagian pengaturan aplikasi. '
              'Kami berkomitmen untuk merespons setiap permintaan dengan segera.',
            ),

            const SizedBox(height: 48),
            Center(
              child: Text(
                'Terima kasih telah mempercayakan catatan dan data tontonan Anda kepada kami 🙏',
                style: TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: textColor?.withOpacity(0.7),
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
