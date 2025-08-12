import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
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

  String formatSimpleDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString();
    final year = (date.year % 100).toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return "$day $month $year $hour:$minute";
  }

  void _shareNote() {
    if (note == null) return;

    final lastEdited = formatSimpleDate(note!.lastEdited);
    final charCount = note!.content.replaceAll('\n', '').length;

    final shareText =
        """
📝 ${note!.title}
------------------------
${note!.content}

📅 Terakhir diedit: $lastEdited
✍️ Karakter: $charCount
""";

    Share.share(shareText.trim());
  }

  Future<void> _editNote() async {
    if (note == null) return;
    final result = await Navigator.pushNamed(
      context,
      '/edit_note',
      arguments: note!.id,
    );

    if (result == true && mounted) {
      setState(() => isLoading = true);
      await _loadNote();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Catatan berhasil diperbarui")),
      );
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

    final lastEdited = formatSimpleDate(note!.lastEdited);
    final charCount = note!.content.replaceAll('\n', '').length;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Detail Catatan"),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: "Bagikan Catatan",
            onPressed: _shareNote,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: "Hapus Catatan",
            onPressed: () {
              viewModel.deleteNote(note!.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text("Catatan dihapus")));
            },
          ),
        ],
      ),
      body: Material(
        color: Colors.transparent, // biar warna background tetap
        child: InkWell(
          splashColor: Colors.blue.withOpacity(0.2), // warna ripple
          highlightColor: Colors.blue.withOpacity(0.1),
          onTap: _editNote,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    note!.title,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "$lastEdited | $charCount karakter",
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    note!.content,
                    style: Theme.of(context).textTheme.bodyLarge,
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
