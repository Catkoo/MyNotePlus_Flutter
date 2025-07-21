import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../models/note_model.dart';

class NoteViewModel extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final List<Note> _notes = [];

  List<Note> get notes => List.unmodifiable(_notes);

  StreamSubscription? _subscription;

  void startNoteListener() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    _subscription?.cancel();

    _subscription = _db
        .collection("users")
        .doc(uid)
        .collection("notes")
        .orderBy(
          "lastEdited",
          descending: true,
        ) // Urutkan berdasarkan lastEdited
        .snapshots()
        .listen((snapshot) {
          _notes.clear();
          for (var doc in snapshot.docs) {
            final data = doc.data();
            _notes.add(Note.fromMap(data, doc.id));
          }
          debugPrint('📝 Note listener: ${_notes.length} item');
          notifyListeners();
        });
  }

  void addNote(Note note) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final id = note.id.isEmpty ? const Uuid().v4() : note.id;
    final newNote = note.copyWith(
      id: id,
      ownerUid: uid,
      lastEdited:
          DateTime.now(), // Tambahkan timestamp saat ditambahkan/diupdate
    );

    _db
        .collection("users")
        .doc(uid)
        .collection("notes")
        .doc(id)
        .set(newNote.toMap());
  }

  void updateNote(Note note) {
    addNote(note); // Sudah menangani lastEdited juga
  }

  void removeNote(Note note) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    _db.collection("users").doc(uid).collection("notes").doc(note.id).delete();
  }

  Future<Note?> getNoteById(String id) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;

    final doc = await _db
        .collection("users")
        .doc(uid)
        .collection("notes")
        .doc(id)
        .get();

    if (doc.exists) {
      return Note.fromMap(doc.data()!, doc.id);
    }
    return null;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void clear() {
    _subscription?.cancel();
    _notes.clear();
    notifyListeners();
  }
}
