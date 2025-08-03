# 🔐 MyNotePlus Security Policy

Terima kasih atas perhatian Anda terhadap keamanan aplikasi kami. MyNotePlus berkomitmen untuk menjaga privasi dan keamanan data pengguna secara serius.

---

## 📆 Versi yang Didukung

Kami hanya menerima laporan keamanan untuk versi terbaru yang dirilis secara publik.

| Versi     | Status Dukungan |
|-----------|-----------------|
| 1.0.3     | ✅ Aktif        |
| < 1.0.3   | ❌ Tidak Didukung |

---

## 🛡️ Cara Melaporkan Kerentanan

Jika Anda menemukan bug atau potensi celah keamanan dalam aplikasi:

1. **Jangan laporkan secara publik.**
2. Laporkan kerentanan melalui formulir berikut:

📋 **[Formulir Pelaporan Keamanan]([https://forms.gle/your-form-link](https://forms.gle/cxjSpfxGk8pSRbQq6))**  

Mohon sertakan:
- Deskripsi masalah
- Langkah-langkah untuk mereproduksi
- Potensi dampak
- Bukti (opsional)

⏱ Kami akan meninjau laporan Anda dalam waktu **maksimal 48 jam** dan menindaklanjuti untuk masalah penting dalam **5 hari kerja**.

---

## 🔒 Kebijakan Perlindungan Data

MynotePlus menyimpan dan mengelola data pengguna melalui Firebase dengan praktik terbaik:

- Semua data dikirim melalui koneksi terenkripsi (HTTPS).
- Autentikasi menggunakan Firebase Auth dan Google Sign-In.
- Data pengguna tidak pernah dibagikan ke pihak ketiga tanpa izin eksplisit.
- Fitur backup ke Google Drive hanya dilakukan atas izin pengguna dan bersifat privat.
- Kami tidak menyimpan password pengguna secara lokal atau dalam format terbuka.

---

## 👩‍💻 Panduan Keamanan untuk Kontributor

Jika Anda ingin berkontribusi ke proyek ini:

- Jangan pernah menyertakan API key, token, atau informasi sensitif di dalam kode.
- Gunakan library yang aman dan ter-maintain.
- Hindari menyimpan data sensitif di `SharedPreferences` tanpa enkripsi.
- Ikuti pedoman keamanan dari [OWASP Mobile Top 10](https://owasp.org/www-project-mobile-top-10/) sebagai referensi utama.

---

## 📢 Disclosure Policy

Kami menyarankan **disclosure yang bertanggung jawab**. Kami akan mencantumkan nama Anda di changelog (dengan izin) jika laporan Anda terbukti valid dan membantu meningkatkan keamanan aplikasi.

---

Terima kasih telah membantu menjaga MyNotePlus tetap aman untuk semua pengguna!
