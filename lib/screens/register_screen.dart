import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart'; // untuk TapGestureRecognizer
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mynoteplus/services/auth_service.dart';
import 'package:google_fonts/google_fonts.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _passwordVisible = false;
  bool _confirmVisible = false;
  bool _isLoading = false;

  bool _isChecked = false; // Checkbox persetujuan ditambahkan

  void _showToast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _register() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final pass = _passwordController.text;
    final confirm = _confirmController.text;

    if (!_isChecked) {
      _showToast(
        "Anda harus menyetujui Kebijakan Privasi dan Peraturan Penggunaan.",
      );
      return;
    }

    if (name.isEmpty || email.isEmpty || pass.isEmpty || confirm.isEmpty) {
      _showToast("Harap isi semua data");
      return;
    }

    if (pass.length < 8) {
      _showToast("Password minimal 8 karakter");
      return;
    }

    if (pass != confirm) {
      _showToast("Konfirmasi password tidak cocok");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: pass,
      );
      final user = result.user;

      if (user != null) {
        await _firestore.collection('users').doc(user.uid).set({
          'name': name,
          'email': email,
          'createdAt': DateTime.now().millisecondsSinceEpoch,
        });

        await user.sendEmailVerification();

        _showToast("Registrasi berhasil! Cek email untuk verifikasi.");
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    } catch (e) {
      _showToast("Gagal registrasi: ${e.toString()}");
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(
                  Icons.person_add_alt_1,
                  size: 64,
                  color: Colors.indigo,
                ),
                const SizedBox(height: 24),
                Text(
                  "Daftar Dulu Ya! 👤",
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo[800],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Buat akun baru untuk mulai mencatat",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 32),

                // Nama
                _buildTextField("Nama Lengkap", Icons.person, _nameController),
                const SizedBox(height: 16),

                // Email
                _buildTextField(
                  "Email",
                  Icons.email_outlined,
                  _emailController,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),

                // Password
                _buildPasswordField(
                  "Password (min. 8 karakter)",
                  _passwordController,
                  _passwordVisible,
                  () {
                    setState(() => _passwordVisible = !_passwordVisible);
                  },
                ),
                const SizedBox(height: 16),

                // Konfirmasi Password
                _buildPasswordField(
                  "Konfirmasi Password",
                  _confirmController,
                  _confirmVisible,
                  () {
                    setState(() => _confirmVisible = !_confirmVisible);
                  },
                ),

                const SizedBox(height: 12),

                // Checkbox persetujuan dengan link klik terpisah
                Row(
                  children: [
                    Checkbox(
                      value: _isChecked,
                      onChanged: (val) {
                        setState(() {
                          _isChecked = val ?? false;
                        });
                      },
                    ),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          text: "Saya setuju dengan ",
                          style: TextStyle(color: Colors.black87),
                          children: [
                            TextSpan(
                              text: "Kebijakan Privasi",
                              style: const TextStyle(
                                color: Colors.blue,
                                decoration: TextDecoration.underline,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  Navigator.pushNamed(
                                    context,
                                    '/privacy_policy',
                                  );
                                },
                            ),
                            const TextSpan(text: " dan "),
                            TextSpan(
                              text: "Peraturan Penggunaan",
                              style: const TextStyle(
                                color: Colors.blue,
                                decoration: TextDecoration.underline,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  Navigator.pushNamed(context, '/terms_of_use');
                                },
                            ),
                            const TextSpan(text: "."),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Tombol Daftar
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: (_isLoading || !_isChecked) ? null : _register,
                    icon: _isLoading
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : const Icon(Icons.person_add_alt_1),
                    label: Text(_isLoading ? "Mendaftarkan..." : "Daftar"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      // (optional) Atur warna saat disabled, tapi biasanya Flutter sudah bagus
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Teks "atau" di tengah
                Text(
                  "atau",
                  style: GoogleFonts.poppins(color: Colors.grey[600]),
                ),

                const SizedBox(height: 16),

                // Tombol Google
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: (_isLoading || !_isChecked)
                        ? null
                        : () async {
                            setState(() => _isLoading = true);
                            try {
                              final cred = await AuthService().signInWithGoogle(
                                isRegister: true,
                              );
                              if (cred != null) {
                                _showToast("Pendaftaran berhasil!");
                                Navigator.pushNamedAndRemoveUntil(
                                  context,
                                  '/',
                                  (route) => false,
                                );
                              }
                            } catch (e) {
                              _showToast(
                                e.toString().replaceAll('Exception: ', ''),
                              );
                            }
                            setState(() => _isLoading = false);
                          },
                    icon: Image.asset("lib/assets/google.png", height: 24),
                    label: const Text("Daftar dengan Google"),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.grey),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      foregroundColor: Colors.black87,
                      backgroundColor: Colors.white,
                      // (optional) Atur style saat disabled juga jika mau custom
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                TextButton(
                  onPressed: () =>
                      Navigator.pushReplacementNamed(context, '/login'),
                  child: const Text("Sudah punya akun? Login"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    IconData icon,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _buildPasswordField(
    String label,
    TextEditingController controller,
    bool isVisible,
    VoidCallback onToggle,
  ) {
    return TextField(
      controller: controller,
      obscureText: !isVisible,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(isVisible ? Icons.visibility : Icons.visibility_off),
          onPressed: onToggle,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
}
