import 'dart:async';
import 'package:rxdart/rxdart.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import '../viewmodel/note_view_model.dart';
import '../viewmodel/film_note_viewmodel.dart';
import '../models/note_model.dart';
import '../models/film_note.dart';
import 'profile_screen.dart';
import '../services/backup_service.dart';
import '../services/google_drive_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedBottomTab = 0;
  String currentVersion = "";
  bool isMaintenance = false;
  bool showBanner = false;
  String maintenanceMessage = "";
  String updateUrl = "";
  String updateChangelog = "";
  bool hasNewNotification = false;
  bool hasUnread = false;
  StreamSubscription? _unreadSub;

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

        // Fungsi untuk menangani Backup ke Google Drive
      Future<void> _handleBackup() async {
        try {
          // Menampilkan loading sederhana (opsional)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Sedang mencadangkan data..."), duration: Duration(seconds: 1)),
          );

          final file = await BackupService().exportDataToJson();
          await GoogleDriveService().uploadJsonBackup(
            file,
            "mynoteplus_backup.json",
          );

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                behavior: SnackBarBehavior.floating,
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                content: const Text("✅ Backup berhasil diupload ke Google Drive"),
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                behavior: SnackBarBehavior.floating,
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                content: Text("❌ Gagal backup: $e"),
              ),
            );
          }
        }
      }

      // Fungsi untuk menangani Restore dari Google Drive
      Future<void> _handleRestore() async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text("Konfirmasi Restore"),
            content: const Text("Data saat ini di aplikasi akan ditimpa dengan data dari Drive. Lanjutkan?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Batal"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Ya, Restore"),
              ),
            ],
          ),
        );

        if (confirmed == true) {
          try {
            await BackupService().restoreFromJsonBackup();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  content: const Text("✅ Restore berhasil! Silakan cek catatan Anda."),
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  content: Text("❌ Gagal restore: $e"),
                ),
              );
            }
          }
        }
      }

  @override
  void initState() {
    super.initState();
    _initFCM();
    _listenForUnreadNotifications();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        Provider.of<NoteViewModel>(context, listen: false).clear();
        Provider.of<FilmNoteViewModel>(context, listen: false).clear();

        Provider.of<NoteViewModel>(context, listen: false).startNoteListener();
        Provider.of<FilmNoteViewModel>(
          context,
          listen: false,
        ).startFilmNoteListener();

        _getVersionAndLoadConfig();
      }
    });
  }

  Future<void> _getVersionAndLoadConfig() async {
    final info = await PackageInfo.fromPlatform();
    currentVersion = info.version;
    _loadAppConfig();
  }

  void _loadAppConfig() async {
    final doc = await FirebaseFirestore.instance
        .collection("app_config")
        .doc("status")
        .get();
    final latestVersion = doc.get("latest_version") ?? currentVersion;
    final url = doc.get("update_url") ?? "";
    final changelog = doc.get("update_changelog") ?? "";
    final isMaint = doc.get("maintenance_mode") ?? false;
    final maintMessage =
        doc.get("maintenance_message") ?? "Sedang dalam perbaikan.";

    if (isMaint) {
      setState(() {
        isMaintenance = true;
        maintenanceMessage = maintMessage;
      });
    } else if (latestVersion != currentVersion) {
      setState(() {
        showBanner = true;
        updateUrl = url;
        updateChangelog = changelog;
      });
    }
  }

    void _listenForUnreadNotifications() {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      _unreadSub?.cancel();

      final globalStream = FirebaseFirestore.instance
          .collection('announcements')
          .snapshots();

      final readStream = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('readAnnouncements')
          .snapshots();

      final personalStream = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .snapshots();

      _unreadSub = Rx.combineLatest3(
        globalStream,
        readStream,
        personalStream,
        (QuerySnapshot globalSnap, QuerySnapshot readSnap, QuerySnapshot personalSnap) {

          final globalDocs = globalSnap.docs;
          final readIds = readSnap.docs.map((e) => e.id).toSet();
          final personalUnread = personalSnap.docs.length;

          // 🔥 HITUNG YANG BELUM DIBACA (GLOBAL)
          final globalUnread = globalDocs
              .where((doc) => !readIds.contains(doc.id))
              .length;

          return globalUnread + personalUnread;
        },
      ).listen((totalUnread) {
        if (mounted) {
          setState(() {
            hasUnread = totalUnread > 0;
          });
        }
      });
    }

    void _initFCM() async {
    NotificationSettings settings = await _messaging.requestPermission();

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('✅ Notifikasi diizinkan');

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        final notification = message.notification;
        if (notification != null) {
          _showLocalNotification(notification.title, notification.body);
        }
      });
    }
  }
  void _showLocalNotification(String? title, String? body) {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'default_channel',
          'Default',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: false,
        );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    _localNotifications.show(
      0,
      title ?? 'Notifikasi',
      body ?? '',
      platformDetails,
    );
  }

  @override
      void dispose() {
      _unreadSub?.cancel(); // Sangat penting untuk performa
      super.dispose();
    }
  Widget build(BuildContext context) {
    if (isMaintenance) {
      return MaintenanceScreen(message: maintenanceMessage);
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        extendBody: true,
          appBar: AppBar(
            elevation: 0,
            scrolledUnderElevation: 2, // Memberi efek elevasi halus saat konten di-scroll
            backgroundColor: Theme.of(context).colorScheme.surface.withValues(alpha: 0.95),
            centerTitle: true,
            title: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "MyNotePlus",
                  style: TextStyle(
                    fontWeight: FontWeight.bold, 
                    fontSize: 20, 
                    letterSpacing: 0.8,
                  ),
                ),
                Text(
                  "Digital Notebook",
                  style: TextStyle(
                    fontSize: 10, 
                    color: Colors.grey[600], 
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
            leading: const Icon(Icons.notes_rounded, color: Colors.indigo),
            actions: [
              Stack(
                alignment: Alignment.center,
                children: [
                    IconButton(
                      tooltip: "Notifikasi",
                      onPressed: () async {
                        await Navigator.pushNamed(context, '/notification');
                      },
                      icon: Icon(
                        hasUnread ? Icons.notifications_active_rounded : Icons.notifications_none_rounded,
                        size: 26,
                        color: hasUnread ? Colors.indigo : Colors.grey[600],
                      ),
                    ),
                  if (hasUnread)
                    Positioned(
                      right: 12,
                      top: 14,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Theme.of(context).colorScheme.surface, 
                            width: 2,
                          ),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 10,
                          minHeight: 10,
                        ),
                      ),
                    ),
                ],
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.cloud_outlined),
                onSelected: (value) {
                  if (value == 'backup') _handleBackup(); // Pindahkan logika backup ke function sendiri
                  if (value == 'restore') _handleRestore(); // Pindahkan logika restore ke function sendiri
                },
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'backup',
                    child: ListTile(
                      leading: Icon(Icons.cloud_upload_outlined, color: Colors.blue),
                      title: Text("Backup Cloud"),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'restore',
                    child: ListTile(
                      leading: Icon(Icons.cloud_download_outlined, color: Colors.green),
                      title: Text("Restore Data"),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
            ],

            // --- TABBAR DESIGN (Pribadi & Film) ---
            bottom: selectedBottomTab == 0
                ? PreferredSize(
                    preferredSize: const Size.fromHeight(55),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: TabBar(
                        dividerColor: Colors.transparent,
                        indicator: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Theme.of(context).colorScheme.primary,
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        labelColor: Colors.white,
                        unselectedLabelColor: Colors.grey[600],
                        tabs: const [
                          Tab(child: Text("Pribadi")),
                          Tab(child: Text("Film/Drama/Donghua")),
                        ],
                      ),
                    ),
                  )
                : null,
          ),
        body: Stack(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              child: Padding(
                padding: const EdgeInsets.only(
                  bottom: 80,
                ), // 👈 tinggi nav bar custom kamu
                child: selectedBottomTab == 0
                    ? const TabBarView(
                        children: [PersonalNotesContent(), FilmNotesContent()],
                      )
                    : const ProfileScreen(),
              ),
            ),
            if (showBanner)
              Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Card(
                    elevation: 8,
                    shadowColor: Colors.black45,
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.95),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: ListTile(
                      leading: const Icon(
                        Icons.system_update,
                        color: Colors.white,
                        size: 28,
                      ),
                      title: const Text(
                        "Tersedia versi baru!",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      subtitle: Text(
                        updateChangelog,
                        style: const TextStyle(color: Colors.white70),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => setState(() => showBanner = false),
                      ),
                      onTap: () async {
                        if (await canLaunchUrl(Uri.parse(updateUrl))) {
                          launchUrl(
                            Uri.parse(updateUrl),
                            mode: LaunchMode.externalApplication,
                          );
                        }
                      },
                    ),
                  ),
                ),
              ),
          ],
        ),
        bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 24), 
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1), 
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: NavigationBar(
            height: 70, 
            elevation: 0,
            backgroundColor: Theme.of(context).colorScheme.surface,
            selectedIndex: selectedBottomTab,
            indicatorColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            onDestinationSelected: (index) => setState(() => selectedBottomTab = index),
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded, color: Theme.of(context).colorScheme.primary),
                label: 'Beranda',
              ),
              NavigationDestination(
                icon: const Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person_rounded, color: Theme.of(context).colorScheme.primary),
                label: 'Profil',
              ),
            ],
          ),
        ),
      ),
        floatingActionButton: selectedBottomTab == 0
            ? SpeedDial(
                icon: Icons.add_rounded, 
                activeIcon: Icons.close_rounded,
                spacing: 12, // Jarak antara tombol utama dan anak-anaknya
                spaceBetweenChildren: 8,
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                overlayColor: Colors.black,
                overlayOpacity: 0.4, // Sedikit lebih gelap agar fokus ke menu
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18), // Sedikit lebih bulat agar matching dengan card
                ),
                elevation: 8,
                animationCurve: Curves.easeInOut,
                children: [
                  SpeedDialChild(
                    child: const Icon(Icons.movie_filter_rounded, color: Colors.white),
                    backgroundColor: Colors.orange[400], // Warna yang ceria untuk film
                    label: "Tambah Progres Film/Drama/Donghua",
                    labelStyle: const TextStyle(fontWeight: FontWeight.w600),
                    labelBackgroundColor: isDark ? Colors.grey[800] : Colors.white,
                    onTap: () => Navigator.pushNamed(context, '/add_film_note'),
                  ),
                  SpeedDialChild(
                    child: const Icon(Icons.edit_note_rounded, color: Colors.white),
                    backgroundColor: Colors.blue[400], // Warna kalem untuk catatan
                    label: "Buat Catatan Umum",
                    labelStyle: const TextStyle(fontWeight: FontWeight.w600),
                    labelBackgroundColor: isDark ? Colors.grey[800] : Colors.white,
                    onTap: () => Navigator.pushNamed(context, '/add_note'),
                  ),
                ],
              )
            : null,
      ),
    );
  }
}

