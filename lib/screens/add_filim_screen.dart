import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/notification_helper.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../models/film_note.dart';
import '../viewmodel/film_note_viewmodel.dart';

class AddFilmNoteScreen extends StatefulWidget {
  const AddFilmNoteScreen({super.key});

  @override
  State<AddFilmNoteScreen> createState() => _AddFilmNoteScreenState();
}

class _AddFilmNoteScreenState extends State<AddFilmNoteScreen> {
  final _titleController = TextEditingController();
  final _yearController = TextEditingController();
  final _mediaController = TextEditingController();
  final _episodeController = TextEditingController(text: '1');
  final _totalEpisodeController = TextEditingController();

  DateTime? _nextEpisodeDateTime;
  final statusOptions = ['Belum selesai', 'Selesai'];
  String selectedStatus = 'Belum selesai';

  double _rating = 0.0;
  bool _mustRewatch = false;
  bool isSaving = false;

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
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

    setState(() {
      _nextEpisodeDateTime = combined;
    });
  }

  void _saveFilmNote() async {
    final title = _titleController.text.trim();
    final year = _yearController.text.trim();
    final media = _mediaController.text.trim();
    final episode = int.tryParse(_episodeController.text.trim()) ?? 0;
    final totalEpisode = int.tryParse(_totalEpisodeController.text.trim());

    if (title.isEmpty || year.isEmpty || episode == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Judul, Tahun, dan Episode wajib diisi')),
      );
      return;
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    final note = FilmNote(
      id: const Uuid().v4(),
      title: title,
      year: year,
      media: media.isEmpty ? null : media,
      episodeWatched: episode,
      isFinished: selectedStatus == 'Selesai',
      ownerUid: currentUser?.uid ?? '',
      lastEdited: DateTime.now(),
      nextEpisodeDate: _nextEpisodeDateTime,
      totalEpisodes: totalEpisode,
      overallRating: selectedStatus == 'Selesai' ? _rating : null,
      mustRewatch: selectedStatus == 'Selesai' ? _mustRewatch : null,
    );

    await FilmNoteViewModel().addFilmNote(note);

    if (_nextEpisodeDateTime != null) {
      await scheduleNotification(
        id: note.id.hashCode,
        title: 'Episode Baru: ${note.title}',
        body: 'Jangan lupa nonton episode berikutnya hari ini!',
        scheduledDate: _nextEpisodeDateTime!,
      );
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateTimeFormatted = _nextEpisodeDateTime != null
        ? DateFormat('dd MMM yyyy, HH:mm').format(_nextEpisodeDateTime!)
        : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Tambah Film/Drama')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Judul Film/Drama',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _yearController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Tahun'),
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
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Episode terakhir ditonton',
                      ),
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
                    const SizedBox(height: 12),
                    TextField(
                      controller: _totalEpisodeController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Total Episode (opsional)',
                      ),
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
                        onChanged: (value) {
                          setState(() => _rating = value);
                        },
                        min: 0.0,
                        max: 5.0,
                        divisions: 10,
                        label: _rating.toStringAsFixed(1),
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        title: const Text('Wajib Ditonton Ulang?'),
                        value: _mustRewatch,
                        onChanged: (value) {
                          setState(() => _mustRewatch = value);
                        },
                      ),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: isSaving ? null : _saveFilmNote,
                        icon: const Icon(Icons.check),
                        label: const Text('Simpan Catatan'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
