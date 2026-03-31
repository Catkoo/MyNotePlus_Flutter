import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/change_password_dialog.dart';
import '../services/auth_service.dart';
import '../viewmodel/note_view_model.dart';
import '../viewmodel/film_note_viewmodel.dart';
import '../widgets/theme_provider.dart';
import '../screens/privacy_policy_screen.dart';
import '../screens/terms_of_use.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final user = FirebaseAuth.instance.currentUser;
  final nameController = TextEditingController();
  bool isLoading = true;
  bool isBiometricEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadBiometricStatus();
  }

  void _loadBiometricStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isBiometricEnabled = prefs.getBool('biometric_enabled') ?? false;
    });
  }

  void _loadUserData() async {
    final uid = user?.uid;
    if (uid != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data();
        if (data != null && data['name'] != null && data['name'] != '') {
          nameController.text = data['name'];
        } else {
          nameController.text = user?.displayName ?? user?.email ?? '';
        }
      }
    }
    setState(() => isLoading = false);
  }

  void _toggleBiometric(bool value) async {
    if (value == false) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('biometric_enabled', false);
      setState(() => isBiometricEnabled = false);
      return;
    }

    bool hasAccepted = false;
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
                  const SizedBox(height: 24),
                  const Icon(Icons.fingerprint_rounded, size: 60, color: Colors.blue),
                  const SizedBox(height: 16),
                  const Text("Aktifkan Kunci Biometrik", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  const Text(
                    "Harap baca ketentuan berikut:\n\n"
                    "• MyNotePlus akan meminta verifikasi wajah/sidik jari saat aplikasi dibuka.\n"
                    "• Data biometrik Anda aman karena dikelola langsung oleh sistem HP.\n"
                    "• Pastikan Anda sudah mengatur PIN/Pola HP sebagai cadangan.",
                    style: TextStyle(fontSize: 14, height: 1.5),
                  ),
                  const SizedBox(height: 20),
                  CheckboxListTile(
                    title: const Text("Saya mengerti dan setuju mengaktifkan fitur ini", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    value: hasAccepted,
                    controlAffinity: ListTileControlAffinity.leading,
                    onChanged: (val) => setModalState(() => hasAccepted = val!),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton(
                      onPressed: hasAccepted ? () async {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setBool('biometric_enabled', true);
                        setState(() => isBiometricEnabled = true);
                        if (context.mounted) Navigator.pop(context);
                      } : null,
                      style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      child: const Text("Aktifkan Sekarang"),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _updateName() async {
    final name = nameController.text.trim();
    if (user != null && name.isNotEmpty) {
      await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({'name': name});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nama berhasil diperbarui'), behavior: SnackBarBehavior.floating));
      }
    }
  }

  void _logout() async {
    context.read<NoteViewModel>().clear();
    context.read<FilmNoteViewModel>().clear();
    await AuthService().signOut();
    if (mounted) Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  void _linkGoogle() async {
    try {
      await AuthService().linkWithGoogle();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Berhasil menautkan Google')));
        setState(() {});
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
    }
  }

  void _unlinkGoogle() async {
    try {
      await AuthService().unlinkGoogle();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Google dilepas')));
        setState(() {});
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
    }
  }

  void _openHelpForm() async => await launchUrl(Uri.parse('https://forms.gle/eDwfXp58cFaYrths5'), mode: LaunchMode.externalApplication);
  void _openDeleteAccountForm() async => await launchUrl(Uri.parse('https://forms.gle/5LHBo9szD2hCfsa48'), mode: LaunchMode.externalApplication);

  void _showChangePasswordDialog() {
    showDialog(context: context, builder: (_) => const ChangePasswordDialog());
  }

  Future<void> _showAddEmailPasswordDialog() async {
    final result = await showDialog<bool>(context: context, builder: (_) => const AddEmailPasswordDialog());
    if (result == true) {
      await FirebaseAuth.instance.currentUser?.reload();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isGoogleLinked = user?.providerData.any((p) => p.providerId == 'google.com') ?? false;
    final isEmailPasswordUser = user?.providerData.any((p) => p.providerId == 'password') ?? false;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Profil Pengguna', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                children: [
                  _buildProfileHeader(theme, isGoogleLinked),
                  const SizedBox(height: 24),
                  _buildSectionTitle("PENGATURAN AKUN"),
                  _buildAccountCard(theme),
                  const SizedBox(height: 24),
                  _buildSectionTitle("KEAMANAN & KONEKSI"),
                  _buildSecurityCard(theme, isGoogleLinked, isEmailPasswordUser),
                  const SizedBox(height: 24),
                  _buildSectionTitle("INFORMASI LAINNYA"),
                  _buildOtherCard(theme),
                  const SizedBox(height: 32),
                  _buildLogoutButton(theme),
                  const SizedBox(height: 16),
                  Text('Versi 1.0.8 (13)', style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileHeader(ThemeData theme, bool isGoogleLinked) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2), width: 4),
          ),
          child: CircleAvatar(
            radius: 50,
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Icon(Icons.person, size: 50, color: theme.colorScheme.onPrimaryContainer),
          ),
        ),
        const SizedBox(height: 16),
        Text(user?.email ?? '-', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
        if (isGoogleLinked)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.g_mobiledata, color: Colors.blue, size: 24),
                Text("Google Linked", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 12)),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.blueGrey)),
      ),
    );
  }

  Widget _buildAccountCard(ThemeData theme) {
    return _customCard(
      child: Column(
        children: [
          TextField(
            controller: nameController,
            decoration: InputDecoration(
              labelText: 'Nama Lengkap',
              prefixIcon: const Icon(Icons.badge_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _updateName,
              icon: const Icon(Icons.check_circle_outline, size: 20),
              label: const Text("Perbarui Nama"),
              style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityCard(ThemeData theme, bool isGoogleLinked, bool isEmailPasswordUser) {
    return _customCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          // Row untuk Password
          if (isGoogleLinked && !isEmailPasswordUser)
            _buildListTile(Icons.add_link, "Tambah Password", "Gunakan email & pass", onTap: _showAddEmailPasswordDialog)
          else if (isEmailPasswordUser)
            _buildListTile(Icons.lock_reset, "Ubah Password", "Ganti kata sandi Anda", onTap: _showChangePasswordDialog),
          const Divider(height: 1),

          // Row untuk Google (Sesuai diagnosa yang minta fungsi ini dipanggil)
          if (!isGoogleLinked)
            _buildListTile(Icons.link, "Tautkan Google", "Hubungkan akun Google", onTap: _linkGoogle)
          else
            _buildListTile(Icons.link_off, "Lepas Google", "Hanya jika email terdaftar", 
                onTap: isEmailPasswordUser ? _unlinkGoogle : null, 
                color: isEmailPasswordUser ? Colors.red : Colors.grey),
          const Divider(height: 1),

          // Switch Biometrik
          SwitchListTile(
            secondary: const Icon(Icons.fingerprint_rounded, color: Colors.blue),
            title: const Text("Kunci Biometrik", style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(isBiometricEnabled ? "Aktif" : "Nonaktif"),
            value: isBiometricEnabled,
            onChanged: (v) => _toggleBiometric(v),
          ),
          const Divider(height: 1),

          // Switch Mode Gelap
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode_outlined),
            title: const Text("Mode Gelap", style: TextStyle(fontWeight: FontWeight.w600)),
            value: context.watch<ThemeProvider>().isDarkMode,
            onChanged: (v) => context.read<ThemeProvider>().toggleTheme(v),
          ),
        ],
      ),
    );
  }

  Widget _buildOtherCard(ThemeData theme) {
    return _customCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _buildListTile(Icons.privacy_tip_outlined, "Kebijakan Privasi", "Data & privasi", onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()))),
          const Divider(height: 1),
          _buildListTile(Icons.article_outlined, "Syarat & Ketentuan", "Aturan penggunaan", onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TermsOfUseScreen()))),
          const Divider(height: 1),
          _buildListTile(Icons.help_outline, "Bantuan", "Hubungi admin", onTap: _openHelpForm),
          const Divider(height: 1),
          _buildListTile(Icons.delete_forever, "Hapus Akun", "Proses penghapusan data", onTap: _openDeleteAccountForm, color: Colors.redAccent),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(ThemeData theme) {
    return OutlinedButton.icon(
      onPressed: _logout,
      icon: const Icon(Icons.logout_rounded),
      label: const Text("LOGOUT AKUN", style: TextStyle(fontWeight: FontWeight.bold)),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.red,
        side: const BorderSide(color: Colors.red, width: 1.5),
        minimumSize: const Size.fromHeight(55),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _customCard({required Widget child, EdgeInsets? padding}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: child,
    );
  }

  Widget _buildListTile(IconData icon, String title, String subtitle, {VoidCallback? onTap, Color? color}) {
    return ListTile(
      leading: Icon(icon, color: color ?? Colors.blueGrey),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: color)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: onTap,
    );
  }
}

