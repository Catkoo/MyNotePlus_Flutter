import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodel/note_view_model.dart';
import '../models/note_model.dart';

class EditNoteScreen extends StatefulWidget {
  final String noteId;
  const EditNoteScreen({super.key, required this.noteId});

  @override
  State<EditNoteScreen> createState() => _EditNoteScreenState();
}

class _EditNoteScreenState extends State<EditNoteScreen> {
  Note? note;
  bool isLoading = true;
  final TextEditingController titleController = TextEditingController();
  final TextEditingController contentController = TextEditingController();

  String? originalTitle;
  String? originalContent;

  @override
  void initState() {
    super.initState();
    final viewModel = Provider.of<NoteViewModel>(context, listen: false);
    viewModel.getNoteById(widget.noteId).then((value) {
      if (value != null) {
        note = value;
        titleController.text = note!.title;
        contentController.text = note!.content;
        originalTitle = note!.title;
        originalContent = note!.content;
      }
      setState(() => isLoading = false);
    });
  }

  Future<bool> _onWillPop() async {
    if (titleController.text.trim() != (originalTitle ?? "") ||
        contentController.text.trim() != (originalContent ?? "")) {
      final shouldExit = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Keluar tanpa menyimpan?"),
          content: const Text(
            "Perubahan belum disimpan. Apakah yakin ingin keluar tanpa menyimpannya?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text("Batal"),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text("Keluar"),
            ),
          ],
        ),
      );
      return shouldExit ?? false;
    }
    return true;
  }

  void _saveNote() {
    if (note != null) {
      final viewModel = Provider.of<NoteViewModel>(context, listen: false);
      final updatedNote = note!.copyWith(
        title: titleController.text.trim(),
        content: contentController.text.trim(),
        lastEdited: DateTime.now(),
      );
      viewModel.updateNote(updatedNote);
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Catatan diperbarui ✅")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (note == null) {
      return const Scaffold(
        body: Center(child: Text("Catatan tidak ditemukan.")),
      );
    }

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
            "Edit Catatan",
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
                      decoration: const InputDecoration(
                        hintText: "Judul catatan...",
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
                      decoration: const InputDecoration(
                        hintText: "Tulis ceritamu di sini ✨...",
                        border: InputBorder.none,
                      ),
                    ),
                  ],
                ),
              ),
            ),
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