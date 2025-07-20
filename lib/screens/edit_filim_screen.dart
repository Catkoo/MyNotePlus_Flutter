import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/film_note.dart';
import '../viewmodel/film_note_viewmodel.dart';

class EditFilmNoteScreen extends StatefulWidget {
  final String filmId;
  const EditFilmNoteScreen({super.key, required this.filmId});

  @override
  State<EditFilmNoteScreen> createState() => _EditFilmNoteScreenState();
}

class _EditFilmNoteScreenState extends State<EditFilmNoteScreen> {
  final _titleController = TextEditingController();
  final _yearController = TextEditingController();
  final _mediaController = TextEditingController();
  final _episodeController = TextEditingController();

  final statusOptions = ['Belum selesai', 'Selesai'];
  String selectedStatus = 'Belum selesai';

  bool isLoading = true;
  FilmNote? note;

  @override
  void initState() {
    super.initState();
    _loadFilmNote();
  }

  void _loadFilmNote() async {
    final viewModel = Provider.of<FilmNoteViewModel>(context, listen: false);
    final fetchedNote = await viewModel.getFilmNoteById(widget.filmId);

    if (!mounted) return;

    if (fetchedNote != null) {
      setState(() {
        note = fetchedNote;
        _titleController.text = fetchedNote.title;
        _yearController.text = fetchedNote.year;
        _mediaController.text = fetchedNote.media ?? '';
        _episodeController.text = fetchedNote.episodeWatched.toString();
        selectedStatus = fetchedNote.isFinished ? 'Selesai' : 'Belum selesai';
        isLoading = false;
      });
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Catatan tidak ditemukan')));
      Navigator.pop(context);
    }
  }

  void _saveChanges() {
    final title = _titleController.text.trim();
    final year = _yearController.text.trim();
    final media = _mediaController.text.trim();
    final episode = int.tryParse(_episodeController.text.trim()) ?? 0;

    if (title.isEmpty || year.isEmpty || episode == 0 || note == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Isi semua field wajib')));
      return;
    }

    final updated = note!.copyWith(
      title: title,
      year: year,
      media: media.isEmpty ? null : media,
      episodeWatched: episode,
      isFinished: selectedStatus == 'Selesai',
    );

    final viewModel = Provider.of<FilmNoteViewModel>(context, listen: false);
    viewModel.updateFilmNote(updated);
    Navigator.pop(context, true); // agar bisa trigger refresh saat kembali
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Catatan diperbarui')));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Film/Drama')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Edit Catatan Film/Drama',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: 'Judul'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _yearController,
                    decoration: const InputDecoration(labelText: 'Tahun'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _mediaController,
                    decoration: const InputDecoration(
                      labelText: 'Media (opsional)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _episodeController,
                    decoration: const InputDecoration(
                      labelText: 'Episode terakhir ditonton',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedStatus,
                    items: statusOptions.map((status) {
                      return DropdownMenuItem(
                        value: status,
                        child: Text(status),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => selectedStatus = value!);
                    },
                    decoration: const InputDecoration(labelText: 'Status'),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _saveChanges,
                      icon: const Icon(Icons.check),
                      label: const Text('Simpan Perubahan'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
