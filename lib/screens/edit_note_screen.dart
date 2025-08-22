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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Catatan diperbarui ✅")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (note == null) {
      return const Scaffold(
        body: Center(child: Text("Catatan tidak ditemukan.")),
      );
    }

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: theme.colorScheme.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header custom
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.arrow_back,
                          color: theme.colorScheme.onBackground,
                        ),
                        onPressed: () async {
                          final canPop = await _onWillPop();
                          if (canPop && mounted) {
                            Navigator.pop(context);
                          }
                        },
                      ),
                      Text(
                        "Edit Catatan",
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onBackground,
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Card input
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: theme.shadowColor.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: titleController,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: const InputDecoration(
                            hintText: "Judul catatan...",
                            border: InputBorder.none,
                          ),
                        ),
                        const Divider(),
                        TextField(
                          controller: contentController,
                          maxLines: null,
                          keyboardType: TextInputType.multiline,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            height: 1.5,
                          ),
                          decoration: const InputDecoration(
                            hintText: "Tulis sesuatu di sini ✨...",
                            border: InputBorder.none,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Tombol simpan
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      icon: const Icon(Icons.save),
                      label: const Text(
                        "Simpan Perubahan",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: _saveNote,
                    ),
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
