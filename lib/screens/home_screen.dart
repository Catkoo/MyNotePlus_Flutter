import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../viewmodel/note_view_model.dart';
import '../viewmodel/film_note_viewmodel.dart';
import '../models/note_model.dart'; 
import '../models/film_note.dart'; 
import 'profile_screen.dart';

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
        // Clear all previous data before listening
        Provider.of<NoteViewModel>(context, listen: false).clear();
        Provider.of<FilmNoteViewModel>(context, listen: false).clear();

        // Start new listener
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
          print('🔍 hasUnread: $hasData'); // Tambah ini buat debug
          setState(() {
            hasUnread = hasData;
          });
        });
  }

  
  void _initFCM() async {
    // ✅ Minta izin notifikasi (Android 13+)
    NotificationSettings settings = await _messaging.requestPermission();

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('✅ Notifikasi diizinkan');

      // ✅ Dapatkan token device (jika perlu)
      final token = await _messaging.getToken();
      debugPrint('📱 Token FCM: $token');

      // ✅ Listener saat pesan diterima saat foreground
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
       appBar: AppBar(
          title: const Text("MyNotePlus"),
          actions: [
            IconButton(
              onPressed: () async {
                await Navigator.pushNamed(context, '/notification');
                // Setelah kembali dari NotificationScreen, Firestore listener akan auto-refresh
              },
              icon: Stack(
                children: [
                  const Icon(Icons.notifications),
                  if (hasUnread)
                    const Positioned(
                      right: 0,
                      top: 0,
                      child: CircleAvatar(
                        radius: 6,
                        backgroundColor: Colors.red,
                        child: Text(
                          '1',
                          style: TextStyle(fontSize: 10, color: Colors.white),
                        ),
                      ),
                    ),
                ],
              ),

            ),
          ],
          bottom: selectedBottomTab == 0
              ? const TabBar(
                  tabs: [
                    Tab(text: "Pribadi"),
                    Tab(text: "Film/Drama"),
                  ],
                )
              : null,
        ),
        body: Stack(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: selectedBottomTab == 0
                  ? const TabBarView(
                      children: [PersonalNotesContent(), FilmNotesContent()],
                    )
                  : const ProfileScreen(),
            ),
            if (showBanner)
              BannerWidget(
                message: "Tersedia versi baru!",
                url: updateUrl,
                changelog: updateChangelog,
                onClose: () => setState(() => showBanner = false),
              ),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: selectedBottomTab,
          onDestinationSelected: (index) {
            setState(() => selectedBottomTab = index);
          },
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
            NavigationDestination(icon: Icon(Icons.person), label: 'Profil'),
          ],
        ),
        floatingActionButton: selectedBottomTab == 0
            ? Builder(
                builder: (context) {
                  return FloatingActionButton.extended(
                    onPressed: () {
                      final tabIndex = DefaultTabController.of(context).index;
                      if (tabIndex == 0) {
                        Navigator.pushNamed(context, '/add_note');
                      } else {
                        Navigator.pushNamed(context, '/add_film_note');
                      }
                    },
                    icon: const Icon(Icons.add),
                    label: const Text("Tambah"),
                  );
                },
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
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
                            Navigator.pop(
                              context,
                              note.isLocked ? "" : pin,
                            ); // "" = buka kunci
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
    return Consumer<NoteViewModel>(
      builder: (context, viewModel, _) {
        final allNotes = viewModel.notes;
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
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: InputDecoration(
                  hintText: "Cari catatan...",
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Expanded(
              child: filteredNotes.isEmpty
                  ? const Center(child: Text("Catatan tidak ditemukan."))
                  : ListView.builder(
                      itemCount: filteredNotes.length,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemBuilder: (context, index) {
                        final note = filteredNotes[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          elevation: 2,
                          child: ListTile(
                            leading: note.isPinned
                                ? const Icon(
                                    Icons.push_pin,
                                    color: Colors.amber,
                                  )
                                : null,
                            title: Text(note.title),
                            subtitle: Text(
                              note.isLocked ? '****' : note.content,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
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
                            onLongPress: () => _showNoteOptions(context, note),
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
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
                // Pinned di atas, lalu terbaru
                if (a.isPinned != b.isPinned) {
                  return b.isPinned ? 1 : -1;
                }
                return b.lastEdited.compareTo(a.lastEdited);
              });

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: InputDecoration(
                  hintText: "Cari film/drama...",
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Expanded(
              child: filteredNotes.isEmpty
                  ? const Center(child: Text("Film/drama tidak ditemukan."))
                  : ListView.builder(
                      itemCount: filteredNotes.length,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemBuilder: (context, index) {
                        final note = filteredNotes[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          elevation: 2,
                          color: note.isFinished ? Colors.green[50] : null,
                          child: ListTile(
                            leading: note.isPinned
                                ? const Icon(
                                    Icons.push_pin,
                                    color: Colors.amber,
                                  )
                                : null,
                            title: Text(note.title),
                            subtitle: Text(
                              "Tahun: ${note.year}  •  Episode: ${note.episodeWatched}",
                            ),
                            trailing: note.isFinished
                                ? const Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                  )
                                : null,
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                '/detail_film_note',
                                arguments: note.id,
                              );
                            },
                            onLongPress: () =>
                                _showFilmNoteOptions(context, note),
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
    return Positioned(
      top: 60,
      left: 16,
      right: 16,
      child: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.amber[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(changelog),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                TextButton(
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
                    child: const Text("Update"),
                  ),

                  TextButton(onPressed: onClose, child: const Text("Tutup")),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
