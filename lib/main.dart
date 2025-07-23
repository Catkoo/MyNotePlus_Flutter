import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_options.dart';
import 'viewmodel/note_view_model.dart';
import 'viewmodel/film_note_viewmodel.dart';


// Screens
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



/// 🔔 Handler pesan dari FCM saat background
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('🔕 [Background] Pesan diterima: ${message.notification?.title}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  await flutterLocalNotificationsPlugin.initialize(
    const InitializationSettings(android: androidSettings),
  );

  // ✅ Listener untuk pesan FCM saat foreground
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
            'my_channel',
            'General Notifications',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
      );

      // Kirim notifikasi ke semua user
      final usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .get();

      for (var userDoc in usersSnapshot.docs) {
        final uid = userDoc.id;
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
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
  runApp(const MyNotePlusApp());
}


class MyNotePlusApp extends StatelessWidget {
  const MyNotePlusApp({super.key});
  

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NoteViewModel()),
        ChangeNotifierProvider(create: (_) => FilmNoteViewModel()),
      ],
      child: MaterialApp(
        title: 'MyNotePlus',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
          useMaterial3: true,
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
        },
        onGenerateRoute: (settings) {
          final args = settings.arguments;

          switch (settings.name) {
            case '/edit_note':
              if (args is String) {
                return MaterialPageRoute(
                  builder: (_) => EditNoteScreen(noteId: args),
                );
              }
              break;
            case '/detail_note':
              if (args is String) {
                return MaterialPageRoute(
                  builder: (_) => DetailNoteScreen(noteId: args),
                );
              }
              break;
            case '/edit_film_note':
              if (args is String) {
                return MaterialPageRoute(
                  builder: (_) => EditFilmNoteScreen(filmId: args),
                );
              }
              break;
            case '/detail_film_note':
              if (args is String) {
                return MaterialPageRoute(
                  builder: (_) => DetailFilmNoteScreen(filmId: args),
                );
              }
              break;
          }

          return MaterialPageRoute(
            builder: (_) => const Scaffold(
              body: Center(child: Text("404 - Halaman tidak ditemukan")),
            ),
          );
        },
      ),
    );
  }
}
