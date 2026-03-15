import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
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
  bool _isChecked = false;

  void _showToast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // --- LOGIC TETAP SAMA ---
  Future<void> _register() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final pass = _passwordController.text;
    final confirm = _confirmController.text;

    if (!_isChecked) {
      _showToast("Anda harus menyetujui Kebijakan Privasi dan Peraturan Penggunaan.");
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
      final result = await _auth.createUserWithEmailAndPassword(email: email, password: pass);
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

  // --- UI DESIGN UPGRADE ---
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient (Sama dengan LoginScreen)
          Container(
            width: size.width,
            height: size.height,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [theme.colorScheme.primaryContainer.withValues(alpha: 0.6), Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
                child: Column(
                  children: [
                    // Icon Header
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 10))
                        ],
                      ),
                      child: Icon(Icons.person_add_alt_1_rounded, size: 40, color: theme.colorScheme.primary),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "Daftar Dulu Ya! 👤",
                      style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Buat akun baru untuk mulai mencatat",
                      style: GoogleFonts.poppins(fontSize: 14, color: Colors.black54),
                    ),
                    const SizedBox(height: 32),

                    // Input Card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.white),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20, offset: const Offset(0, 10))
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildTextField("Nama Lengkap", Icons.person_outline_rounded, _nameController),
                          const SizedBox(height: 16),
                          _buildTextField("Email", Icons.email_outlined, _emailController, keyboardType: TextInputType.emailAddress),
                          const SizedBox(height: 16),
                          _buildPasswordField(
                            "Password (min. 8 karakter)", 
                            _passwordController, 
                            _passwordVisible, 
                            () => setState(() => _passwordVisible = !_passwordVisible)
                          ),
                          const SizedBox(height: 16),
                          _buildPasswordField(
                            "Konfirmasi Password", 
                            _confirmController, 
                            _confirmVisible, 
                            () => setState(() => _confirmVisible = !_confirmVisible)
                          ),
                          const SizedBox(height: 20),
                          
                          // Checkbox Section
                          Row(
                            children: [
                              SizedBox(
                                height: 24,
                                width: 24,
                                child: Checkbox(
                                  value: _isChecked,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                  onChanged: (val) => setState(() => _isChecked = val ?? false),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text.rich(
                                  TextSpan(
                                    text: "Saya setuju dengan ",
                                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                                    children: [
                                      _linkSpan("Kebijakan Privasi", '/privacy_policy'),
                                      const TextSpan(text: " & "),
                                      _linkSpan("Ketentuan", '/terms_of_use'),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Register Button
                          SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton(
                              onPressed: (_isLoading || !_isChecked) ? null : _register,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.colorScheme.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              child: _isLoading
                                  ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Text("Daftar Sekarang", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Divider "atau"
                    Row(
                      children: [
                        Expanded(child: Divider(color: Colors.grey.withValues(alpha: 0.2))),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text("Atau daftar dengan", style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                        ),
                        Expanded(child: Divider(color: Colors.grey.withValues(alpha: 0.2))),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Google Button
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: OutlinedButton.icon(
                        onPressed: (_isLoading || !_isChecked) 
                          ? null 
                          : () async {
                              setState(() => _isLoading = true);
                              try {
                                final cred = await AuthService().signInWithGoogle(isRegister: true);
                                if (cred != null) {
                                  _showToast("Pendaftaran berhasil!");
                                  Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                                }
                              } catch (e) {
                                _showToast(e.toString().replaceAll('Exception: ', ''));
                              }
                              setState(() => _isLoading = false);
                            },
                        icon: Image.asset("lib/assets/google.png", height: 22),
                        label: const Text("Google", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Back to Login
                    TextButton(
                      onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                      child: Text.rich(
                        TextSpan(
                          text: "Sudah punya akun? ",
                          style: const TextStyle(color: Colors.black54),
                          children: [
                            TextSpan(
                              text: "Login di sini",
                              style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- REUSABLE COMPONENTS ---
  Widget _buildTextField(String label, IconData icon, TextEditingController controller, {TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 22),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
      ),
    );
  }

  Widget _buildPasswordField(String label, TextEditingController controller, bool isVisible, VoidCallback onToggle) {
    return TextField(
      controller: controller,
      obscureText: !isVisible,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline_rounded, size: 22),
        suffixIcon: IconButton(
          icon: Icon(isVisible ? Icons.visibility_rounded : Icons.visibility_off_rounded, size: 20),
          onPressed: onToggle,
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
      ),
    );
  }

  TextSpan _linkSpan(String text, String route) {
    return TextSpan(
      text: text,
      style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
      recognizer: TapGestureRecognizer()..onTap = () => Navigator.pushNamed(context, route),
    );
  }
}