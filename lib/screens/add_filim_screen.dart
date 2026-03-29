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
  
  // ✅ Tambahan untuk Coming Soon Date
  DateTime? _selectedReleaseDate;

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

  // ✅ Ditambah 'Coming Soon'
  final statusOptions = ['Belum selesai', 'Selesai', 'Coming Soon'];
  String selectedStatus = 'Belum selesai';

  double _rating = 0.0;
  bool _mustRewatch = false;
  bool isSaving = false;

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
                "Pilih Platform Nonton",
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

  void _saveFilmNote() async {
    final title = _titleController.text.trim();
    final year = _yearController.text.trim();
    final media = _mediaController.text.trim();
    final episode = int.tryParse(_episodeController.text.trim()) ?? 0;
    final totalEpisode = int.tryParse(_totalEpisodeController.text.trim());

    if (title.isEmpty || year.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Judul dan Tahun wajib diisi')),
      );
      return;
    }

    setState(() => isSaving = true);

    // ✅ Konversi status UI ke String Model
    String dbStatus = 'watching';
    if (selectedStatus == 'Selesai') dbStatus = 'finished';
    if (selectedStatus == 'Coming Soon') dbStatus = 'coming_soon';

    final currentUser = FirebaseAuth.instance.currentUser;
    final note = FilmNote(
      id: const Uuid().v4(),
      title: title,
      year: year,
      media: media.isEmpty ? null : media,
      episodeWatched: selectedStatus == 'Coming Soon' ? 0 : episode,
      isFinished: selectedStatus == 'Selesai',
      ownerUid: currentUser?.uid ?? '',
      lastEdited: DateTime.now(),
      totalEpisodes: totalEpisode,
      overallRating: selectedStatus == 'Selesai' ? _rating : null,
      mustRewatch: selectedStatus == 'Selesai' ? _mustRewatch : null,
      status: dbStatus, // ✅ Disimpan ke Firestore
      nextEpisodeDate: _selectedReleaseDate, // ✅ Simpan tgl rilis jika ada
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
              Text("Review berhasil ditambahkan!"),
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
        selectedStatus == 'Belum selesai';

    if (isEmpty) return true;

    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text("Batal simpan?"),
        content: const Text("Data yang kamu isi akan hilang."),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text("Lanjut Isi")),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Buang"),
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
        final canExit = await _onWillPop();
        if (canExit && context.mounted) Navigator.of(context).pop(); 
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
              _buildSectionTitle("🎬 DETAIL INFORMASI"),
              const SizedBox(height: 12),
              _buildModernTextField(
                controller: _titleController,
                label: "Judul Film/Drama/Donghua",
                icon: Icons.movie_filter_rounded,
                textCapitalization: TextCapitalization.words,
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
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildModernTextField(
                      controller: _mediaController,
                      label: "Platform",
                      icon: Icons.connected_tv_rounded,
                      textCapitalization: TextCapitalization.words,
                      hint: "Pilih",
                      onTap: _showPlatformPicker,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSectionTitle("🚦 STATUS"),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
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
                              fontSize: 12,
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
              const SizedBox(height: 24),

              // ✅ Progres Nonton: Muncul jika BUKAN Coming Soon
              if (selectedStatus != 'Coming Soon') ...[
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
              ],

              // ✅ Tanggal Rilis: Muncul jika Coming Soon
              if (selectedStatus == 'Coming Soon') ...[
                _buildSectionTitle("📅 RENCANA TAYANG"),
                const SizedBox(height: 12),
                _buildModernTextField(
                  controller: TextEditingController(
                    text: _selectedReleaseDate == null 
                      ? "" 
                      : "${_selectedReleaseDate!.day}/${_selectedReleaseDate!.month}/${_selectedReleaseDate!.year}"
                  ),
                  label: "Tanggal Rilis",
                  icon: Icons.event_repeat_rounded,
                  hint: "Klik untuk pilih tanggal",
                  onTap: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2100),
                    );
                    if (pickedDate != null) {
                      setState(() => _selectedReleaseDate = pickedDate);
                    }
                  },
                ),
              ],

              // ✅ Rating: Muncul jika Selesai
              if (selectedStatus == 'Selesai') ...[
                const SizedBox(height: 32),
                _buildSectionTitle("⭐ PENILAIAN"),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
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
                      color: theme.colorScheme.primary.withOpacity(0.3),
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
        fontSize: 11,
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
    TextCapitalization textCapitalization = TextCapitalization.none,
    VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        controller: controller,
        onTap: onTap,
        readOnly: onTap != null, // Biar ga muncul keyboard kalau cuma buat pilih tgl/platform
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
        style: const TextStyle(fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
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
    );
  }
}