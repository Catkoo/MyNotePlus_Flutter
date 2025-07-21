import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  @override
  void initState() {
    super.initState();
    final viewModel = Provider.of<NoteViewModel>(context, listen: false);
    viewModel.getNoteById(widget.noteId).then((value) {
      if (value != null) {
        note = value;
        titleController.text = note!.title;
        contentController.text = note!.content;
      }
      setState(() => isLoading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<NoteViewModel>(context, listen: false);

    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (note == null) {
      return const Scaffold(
        body: Center(child: Text("Catatan tidak ditemukan.")),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Edit Catatan")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: "Judul",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: contentController,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: "Isi Catatan",
                border: OutlineInputBorder(),
              ),
            ),
            const Spacer(),
            FilledButton.icon(
              icon: const Icon(Icons.check),
              label: const Text("Simpan"),
              onPressed: () {
                final updatedNote = note!.copyWith(
                  title: titleController.text,
                  content: contentController.text,
                  lastEdited: DateTime.now(),
                );
                viewModel.updateNote(updatedNote);
                Navigator.pop(context, true);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Catatan diperbarui")),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
