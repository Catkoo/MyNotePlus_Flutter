import 'dart:async';
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
import '../widgets/home_backup_sync_buttons.dart';
import '../viewmodel/note_view_model.dart';
import '../viewmodel/film_note_viewmodel.dart';
import '../models/note_model.dart';
import '../models/film_note.dart';
import 'profile_screen.dart';
import '../screens/profile_screen_with_backup.dart';
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

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

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

    FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
          final hasData = snapshot.docs.isNotEmpty;
          debugPrint('🔍 hasUnread: $hasData');
          setState(() {
            hasUnread = hasData;
          });
        });
  }

  void _initFCM() async {
    NotificationSettings settings = await _messaging.requestPermission();

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('✅ Notifikasi diizinkan');

      final token = await _messaging.getToken();
      debugPrint('📱 Token FCM: $token');

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        final notification = message.notification;
        if (notification != null) {
          _showLocalNotification(notification.title, notification.body);
          setState(() => hasNewNotification = true);
        }
      });
    } else {
      debugPrint('❌ Notifikasi tidak diizinkan');
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
  Widget build(BuildContext context) {
    if (isMaintenance) {
      return MaintenanceScreen(message: maintenanceMessage);
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        extendBody: true,
        appBar: AppBar(
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: Theme.of(
            context,
          ).colorScheme.surface.withOpacity(0.95),
          title: const Text(
            "MyNotePlus",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              letterSpacing: 0.5,
            ),
          ),
          centerTitle: true,
          actions: [
            // Notification icon
            IconButton(
              tooltip: "Notifikasi",
              onPressed: () async {
                await Navigator.pushNamed(context, '/notification');
              },
              icon: Stack(
                children: [
                  const Icon(Icons.notifications_outlined, size: 26),
                  if (hasUnread)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        height: 16,
                        width: 16,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Text(
                            '!',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Backup
            IconButton(
              icon: const Icon(Icons.cloud_upload_outlined, size: 24),
              tooltip: "Backup ke Google Drive",
              onPressed: () async {
                try {
                  final file = await BackupService().exportDataToJson();
                  await GoogleDriveService().uploadJsonBackup(
                    file,
                    "mynoteplus_backup.json",
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      content: const Text(
                        "✅ Backup berhasil diupload ke Google Drive",
                      ),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      content: Text("❌ Gagal backup: $e"),
                    ),
                  );
                }
              },
            ),

            // Restore
            IconButton(
              icon: const Icon(Icons.cloud_download_outlined, size: 24),
              tooltip: "Restore dari Google Drive",
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    title: const Text("Konfirmasi Restore"),
                    content: const Text(
                      "Data saat ini akan ditimpa. Lanjutkan?",
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text("Batal"),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text("Restore"),
                      ),
                    ],
                  ),
                );

                if (confirmed == true) {
                  try {
                    await BackupService().restoreFromJsonBackup();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        content: const Text("✅ Restore berhasil"),
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        content: Text("❌ Gagal restore: $e"),
                      ),
                    );
                  }
                }
              },
            ),
          ],
          bottom: selectedBottomTab == 0
              ? PreferredSize(
                  preferredSize: const Size.fromHeight(50),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TabBar(
                      indicator: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Theme.of(context).colorScheme.primaryContainer,
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      unselectedLabelColor: Theme.of(
                        context,
                      ).colorScheme.onSurfaceVariant,
                      labelColor: Theme.of(
                        context,
                      ).colorScheme.onPrimaryContainer,
                      tabs: const [
                        Tab(text: "Pribadi"),
                        Tab(text: "Film/Drama"),
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
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: NavigationBar(
            height: 65,
            backgroundColor: Colors.transparent,
            selectedIndex: selectedBottomTab,
            onDestinationSelected: (index) {
              setState(() => selectedBottomTab = index);
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Profil',
              ),
            ],
          ),
        ),
        floatingActionButton: selectedBottomTab == 0
            ? SpeedDial(
                animatedIcon: AnimatedIcons.add_event,
                backgroundColor: Theme.of(context).colorScheme.primary,
                overlayColor: Colors.black,
                overlayOpacity: 0.3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                children: [
                  SpeedDialChild(
                    child: const Icon(Icons.edit_note, color: Colors.white),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    label: "Tambah Catatan",
                    labelStyle: const TextStyle(fontSize: 14),
                    onTap: () {
                      Navigator.pushNamed(context, '/add_note');
                    },
                  ),
                  SpeedDialChild(
                    child: const Icon(
                      Icons.movie_creation_outlined,
                      color: Colors.white,
                    ),
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    label: "Tambah Film",
                    labelStyle: const TextStyle(fontSize: 14),
                    onTap: () {
                      Navigator.pushNamed(context, '/add_film_note');
                    },
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
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: isDark
                      ? Colors.grey[850]
                      : theme.colorScheme.surfaceVariant,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
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
                              color: isDark
                                  ? theme.colorScheme.surfaceVariant
                                        .withOpacity(0.5)
                                  : theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: isDark
                                      ? Colors.black.withOpacity(0.3)
                                      : Colors.grey.withOpacity(0.15),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 🔖 Top icons (pin / lock)
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    if (note.isPinned)
                                      const Icon(
                                        Icons.push_pin,
                                        color: Colors.amber,
                                        size: 18,
                                      ),
                                    if (note.isLocked)
                                      const Padding(
                                        padding: EdgeInsets.only(left: 4),
                                        child: Icon(
                                          Icons.lock,
                                          color: Colors.redAccent,
                                          size: 18,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                // 📌 Title
                                Text(
                                  note.title,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                // 📄 Content
                                Expanded(
                                  child: Text(
                                    note.isLocked ? "••••" : note.content,
                                    maxLines: 6,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      height: 1.4,
                                      color: isDark
                                          ? Colors.white70
                                          : Colors.black87,
                                    ),
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
                  hintText: "Cari film/drama...",
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: isDark
                      ? Colors.grey[850]
                      : theme.colorScheme.surfaceVariant,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 16,
                ),
              ),
            ),

            // 🎬 Film Notes Grid
            Expanded(
              child: filteredNotes.isEmpty
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.movie_creation_outlined,
                          size: 64,
                          color: isDark ? Colors.white24 : Colors.black26,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "Belum ada catatan film/drama",
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                        ),
                      ],
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                            childAspectRatio: 3 / 2,
                          ),
                      itemCount: filteredNotes.length,
                      itemBuilder: (context, index) {
                        final note = filteredNotes[index];

                        return InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              '/detail_film_note',
                              arguments: note.id,
                            );
                          },
                          onLongPress: () {
                            HapticFeedback.mediumImpact();
                            _showFilmNoteOptions(context, note);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: note.isFinished
                                  ? (isDark
                                        ? Colors.green[900]
                                        : Colors.green[50])
                                  : (isDark
                                        ? theme.colorScheme.surfaceVariant
                                              .withOpacity(0.6)
                                        : theme.colorScheme.surface),
                              boxShadow: [
                                BoxShadow(
                                  color: isDark
                                      ? Colors.black.withOpacity(0.3)
                                      : Colors.grey.withOpacity(0.15),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // 📌 Pinned icon
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      if (note.isPinned)
                                        const Icon(
                                          Icons.push_pin,
                                          color: Colors.amber,
                                          size: 18,
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),

                                  // 🎬 Title
                                  Text(
                                    note.title,
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
                                          color: isDark
                                              ? Colors.white
                                              : Colors.black87,
                                        ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),

                                  // 📊 Progress
                                  Text(
                                    "Tahun: ${note.year}",
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: isDark
                                          ? Colors.white70
                                          : Colors.black54,
                                    ),
                                  ),
                                  Text(
                                    "Episode: ${note.episodeWatched}",
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: isDark
                                          ? Colors.white70
                                          : Colors.black54,
                                    ),
                                  ),
                                  const Spacer(),

                                  // Status bar
                                  if (!note.isFinished)
                                    LinearProgressIndicator(
                                      value:
                                          (note.totalEpisodes != null &&
                                              note.totalEpisodes! > 0)
                                          ? note.episodeWatched /
                                                note.totalEpisodes!
                                          : 0,
                                      backgroundColor: isDark
                                          ? Colors.white10
                                          : Colors.grey[200],
                                      color: Colors.blueAccent,
                                      minHeight: 4,
                                      borderRadius: BorderRadius.circular(8),
                                    ),

                                  if (note.isFinished)
                                    const Align(
                                      alignment: Alignment.bottomRight,
                                      child: Icon(
                                        Icons.check_circle,
                                        color: Colors.green,
                                        size: 20,
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

    final changelogItems = changelog
        .split("\n")
        .where((e) => e.trim().isNotEmpty)
        .toList();

    return Positioned(
      top: 60,
      left: 16,
      right: 16,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(20),
        color: theme.colorScheme.surface,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border(
              left: BorderSide(color: theme.colorScheme.primary, width: 5),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🔹 Header
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                    child: Icon(
                      Icons.system_update_alt_rounded,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      message,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // 📜 Changelog scrollable
              SizedBox(
                height: 120,
                child: Scrollbar(
                  thumbVisibility: true,
                  radius: const Radius.circular(8),
                  child: ListView.separated(
                    itemCount: changelogItems.length,
                    itemBuilder: (context, index) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("• "),
                          Expanded(
                            child: Text(
                              changelogItems[index],
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      );
                    },
                    separatorBuilder: (_, __) => const SizedBox(height: 4),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 🔘 Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: onClose,
                    child: const Text("Tutup"),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: () async {
                      final uri = Uri.parse(url);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(
                          uri,
                          mode: LaunchMode.externalApplication,
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Gagal membuka link update'),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.open_in_new, size: 18),
                    label: const Text("Update"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
