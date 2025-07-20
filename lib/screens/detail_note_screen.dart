import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodel/note_view_model.dart';
import '../models/note_model.dart';

class DetailNoteScreen extends StatefulWidget {
  final String noteId;
  const DetailNoteScreen({super.key, required this.noteId});

  @override
  State<DetailNoteScreen> createState() => _DetailNoteScreenState();
}

class _DetailNoteScreenState extends State<DetailNoteScreen> {
  Note? note;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNote();
  }

  Future<void> _loadNote() async {
    final viewModel = Provider.of<NoteViewModel>(context, listen: false);
    final fetchedNote = await viewModel.getNoteById(widget.noteId);

    if (mounted) {
      setState(() {
        note = fetchedNote;
        isLoading = false;
      });
    }
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
      appBar: AppBar(title: const Text("Detail Catatan")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(note!.title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            Text(note!.content),
            const Spacer(),
            Row(
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.edit),
                  label: const Text("Edit"),
                  onPressed: () async {
                    final result = await Navigator.pushNamed(
                      context,
                      '/edit_note',
                      arguments: note!.id,
                    );

                    if (result == true && mounted) {
                      setState(() => isLoading = true);
                      await _loadNote();

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Catatan berhasil diperbarui"),
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  icon: const Icon(Icons.delete),
                  label: const Text("Hapus"),
                  onPressed: () {
                    viewModel.removeNote(note!);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Catatan dihapus")),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
