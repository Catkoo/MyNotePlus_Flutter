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

  // Data Platform untuk Grid Picker
  final List<Map<String, dynamic>> platformList = [
    {'name': 'Netflix', 'icon': Icons.movie_filter_rounded},
    {'name': 'Iqiyi', 'icon': Icons.video_library_rounded},
    {'name': 'WeTV', 'icon': Icons.live_tv_rounded},
    {'name': 'Viu', 'icon': Icons.tv_rounded},
    {'name': 'Youku', 'icon': Icons.smart_display_rounded},
    {'name': 'Disney+', 'icon': Icons.auto_awesome_motion_rounded},
    {'name': 'Prime', 'icon': Icons.layers_rounded},
    {'name': 'YouTube', 'icon': Icons.play_circle_filled_rounded},
  ];

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

  // Tampilan Platform Picker Grid (Sama seperti halaman Add)
  void _showPlatformPicker() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 45,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 25),
              Text(
                "Pilih Platform",
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 25),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 15,
                  crossAxisSpacing: 15,
                  childAspectRatio: 0.8,
                ),
                itemCount: platformList.length + 1,
                itemBuilder: (context, index) {
                  if (index < platformList.length) {
                    final p = platformList[index];
                    return _buildPlatformItem(p['name'], p['icon'], theme);
                  } else {
                    return _buildPlatformItem("Lainnya", Icons.edit_note_rounded, theme, isManual: true);
                  }
                },
              ),
              const SizedBox(height: 30),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPlatformItem(String name, IconData icon, ThemeData theme, {bool isManual = false}) {
    final isDark = theme.brightness == Brightness.dark;
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        if (!isManual) {
          setState(() => _mediaController.text = name);
        }
      },
      borderRadius: BorderRadius.circular(20),
      child: Column(
        children: [
          Container(
            height: 60,
            width: 60,
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.05) : theme.colorScheme.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: theme.colorScheme.primary.withOpacity(0.1)),
            ),
            child: Icon(icon, color: theme.colorScheme.primary, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text("Abaikan Perubahan?"),
        content: const Text("Perubahan yang Anda buat belum disimpan."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Batal")),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            style: TextButton.styleFrom(foregroundColor: Colors.red),
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
        backgroundColor: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF5F7FA),
        appBar: AppBar(
          title: const Text('Edit Catatan', style: TextStyle(fontWeight: FontWeight.bold)),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: isDark ? Colors.white : Colors.black87,
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () async {
              if (await _onWillPop() && mounted) Navigator.pop(context);
            },
          ),
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Column(
                  children: [
                    _buildSectionCard(
                      "🎬 DETAIL INFORMASI",
                      Column(
                        children: [
                          _buildModernField(_titleController, "Judul Film/Drama/Donghua", Icons.movie_filter_rounded),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(child: _buildModernField(_yearController, "Tahun", Icons.calendar_month_rounded, isNum: true)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildModernField(
                                  _mediaController, 
                                  "Platform", 
                                  Icons.connected_tv_rounded,
                                  onTap: _showPlatformPicker,
                                  hint: "Pilih...",
                                )
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    _buildSectionCard(
                      "📺 PROGRES NONTON",
                      Column(
                        children: [
                          Row(
                            children: [
                              Expanded(child: _buildModernField(_episodeController, "Eps Ditonton", Icons.play_circle_fill_rounded, isNum: true)),
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
                        "⭐ REVIEW & RATING",
                        Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text("Rating", style: TextStyle(fontWeight: FontWeight.bold)),
                                Text("${_rating.toStringAsFixed(1)} / 5.0", 
                                  style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 18)),
                              ],
                            ),
                            Slider(
                              value: _rating,
                              min: 0, max: 5,
                              divisions: 10,
                              activeColor: theme.colorScheme.primary,
                              onChanged: (v) => setState(() => _rating = v),
                            ),
                            const Divider(height: 32),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text("Wajib Tonton Ulang?", style: TextStyle(fontWeight: FontWeight.w500)),
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

      Widget _buildModernField(
        TextEditingController controller, 
        String label, 
        IconData icon, {
        bool isNum = false, 
        VoidCallback? onTap, 
        String? hint
      }) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        
        return Container(
          margin: const EdgeInsets.only(top: 8), // Biar ada jarak dikit dari label atas
          child: TextField(
            controller: controller,
            onTap: onTap,
            keyboardType: isNum ? TextInputType.number : TextInputType.text,
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            decoration: InputDecoration(
              labelText: label,
              hintText: hint,
              prefixIcon: Icon(icon, size: 22, color: Theme.of(context).colorScheme.primary),
              
              // Warna background input
              filled: true,
              fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[50],
              
              // Border saat TIDAK diklik (Garis halus)
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: isDark ? Colors.white10 : Colors.black.withOpacity(0.1),
                  width: 1.5,
                ),
              ),
              
              // Border saat DIKLIK/FOKUS (Garis lebih tegas)
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                ),
              ),
              
              contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
            ),
          ),
        );
      }

  Widget _buildStatusSelector(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: statusOptions.map((status) {
          final isSelected = selectedStatus == status;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => selectedStatus = status),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? theme.colorScheme.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
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
        color: isDark ? Colors.white.withOpacity(0.02) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.2, color: Colors.grey)),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildSaveButton(ThemeData theme) {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: FilledButton(
        onPressed: isSaving ? null : _updateFilmNote,
        style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
        child: isSaving
            ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
            : const Text("SIMPAN PERUBAHAN", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 1)),
      ),
    );
  }
}