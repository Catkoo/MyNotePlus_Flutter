import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/film_note.dart';
import '../viewmodel/film_note_viewmodel.dart';

class DetailFilmNoteScreen extends StatefulWidget {
  final String filmId;
  const DetailFilmNoteScreen({super.key, required this.filmId});

  @override
  State<DetailFilmNoteScreen> createState() => _DetailFilmNoteScreenState();
}

class _DetailFilmNoteScreenState extends State<DetailFilmNoteScreen> {
  FilmNote? filmNote;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFilmNote();
  }

  Future<void> _loadFilmNote() async {
    final viewModel = Provider.of<FilmNoteViewModel>(context, listen: false);
    final note = await viewModel.getFilmNoteById(widget.filmId);

    if (mounted) {
      setState(() {
        filmNote = note;
        isLoading = false;
      });
    }
  }

  String formatSimpleDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = (date.year % 100).toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return "$day $month $year | $hour:$minute";
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<FilmNoteViewModel>(context);
    final theme = Theme.of(context);

    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text("Detail Film/Drama")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (filmNote == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Detail Film/Drama")),
        body: const Center(child: Text("Catatan tidak ditemukan.")),
      );
    }

    final note = filmNote!;
    final lastEdited = formatSimpleDate(note.lastEdited);

    return Scaffold(
      appBar: AppBar(title: const Text("Detail Film/Drama")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      note.title,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      lastEdited,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 16),
                        const SizedBox(width: 6),
                        Text(note.year),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (note.media != null && note.media!.isNotEmpty)
                      Row(
                        children: [
                          const Icon(Icons.tv, size: 16),
                          const SizedBox(width: 6),
                          Text("Media: ${note.media}"),
                        ],
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.video_collection, size: 16),
                        const SizedBox(width: 6),
                        Text("Episode terakhir: ${note.episodeWatched}"),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          note.isFinished
                              ? Icons.check_circle
                              : Icons.hourglass_bottom,
                          size: 16,
                          color: note.isFinished ? Colors.green : Colors.orange,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          note.isFinished
                              ? "✅ Selesai ditonton"
                              : "⏳ Belum selesai",
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.edit),
                    label: const Text("Edit"),
                    onPressed: () async {
                      final result = await Navigator.pushNamed(
                        context,
                        "/edit_film_note",
                        arguments: note.id,
                      );

                      if (result == true && mounted) {
                        setState(() => isLoading = true);
                        final updatedNote = await viewModel.getFilmNoteById(
                          widget.filmId,
                        );
                        if (mounted) {
                          setState(() {
                            filmNote = updatedNote;
                            isLoading = false;
                          });

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Catatan berhasil diperbarui'),
                            ),
                          );
                        }
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.delete),
                    label: const Text("Hapus"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.error,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      viewModel.deleteFilmNote(note);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Catatan film dihapus")),
                      );
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
