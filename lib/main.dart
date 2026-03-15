import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timezone/data/latest_all.dart' as tz;

import 'firebase_options.dart';
import 'services/notification_helper.dart';
import 'viewmodel/note_view_model.dart';
import 'viewmodel/film_note_viewmodel.dart';
import 'widgets/theme_provider.dart';
import 'services/backup_service.dart';
import 'services/google_drive_service.dart';

// Screens...
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/add_note_screen.dart';
import 'screens/edit_note_screen.dart';
import 'screens/detail_note_screen.dart';
import 'screens/add_filim_screen.dart';
import 'screens/edit_filim_screen.dart';
import 'screens/detail_filim_screen.dart';
import 'screens/notification_screen.dart';
import 'screens/privacy_policy_screen.dart';
import 'screens/terms_of_use.dart';

/// 🔔 Handler pesan dari FCM saat background
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('🔕 [Background] Pesan diterima: ${message.notification?.title}');
}

void main() async {
  // 1. Inisialisasi Dasar (Harus Cepat)
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // ⏰ Init timezone & Notifikasi
  tz.initializeTimeZones();
  await initializeNotifications();

  // 🔔 Init handler background FCM
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // ✅ Listener pesan FCM saat foreground
  setupForegroundNotificationListener();

  // ✅ Load tema awal
  final isDarkMode = await ThemeProvider.loadInitialTheme();

  // 🚀 JALANKAN APP TERLEBIH DAHULU (Agar tidak blank hitam)
  runApp(MyNotePlusApp(isDarkMode: isDarkMode));

  // 🆕 Jalankan Auto-backup SETELAH runApp (Tanpa 'await')
  // Ini akan berjalan di latar belakang tanpa mengganggu kemunculan UI
  _performAutoBackup();
}

/// Fungsi pembantu untuk memisahkan logika backup dari alur utama startup
Future<void> _performAutoBackup() async {
  try {
    final googleUser = await GoogleDriveService().googleSignIn.signInSilently();
    if (googleUser != null) {
      final file = await BackupService().exportDataToJson();
      await GoogleDriveService().uploadJsonBackup(
        file,
        "mynoteplus_backup.json",
      );
      debugPrint("✅ Auto-backup sukses di background");
    } else {
      debugPrint("ℹ️ Auto-backup dilewati: user belum login Google");
    }
  } catch (e) {
    debugPrint("❌ Auto-backup gagal: $e");
  }
}

/// Fungsi pembantu untuk merapikan listener notifikasi
void setupForegroundNotificationListener() {
  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    if (message.notification != null) {
      final title = message.notification!.title ?? '';
      final body = message.notification!.body ?? '';

      flutterLocalNotificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'film_reminder_channel',
            'Film Reminder',
            channelDescription: 'Notifikasi episode berikutnya film/drama',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
      );

      // Simpan ke Firestore (Hanya jika kamu benar-benar butuh simpan di semua user)
      final usersSnapshot = await FirebaseFirestore.instance.collection('users').get();
      for (var userDoc in usersSnapshot.docs) {
        FirebaseFirestore.instance
            .collection('users')
            .doc(userDoc.id)
            .collection('notifications')
            .add({
          'title': title,
          'message': body,
          'timestamp': FieldValue.serverTimestamp(),
          'isRead': false,
        });
      }
    }
  });
}

class MyNotePlusApp extends StatelessWidget {
  final bool isDarkMode;
  const MyNotePlusApp({super.key, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider(isDarkMode)),
        ChangeNotifierProvider(create: (_) => NoteViewModel()),
        ChangeNotifierProvider(create: (_) => FilmNoteViewModel()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'MyNotePlus',
            debugShowCheckedModeBanner: false,
            themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            theme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.light,
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.indigo,
                brightness: Brightness.light,
              ),
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.dark,
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.indigo,
                brightness: Brightness.dark,
              ),
            ),
            initialRoute: '/',
            routes: {
              '/': (context) => const SplashScreen(),
              '/login': (context) => const LoginScreen(),
              '/register': (context) => const RegisterScreen(),
              '/home': (context) => const HomeScreen(),
              '/add_note': (context) => const AddNoteScreen(),
              '/add_film_note': (context) => const AddFilmNoteScreen(),
              '/profile': (context) => const ProfileScreen(),
              '/notification': (context) => const NotificationScreen(),
              '/privacy_policy': (context) => const PrivacyPolicyScreen(),
              '/terms_of_use': (context) => const TermsOfUseScreen(),
            },
            onGenerateRoute: (settings) {
              final args = settings.arguments;
              switch (settings.name) {
                case '/edit_note':
                  if (args is String) {
                    return MaterialPageRoute(builder: (_) => EditNoteScreen(noteId: args));
                  }
                  break;
                case '/detail_note':
                  if (args is String) {
                    return MaterialPageRoute(builder: (_) => DetailNoteScreen(noteId: args));
                  }
                  break;
                case '/edit_film_note':
                  if (args is String) {
                    return MaterialPageRoute(builder: (_) => EditFilmNoteScreen(filmId: args));
                  }
                  break;
                case '/detail_film_note':
                  if (args is String) {
                    return MaterialPageRoute(builder: (_) => DetailFilmNoteScreen(filmId: args));
                  }
                  break;
              }
              return MaterialPageRoute(
                builder: (_) => const Scaffold(
                  body: Center(child: Text("404 - Halaman tidak ditemukan")),
                ),
              );
            },
          );
        },
      ),
    );
  }
}