// --- CLASS DIALOG (WAJIB ADA AGAR TIDAK ERROR "creation_with_non_type") ---
class AddEmailPasswordDialog extends StatefulWidget {
  const AddEmailPasswordDialog({super.key});
  @override
  State<AddEmailPasswordDialog> createState() => _AddEmailPasswordDialogState();
}

class _AddEmailPasswordDialogState extends State<AddEmailPasswordDialog> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLoading = false;
  String? errorMessage;

  Future<void> _linkEmailPassword() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final user = FirebaseAuth.instance.currentUser;
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        isLoading = false;
        errorMessage = "Wajib diisi";
      });
      return;
    }

    try {
      final credential = EmailAuthProvider.credential(email: email, password: password);
      await user?.linkWithCredential(credential);
      await user?.sendEmailVerification();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Email verifikasi telah dikirim.")));
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AlertDialog(
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      title: const Text("Keamanan Akun", textAlign: TextAlign.center),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: emailController,
            decoration: InputDecoration(labelText: "Email", prefixIcon: const Icon(Icons.email_outlined), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: passwordController,
            obscureText: true,
            decoration: InputDecoration(labelText: "Password", prefixIcon: const Icon(Icons.lock_outline), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
          ),
          if (errorMessage != null) Padding(padding: const EdgeInsets.only(top: 10), child: Text(errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 12))),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
        FilledButton(onPressed: isLoading ? null : _linkEmailPassword, child: const Text("Simpan")),
      ],
    );
  }
}