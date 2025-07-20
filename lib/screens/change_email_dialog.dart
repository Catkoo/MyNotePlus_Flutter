import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChangeEmailDialog extends StatefulWidget {
  final User user;
  const ChangeEmailDialog({super.key, required this.user});

  @override
  State<ChangeEmailDialog> createState() => _ChangeEmailDialogState();
}

class _ChangeEmailDialogState extends State<ChangeEmailDialog> {
  final passwordController = TextEditingController();
  final newEmailController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ganti Email'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: passwordController,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Password'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: newEmailController,
            decoration: const InputDecoration(labelText: 'Email baru'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () async {
            try {
              final cred = EmailAuthProvider.credential(
                email: widget.user.email!,
                password: passwordController.text.trim(),
              );
              await widget.user.reauthenticateWithCredential(cred);
              await widget.user.updateEmail(newEmailController.text.trim());
              await widget.user.sendEmailVerification();

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Email diperbarui, verifikasi dikirim'),
                  ),
                );
              }
            } catch (_) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Gagal mengubah email')),
                );
              }
            }
          },
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}
