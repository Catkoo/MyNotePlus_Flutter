import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
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

  final statusOptions = ['Belum selesai', 'Selesai'];
  String selectedStatus = 'Belum selesai';

  double _rating = 0.0;
  bool _mustRewatch = false;
  bool isSaving = false;

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
      totalEpisodes: totalEpisode,
      overallRating: selectedStatus == 'Selesai' ? _rating : null,
      mustRewatch: selectedStatus == 'Selesai' ? _mustRewatch : null,
    );

    await FilmNoteViewModel().addFilmNote(note);

    setState(() => isSaving = false);

    if (mounted) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text("Catatan film berhasil disimpan!"),
            ],
          ),
        ),
      );
    }
  }

  Future<bool> _onWillPop() async {
    final isEmpty = _titleController.text.trim().isEmpty &&
        _yearController.text.trim().isEmpty &&
        _mediaController.text.trim().isEmpty &&
        _episodeController.text.trim().isEmpty &&
        _totalEpisodeController.text.trim().isEmpty;

    if (isEmpty) return true;

    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text("Batalkan Catatan?"),
        content: const Text("Perubahan yang Anda buat belum disimpan."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Lanjut Tulis"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Hapus"),
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

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final canPop = await _onWillPop();
        if (canPop && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF5F7FA),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          leading: IconButton(
            icon: Icon(Icons.close_rounded, color: isDark ? Colors.white : Colors.black87),
            onPressed: () async {
              final canExit = await _onWillPop();
              if (canExit && mounted) Navigator.pop(context);
            },
          ),
          title: Text(
            'Tambah Review',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle("🎬 INFORMASI FILM"),
              const SizedBox(height: 12),
              _buildModernTextField(
                controller: _titleController,
                label: "Judul Film atau Drama",
                icon: Icons.movie_filter_rounded,
                hint: "Contoh: Interstellar",
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildModernTextField(
                      controller: _yearController,
                      label: "Tahun Rilis",
                      icon: Icons.calendar_month_rounded,
                      keyboardType: TextInputType.number,
                      hint: "2024",
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildModernTextField(
                      controller: _mediaController,
                      label: "Platform",
                      icon: Icons.connected_tv_rounded,
                      hint: "Netflix, Cinema",
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              _buildSectionTitle("📺 PROGRES NONTON"),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildModernTextField(
                      controller: _episodeController,
                      label: "Eps Saat Ini",
                      icon: Icons.play_circle_fill_rounded,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildModernTextField(
                      controller: _totalEpisodeController,
                      label: "Total Eps",
                      icon: Icons.list_alt_rounded,
                      keyboardType: TextInputType.number,
                      hint: "Opsional",
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: statusOptions.map((status) {
                    final selected = status == selectedStatus;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => selectedStatus = status),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: selected ? theme.colorScheme.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            status,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: selected ? Colors.white : Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 32),
              if (selectedStatus == 'Selesai') ...[
                _buildSectionTitle("⭐ PENILAIAN"),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Rating", style: TextStyle(fontWeight: FontWeight.bold)),
                          Text("${_rating.toStringAsFixed(1)} / 5.0",
                              style: TextStyle(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18)),
                        ],
                      ),
                      Slider(
                        value: _rating,
                        min: 0,
                        max: 5,
                        divisions: 10,
                        activeColor: theme.colorScheme.primary,
                        onChanged: (value) => setState(() => _rating = value),
                      ),
                      const Divider(height: 32),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Wajib Tonton Ulang',
                            style: TextStyle(fontWeight: FontWeight.w500)),
                        secondary: Icon(Icons.repeat_rounded, color: theme.colorScheme.primary),
                        value: _mustRewatch,
                        onChanged: (value) => setState(() => _mustRewatch = value),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 40),
              Container(
                width: double.infinity,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    )
                  ],
                ),
                child: FilledButton(
                  onPressed: isSaving ? null : _saveFilmNote,
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: isSaving
                      ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.save_rounded),
                            SizedBox(width: 10),
                            Text("Simpan Review",
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.2,
        color: Colors.grey,
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType? keyboardType,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              if (!isDark)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
            ],
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: const TextStyle(fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              labelText: label,
              hintText: hint,
              hintStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 14),
              prefixIcon: Icon(icon, size: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.transparent,
              contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            ),
          ),
        ),
      ],
    );
  }
}