import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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

          // fallback: jika route tidak ditemukan
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
