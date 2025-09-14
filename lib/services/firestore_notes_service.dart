import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/note.dart';

class FirestoreNotesService {
  static String _currentUid() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      throw Exception('Usuario no autenticado');
    }
    return uid;
  }

  static CollectionReference<Map<String, dynamic>> _notesCol() {
    final uid = _currentUid();
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('notes');
  }

  static Future<List<Note>> fetchNotes() async {
    final uid = _currentUid();
    final snap = await _notesCol().orderBy('createdAt', descending: true).get();
    return snap.docs.map<Note>((d) {
      final data = d.data();
      return Note(
        id: null,
        remoteKey: d.id,
        userId: uid,
        title: data['title'] as String,
        content: data['content'] as String,
        createdAt: DateTime.parse(data['createdAt'] as String),
        updatedAt: data['updatedAt'] != null ? DateTime.parse(data['updatedAt'] as String) : null,
      );
    }).toList();
  }

  static Future<Note> createNote(Note note) async {
    final uid = _currentUid();
    final doc = await _notesCol().add({
      'title': note.title,
      'content': note.content,
      'createdAt': note.createdAt.toIso8601String(),
      'updatedAt': note.updatedAt?.toIso8601String(),
    });
    final data = await doc.get();
    final d = data.data()!;
    return Note(
      id: null,
      remoteKey: doc.id,
      userId: uid,
      title: d['title'] as String,
      content: d['content'] as String,
      createdAt: DateTime.parse(d['createdAt'] as String),
      updatedAt: d['updatedAt'] != null ? DateTime.parse(d['updatedAt'] as String) : null,
    );
  }

  static Future<Note> updateNote(Note note) async {
    final uid = _currentUid();
    final key = note.remoteKey;
    if (key == null) throw Exception('remoteKey requerido para actualizar');
    await _notesCol().doc(key).update({
      'title': note.title,
      'content': note.content,
      'createdAt': note.createdAt.toIso8601String(),
      'updatedAt': note.updatedAt?.toIso8601String(),
    });
    final snap = await _notesCol().doc(key).get();
    final d = snap.data()!;
    return Note(
      id: note.id,
      remoteKey: key,
      userId: uid,
      title: d['title'] as String,
      content: d['content'] as String,
      createdAt: DateTime.parse(d['createdAt'] as String),
      updatedAt: d['updatedAt'] != null ? DateTime.parse(d['updatedAt'] as String) : null,
    );
  }

  static Future<void> deleteNote(Note note) async {
    final key = note.remoteKey;
    if (key == null) return;
    await _notesCol().doc(key).delete();
  }
}
