import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../screens/change_email_dialog.dart';
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

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() async {
    final uid = user?.uid;
    if (uid != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      nameController.text = doc['name'] ?? '';
    }
    setState(() => isLoading = false);
  }

  void _updateName() async {
    final name = nameController.text.trim();
    if (user != null && name.isNotEmpty) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .update({'name': name});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nama berhasil diperbarui')),
        );
      }
    }
  }

  void _logout() async {
    context.read<NoteViewModel>().clear();
    context.read<FilmNoteViewModel>().clear();
    await AuthService().signOut();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Berhasil logout')));
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }
  }

  void _linkGoogle() async {
    try {
      await AuthService().linkWithGoogle();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Berhasil menautkan akun Google')),
        );
        setState(() {});
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menautkan akun Google: $e')),
      );
    }
  }

  void _unlinkGoogle() async {
    try {
      await AuthService().unlinkGoogle();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Akun Google berhasil dilepas')),
        );
        setState(() {});
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal melepas akun Google: $e')));
    }
  }

  void _openHelpForm() async {
    const url = 'https://forms.gle/eDwfXp58cFaYrths5';
    final uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal membuka Google Form')),
      );
    }
  }

  void _openDeleteAccountForm() async {
    const url =
        'https://forms.gle/5LHBo9szD2hCfsa48'; // Ganti dengan link form kamu
    final uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal membuka formulir penghapusan akun'),
        ),
      );
    }
  }

  Future<void> _showAddEmailPasswordDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => const AddEmailPasswordDialog(),
    );
    if (result == true) {
      // reload user to reflect new provider
      await FirebaseAuth.instance.currentUser?.reload();
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email & password berhasil ditambahkan')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final isGoogleLinked =
        user?.providerData.any((p) => p.providerId == 'google.com') ?? false;
    final isEmailPasswordUser =
        user?.providerData.any((p) => p.providerId == 'password') ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        centerTitle: true,
        elevation: 1,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 44,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Icon(
                      Icons.person,
                      size: 44,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user?.email ?? '-',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (isGoogleLinked)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Chip(
                        label: const Text('Tertaut dengan Google'),
                        avatar: Icon(
                          Icons.link,
                          color: theme.colorScheme.primary,
                        ),
                        backgroundColor: theme.colorScheme.primary.withOpacity(
                          0.1,
                        ),
                      ),
                    ),
                  const SizedBox(height: 32),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Informasi Akun",
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          TextField(
                            controller: nameController,
                            decoration: InputDecoration(
                              labelText: 'Nama Lengkap',
                              prefixIcon: const Icon(Icons.person_outline),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: _updateName,
                              icon: const Icon(Icons.save),
                              label: const Text("Simpan"),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text("Keamanan", style: theme.textTheme.titleMedium),
                  ),
                  const SizedBox(height: 12),
                  if (isGoogleLinked && !isEmailPasswordUser) ...[
                    FilledButton.icon(
                      icon: const Icon(Icons.link),
                      onPressed: _showAddEmailPasswordDialog,
                      label: const Text("Tambah Email & Password"),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      icon: const Icon(Icons.link_off),
                      onPressed: null, // disabled
                      label: const Text("Lepas Akun Google"),
                      style: FilledButton.styleFrom(
                        backgroundColor: theme.colorScheme.error.withOpacity(
                          0.6,
                        ),
                        foregroundColor: Colors.white.withOpacity(0.7),
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    Tooltip(
                      message:
                          'Tambahkan email & password dulu agar bisa lepaskan Google',
                      child: const SizedBox(height: 0),
                    ),
                  ] else if (isEmailPasswordUser) ...[
                    if (!isGoogleLinked)
                      FilledButton.icon(
                        icon: const Icon(Icons.link),
                        onPressed: _linkGoogle,
                        label: const Text("Tautkan dengan Akun Google"),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    if (isGoogleLinked)
                      FilledButton.icon(
                        icon: const Icon(Icons.link_off),
                        onPressed: _unlinkGoogle,
                        label: const Text("Lepas Akun Google"),
                        style: FilledButton.styleFrom(
                          backgroundColor: theme.colorScheme.error.withOpacity(
                            0.9,
                          ),
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      icon: const Icon(Icons.lock_outline),
                      onPressed: _showChangePasswordDialog,
                      label: const Text("Ubah Password"),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      icon: const Icon(Icons.lock_reset),
                      onPressed: () {
                        final email = user?.email;
                        if (email != null) {
                          FirebaseAuth.instance.sendPasswordResetEmail(
                            email: email,
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Link reset dikirim ke email"),
                            ),
                          );
                        }
                      },
                      label: const Text("Lupa Password?"),
                    ),
                  ],
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    icon: const Icon(
                      Icons.privacy_tip_outlined,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'Kebijakan Privasi',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PrivacyPolicyScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    icon: const Icon(
                      Icons.article_outlined,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'Syarat & Ketentuan',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TermsOfUseScreen(),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 48),
                  FilledButton.icon(
                    icon: const Icon(Icons.help_outline),
                    onPressed: _openHelpForm,
                    label: const Text("Bantuan / Hubungi Kami"),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    icon: const Icon(Icons.delete_forever),
                    label: const Text('Ajukan Hapus Akun'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _openDeleteAccountForm,
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Mode Gelap'),
                    secondary: const Icon(Icons.dark_mode),
                    value: context.watch<ThemeProvider>().isDarkMode,
                    onChanged: (bool value) {
                      context.read<ThemeProvider>().toggleTheme(value);
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    tileColor: theme.colorScheme.surfaceVariant.withOpacity(
                      0.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.logout),
                    label: const Text("Logout"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                      side: BorderSide(color: theme.colorScheme.error),
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _logout,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Versi 1.0.5',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  void _showChangePasswordDialog() {
    showDialog(context: context, builder: (_) => const ChangePasswordDialog());
  }
}

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
    if (user == null) {
      setState(() {
        isLoading = false;
        errorMessage = "User tidak ditemukan";
      });
      return;
    }

    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        isLoading = false;
        errorMessage = "Email dan password wajib diisi";
      });
      return;
    }

    final currentUserEmail = user.email ?? '';
    final currentDomain = currentUserEmail.split('@').last.toLowerCase();
    final inputDomain = email.split('@').last.toLowerCase();
    if (inputDomain != currentDomain) {
      setState(() {
        isLoading = false;
        errorMessage =
            "Email harus menggunakan domain yang sama dengan akun Google Anda ($currentDomain)";
      });
      return;
    }

    if (password.length < 8) {
      setState(() {
        isLoading = false;
        errorMessage = "Password harus minimal 8 karakter";
      });
      return;
    }

    try {
      final credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );
      await user.linkWithCredential(credential);

      if (mounted) {
        Navigator.pop(context, true);
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = e.message ?? "Terjadi kesalahan";
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = "Terjadi kesalahan: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text("Tambah Email & Password"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: emailController,
            decoration: const InputDecoration(
              labelText: "Email baru",
              prefixIcon: Icon(Icons.email_outlined),
            ),
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: passwordController,
            decoration: const InputDecoration(
              labelText: "Password baru",
              prefixIcon: Icon(Icons.lock_outline),
            ),
            obscureText: true,
            autofillHints: const [AutofillHints.newPassword],
          ),
          if (errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              errorMessage!,
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: isLoading ? null : () => Navigator.pop(context, false),
          child: const Text("Batal"),
        ),
        FilledButton(
          onPressed: isLoading ? null : _linkEmailPassword,
          child: isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text("Tambah"),
        ),
      ],
    );
  }
}
