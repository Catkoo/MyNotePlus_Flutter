import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _checkLoginExpired();
  }

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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _login() async {
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
    setState(() => _isLoading = true);
    try {
      final user = await AuthService().signInWithGoogle(
        isRegister: false,
      ); // tambahkan ini

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
      _showToast(
        e.toString(),
      ); // agar pesan error terlihat jelas, misal "akun belum terdaftar"
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

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: Container(
        width: size.width,
        height: size.height,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFEDEFF9), Color(0xFFD6E4FF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 16,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.note_alt_outlined,
                    size: 60,
                    color: Colors.indigo,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Selamat Datang 👋",
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Colors.indigo[800],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Silakan login untuk mulai mencatat",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: "Email",
                      prefixIcon: const Icon(Icons.email_outlined),
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    obscureText: !_passwordVisible,
                    decoration: InputDecoration(
                      labelText: "Password",
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _passwordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () => setState(
                          () => _passwordVisible = !_passwordVisible,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _resetPassword,
                      child: const Text("Lupa password?"),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            )
                          : const Text("Login", style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: <Widget>[
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          "atau",
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _isLoading ? null : _signInWithGoogle,
                    icon: Image.asset('lib/assets/google.png', height: 24),
                    label: const Text("Masuk dengan Google"),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 16,
                      ),
                      foregroundColor: Colors.black87,
                      side: const BorderSide(color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/register'),
                    child: const Text("Belum punya akun? Daftar di sini"),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
