import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
        isLoading = false;
      });
    } else {
      Navigator.pop(context);
    }
  }

  void _updateFilmNote() async {
    final title = _titleController.text.trim();
    final year = _yearController.text.trim();
    final media = _mediaController.text.trim();
    final episode = int.tryParse(_episodeController.text.trim()) ?? 0;
    final totalEpisode = int.tryParse(_totalEpisodeController.text.trim());

    if (title.isEmpty) {
      _showSnackBar('Judul tidak boleh kosong', Colors.red);
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
      totalEpisodes: totalEpisode,
      overallRating: selectedStatus == 'Selesai' ? _rating : null,
      mustRewatch: selectedStatus == 'Selesai' ? _mustRewatch : null,
    );

    await FilmNoteViewModel().updateFilmNote(updatedNote);

    if (!mounted) return;
    setState(() => isSaving = false);
    Navigator.pop(context, true);
    _showSnackBar('Catatan berhasil diperbarui', Colors.green);
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color, behavior: SnackBarBehavior.floating),
    );
  }

  bool get _hasChanges {
    if (_currentNote == null) return false;
    return _titleController.text.trim() != _currentNote!.title ||
        _yearController.text.trim() != _currentNote!.year ||
        _mediaController.text.trim() != (_currentNote!.media ?? '') ||
        _episodeController.text.trim() != _currentNote!.episodeWatched.toString() ||
        _totalEpisodeController.text.trim() != (_currentNote!.totalEpisodes?.toString() ?? '') ||
        selectedStatus != (_currentNote!.isFinished ? 'Selesai' : 'Belum selesai') ||
        _rating != (_currentNote!.overallRating ?? 0.0) ||
        _mustRewatch != (_currentNote!.mustRewatch ?? false);
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Abaikan Perubahan?"),
        content: const Text("Perubahan yang Anda buat belum disimpan."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Batal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, elevation: 0),
            onPressed: () => Navigator.pop(context, true), 
            child: const Text("Abaikan")
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
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) Navigator.pop(context);
      },
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA),
        appBar: AppBar(
          title: const Text('Edit Catatan', style: TextStyle(fontWeight: FontWeight.bold)),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: isDark ? Colors.white : Colors.black87,
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Column(
                  children: [
                    _buildSectionCard(
                      "DETAIL INFORMASI",
                      Column(
                        children: [
                          _buildModernField(_titleController, "Judul Film/Drama", Icons.movie_rounded),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(child: _buildModernField(_yearController, "Tahun", Icons.calendar_today_rounded, isNum: true)),
                              const SizedBox(width: 12),
                              Expanded(child: _buildModernField(_mediaController, "Media", Icons.tv_rounded)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    _buildSectionCard(
                      "PROGRES NONTON",
                      Column(
                        children: [
                          Row(
                            children: [
                              Expanded(child: _buildModernField(_episodeController, "Eps Ditonton", Icons.play_arrow_rounded, isNum: true)),
                              const SizedBox(width: 12),
                              Expanded(child: _buildModernField(_totalEpisodeController, "Total Eps", Icons.list_alt_rounded, isNum: true)),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _buildStatusSelector(theme),
                        ],
                      ),
                    ),
                    if (selectedStatus == 'Selesai')
                      _buildSectionCard(
                        "REVIEW & RATING",
                        Column(
                          children: [
                            Text("Rating: ${_rating.toStringAsFixed(1)} / 5.0", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Slider(
                              value: _rating,
                              min: 0, max: 5,
                              divisions: 10,
                              activeColor: theme.colorScheme.primary,
                              onChanged: (v) => setState(() => _rating = v),
                            ),
                            SwitchListTile(
                              title: const Text("Wajib Tonton Ulang?", style: TextStyle(fontSize: 15)),
                              value: _mustRewatch,
                              secondary: Icon(Icons.repeat_rounded, color: theme.colorScheme.primary),
                              onChanged: (v) => setState(() => _mustRewatch = v),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 32),
                    _buildSaveButton(theme),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildModernField(TextEditingController controller, String label, IconData icon, {bool isNum = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextField(
      controller: controller,
      keyboardType: isNum ? TextInputType.number : TextInputType.text,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      ),
    );
  }

  Widget _buildStatusSelector(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark ? Colors.white.withOpacity(0.05) : Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: statusOptions.map((status) {
          final isSelected = selectedStatus == status;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => selectedStatus = status),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? theme.colorScheme.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: isSelected ? [BoxShadow(color: theme.colorScheme.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))] : [],
                ),
                child: Center(
                  child: Text(
                    status,
                    style: TextStyle(color: isSelected ? Colors.white : Colors.grey, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSectionCard(String title, Widget child) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: Colors.blueGrey)),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildSaveButton(ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: isSaving ? null : _updateFilmNote,
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          elevation: 4,
          shadowColor: theme.colorScheme.primary.withOpacity(0.4),
        ),
        child: isSaving
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text("SIMPAN PERUBAHAN", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 1)),
      ),
    );
  }
}