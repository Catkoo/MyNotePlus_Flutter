import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../viewmodel/note_view_model.dart';
import '../viewmodel/film_note_viewmodel.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _passwordVisible = false;
  bool _isLoading = false;
  bool _isChecked = false;

  @override
  void initState() {
    super.initState();
    _checkLoginExpired();
  }

  // --- LOGIC TETAP SAMA ---
  Future<void> _checkLoginExpired() async {
    final prefs = await SharedPreferences.getInstance();
    final lastLogin = prefs.getInt('lastLogin') ?? 0;
    final sevenDays = 7 * 24 * 60 * 60 * 1000;
    if (DateTime.now().millisecondsSinceEpoch - lastLogin > sevenDays) {
      final auth = FirebaseAuth.instance;
      if (auth.currentUser != null) {
        await auth.signOut();
        prefs.remove('lastLogin');
        _showToast("Login kadaluarsa. Silakan login ulang.");
      }
    }
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _login() async {
    if (!_isChecked) {
      _showToast("Anda harus menyetujui Kebijakan Privasi dan Peraturan Penggunaan.");
      return;
    }
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      _showToast("Isi email dan password");
      return;
    }
    setState(() => _isLoading = true);
    try {
      final result = await AuthService().loginWithEmail(email, password);
      if (result.user != null && result.user!.emailVerified) {
        final prefs = await SharedPreferences.getInstance();
        prefs.setInt('lastLogin', DateTime.now().millisecondsSinceEpoch);
        if (mounted) {
          context.read<NoteViewModel>().clear();
          context.read<FilmNoteViewModel>().clear();
        }
        _showToast("Login berhasil");
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      } else {
        _showToast("Verifikasi email dulu ya");
      }
    } catch (e) {
      _showToast("Gagal login: ${e.toString()}");
    }
    setState(() => _isLoading = false);
  }

  Future<void> _signInWithGoogle() async {
    if (!_isChecked) {
      _showToast("Anda harus menyetujui Kebijakan Privasi dan Peraturan Penggunaan.");
      return;
    }
    setState(() => _isLoading = true);
    try {
      final user = await AuthService().signInWithGoogle(isRegister: false);
      if (user != null) {
        final prefs = await SharedPreferences.getInstance();
        prefs.setInt('lastLogin', DateTime.now().millisecondsSinceEpoch);
        if (mounted) {
          context.read<NoteViewModel>().clear();
          context.read<FilmNoteViewModel>().clear();
          Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
        }
        _showToast("Login Google berhasil");
      }
    } catch (e) {
      _showToast(e.toString());
    }
    setState(() => _isLoading = false);
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showToast("Masukkan email terlebih dahulu");
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      _showToast("Cek email untuk reset password");
    } catch (e) {
      _showToast("Gagal kirim email: ${e.toString()}");
    }
  }

  // --- UI DITINGKATKAN ---
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient yang lebih Modern
          Container(
            width: size.width,
            height: size.height,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [theme.colorScheme.primaryContainer, Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          // Elemen dekorasi lingkaran transparan (Opsional)
          Positioned(
            top: -50,
            right: -50,
            child: CircleAvatar(radius: 100, backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.05)),
          ),
          
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo Section
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 10))
                        ],
                      ),
                      child: Icon(Icons.note_alt_rounded, size: 50, color: theme.colorScheme.primary),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      "Selamat Datang 👋",
                      style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Silakan login untuk mulai mencatat",
                      style: GoogleFonts.poppins(fontSize: 14, color: Colors.black54),
                    ),
                    const SizedBox(height: 40),

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
                          _buildTextField(
                            controller: _emailController,
                            label: "Email",
                            icon: Icons.email_outlined,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _passwordController,
                            label: "Password",
                            icon: Icons.lock_outline_rounded,
                            isPassword: true,
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _resetPassword,
                              child: Text("Lupa password?", style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w600)),
                            ),
                          ),
                          const SizedBox(height: 8),
                          
                          // Checkbox & Terms
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
                                      _linkSpan("Syarat", '/terms_of_use'),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Login Button
                          SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton(
                              onPressed: (_isLoading || !_isChecked) ? null : _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.colorScheme.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              child: _isLoading
                                  ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Text("Masuk", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Social Login Divider
                    Row(
                      children: [
                        Expanded(child: Divider(color: Colors.grey.withValues(alpha: 0.3))),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text("Atau lanjut dengan", style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                        ),
                        Expanded(child: Divider(color: Colors.grey.withValues(alpha: 0.3))),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Google Login
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: OutlinedButton.icon(
                        onPressed: (_isLoading || !_isChecked) ? null : _signInWithGoogle,
                        icon: Image.asset('lib/assets/google.png', height: 22),
                        label: const Text("Google", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Register Link
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, '/register'),
                      child: Text.rich(
                        TextSpan(
                          text: "Belum punya akun? ",
                          style: const TextStyle(color: Colors.black54),
                          children: [
                            TextSpan(
                              text: "Daftar Sekarang",
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword ? !_passwordVisible : false,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 22),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(_passwordVisible ? Icons.visibility : Icons.visibility_off, size: 20),
                onPressed: () => setState(() => _passwordVisible = !_passwordVisible),
              )
            : null,
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