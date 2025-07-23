import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/film_note.dart';

class FilmNoteViewModel extends ChangeNotifier {
  final List<FilmNote> _filmNotes = [];
  final _db = FirebaseFirestore.instance;
  bool _isListening = false;

  List<FilmNote> get filmNotes => List.unmodifiable(_filmNotes);

  Future<void> addFilmNote(FilmNote note) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final id = note.id.isEmpty ? const Uuid().v4() : note.id;
    final newNote = note.copyWith(id: id, ownerUid: uid);

    await _db
        .collection('users')
        .doc(uid)
        .collection('film_notes')
        .doc(id)
        .set(newNote.toMap());
  }

  void updateFilmNote(FilmNote note) => addFilmNote(note);

  void deleteNote(String noteId) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    _db
        .collection("users")
        .doc(uid)
        .collection("film_notes")
        .doc(noteId)
        .delete();
  }

  Future<void> togglePin(String noteId, bool shouldPin) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await _db
        .collection('users')
        .doc(uid)
        .collection('film_notes')
        .doc(noteId)
        .update({'isPinned': shouldPin});
  }

  Future<FilmNote?> getFilmNoteById(String id) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;

    final doc = await _db
        .collection('users')
        .doc(uid)
        .collection('film_notes')
        .doc(id)
        .get();

    if (doc.exists) {
      return FilmNote.fromMap(doc.data()!, doc.id);
    }
    return null;
  }

  void startFilmNoteListener() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    _db
        .collection('users')
        .doc(uid)
        .collection('film_notes')
        .orderBy('lastEdited', descending: true)
        .snapshots()
        .listen((snapshot) {
          _filmNotes.clear();
          for (final doc in snapshot.docs) {
            final note = FilmNote.fromMap(doc.data(), doc.id);
            _filmNotes.add(note);
          }
          debugPrint('🎬 FilmNote listener: ${_filmNotes.length} item');
          notifyListeners();
        });

    _isListening = true;
  }

  /// Untuk mencari film yang akan tayang dalam 24 jam ke depan
  List<FilmNote> getUpcomingEpisodes() {
    final now = DateTime.now();
    return _filmNotes.where((note) {
      if (note.isFinished) return false;
      if (note.nextEpisodeDate == null) return false;
      return note.nextEpisodeDate!.isAfter(now) &&
          note.nextEpisodeDate!.isBefore(now.add(const Duration(days: 1)));
    }).toList();
  }

  void clear() {
    _filmNotes.clear();
    _isListening = false;
    notifyListeners();
  }
}
