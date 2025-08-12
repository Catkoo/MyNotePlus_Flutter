import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

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
        title: const Text('Kebijakan Privasi'),
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
              'Kami sangat menghargai kepercayaan Anda dan berkomitmen penuh untuk melindungi privasi serta data pribadi Anda. Kebijakan privasi ini menjelaskan bagaimana kami mengumpulkan, menggunakan, dan menjaga keamanan informasi Anda saat menggunakan aplikasi kami. Dengan menggunakan layanan kami, Anda menyetujui pengumpulan dan penggunaan informasi sesuai dengan kebijakan ini.',
            ),
            _buildSectionTitle('Data yang Dikumpulkan'),
            _buildSectionContent(
              'Kami mengumpulkan berbagai informasi pribadi yang Anda berikan secara langsung melalui aplikasi, termasuk namun tidak terbatas pada data catatan pribadi, alamat email, dan informasi akun yang diperlukan untuk menyediakan layanan yang optimal. Selain itu, kami dapat mengumpulkan data teknis terkait penggunaan aplikasi untuk meningkatkan pengalaman pengguna.',
            ),
            _buildSectionTitle('Tujuan Penggunaan Data'),
            _buildSectionContent(
              'Data yang kami kumpulkan digunakan untuk tujuan berikut:\n\n'
              '- Menyimpan dan mengelola catatan pribadi Anda secara aman.\n'
              '- Memproses autentikasi dan otorisasi pengguna.\n'
              '- Memberikan dukungan dan layanan pelanggan.\n'
              '- Meningkatkan fitur dan performa aplikasi.\n'
              '- Mematuhi kewajiban hukum yang berlaku.',
            ),
            _buildSectionTitle('Keamanan Data'),
            _buildSectionContent(
              'Kami menerapkan teknologi keamanan terbaik, termasuk enkripsi data dan protokol keamanan, untuk melindungi informasi pribadi Anda dari akses, perubahan, atau penghapusan yang tidak sah. Meskipun kami berupaya keras menjaga keamanan data, kami juga mengimbau pengguna untuk berhati-hati menjaga kerahasiaan informasi akun mereka.',
            ),
            _buildSectionTitle('Pengungkapan dan Pembagian Data'),
            _buildSectionContent(
              'Kami tidak akan membagikan data pribadi Anda kepada pihak ketiga tanpa persetujuan Anda, kecuali apabila diwajibkan oleh peraturan hukum yang berlaku atau untuk kepentingan keamanan dan penegakan hukum. Data anonim yang tidak dapat diidentifikasi secara pribadi mungkin digunakan untuk analisis dan peningkatan layanan.',
            ),
            _buildSectionTitle('Hak dan Pilihan Anda'),
            _buildSectionContent(
              'Anda memiliki hak untuk mengakses, memperbaiki, atau menghapus data pribadi Anda yang tersimpan di aplikasi kami kapan saja. Untuk melakukan ini, Anda dapat menghubungi layanan bantuan kami melalui aplikasi atau mengubah pengaturan akun Anda sesuai kebijakan yang berlaku.',
            ),
            _buildSectionTitle('Perubahan pada Kebijakan Privasi'),
            _buildSectionContent(
              'Kami dapat memperbarui kebijakan privasi ini dari waktu ke waktu untuk mencerminkan perubahan dalam praktik kami atau peraturan yang berlaku. Setiap perubahan akan diinformasikan melalui aplikasi atau media komunikasi lainnya sebelum diberlakukan.',
            ),
            _buildSectionTitle('Kontak Kami'),
            _buildSectionContent(
              'Jika Anda memiliki pertanyaan, kekhawatiran, atau permintaan terkait kebijakan privasi ini, silakan hubungi kami melalui fitur bantuan di aplikasi atau email resmi kami. Kami siap membantu dan menanggapi pertanyaan Anda dengan cepat.',
            ),
            const SizedBox(height: 48),
            Center(
              child: Text(
                'Terima kasih telah mempercayakan data Anda kepada kami dan menggunakan aplikasi ini dengan penuh tanggung jawab.',
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