class PersonalNotesContent extends StatefulWidget {
  const PersonalNotesContent({super.key});

  @override
  State<PersonalNotesContent> createState() => _PersonalNotesContentState();
}

class _PersonalNotesContentState extends State<PersonalNotesContent> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  void _showPinDialog(
    BuildContext context,
    String correctPin,
    VoidCallback onSuccess,
  ) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text("Masukkan PIN"),
          content: TextField(
            controller: controller,
            obscureText: true,
            maxLength: 4,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: "4-digit PIN"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal"),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text == correctPin) {
                  Navigator.pop(context);
                  onSuccess();
                } else {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text("PIN salah")));
                }
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  void _showNoteOptions(BuildContext context, Note note) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  note.isPinned ? Icons.push_pin_outlined : Icons.push_pin,
                ),
                title: Text(note.isPinned ? 'Lepas Pin' : 'Pin Catatan'),
                onTap: () {
                  Provider.of<NoteViewModel>(
                    context,
                    listen: false,
                  ).togglePin(note.id, !note.isPinned);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(note.isLocked ? Icons.lock_open : Icons.lock),
                title: Text(note.isLocked ? 'Buka Kunci' : 'Kunci dengan PIN'),
                onTap: () async {
                  Navigator.pop(context);

                  final pinController = TextEditingController();
                  final result = await showDialog<String>(
                    context: context,
                    builder: (_) => AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      title: Text(
                        note.isLocked ? "Buka Kunci" : "Atur PIN (4 angka)",
                      ),
                      content: TextField(
                        controller: pinController,
                        obscureText: true,
                        maxLength: 4,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: "Masukkan PIN",
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Batal"),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            final pin = pinController.text.trim();
                            if (!note.isLocked && pin.length != 4) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("PIN harus 4 angka"),
                                ),
                              );
                              return;
                            }
                            Navigator.pop(context, note.isLocked ? "" : pin);
                          },
                          child: Text(note.isLocked ? "Buka" : "Kunci"),
                        ),
                      ],
                    ),
                  );

                  if (result != null) {
                    await Provider.of<NoteViewModel>(
                      context,
                      listen: false,
                    ).setNotePin(note.id, result.isEmpty ? null : result);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Hapus Catatan'),
                onTap: () {
                  Provider.of<NoteViewModel>(
                    context,
                    listen: false,
                  ).deleteNote(note.id);
                  Navigator.pop(context);
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.close),
                title: const Text('Batal'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

    Color _getNoteColor(int index, bool isDark) {
    // Daftar warna pastel untuk mode terang
    final lightColors = [
      const Color(0xFFE3F2FD), // Biru muda
      const Color(0xFFF1F8E9), // Hijau muda
      const Color(0xFFFFF3E0), // Oranye muda
      const Color(0xFFFCE4EC), // Pink muda
      const Color(0xFFF3E5F5), // Ungu muda
    ];

    // Daftar warna gelap yang elegan untuk mode gelap
    final darkColors = [
      const Color(0xFF1A237E).withOpacity(0.3), // Dark Blue
      const Color(0xFF1B5E20).withOpacity(0.3), // Dark Green
      const Color(0xFF4E342E).withOpacity(0.3), // Dark Brown
      const Color(0xFF311B92).withOpacity(0.3), // Dark Purple
    ];

    if (isDark) {
      return darkColors[index % darkColors.length];
    } else {
      return lightColors[index % lightColors.length];
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Consumer<NoteViewModel>(
      builder: (context, viewModel, _) {
        final allNotes = viewModel.notes;
        final filteredNotes =
            allNotes
                .where(
                  (note) =>
                      note.title.toLowerCase().contains(
                        _searchQuery.toLowerCase(),
                      ) ||
                      note.content.toLowerCase().contains(
                        _searchQuery.toLowerCase(),
                      ),
                )
                .toList()
              ..sort((a, b) {
                if (a.isPinned != b.isPinned) {
                  return b.isPinned ? 1 : -1;
                }
                return b.lastEdited.compareTo(a.lastEdited);
              });

        return Column(
          children: [
            // 🔍 Search Bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: InputDecoration(
                    hintText: "Cari catatan...",
                    hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38),
                    prefixIcon: Icon(Icons.search_rounded, color: theme.colorScheme.primary),
                    filled: true,
                    fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100],
                    contentPadding: const EdgeInsets.symmetric(vertical: 0), // Biar lebih ramping
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 16,
                ),
              ),
            ),

            // 📝 Notes Grid
            Expanded(
              child: filteredNotes.isEmpty
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.note_alt_outlined,
                          size: 64,
                          color: isDark ? Colors.white24 : Colors.black26,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "Belum ada catatan",
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                        ),
                      ],
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                            childAspectRatio: 0.95,
                          ),
                      itemCount: filteredNotes.length,
                      itemBuilder: (context, index) {
                        final note = filteredNotes[index];
                        return InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () {
                            if (note.isLocked) {
                              _showPinDialog(context, note.pin!, () {
                                Navigator.pushNamed(
                                  context,
                                  '/detail_note',
                                  arguments: note.id,
                                );
                              });
                            } else {
                              Navigator.pushNamed(
                                context,
                                '/detail_note',
                                arguments: note.id,
                              );
                            }
                          },
                          onLongPress: () {
                            HapticFeedback.mediumImpact();
                            _showNoteOptions(context, note);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              // Menggunakan fungsi getNoteColor yang kita bahas sebelumnya
                              color: _getNoteColor(index, isDark), 
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: isDark ? Colors.black26 : Colors.grey.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // --- HEADER: TANGGAL & STATUS ---
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.access_time_rounded,
                                          size: 10,
                                          color: isDark ? Colors.white38 : Colors.black38,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          "${note.lastEdited.day}/${note.lastEdited.month}",
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: isDark ? Colors.white38 : Colors.black38,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        if (note.isPinned)
                                          const Icon(Icons.push_pin_rounded, size: 14, color: Colors.orange),
                                        if (note.isLocked)
                                          const Padding(
                                            padding: EdgeInsets.only(left: 4),
                                            child: Icon(Icons.lock_rounded, size: 14, color: Colors.redAccent),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                // --- BODY: JUDUL ---
                                Text(
                                  note.title,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),

                                // --- BODY: ISI CATATAN ---
                                Expanded(
                                  child: Text(
                                    note.isLocked ? "Konten ini terkunci..." : note.content,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      height: 1.4,
                                      color: isDark ? Colors.white70 : Colors.black54,
                                    ),
                                    maxLines: 4,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),

                                // --- FOOTER: DEKORASI ---
                                Align(
                                  alignment: Alignment.bottomRight,
                                  child: Icon(
                                    Icons.more_horiz,
                                    size: 16,
                                    color: isDark ? Colors.white24 : Colors.black12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

class FilmNotesContent extends StatefulWidget {
  const FilmNotesContent({super.key});

  @override
  State<FilmNotesContent> createState() => _FilmNotesContentState();
}

class _FilmNotesContentState extends State<FilmNotesContent> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  void _showFilmNoteOptions(BuildContext context, FilmNote note) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  note.isPinned ? Icons.push_pin_outlined : Icons.push_pin,
                ),
                title: Text(note.isPinned ? 'Lepas Pin' : 'Pin Catatan'),
                onTap: () {
                  Provider.of<FilmNoteViewModel>(
                    context,
                    listen: false,
                  ).togglePin(note.id, !note.isPinned);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Hapus Catatan'),
                onTap: () {
                  Provider.of<FilmNoteViewModel>(
                    context,
                    listen: false,
                  ).deleteNote(note.id);
                  Navigator.pop(context);
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.close),
                title: const Text('Batal'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Consumer<FilmNoteViewModel>(
      builder: (context, viewModel, _) {
        final allNotes = viewModel.filmNotes;
        final filteredNotes =
            allNotes
                .where(
                  (note) => note.title.toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  ),
                )
                .toList()
              ..sort((a, b) {
                if (a.isPinned != b.isPinned) {
                  return b.isPinned ? 1 : -1;
                }
                return b.lastEdited.compareTo(a.lastEdited);
              });

        return Column(
          children: [
            // 🔍 Search
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: InputDecoration(
                    hintText: "Cari film/drama/donghua...",
                    hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38),
                    prefixIcon: Icon(Icons.search_rounded, color: theme.colorScheme.primary),
                    filled: true,
                    fillColor: isDark ? Colors.grey[900] : Colors.grey[100],
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16), // Kotak melengkung modern
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
                    ),
                  ),
                ),
            ),

            // 🎬 Film Notes Grid
            Expanded(
              child: filteredNotes.isEmpty
                  ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(32),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withOpacity(0.05),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.movie_filter_rounded,
                                  size: 80,
                                  color: theme.colorScheme.primary.withOpacity(0.4),
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                "Belum ada koleksi film/drama/donghua",
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 40),
                                child: Text(
                                  "Catat film/drama/donghua yang sedang kamu tonton agar tidak lupa progresnya!",
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: isDark ? Colors.white54 : Colors.black54,
                                  ),
                                ),
                              ),
                            ],
                                              )
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                            childAspectRatio: 3 / 2.5,
                          ),
                      itemCount: filteredNotes.length,
                      itemBuilder: (context, index) {
                        final note = filteredNotes[index];
                        return InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () => Navigator.pushNamed(context, '/detail_film_note', arguments: note.id),
                          onLongPress: () {
                            HapticFeedback.mediumImpact();
                            _showFilmNoteOptions(context, note);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: note.isFinished
                                  ? (isDark ? Colors.green.withOpacity(0.15) : Colors.green[50])
                                  : (isDark ? theme.colorScheme.surfaceVariant.withOpacity(0.4) : Colors.white),
                              border: Border.all(
                                color: note.isFinished 
                                    ? Colors.green.withOpacity(0.3) 
                                    : (isDark ? Colors.white10 : Colors.grey.withOpacity(0.2)),
                                width: 1,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Stack(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      // KUNCI UTAMA: Mendorong grup atas ke atas, grup bawah ke bawah
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                                      children: [
                                        // --- GRUP ATAS: JUDUL & TAHUN ---
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              note.title,
                                              style: theme.textTheme.titleMedium?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: -0.5,
                                                color: isDark ? Colors.white : Colors.black87,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                "${note.year}",
                                                style: theme.textTheme.labelSmall?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                  color: isDark ? Colors.white70 : Colors.black54,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),

                                        // --- GRUP BAWAH: EPISODE & PROGRESS BAR ---
                                        Column(
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  "Eps: ${note.episodeWatched}/${note.totalEpisodes ?? '?'}",
                                                  style: theme.textTheme.bodySmall?.copyWith(
                                                    fontWeight: FontWeight.w500,
                                                    color: isDark ? Colors.white60 : Colors.black45,
                                                  ),
                                                ),
                                                if (note.isFinished)
                                                  const Icon(Icons.check_circle_rounded, color: Colors.green, size: 18),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            // Bar ini sekarang aman karena dibungkus dalam grup bawah
                                            if (!note.isFinished)
                                              ClipRRect(
                                                borderRadius: BorderRadius.circular(10),
                                                child: LinearProgressIndicator(
                                                  value: (note.totalEpisodes != null && note.totalEpisodes! > 0)
                                                      ? note.episodeWatched / note.totalEpisodes!
                                                      : 0,
                                                  backgroundColor: isDark ? Colors.white10 : Colors.grey[200],
                                                  color: theme.colorScheme.primary,
                                                  minHeight: 6,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Pin Indicator (Positioned)
                                  if (note.isPinned)
                                    Positioned(
                                      top: 0,
                                      right: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.amber.withOpacity(0.2),
                                          borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(12)),
                                        ),
                                        child: const Icon(Icons.push_pin_rounded, color: Colors.amber, size: 14),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

class MaintenanceScreen extends StatelessWidget {
  final String message;
  const MaintenanceScreen({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF212121),
      body: Center(
        child: Card(
          margin: const EdgeInsets.all(24),
          color: Colors.orange[100],
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "\u{1F6E0}\uFE0F Maintenance Mode",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepOrange,
                  ),
                ),
                const SizedBox(height: 12),
                Text(message, style: const TextStyle(fontSize: 16)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
class BannerWidget extends StatelessWidget {
  final String message;
  final String url;
  final String changelog;
  final VoidCallback onClose;

  const BannerWidget({
    super.key,
    required this.message,
    required this.url,
    required this.changelog,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Parsing changelog menjadi list
    final changelogItems = changelog
        .split("\n")
        .where((e) => e.trim().isNotEmpty)
        .toList();

    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 16,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withOpacity(0.9), // Glassmorphism effect
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 25,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Bagian Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 12, 0),
                  child: Row(
                    children: [
                      // Animated-like Icon Container
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.primary.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              message,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                              ),
                            ),
                            Text(
                              "Pembaruan sistem tersedia",
                              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: onClose,
                        icon: Icon(Icons.close_rounded, color: Colors.grey[400], size: 20),
                      ),
                    ],
                  ),
                ),

                // Changelog Section
                if (changelogItems.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 80),
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: changelogItems.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("• ", style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                                  Expanded(
                                    child: Text(
                                      changelogItems[index],
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: Colors.black87,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),

                // Action Buttons
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: onClose,
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.grey[600],
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Text("Nanti Saja"),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ).copyWith(
                            // Efek shadow saat ditekan
                            elevation: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.pressed) ? 0 : 4),
                          ),
                          onPressed: () async {
                            final Uri _url = Uri.parse(url);
                            if (await canLaunchUrl(_url)) {
                              await launchUrl(_url, mode: LaunchMode.externalApplication);
                            }
                          },
                          child: const Text(
                            "Update Sekarang",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}