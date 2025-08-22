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

    setState(() {
      _nextEpisodeDateTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
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

    setState(() => isSaving = true);

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

    setState(() => isSaving = false);

    if (mounted) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text("Catatan berhasil disimpan"),
            ],
          ),
        ),
      );
    }
  }

  Future<bool> _onWillPop() async {
    final isEmpty =
        _titleController.text.trim().isEmpty &&
        _yearController.text.trim().isEmpty &&
        _mediaController.text.trim().isEmpty &&
        _episodeController.text.trim().isEmpty &&
        _totalEpisodeController.text.trim().isEmpty;

    if (isEmpty) return true;

    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Keluar tanpa menyimpan?"),
        content: const Text(
          "Anda memiliki catatan yang belum disimpan. Yakin ingin keluar?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Keluar"),
          ),
        ],
      ),
    );

    return shouldExit ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateTimeFormatted = _nextEpisodeDateTime != null
        ? DateFormat('dd MMM yyyy, HH:mm').format(_nextEpisodeDateTime!)
        : null;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Tambah Catatan Film/Drama'),
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              final canExit = await _onWillPop();
              if (canExit && mounted) Navigator.pop(context);
            },
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildSectionCard(
                "🎬 Info Utama",
                Column(
                  children: [
                    _buildTextField(
                      controller: _titleController,
                      label: "Judul Film/Drama",
                      icon: Icons.movie,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _yearController,
                            label: "Tahun",
                            icon: Icons.calendar_today,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTextField(
                            controller: _mediaController,
                            label: "Media (opsional)",
                            icon: Icons.tv,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              _buildSectionCard(
                "📺 Progres",
                Column(
                  children: [
                    _buildTextField(
                      controller: _episodeController,
                      label: "Episode terakhir ditonton",
                      icon: Icons.play_arrow,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _totalEpisodeController,
                      label: "Total Episode (opsional)",
                      icon: Icons.format_list_numbered,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: statusOptions.map((status) {
                        final selected = status == selectedStatus;
                        return ChoiceChip(
                          label: Text(status),
                          selected: selected,
                          labelStyle: TextStyle(
                            color: selected
                                ? theme.colorScheme.onPrimary
                                : theme.colorScheme.onSurface,
                          ),
                          selectedColor: theme.colorScheme.primary,
                          backgroundColor: theme.colorScheme.surfaceVariant,
                          onSelected: (_) {
                            setState(() => selectedStatus = status);
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              _buildSectionCard(
                "⏰ Reminder",
                ListTile(
                  leading: const Icon(Icons.schedule),
                  title: Text(
                    dateTimeFormatted ?? 'Jadwal episode berikutnya (opsional)',
                    style: TextStyle(
                      color: dateTimeFormatted != null
                          ? theme.colorScheme.onSurface
                          : Colors.grey,
                    ),
                  ),
                  trailing: ElevatedButton.icon(
                    onPressed: _pickDateTime,
                    icon: const Icon(Icons.edit_calendar),
                    label: const Text('Pilih'),
                  ),
                ),
              ),

              if (selectedStatus == 'Selesai')
                _buildSectionCard(
                  "⭐ Review",
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Rating Kamu: ${_rating.toStringAsFixed(1)} / 5"),
                      Slider(
                        value: _rating,
                        min: 0,
                        max: 5,
                        divisions: 10,
                        label: _rating.toStringAsFixed(1),
                        onChanged: (value) {
                          setState(() => _rating = value);
                        },
                      ),
                      SwitchListTile(
                        title: const Text('Wajib Ditonton Ulang?'),
                        value: _mustRewatch,
                        onChanged: (value) {
                          setState(() => _mustRewatch = value);
                        },
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: isSaving ? null : _saveFilmNote,
                  icon: isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check),
                  label: Text(
                    isSaving ? "Menyimpan..." : "Simpan Catatan",
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        prefixIcon: Icon(icon),
      ),
    );
  }

  Widget _buildSectionCard(String title, Widget child) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Divider(),
            child,
          ],
        ),
      ),
    );
  }
}
