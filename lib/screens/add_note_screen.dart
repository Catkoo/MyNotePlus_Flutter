import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../viewmodel/note_view_model.dart';
import '../models/note_model.dart';

class AddNoteScreen extends StatefulWidget {
  const AddNoteScreen({super.key});

  @override
  State<AddNoteScreen> createState() => _AddNoteScreenState();
}

class _AddNoteScreenState extends State<AddNoteScreen> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController contentController = TextEditingController();

  @override
  void dispose() {
    titleController.dispose();
    contentController.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    final hasText = titleController.text.trim().isNotEmpty ||
        contentController.text.trim().isNotEmpty;

    if (!hasText) return true;

    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Keluar tanpa menyimpan?"),
        content: const Text(
          "Anda telah menulis sesuatu. Apakah yakin ingin keluar tanpa menyimpannya?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Batal"),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.redAccent.withValues(alpha: 0.9),
            ),
            child: const Text("Keluar"),
          ),
        ],
      ),
    );

    return shouldExit ?? false;
  }

  void _saveNote() {
    final viewModel = Provider.of<NoteViewModel>(context, listen: false);
    final title = titleController.text.trim();
    final content = contentController.text.trim();
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid != null && (title.isNotEmpty || content.isNotEmpty)) {
      final note = Note(
        id: const Uuid().v4(),
        title: title.isEmpty ? "Tanpa Judul" : title,
        content: content,
        ownerUid: uid,
        lastEdited: DateTime.now(),
      );
      viewModel.addNote(note);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Catatan disimpan ✅")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Isi catatan tidak boleh kosong!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final canPop = await _onWillPop();
        if (canPop && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF8F9FA),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          leading: IconButton(
            icon: Icon(Icons.close_rounded, color: isDark ? Colors.white : Colors.black87),
            onPressed: () async {
              final canPop = await _onWillPop();
              if (canPop && mounted) Navigator.pop(context);
            },
          ),
          title: Text(
            "Catatan Baru",
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          centerTitle: true,
          actions: [
            TextButton(
              onPressed: _saveNote,
              child: Text(
                "Simpan",
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    TextField(
                      controller: titleController,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      decoration: InputDecoration(
                        hintText: "Judul catatan...",
                        hintStyle: TextStyle(color: isDark ? Colors.white24 : Colors.black26),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 16),
                      height: 1.5,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primary.withValues(alpha: 0.5),
                            theme.colorScheme.primary.withValues(alpha: 0.01),
                          ],
                        ),
                      ),
                    ),
                    TextField(
                      controller: contentController,
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        height: 1.6,
                        fontSize: 17,
                        color: isDark ? Colors.white.withValues(alpha: 0.8) : Colors.black87,
                      ),
                      decoration: InputDecoration(
                        hintText: "Tulis ide cemerlangmu di sini ✨...",
                        hintStyle: TextStyle(color: isDark ? Colors.white24 : Colors.black26),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.only(bottom: 100),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Tombol Simpan di bagian bawah (Floating Style)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                
              ),
            ),
          ],
        ),
      ),
    );
  }
}