import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/notes_database.dart';
import '../models/note.dart';
import 'firestore_notes_service.dart';

class SyncService {
  static Future<void> syncNotes() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final token = await user.getIdToken();
    if (token == null) return;
    final localNotes = await NotesDatabase.getNotesForUser(user.uid);
    for (final note in localNotes) {
      if (note.remoteKey != null) {
        try {
          final updated = await FirestoreNotesService.updateNote(note);
          final updatedLocal = Note(
            id: note.id,
            remoteKey: updated.remoteKey,
            userId: note.userId,
            title: updated.title,
            content: updated.content,
            createdAt: updated.createdAt,
            updatedAt: updated.updatedAt,
          );
          await NotesDatabase.updateNote(updatedLocal);
        } catch (e) {
          try {
            final created = await FirestoreNotesService.createNote(note);
            final createdLocal = Note(
              id: note.id,
              remoteKey: created.remoteKey,
              userId: note.userId,
              title: created.title,
              content: created.content,
              createdAt: created.createdAt,
              updatedAt: created.updatedAt,
            );
            await NotesDatabase.updateNote(createdLocal);
          } catch (_) {}
        }
      } else {
        try {
          final created = await FirestoreNotesService.createNote(note);
          final createdLocal = Note(
            id: note.id,
            remoteKey: created.remoteKey,
            userId: note.userId,
            title: created.title,
            content: created.content,
            createdAt: created.createdAt,
            updatedAt: created.updatedAt,
          );
          await NotesDatabase.updateNote(createdLocal);
        } catch (_) {}
      }
    }
    
  }
}
