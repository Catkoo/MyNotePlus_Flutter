import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/film_note.dart';
import '../viewmodel/film_note_viewmodel.dart';
import '../services/notification_helper.dart';

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
  final _totalEpisodeController = TextEditingController();

  final statusOptions = ['Belum selesai', 'Selesai'];
  String selectedStatus = 'Belum selesai';
  DateTime? _nextEpisodeDateTime;

  double _rating = 0.0;
  bool _mustRewatch = false;

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
        _totalEpisodeController.text =
            fetchedNote.totalEpisodes?.toString() ?? '';
        selectedStatus = fetchedNote.isFinished ? 'Selesai' : 'Belum selesai';
        _nextEpisodeDateTime = fetchedNote.nextEpisodeDate;
        _rating = fetchedNote.overallRating ?? 0.0;
        _mustRewatch = fetchedNote.mustRewatch ?? false;
        isLoading = false;
      });
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Catatan tidak ditemukan')));
      Navigator.pop(context);
    }
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _nextEpisodeDateTime ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );

    if (pickedDate == null) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 20, minute: 0),
    );

    if (pickedTime == null) return;

    final combined = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    setState(() => _nextEpisodeDateTime = combined);
  }

  void _saveChanges() async {
    final title = _titleController.text.trim();
    final year = _yearController.text.trim();
    final media = _mediaController.text.trim();
    final episode = int.tryParse(_episodeController.text.trim()) ?? 0;
    final totalEpisodes = int.tryParse(_totalEpisodeController.text.trim());

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
      lastEdited: DateTime.now(),
      nextEpisodeDate: _nextEpisodeDateTime,
      totalEpisodes: totalEpisodes,
      overallRating: selectedStatus == 'Selesai' ? _rating : null,
      mustRewatch: selectedStatus == 'Selesai' ? _mustRewatch : null,
    );

    final viewModel = Provider.of<FilmNoteViewModel>(context, listen: false);
    await viewModel.updateFilmNote(updated);

    final notifId = updated.id.hashCode;

    await cancelNotification(notifId);

    if (_nextEpisodeDateTime != null) {
      await scheduleNotification(
        id: notifId,
        title: 'Episode Baru: ${updated.title}',
        body: 'Jangan lupa nonton episode berikutnya hari ini!',
        scheduledDate: _nextEpisodeDateTime!,
      );
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Catatan diperbarui')));
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateTimeFormatted = _nextEpisodeDateTime != null
        ? DateFormat('dd MMM yyyy, HH:mm').format(_nextEpisodeDateTime!)
        : null;

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
                  _buildInputField('Judul', _titleController),
                  _buildInputField(
                    'Tahun',
                    _yearController,
                    TextInputType.number,
                  ),
                  _buildInputField('Media (opsional)', _mediaController),
                  _buildInputField(
                    'Episode terakhir ditonton',
                    _episodeController,
                    TextInputType.number,
                  ),
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
                  _buildInputField(
                    'Total Episode (opsional)',
                    _totalEpisodeController,
                    TextInputType.number,
                  ),
                  const SizedBox(height: 20),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.schedule),
                    title: Text(
                      dateTimeFormatted ??
                          'Jadwal episode berikutnya (opsional)',
                      style: TextStyle(
                        color: dateTimeFormatted != null
                            ? theme.colorScheme.onSurface
                            : Colors.grey,
                      ),
                    ),
                    trailing: TextButton(
                      onPressed: _pickDateTime,
                      child: const Text('Pilih'),
                    ),
                  ),
                  if (selectedStatus == 'Selesai') ...[
                    const SizedBox(height: 24),
                    Text('Rating Kamu', style: theme.textTheme.titleMedium),
                    Slider(
                      value: _rating,
                      onChanged: (value) => setState(() => _rating = value),
                      min: 0.0,
                      max: 5.0,
                      divisions: 10,
                      label: _rating.toStringAsFixed(1),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      title: const Text('Wajib Ditonton Ulang?'),
                      value: _mustRewatch,
                      onChanged: (value) =>
                          setState(() => _mustRewatch = value),
                    ),
                  ],
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

  Widget _buildInputField(
    String label,
    TextEditingController controller, [
    TextInputType? inputType,
  ]) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        keyboardType: inputType,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}
