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
    final month = date.month.toString().padLeft(2, '0');
    final year = (date.year % 100).toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return "$day/$month/$year $hour:$minute";
  }

  void _shareNote() {
    if (note == null) return;
    final lastEdited = formatSimpleDate(note!.lastEdited);
    final shareText = "📝 ${note!.title}\n---\n${note!.content}\n\n📅 Diedit: $lastEdited";
    Share.share(shareText.trim());
  }

  // --- FUNGSI DELETE DENGAN KONFIRMASI ---
  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hapus Catatan?"),
        content: const Text("Apakah Anda yakin ingin menghapus catatan ini? Tindakan ini tidak dapat dibatalkan."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          FilledButton(
            onPressed: () {
              final viewModel = Provider.of<NoteViewModel>(context, listen: false);
              viewModel.deleteNote(note!.id);
              Navigator.pop(context); // Tutup Dialog
              Navigator.pop(context); // Kembali ke Home
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Catatan berhasil dihapus 🗑️")),
              );
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text("Hapus"),
          ),
        ],
      ),
    );
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (note == null) return const Scaffold(body: Center(child: Text("Catatan tidak ditemukan.")));

    final lastEdited = formatSimpleDate(note!.lastEdited);
    final charCount = note!.content.replaceAll('\n', '').length;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            onPressed: _shareNote,
            color: theme.colorScheme.primary,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: _confirmDelete, // Memanggil fungsi konfirmasi
            color: Colors.redAccent,
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _editNote,
        icon: const Icon(Icons.edit_document),
        label: const Text("Edit Catatan"),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.event_note, size: 14, color: theme.colorScheme.primary),
                  const SizedBox(width: 6),
                  Text(
                    lastEdited,
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text("|", style: TextStyle(color: theme.colorScheme.primary.withValues(alpha: 0.3))),
                  const SizedBox(width: 12),
                  Icon(Icons.text_fields_rounded, size: 14, color: theme.colorScheme.primary),
                  const SizedBox(width: 6),
                  Text(
                    "$charCount Karakter",
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              note!.title,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
                letterSpacing: -0.5,
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(vertical: 20),
              height: 1,
              width: 60,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              note!.content,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontSize: 17,
                height: 1.6,
                color: isDark ? Colors.white.withValues(alpha: 0.9) : Colors.black87.withValues(alpha: 0.8),
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}