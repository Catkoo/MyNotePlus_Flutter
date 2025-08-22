import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
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
    return "$day/$month/$year • $hour:$minute";
  }

  void shareNote() {
    if (filmNote == null) return;
    final note = filmNote!;
    final shareText =
        '''
🎬 ${note.title}
Tahun: ${note.year}
Episode terakhir: ${note.episodeWatched}${note.totalEpisodes != null ? " / ${note.totalEpisodes}" : ""}
Status: ${note.isFinished ? "✅ Selesai" : "⏳ Belum selesai"}
${note.overallRating != null ? "Rating: ${note.overallRating!.toStringAsFixed(1)}/5" : ""}
${note.mustRewatch != null ? (note.mustRewatch! ? "🔄 Wajib ditonton ulang" : "❌ Tidak wajib rewatch") : ""}

📅 Terakhir diubah: ${formatSimpleDate(note.lastEdited)}
${note.nextEpisodeDate != null ? "📢 Tayang berikutnya: ${formatSimpleDate(note.nextEpisodeDate!)}" : ""}

Catatan dibuat di MyNotePlus 📱
''';

    Share.share(shareText);
  }

  Future<void> goToEdit(FilmNote note, FilmNoteViewModel viewModel) async {
    final result = await Navigator.pushNamed(
      context,
      "/edit_film_note",
      arguments: note.id,
    );

    if (result == true && mounted) {
      setState(() => isLoading = true);
      final updatedNote = await viewModel.getFilmNoteById(widget.filmId);
      if (mounted) {
        setState(() {
          filmNote = updatedNote;
          isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Catatan berhasil diperbarui')),
        );
      }
    }
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
      appBar: AppBar(
        title: const Text("Detail Film/Drama"),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: "Bagikan",
            onPressed: shareNote,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: "Hapus",
            onPressed: () {
              viewModel.deleteNote(note.id);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Catatan film dihapus")),
              );
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: GestureDetector(
            onTap: () => goToEdit(note, viewModel), // klik area card = edit
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 4,
              shadowColor: Colors.black26,
              child: Padding(
                padding: const EdgeInsets.all(20),
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
                      "Terakhir diubah: $lastEdited",
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                    const Divider(height: 24),

                    // Tahun
                    if (note.year.isNotEmpty) ...[
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 18),
                          const SizedBox(width: 8),
                          Text(note.year),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Media
                    if (note.media != null && note.media!.isNotEmpty) ...[
                      Row(
                        children: [
                          const Icon(Icons.tv, size: 18),
                          const SizedBox(width: 8),
                          Text("Media: ${note.media}"),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Episode terakhir
                    Row(
                      children: [
                        const Icon(Icons.video_collection, size: 18),
                        const SizedBox(width: 8),
                        Text("Episode terakhir: ${note.episodeWatched}"),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Total episode
                    if (note.totalEpisodes != null) ...[
                      Row(
                        children: [
                          const Icon(Icons.format_list_numbered, size: 18),
                          const SizedBox(width: 8),
                          Text("Total episode: ${note.totalEpisodes}"),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Next episode
                    if (note.nextEpisodeDate != null) ...[
                      Row(
                        children: [
                          const Icon(Icons.notifications_active, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            "Tayang berikutnya: ${formatSimpleDate(note.nextEpisodeDate!)}",
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Status
                    Row(
                      children: [
                        Icon(
                          note.isFinished
                              ? Icons.check_circle
                              : Icons.hourglass_bottom,
                          size: 18,
                          color: note.isFinished ? Colors.green : Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          note.isFinished
                              ? "✅ Selesai ditonton"
                              : "⏳ Belum selesai",
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Rating
                    if (note.isFinished && note.overallRating != null) ...[
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rate,
                            size: 18,
                            color: Colors.amber,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Rating: ${note.overallRating!.toStringAsFixed(1)} / 5",
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Rewatch
                    if (note.isFinished && note.mustRewatch != null) ...[
                      Row(
                        children: [
                          const Icon(Icons.loop, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            note.mustRewatch!
                                ? "Wajib ditonton ulang"
                                : "Tidak wajib rewatch",
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
