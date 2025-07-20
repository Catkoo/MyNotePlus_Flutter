import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../viewmodel/note_view_model.dart';
import '../viewmodel/film_note_viewmodel.dart';
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

  @override
  void initState() {
    super.initState();

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

class PersonalNotesContent extends StatelessWidget {
  const PersonalNotesContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<NoteViewModel>(
      builder: (context, viewModel, _) {
        final notes = viewModel.notes;
        if (notes.isEmpty) {
          return const Center(child: Text("Belum ada catatan."));
        }
        return ListView.builder(
          itemCount: notes.length,
          padding: const EdgeInsets.all(16),
          itemBuilder: (context, index) {
            final note = notes[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              elevation: 2,
              child: ListTile(
                title: Text(note.title),
                subtitle: Text(
                  note.content,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/detail_note',
                    arguments: note.id,
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}

class FilmNotesContent extends StatelessWidget {
  const FilmNotesContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<FilmNoteViewModel>(
      builder: (context, viewModel, _) {
        final notes = viewModel.filmNotes;
        if (notes.isEmpty) {
          return const Center(child: Text("Belum ada catatan film."));
        }
        return ListView.builder(
          itemCount: notes.length,
          padding: const EdgeInsets.all(16),
          itemBuilder: (context, index) {
            final note = notes[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              elevation: 2,
              color: note.isFinished ? Colors.green[50] : null,
              child: ListTile(
                title: Text(note.title),
                subtitle: Text(
                  "Tahun: ${note.year}  •  Episode: ${note.episodeWatched}",
                ),
                trailing: note.isFinished
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : null,
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/detail_film_note',
                    arguments: note.id,
                  );
                },
              ),
            );
          },
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
                    onPressed: () {
                      // Implement open URL logic
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
