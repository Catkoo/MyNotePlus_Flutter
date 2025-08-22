import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/notification_helper.dart';
import 'package:intl/intl.dart';
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
  final _totalEpisodeController = TextEditingController();

  DateTime? _nextEpisodeDateTime;
  final statusOptions = ['Belum selesai', 'Selesai'];
  String selectedStatus = 'Belum selesai';

  double _rating = 0.0;
  bool _mustRewatch = false;
  bool isSaving = false;
  bool isLoading = true;

  FilmNote? _currentNote;

  @override
  void initState() {
    super.initState();
    _loadNote();
  }

  Future<void> _loadNote() async {
    final note = await FilmNoteViewModel().getFilmNoteById(widget.filmId);
    if (!mounted) return;

    if (note != null) {
      setState(() {
        _currentNote = note;
        _titleController.text = note.title;
        _yearController.text = note.year;
        _mediaController.text = note.media ?? '';
        _episodeController.text = note.episodeWatched.toString();
        _totalEpisodeController.text = note.totalEpisodes?.toString() ?? '';
        selectedStatus = note.isFinished ? 'Selesai' : 'Belum selesai';
        _rating = note.overallRating ?? 0.0;
        _mustRewatch = note.mustRewatch ?? false;
        _nextEpisodeDateTime = note.nextEpisodeDate;
        isLoading = false;
      });
    } else {
      Navigator.pop(context); // jika id tidak ditemukan
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

  void _updateFilmNote() async {
    final title = _titleController.text.trim();
    final year = _yearController.text.trim();
    final media = _mediaController.text.trim();
    final episode = int.tryParse(_episodeController.text.trim()) ?? 0;
    final totalEpisode = int.tryParse(_totalEpisodeController.text.trim());

    // Validasi ketat: judul wajib ada, tahun wajib, episode > 0
    if (title.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Judul tidak boleh kosong')));
      return;
    }
    if (year.isEmpty || episode == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tahun dan Episode wajib diisi')),
      );
      return;
    }

    setState(() => isSaving = true);

    final currentUser = FirebaseAuth.instance.currentUser;
    final updatedNote = FilmNote(
      id: _currentNote!.id,
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

    await FilmNoteViewModel().updateFilmNote(updatedNote);

    // Update notifikasi
    if (_nextEpisodeDateTime != null) {
      await scheduleNotification(
        id: updatedNote.id.hashCode,
        title: 'Episode Baru: ${updatedNote.title}',
        body: 'Jangan lupa nonton episode berikutnya hari ini!',
        scheduledDate: _nextEpisodeDateTime!,
      );
    }

    setState(() => isSaving = false);

    if (!mounted) return;
    Navigator.pop(context, true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text("Catatan berhasil diperbarui"),
          ],
        ),
      ),
    );
  }

  bool get _hasChanges {
    if (_currentNote == null) return false;
    return _titleController.text.trim() != _currentNote!.title ||
        _yearController.text.trim() != _currentNote!.year ||
        _mediaController.text.trim() != (_currentNote!.media ?? '') ||
        _episodeController.text.trim() !=
            _currentNote!.episodeWatched.toString() ||
        _totalEpisodeController.text.trim() !=
            (_currentNote!.totalEpisodes?.toString() ?? '') ||
        selectedStatus !=
            (_currentNote!.isFinished ? 'Selesai' : 'Belum selesai') ||
        _nextEpisodeDateTime != _currentNote!.nextEpisodeDate ||
        _rating != (_currentNote!.overallRating ?? 0.0) ||
        _mustRewatch != (_currentNote!.mustRewatch ?? false);
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;

    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Keluar tanpa menyimpan?"),
        content: const Text(
          "Anda memiliki perubahan yang belum disimpan. Yakin ingin keluar?",
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
    final isDark = theme.brightness == Brightness.dark;
    final dateTimeFormatted = _nextEpisodeDateTime != null
        ? DateFormat('dd MMM yyyy, HH:mm').format(_nextEpisodeDateTime!)
        : null;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Edit Catatan Film/Drama'),
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
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
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
                            icon: Icons.movie_outlined,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  controller: _yearController,
                                  label: "Tahun",
                                  icon: Icons.calendar_month_outlined,
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildTextField(
                                  controller: _mediaController,
                                  label: "Media (opsional)",
                                  icon: Icons.tv_outlined,
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
                            icon: Icons.play_arrow_outlined,
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _totalEpisodeController,
                            label: "Total Episode (opsional)",
                            icon: Icons.format_list_numbered_outlined,
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: statusOptions.map((status) {
                              final selected = status == selectedStatus;
                              return ChoiceChip(
                                label: Text(status),
                                selected: selected,
                                labelStyle: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: selected
                                      ? theme.colorScheme.onPrimary
                                      : theme.colorScheme.onSurface,
                                ),
                                selectedColor: theme.colorScheme.primary,
                                backgroundColor: theme
                                    .colorScheme
                                    .surfaceVariant
                                    .withOpacity(isDark ? 0.25 : 0.6),
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
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.alarm_outlined),
                        title: Text(
                          dateTimeFormatted ??
                              'Jadwal episode berikutnya (opsional)',
                          style: TextStyle(
                            fontSize: 14,
                            color: dateTimeFormatted != null
                                ? theme.colorScheme.onSurface
                                : theme.hintColor,
                          ),
                        ),
                        trailing: OutlinedButton.icon(
                          onPressed: _pickDateTime,
                          icon: const Icon(Icons.edit_calendar_outlined),
                          label: const Text('Atur'),
                        ),
                      ),
                    ),

                    if (selectedStatus == 'Selesai')
                      _buildSectionCard(
                        "⭐ Review",
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Rating Kamu: ${_rating.toStringAsFixed(1)} / 5",
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
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
                              contentPadding: EdgeInsets.zero,
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
                        onPressed: isSaving ? null : _updateFilmNote,
                        icon: isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save_outlined),
                        label: Text(
                          isSaving ? "Menyimpan..." : "Perbarui Catatan",
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Label muncul hanya jika ada isi; kalau kosong, pakai hint
    final showLabel = controller.text.isNotEmpty;

    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: (_) =>
          setState(() {}), // trigger rebuild agar label/hint adaptif
      decoration: InputDecoration(
        labelText: showLabel ? label : null,
        hintText: showLabel ? null : "Masukkan $label",
        hintStyle: TextStyle(color: theme.hintColor),
        filled: true,
        fillColor: theme.colorScheme.surfaceVariant.withOpacity(
          isDark ? 0.2 : 0.6,
        ),
        prefixIcon: Icon(icon, color: theme.colorScheme.primary),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildSectionCard(String title, Widget child) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 2,
      color: theme.cardColor,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
