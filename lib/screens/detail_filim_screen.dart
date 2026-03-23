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
      
      // Penentuan Status & Progress Text
      final statusText = note.isFinished ? "🍿 Finished" : "⏳ On-Going";
      final progressText = "${note.episodeWatched}${note.totalEpisodes != null ? " / ${note.totalEpisodes}" : " Eps"}";
      
      // Visual Progress Bar (Emoji)
      String progressBar = "";
      if (note.totalEpisodes != null && note.totalEpisodes! > 0) {
        const int totalTicks = 10;
        int filledTicks = ((note.episodeWatched / note.totalEpisodes!) * totalTicks).round().clamp(0, totalTicks);
        progressBar = "\n📊 Progress : " + "🟦" * filledTicks + "⬜" * (totalTicks - filledTicks);
      }

      // Template Teks (Tanpa Review/Content)
      final shareText = '''
    Detail Informasi Filim/Drama/Donghua 🚀

    🎬 ${note.title.toUpperCase()} (${note.year})
    ─────────────────────────
    📌 Platform : ${note.media ?? "-"}
    📺 Episode  : $progressText $progressBar
    ✨ Status   : $statusText
    ${note.overallRating != null ? "⭐ Rating   : ${note.overallRating!.toStringAsFixed(1)} / 5.0" : ""}

    Dibagikan Melalui MyNotePlus ✨
    ''';

      Share.share(shareText, subject: 'Update Nonton: ${note.title}');
    }

  void _confirmDelete(FilmNoteViewModel viewModel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Hapus Catatan?"),
        content: const Text("Catatan film/drama/donghua ini akan dihapus permanen."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
          TextButton(
            onPressed: () {
              viewModel.deleteNote(filmNote!.id);
              Navigator.pop(context); // Tutup dialog
              Navigator.pop(context); // Kembali ke list
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Hapus"),
          ),
        ],
      ),
    );
  }

  Future<void> goToEdit(FilmNote note, FilmNoteViewModel viewModel) async {
    final result = await Navigator.pushNamed(
      context,
      "/edit_film_note",
      arguments: note.id,
    );

    if (result == true && mounted) {
      setState(() => isLoading = true);
      _loadFilmNote();
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<FilmNoteViewModel>(context, listen: false);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (filmNote == null) return const Scaffold(body: Center(child: Text("Catatan tidak ditemukan.")));

    final note = filmNote!;
    final lastEdited = formatSimpleDate(note.lastEdited);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: shareNote,
            color: theme.colorScheme.primary,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: () => _confirmDelete(viewModel),
            color: Colors.redAccent,
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => goToEdit(note, viewModel),
        icon: const Icon(Icons.edit_rounded),
        label: const Text("Edit Review"),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Header Title ---
            const SizedBox(height: 10),
            Text(
              note.title.toUpperCase(),
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildBadge(note.year, theme.colorScheme.primary.withValues(alpha: 0.1), theme.colorScheme.primary),
                const SizedBox(width: 8),
                if (note.media != null)
                  _buildBadge(note.media!, Colors.grey.withValues(alpha: 0.1), Colors.grey),
              ],
            ),
            const SizedBox(height: 24),

            // --- Status & Progress Card ---
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  if (!isDark)
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    )
                ],
              ),
              child: Column(
                children: [
                  _buildInfoRow(
                    Icons.movie_creation_outlined,
                    "Status Nonton",
                    note.isFinished ? "Selesai" : "Sedang Berjalan",
                    trailing: Icon(
                      note.isFinished ? Icons.check_circle_rounded : Icons.pending_rounded,
                      color: note.isFinished ? Colors.green : Colors.orange,
                    ),
                  ),
                  const Divider(height: 32),
                  _buildInfoRow(
                    Icons. theater_comedy_outlined,
                    "Progres Episode",
                    "${note.episodeWatched} ${note.totalEpisodes != null ? "/ ${note.totalEpisodes}" : "Eps"}",
                  ),
                  if (note.nextEpisodeDate != null) ...[
                    const Divider(height: 32),
                    _buildInfoRow(
                      Icons.schedule_rounded,
                      "Jadwal Berikutnya",
                      formatSimpleDate(note.nextEpisodeDate!),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            // --- Rating Section (If Finished) ---
            if (note.isFinished && note.overallRating != null)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [theme.colorScheme.primary, theme.colorScheme.primaryContainer],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "RATING KAMU",
                          style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              note.overallRating!.toStringAsFixed(1),
                              style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                            ),
                            const Text(" / 5.0", style: TextStyle(color: Colors.white70, fontSize: 16)),
                          ],
                        ),
                      ],
                    ),
                    const Spacer(),
                    const Icon(Icons.star_rounded, color: Colors.white, size: 48),
                  ],
                ),
              ),
            
            if (note.mustRewatch == true) ...[
               const SizedBox(height: 12),
               _buildRewatchRibbon(theme),
            ],

            const SizedBox(height: 32),
            Center(
              child: Text(
                "Terakhir diperbarui pada $lastEdited",
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
      child: Text(
        text,
        style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {Widget? trailing}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: Colors.grey),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ],
        ),
        const Spacer(),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _buildRewatchRibbon(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
      ),
      child: const Row(
        children: [
          Icon(Icons.repeat_rounded, color: Colors.amber, size: 20),
          SizedBox(width: 10),
          Text("Wajib Ditonton Ulang", style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}